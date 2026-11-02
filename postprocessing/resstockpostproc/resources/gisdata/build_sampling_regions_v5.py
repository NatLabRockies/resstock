"""Apply the v5 sampling regions and County x PUMA weather to the sampler, options_lookup and allocator.

v5 replaces the county-built regions (v1/v3) with 300 regions clustered on weather from County x PUMA
cells, and gives each cell its own weather file. Both come from one table, `sampling_regions_v5_cells.csv`,
built by the 2026-08 New Sampling change documentation analysis (`sampling_regions_v5_build.py`):

  * Weather: each cell takes the AMY2018 county weather file whose station best matches the degree days
    where the cell's housing units are, among files on the county's own (zip code) UTC offset, so the
    simulation clock does not change.
  * Regions: within each state x UTC offset piece, cells are ordered by an energy index of their weather
    (2.34 kWh per HDD65 + 1.73 kWh per CDD65, fitted on the 6_15 run) and cut into contiguous runs by an
    optimal 1-D partition; 300 regions are spread over the pieces greedily by the reduction in
    within-region variance, with a floor of 0.02% of housing units per region. California is clustered
    like every other state (no CEC climate zones). A region never crosses a state line or a clock.

    v5_id = state_fips * 10000 + abs(utc_offset) * 100 + k     (k = 1-based rank by energy index)

The table covers the cells that hold 2010 tracts. The sampler also has 11 cells under county codes that
postdate them or that the tracts leave out (Alaska's 2013-2019 splits, Kusilvak, Oglala Lakota, Kalawao);
each takes the region of the largest cell of the same PUMA on the county's own UTC offset, and keeps the
weather file its County row sets today. The UTC offset is the one the simulation runs on: that of the
County row's zip code (zipcode_weather_stations.csv). The 82 Puerto Rico cells only options_lookup lists
have no County row and no weather file, and are left as they are.

Writes:
  sampling_regions_v5.json                  "county|puma" -> region, for every sampler cell (the allocator's key)
  sampling_regions_v5_validation.txt        the checks below
  project_national/housing_characteristics/Sampling Region.tsv   (Dependency=County and PUMA)
  project_testing/housing_characteristics/County and PUMA.tsv    (Dependency=County, from the national one)
  resources/options_lookup.tsv              Sampling Region options; location_epw_path moved from County
                                            to County and PUMA

Usage:  python -I -X utf8 build_sampling_regions_v5.py
"""

import csv
import json
import os
import re
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
CELLS = os.path.join(HERE, "sampling_regions_v5_cells.csv")
NATIONAL = os.path.join(REPO, "project_national", "housing_characteristics")
TESTING = os.path.join(REPO, "project_testing", "housing_characteristics")
OPTIONS_LOOKUP = os.path.join(REPO, "resources", "options_lookup.tsv")
ZIP_CSV = os.path.join(
    REPO, "resources", "hpxml-measures", "HPXMLtoOpenStudio", "resources", "data", "zipcode_weather_stations.csv"
)
WEATHER_PREFIX = "../../../weather/"

TAB, CRLF = chr(9), chr(13) + chr(10)

out = []


def say(line=""):
    print(line)
    out.append(line)


def check(ok, what):
    say(f"  [{'ok' if ok else 'FAIL'}] {what}")
    if not ok:
        raise SystemExit(f"check failed: {what}")


def read_tsv(path):
    """Header, data rows and comment lines of a housing characteristic TSV."""
    with open(path, encoding="utf-8", newline="") as f:
        lines = f.read().replace(CRLF, chr(10)).split(chr(10))
    head = lines[0].split(TAB)
    rows = [ln.split(TAB) for ln in lines[1:] if ln and not ln.startswith("#")]
    comments = [ln for ln in lines[1:] if ln.startswith("#")]
    return head, rows, comments


def write_tsv(path, head, rows, comments):
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(CRLF.join(TAB.join(r) for r in [head] + rows + [[c] for c in comments]) + CRLF)


def read_options_lookup():
    with open(OPTIONS_LOOKUP, encoding="utf-8", newline="") as f:
        return [ln.split(TAB) for ln in f.read().replace(CRLF, chr(10)).split(chr(10))]


def main():
    say("v5 sampling regions: 300 weather-clustered regions on County x PUMA cells, County x PUMA weather")

    # ---- inputs ------------------------------------------------------------
    with open(CELLS, encoding="utf-8", newline="") as f:
        table = {(r["county"], r["puma"]): r for r in csv.DictReader(f)}
    cp_head, cp_rows, _ = read_tsv(os.path.join(NATIONAL, "County and PUMA.tsv"))
    cells = [h[len("Option=") :] for h in cp_head if h.startswith("Option=")]
    cty_head, cty_rows, _ = read_tsv(os.path.join(NATIONAL, "County.tsv"))
    lookup = read_options_lookup()
    with open(ZIP_CSV, encoding="utf-8", newline="") as f:
        zip_tz = {r["zipcode"]: r["zipcode_utc_offset"] for r in csv.DictReader(f)}
    epw_of_name, tz_of_name = {}, {}  # County option -> its weather file today, and its zip code's offset
    epw_of_cell = {}  # County and PUMA option -> its weather file, once this script has run
    for r in lookup:
        if r[0] == "County and PUMA":
            m = re.search(r"location_epw_path=\S*?(G\d{7}\.epw)", TAB.join(r))
            if m:
                epw_of_cell[r[1]] = m.group(1)
        if r[0] == "County":
            m = re.search(r"location_epw_path=\S*?(G\d{7}\.epw)", TAB.join(r))
            z = re.search(r"location_zip_code=(\d{5})", TAB.join(r))
            if m:
                epw_of_name[r[1]] = m.group(1)
            if z:
                tz_of_name[r[1]] = zip_tz.get(z.group(1))
    # County gisjoin -> its own weather file. A renamed county keeps its former county's file
    # (Kusilvak runs on G0202700.epw), so go through the County option rather than the code. On a
    # rerun the County rows no longer carry it, and the cells this script gives the county's own
    # file still do.
    own_epw, own_tz = {}, {}
    for r in cty_rows:
        name = next(h[len("Option=") :] for h, v in zip(cty_head, r) if h.startswith("Option=") and v == "1")
        county = r[0].split(", ")[0]
        if name in epw_of_name:
            own_epw[county] = epw_of_name[name]
        elif (county, r[0].split(", ")[1]) not in table:
            own_epw[county] = epw_of_cell[r[0]]
        own_tz[county] = tz_of_name[name]
    say(f"  cell table: {len(table):,} cells, {len({r['sampling_region_v5'] for r in table.values()})} regions")
    say(
        f"  sampler cells (County and PUMA.tsv options): {len(cells):,}; "
        f"County rows with a weather file: {len(epw_of_name):,}"
    )

    # ---- every sampler cell gets a region and a weather file ----------------
    region, epw, offset, how = {}, {}, {}, Counter()
    units_by_cell = {k: int(r["units"]) for k, r in table.items()}
    for cell in cells:
        county, puma = cell.split(", ")
        if (county, puma) in table:
            r = table[(county, puma)]
            region[cell], epw[cell], offset[cell] = r["sampling_region_v5"], r["epw_file"], r["utc_offset"]
            how["in the cell table"] += 1
            continue
        same = [k for k in table if k[1] == puma and table[k]["utc_offset"] == own_tz[county]]
        if not same:
            raise SystemExit(f"no cell of PUMA {puma} on UTC offset {own_tz[county]} to take a region from for {cell}")
        k = max(same, key=lambda k: units_by_cell[k])
        region[cell], offset[cell], epw[cell] = table[k]["sampling_region_v5"], own_tz[county], own_epw[county]
        how["same PUMA and offset's largest cell"] += 1
        say(f"    {cell}: region {region[cell]} (from {k[0]}, offset {offset[cell]}), weather {epw[cell]}")
    say("  sampler cells by source: " + ", ".join(f"{k} {v:,}" for k, v in how.items()))

    ids = sorted({int(v) for v in region.values()})
    regions_by_state = defaultdict(set)
    span_state, span_tz = defaultdict(set), defaultdict(set)
    for cell, rid in region.items():
        span_state[rid].add(cell[1:3])
        span_tz[rid].add(offset[cell])
        regions_by_state[cell[1:3]].add(rid)

    # ---- allocator key ------------------------------------------------------
    v5 = {cell.replace(", ", "|"): int(rid) for cell, rid in sorted(region.items())}
    with open(os.path.join(HERE, "sampling_regions_v5.json"), "w", encoding="utf-8") as f:
        json.dump(v5, f, indent=1, sort_keys=True)

    # ---- Sampling Region.tsv: one row per County and PUMA option, as County.tsv --------
    dep = [i for i, h in enumerate(cty_head) if h.startswith("Dependency=")]
    check(
        len(dep) == 1 and cty_head[dep[0]] == "Dependency=County and PUMA",
        "County.tsv depends on County and PUMA alone",
    )
    tail_idx = [i for i, h in enumerate(cty_head) if not h.startswith(("Dependency=", "Option="))]
    sr_head = ["Dependency=County and PUMA"] + [f"Option={i}" for i in ids] + [cty_head[i] for i in tail_idx]
    pos = {str(i): k for k, i in enumerate(ids)}
    sr_rows = []
    for r in cty_rows:
        hot = ["0"] * len(ids)
        hot[pos[region[r[0]]]] = "1"
        sr_rows.append([r[0]] + hot + [r[i] for i in tail_idx])
    sr_comments = [
        r"# Created by: postprocessing\resstockpostproc\resources\gisdata\build_sampling_regions_v5.py",
        "# Description: The sampling region that the sample is located.",
        "# Source: 300 regions clustered on County x PUMA weather within each state and UTC offset "
        "(2026-08 New Sampling change documentation, sampling_regions_v5_cells.csv).",
    ]
    write_tsv(os.path.join(NATIONAL, "Sampling Region.tsv"), sr_head, sr_rows, sr_comments)

    # ---- project_testing County and PUMA.tsv: P(cell | county) from the national files --------
    # National P(cell) = sum over climate zone rows of P(row) * P(cell | row)
    sp = cp_head.index("sampling_probability")
    opt_idx = [i for i, h in enumerate(cp_head) if h.startswith("Option=")]
    p_cell = Counter()
    for r in cp_rows:
        w = float(r[sp])
        for i in opt_idx:
            if r[i] not in ("0", ""):
                p_cell[cp_head[i][len("Option=") :]] += w * float(r[i])
    cty_opt = [h for h in cty_head if h.startswith("Option=")]
    county_of_cell = {}
    for r in cty_rows:
        for h, v in zip(cty_head, r):
            if h.startswith("Option=") and v == "1":
                county_of_cell[r[0]] = h[len("Option=") :]
    check(len(county_of_cell) == len(cty_rows) and len(cty_opt) > 0, "every County.tsv row is one-hot")
    t_head, _, _ = read_tsv(os.path.join(TESTING, "County.tsv"))
    t_counties = [h[len("Option=") :] for h in t_head if h.startswith("Option=")]
    t_cells = [c for c in cells if county_of_cell.get(c) in t_counties]
    t_rows = []
    for county in t_counties:
        mine = [c for c in t_cells if county_of_cell[c] == county]
        tot = sum(p_cell[c] for c in mine)
        probs = {c: p_cell[c] / tot for c in mine}
        t_rows.append([county] + [f"{probs[c]:.6g}" if c in probs else "0" for c in t_cells])
    write_tsv(
        os.path.join(TESTING, "County and PUMA.tsv"),
        ["Dependency=County"] + [f"Option={c}" for c in t_cells],
        t_rows,
        [
            "# Created by: postprocessing\\resstockpostproc\\resources\\gisdata\\build_sampling_regions_v5.py",
            "# Description: The GISJOIN identifier for the County and the Public Use Microdata Area "
            "that the sample is located.",
            "# Source: project_national County and PUMA.tsv and County.tsv, "
            "as the share of each county's housing units in each PUMA.",
        ],
    )

    # ---- options_lookup -----------------------------------------------------
    before = Counter(r[0] for r in lookup if r and r[0] in ("Sampling Region", "County", "County and PUMA"))
    first_sr = next(i for i, r in enumerate(lookup) if r[0] == "Sampling Region")
    new = []
    for i, r in enumerate(lookup):
        if r[0] == "Sampling Region":
            if i == first_sr:
                new += [["Sampling Region", str(rid)] for rid in ids]
            continue
        row = r
        if r[0] == "County":
            row = [x for x in r if not x.startswith("location_epw_path=")]
        elif r[0] == "County and PUMA" and r[1] in epw:
            row = r[:2] + ["ResStockArguments", f"location_epw_path={WEATHER_PREFIX}{epw[r[1]]}"]
        elif r[0] == "County and PUMA" and not r[1].startswith("G72"):
            raise SystemExit(f"no weather file for County and PUMA {r[1]}")
        new.append(row)
    with open(OPTIONS_LOOKUP, "w", encoding="utf-8", newline="") as f:
        f.write(CRLF.join(TAB.join(r) for r in new))
    after = Counter(r[0] for r in new if r and r[0] in ("Sampling Region", "County", "County and PUMA"))

    # ---- checks ---------------------------------------------------------------
    say()
    say("=== checks ===")
    check(len(ids) == 300, f"{len(ids)} regions")
    check(len(region) == len(cells), f"every sampler cell has a region ({len(region):,})")
    check(not [r for r in span_state.values() if len(r) > 1], "no region spans two states")
    check(not [r for r in span_tz.values() if len(r) > 1], "no region mixes UTC offsets")
    county_files = {c.split(", ")[0] + ".epw" for c in cells} | set(own_epw.values())
    check(set(epw.values()) <= county_files, "every cell weather file is a county weather file")
    other = sum(1 for c, f in epw.items() if f != c.split(", ")[0] + ".epw")
    say(f"  cells simulated on another county's weather file: {other:,} of {len(epw):,}")
    check(
        sorted(int(h[len("Option=") :]) for h in sr_head if h.startswith("Option=")) == ids,
        "Sampling Region.tsv options are the v5 ids",
    )
    check(
        all(sum(v == "1" for v in r[1 : len(ids) + 1]) == 1 for r in sr_rows),
        f"Sampling Region.tsv rows one-hot ({len(sr_rows):,})",
    )
    check(
        all(abs(sum(float(v) for v in r[1:]) - 1) < 1e-4 for r in t_rows),
        f"project_testing County and PUMA.tsv rows sum to 1 ({len(t_rows)} counties, {len(t_cells)} cells)",
    )
    check(
        after["Sampling Region"] == len(ids),
        f"options_lookup Sampling Region rows {before['Sampling Region']} -> {after['Sampling Region']}",
    )
    check(
        not [r for r in new if r[0] == "County" and any(x.startswith("location_epw_path=") for x in r)],
        f"no County row sets location_epw_path ({after['County']:,} rows)",
    )
    check(
        all(
            any(x.startswith("location_epw_path=") for x in r) for r in new if r[0] == "County and PUMA" and r[1] in epw
        ),
        f"every sampler cell's County and PUMA row sets location_epw_path ({len(epw):,})",
    )
    check(
        all(r["utc_offset"] == own_tz[k[0]] for k, r in table.items()),
        "every cell table offset is its county's zip code offset",
    )
    check(
        all(
            table[(c.split(", ")[0], c.split(", ")[1])]["epw_file"] == epw[c]
            for c in epw
            if (c.split(", ")[0], c.split(", ")[1]) in table
        ),
        "cell weather files as in the cell table",
    )
    say()
    say("  regions by state: " + ", ".join(f"{s} {len(v)}" for s, v in sorted(regions_by_state.items())))

    with open(os.path.join(HERE, "sampling_regions_v5_validation.txt"), "w", encoding="utf-8") as f:
        f.write(chr(10).join(out) + chr(10))


if __name__ == "__main__":
    main()
