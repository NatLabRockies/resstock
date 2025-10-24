"""Choropleth plotting helpers for standard plots."""

from __future__ import annotations

import csv
import json
import math
from pathlib import Path
from typing import Any, Literal

import polars as pl
import plotly.colors as pc
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from resstockpostproc.standard_plots.plotters import plot_utils
from resstockpostproc.standard_plots import theme
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, QuantityType

__all__ = ["create_plot"]

_STATE_ABBR_TO_NAME = {
    "AL": "Alabama",
    "AK": "Alaska",
    "AZ": "Arizona",
    "AR": "Arkansas",
    "CA": "California",
    "CO": "Colorado",
    "CT": "Connecticut",
    "DE": "Delaware",
    "DC": "District of Columbia",
    "FL": "Florida",
    "GA": "Georgia",
    "HI": "Hawaii",
    "ID": "Idaho",
    "IL": "Illinois",
    "IN": "Indiana",
    "IA": "Iowa",
    "KS": "Kansas",
    "KY": "Kentucky",
    "LA": "Louisiana",
    "ME": "Maine",
    "MD": "Maryland",
    "MA": "Massachusetts",
    "MI": "Michigan",
    "MN": "Minnesota",
    "MS": "Mississippi",
    "MO": "Missouri",
    "MT": "Montana",
    "NE": "Nebraska",
    "NV": "Nevada",
    "NH": "New Hampshire",
    "NJ": "New Jersey",
    "NM": "New Mexico",
    "NY": "New York",
    "NC": "North Carolina",
    "ND": "North Dakota",
    "OH": "Ohio",
    "OK": "Oklahoma",
    "OR": "Oregon",
    "PA": "Pennsylvania",
    "RI": "Rhode Island",
    "SC": "South Carolina",
    "SD": "South Dakota",
    "TN": "Tennessee",
    "TX": "Texas",
    "UT": "Utah",
    "VT": "Vermont",
    "VA": "Virginia",
    "WA": "Washington",
    "WV": "West Virginia",
    "WI": "Wisconsin",
    "WY": "Wyoming",
    "PR": "Puerto Rico",
}

_STATE_NAME_TO_ABBR = {name: abbr for abbr, name in _STATE_ABBR_TO_NAME.items()}

_COUNTY_GEOJSON: dict[str, Any] | None = None
_COUNTY_LABEL_MAP: dict[str, str] | None = None
_STATE_LABEL_CACHE: dict[str, tuple[float, float]] | None = None


def create_plot(
    data: pl.DataFrame,
    plot_spec: PlotSpec,
    *,
    resolution: Literal["state", "county"] = "state",
    show_labels: bool = False,
    show_boundaries: bool = False,
) -> go.Figure:
    """Create a choropleth map for the provided data."""

    location_col = "in.state" if resolution == "state" else "in.county"
    second_category_col = plot_spec.group_by
    title_text: str | None = None

    if plot_spec.quantity_type == QuantityType.prevalence:
        if not plot_spec.quantity_group_name:
            raise ValueError("Prevalence choropleth plots require quantity_group_name to be set.")
        value_col = "prevalence"
        first_category_col = plot_spec.quantity_group_name
        processed = data
    elif isinstance(plot_spec.quantity, QuantityGroup):
        processed, value_col, first_category_col, title_text = _prepare_quantity_group_dataframe(
            data,
            plot_spec,
            location_column=location_col,
            second_category_column=second_category_col,
        )
    else:
        value_col = str(plot_spec.quantity)
        first_category_col = "upgrade_name"
        processed = data

    required_cols = {location_col, value_col, first_category_col, "model_count"}
    if second_category_col:
        required_cols.add(second_category_col)

    missing_cols = [col for col in required_cols if col not in processed.columns]
    if missing_cols:
        missing = ", ".join(sorted(missing_cols))
        raise ValueError(f"Choropleth data is missing required columns: {missing}")

    filters = [
        pl.col(location_col).is_not_null(),
        pl.col(value_col).is_not_null(),
        pl.col(first_category_col).is_not_null(),
    ]
    if second_category_col:
        filters.append(pl.col(second_category_col).is_not_null())

    filtered = processed.filter(filters)
    if filtered.is_empty():
        raise ValueError("No data remaining after filtering null locations/values for choropleth plot.")

    if plot_spec.quantity_type == QuantityType.prevalence:
        filtered = filtered.filter(pl.col("model_count") > 0)
        if filtered.is_empty():
            raise ValueError("No non-zero model counts available for prevalence choropleth plot.")

    value_title = plot_utils.get_quantity_title(plot_spec)
    fig = _create_plot(
        filtered,
        location_col,
        value_col,
        first_category_col,
        second_category_col,
        plot_spec.quantity_type,
        value_title,
        resolution,
        title_text=title_text,
        show_labels=show_labels,
        show_boundaries=show_boundaries,
    )
    return fig


def _create_plot(
    data: pl.DataFrame,
    location_column: str,
    value_column: str,
    first_category_column: str,
    second_category_column: str | None,
    quantity_type: QuantityType,
    value_title: str,
    resolution: Literal["state", "county"],
    *,
    title_text: str | None = None,
    show_labels: bool,
    show_boundaries: bool,
) -> go.Figure:
    quantity_min = float(data[value_column].min())
    quantity_max = float(data[value_column].max())
    colorscale, cmin, cmax, tickvals, ticktext = _choose_colorscale(
        quantity_min,
        quantity_max,
        quantity_type,
    )

    first_values = data[first_category_column].unique(maintain_order=True).to_list()
    n_cols = max(1, len(first_values))

    second_values = (
        data[second_category_column].unique(maintain_order=True).to_list()
        if second_category_column
        else [None]
    )
    n_rows = max(1, len(second_values))

    column_titles = (
        [
            plot_utils.format_label(str(val)) if val is not None else ""
            for val in first_values
        ]
        if first_values
        else None
    )
    row_titles = None
    if second_category_column:
        row_titles = [
            plot_utils.format_label(str(value)) if value is not None else ""
            for value in second_values
        ]

    fig = make_subplots(
        rows=n_rows,
        cols=n_cols,
        specs=[[{"type": "choropleth"} for _ in range(n_cols)] for _ in range(n_rows)],
        column_titles=column_titles,
        row_titles=row_titles,
        vertical_spacing=0.02,
        horizontal_spacing=0.02,
    )

    geojson = _load_county_geojson() if resolution == "county" else None
    county_extent_added: set[tuple[int, int]] = set()

    for row_idx, second_val in enumerate(second_values, start=1):
        facet_df = (
            data
            if second_category_column is None
            else data.filter(pl.col(second_category_column) == second_val)
        )
        if facet_df.is_empty():
            continue

        for col_idx, first_val in enumerate(first_values, start=1):
            subset = facet_df.filter(pl.col(first_category_column) == first_val)
            if subset.is_empty():
                continue

            locations, labels = _extract_locations(
                subset[location_column].to_list(), resolution
            )
            values = subset[value_column].to_list()
            model_counts = subset["model_count"].to_list()
            text_values = (
                _build_text_labels(resolution, values, quantity_type, value_title)
                if show_labels
                else None
            )

            default_line_width = 1.4 if resolution == "state" else 0.6
            subtle_line_width = max(default_line_width * 0.2, 0.2)
            marker_line_width = default_line_width if show_boundaries else subtle_line_width
            marker_line_color = (
                "rgba(0,0,0,0.85)" if show_boundaries else "rgba(0,0,0,0.25)"
            )

            trace = go.Choropleth(
                locations=locations,
                z=values,
                locationmode="USA-states" if resolution == "state" else None,
                geojson=geojson,
                featureidkey="id" if resolution == "county" else None,
                coloraxis="coloraxis",
                marker_line_width=marker_line_width,
                marker_line_color=marker_line_color,
                customdata=list(zip(labels, model_counts)),
                hovertemplate=_build_hovertemplate(value_title),
            )
            if text_values:
                trace.update(text=text_values)
            fig.add_trace(trace, row=row_idx, col=col_idx)

            if resolution == "county" and (row_idx, col_idx) not in county_extent_added:
                fig.add_trace(_build_county_extent_trace(), row=row_idx, col=col_idx)
                county_extent_added.add((row_idx, col_idx))

            if text_values:
                label_positions = _state_label_positions()
                latitudes: list[float] = []
                longitudes: list[float] = []
                texts: list[str] = []
                for loc, text in zip(locations, text_values):
                    coords = label_positions.get(loc)
                    if not coords or not text:
                        continue
                    latitudes.append(coords[0])
                    longitudes.append(coords[1])
                    texts.append(text)
                if latitudes:
                    scatter = go.Scattergeo(
                        lat=latitudes,
                        lon=longitudes,
                        text=texts,
                        mode="text",
                        textfont={"color": "rgba(0,0,0,0.75)", "size": 12},
                        showlegend=False,
                    )
                    fig.add_trace(scatter, row=row_idx, col=col_idx)

    geo_kwargs: dict[str, Any] = {
        "scope": "usa",
        "showcountries": True,
        "showsubunits": True,
        "showlakes": True,
        "showframe": True,
        "showcoastlines": False,
        "bgcolor": "rgba(0,0,0,0)",
        "projection": {"type": "albers usa"},
        "center": {"lat": 38.0, "lon": -96.5},
    }

    for row_idx in range(1, n_rows + 1):
        for col_idx in range(1, n_cols + 1):
            fig.update_geos(row=row_idx, col=col_idx, **geo_kwargs)

    colorbar: dict[str, Any] = {
        "title": {"text": value_title},
        "x": 1.02,
        "y": 0.5,
        "yanchor": "middle",
        "len": 0.9,
        "thickness": 18,
    }
    if tickvals and ticktext:
        colorbar.update({"tickmode": "array", "tickvals": tickvals, "ticktext": ticktext})

    fig.update_layout(
        coloraxis={
            "colorscale": colorscale,
            "cmin": cmin,
            "cmax": cmax,
            "colorbar": colorbar,
        }
    )
    theme.apply_layout(fig)
    base_height = 620 if resolution == "county" else 540
    preferred_height = base_height * n_rows
    current_height = fig.layout.height or 0
    if current_height < preferred_height:
        fig.update_layout(height=preferred_height)
    _stretch_geo_height(fig)

    top_margin = 60 + (120 if title_text else 20)
    left_margin = 40
    if second_category_column and row_titles:
        max_chars = max((len(title) for title in row_titles if title), default=0)
        left_margin = max(160, min(260, 90 + max_chars * 6))
    elif second_category_column:
        left_margin = 160

    fig.update_layout(
        margin={"l": left_margin, "r": 100, "t": top_margin, "b": 40},
        width=max(900, n_cols * 420),
    )

    if row_titles:
        row_title_set = {title for title in row_titles if title}
        for annotation in fig.layout.annotations:
            if annotation.text in row_title_set:
                annotation.update(x=0.0, xref="paper", xanchor="right")

    if title_text:
        fig.update_layout(
            title={
                "text": title_text,
                "y": 0.94,
                "yanchor": "top",
                "x": 0.0,
                "xanchor": "left",
            }
        )

    return fig


def _prepare_quantity_group_dataframe(
    data: pl.DataFrame,
    plot_spec: PlotSpec,
    *,
    location_column: str,
    second_category_column: str | None,
) -> tuple[pl.DataFrame, str, str, str | None]:
    """Return long-form choropleth data for QuantityGroup quantities."""
    if not isinstance(plot_spec.quantity, QuantityGroup):
        raise ValueError("QuantityGroup preparation requires QuantityGroup quantity definition.")

    quantities: list[str] = list(plot_spec.quantity.constituents)
    if plot_spec.quantity.sum:
        quantities.append(plot_spec.quantity.sum)
    if not quantities:
        raise ValueError("QuantityGroup must include at least one constituent column.")

    ensured = plot_utils.ensure_columns_exist(data, quantities)

    title_text: str | None = None
    filtered = ensured

    if plot_spec.upgrade is not None:
        if "upgrade" not in filtered.columns:
            raise ValueError("Choropleth data is missing 'upgrade' column required for filtering.")
        filtered = filtered.filter(pl.col("upgrade") == plot_spec.upgrade)
        if filtered.is_empty():
            raise ValueError(f"No data available for upgrade {plot_spec.upgrade} when building choropleth plot.")
    else:
        if "upgrade_name" not in filtered.columns:
            raise ValueError("Choropleth data is missing 'upgrade_name' column required to infer upgrade.")
        upgrade_names = filtered["upgrade_name"].unique(maintain_order=True).to_list()
        if not upgrade_names:
            raise ValueError("No upgrades available to infer default upgrade for choropleth plot.")
        fallback_upgrade = upgrade_names[-1]
        filtered = filtered.filter(pl.col("upgrade_name") == fallback_upgrade)
        if filtered.is_empty():
            raise ValueError(
                f"No data available after selecting inferred upgrade '{fallback_upgrade}' for choropleth plot."
            )
        title_text = f"Defaulting to upgrade scenario: {fallback_upgrade}"

    index_cols = [location_column, "model_count"]
    if second_category_column:
        index_cols.append(second_category_column)
    missing_index = [col for col in index_cols if col not in filtered.columns]
    if missing_index:
        missing = ", ".join(sorted(missing_index))
        raise ValueError(f"Choropleth data is missing required index columns: {missing}")

    long_df = filtered.unpivot(
        quantities,
        index=index_cols,
        variable_name="_quantity_metric",
        value_name="_quantity_value",
    )
    prepared = long_df.rename(
        {
            "_quantity_metric": "__quantity_metric__",
            "_quantity_value": "__quantity_value__",
        }
    )
    return prepared, "__quantity_value__", "__quantity_metric__", title_text


def _choose_colorscale(
    z_min: float,
    z_max: float,
    quantity_type: QuantityType,
) -> tuple[list[list[float | str]], float, float, list[float], list[str]]:
    """Select colorscale, range, and tick labels for the colorbar."""
    suffix = "%" if quantity_type == QuantityType.percent_savings else ""
    cmin, cmax = z_min, z_max

    if math.isclose(cmax, cmin, rel_tol=1e-12, abs_tol=1e-12):
        delta = abs(cmin) if not math.isclose(cmin, 0.0, abs_tol=1e-12) else 1.0
        cmin -= delta * 0.05
        cmax += delta * 0.05

    max_abs = max(abs(cmin), abs(cmax))
    if math.isclose(max_abs, 0.0, abs_tol=1e-12):
        max_abs = 1.0

    colorscale = _build_balanced_colorscale(cmin, cmax, max_abs)

    tickvals, ticktext = _build_colorbar_ticks(z_min, z_max, cmin, cmax, suffix=suffix)
    return colorscale, cmin, cmax, tickvals, ticktext


NEGATIVE_COLOR = "#812E36"
POSITIVE_COLOR = "#7DA544"
NEUTRAL_COLOR = "#FFFFFF"


def _build_balanced_colorscale(cmin: float, cmax: float, max_abs: float) -> list[list[float | str]]:
    if cmax <= cmin:
        return [[0.0, NEUTRAL_COLOR], [1.0, NEUTRAL_COLOR]]

    anchors: list[tuple[float, str]] = []
    anchors.append((cmin, _color_for_value(cmin, max_abs)))
    if cmin < 0 < cmax:
        anchors.append((0.0, NEUTRAL_COLOR))
    anchors.append((cmax, _color_for_value(cmax, max_abs)))

    unique: dict[float, str] = {}
    for value, color in anchors:
        clamped_value = min(max(value, cmin), cmax)
        unique[clamped_value] = color

    denom = cmax - cmin
    colorscale: list[list[float | str]] = []
    for value in sorted(unique.keys()):
        position = (value - cmin) / denom
        colorscale.append([position, unique[value]])

    if colorscale:
        colorscale[0][0] = 0.0
        colorscale[-1][0] = 1.0
    return colorscale


def _color_for_value(value: float, max_abs: float) -> str:
    if math.isclose(max_abs, 0.0, abs_tol=1e-12):
        return NEUTRAL_COLOR
    value = max(-max_abs, min(max_abs, value))
    if value >= 0:
        ratio = value / max_abs
        return _lerp_color(NEUTRAL_COLOR, POSITIVE_COLOR, ratio)
    ratio = (value + max_abs) / max_abs
    return _lerp_color(NEGATIVE_COLOR, NEUTRAL_COLOR, ratio)


def _lerp_color(color_a: str, color_b: str, t: float) -> str:
    t = min(max(t, 0.0), 1.0)
    r1, g1, b1 = _hex_to_rgb(color_a)
    r2, g2, b2 = _hex_to_rgb(color_b)
    r = int(round(r1 + (r2 - r1) * t))
    g = int(round(g1 + (g2 - g1) * t))
    b = int(round(b1 + (b2 - b1) * t))
    return f"#{r:02X}{g:02X}{b:02X}"


def _hex_to_rgb(color: str) -> tuple[int, int, int]:
    color = color.lstrip("#")
    return tuple(int(color[i : i + 2], 16) for i in (0, 2, 4))


def _build_colorbar_ticks(
    z_min: float,
    z_max: float,
    cmin: float,
    cmax: float,
    *,
    suffix: str = "",
) -> tuple[list[float], list[str]]:
    ticks = [cmin, cmax] if not math.isclose(cmin, cmax, rel_tol=1e-12, abs_tol=1e-12) else [cmin]
    ticktexts = [_format_colorbar_tick(val, suffix=suffix) for val in ticks]
    return ticks, ticktexts


def _build_county_extent_trace() -> go.Scattergeo:
    return go.Scattergeo(
        lat=[24.5, 49.5, 49.5, 24.5, 24.5],
        lon=[-124.8, -124.8, -66.9, -66.9, -124.8],
        mode="lines",
        line={"color": "rgba(0,0,0,0.15)", "width": 0.5},
        fill="toself",
        fillcolor="rgba(0,0,0,0.02)",
        showlegend=False,
    )


def _format_colorbar_tick(value: float, *, suffix: str = "") -> str:
    abs_val = abs(value)
    sign = "-" if value < 0 else ""
    if math.isclose(abs_val, 0.0, abs_tol=1e-9):
        base = "0"
    elif abs_val >= 1_000_000_000:
        base = f"{abs_val / 1_000_000_000:.1f}B"
    elif abs_val >= 1_000_000:
        base = f"{abs_val / 1_000_000:.1f}M"
    elif abs_val >= 1_000:
        base = f"{abs_val / 1_000:.1f}K"
    elif abs_val >= 1.0:
        base = f"{abs_val:,.0f}"
    else:
        base = f"{abs_val:.2f}"

    base = base.rstrip("0").rstrip(".") if "." in base else base
    return f"{sign}{base}{suffix}"


def _build_hovertemplate(quantity_title: str) -> str:
    return (
        "%{customdata[0]}<br>"
        f"{quantity_title}: %{{z:,.2f}}<br>"
        "Number of models: %{customdata[1]:,}"
        "<extra></extra>"
    )


def _stretch_geo_height(fig: go.Figure, padding: float = 0.02) -> None:
    layout_dict = fig.to_dict().get("layout", {})
    geo_entries = [
        (name, data)
        for name, data in layout_dict.items()
        if name.startswith("geo") and isinstance(data, dict) and "domain" in data
    ]
    if not geo_entries:
        return

    y_domains: set[tuple[float, float]] = set()
    for _, entry in geo_entries:
        domain = entry.get("domain")
        if not isinstance(domain, dict):
            continue
        y_vals = domain.get("y")
        if (
            isinstance(y_vals, (list, tuple))
            and len(y_vals) == 2
            and all(isinstance(val, (int, float)) for val in y_vals)
        ):
            y_domains.add((float(y_vals[0]), float(y_vals[1])))
    if len(y_domains) != 1:
        return

    current_y = next(iter(y_domains), ())
    if not current_y:
        return
    span = current_y[1] - current_y[0]
    desired_span = 1.0 - (padding * 2)
    if span >= desired_span - 1e-6:
        return

    for name, _ in geo_entries:
        geo = getattr(fig.layout, name, None)
        if geo is None or getattr(geo, "domain", None) is None:
            continue
        domain = geo.domain
        x_domain = list(domain.x) if domain.x else [0.0, 1.0]
        geo.update(domain={"x": x_domain, "y": [padding, 1.0 - padding]})


def _build_text_labels(
    resolution: str,
    values: list[float],
    quantity_type: QuantityType,
    quantity_title: str,
) -> list[str] | None:
    if resolution != "state":
        return None

    labels: list[str] = []
    for value in values:
        if value is None:
            labels.append("")
            continue
        if quantity_type == QuantityType.percent_savings or "Percent" in quantity_title:
            labels.append(f"{value:.1f}%")
        elif abs(value) >= 1_000_000:
            labels.append(f"{value/1_000_000:.1f}M")
        elif abs(value) >= 1_000:
            labels.append(f"{value/1_000:.1f}K")
        else:
            labels.append(f"{value:.1f}")
    return labels


def _extract_locations(raw_values: list[Any], resolution: str) -> tuple[list[str], list[str]]:
    if resolution == "state":
        locations = [str(val).upper() for val in raw_values]
        labels = [
            f"{_STATE_ABBR_TO_NAME.get(loc, loc)} ({loc})"
            for loc in locations
        ]
        return locations, labels

    fips_codes, labels = [], []
    county_labels = _load_county_labels()
    for raw in raw_values:
        code = str(raw)
        fips = _normalize_county_code(code)
        label = county_labels.get(code) or county_labels.get(fips) or code
        if label and "," in label:
            state_abbr, locality = [part.strip() for part in label.split(",", 1)]
            state_name = _STATE_ABBR_TO_NAME.get(state_abbr, state_abbr)
            label = f"{locality}, {state_name}"
        labels.append(label)
        fips_codes.append(fips)
    return fips_codes, labels


def _normalize_county_code(code: str) -> str:
    if not code:
        return code
    code = code.strip()
    if code.startswith("G") and len(code) >= 5:
        body = code[1:]
        state = body[:2].zfill(2)
        county = body[-4:-1]
        return f"{state}{county}"
    if len(code) == 5:
        return code
    return code.zfill(5)


def _load_county_geojson() -> dict[str, Any]:
    global _COUNTY_GEOJSON
    if _COUNTY_GEOJSON is None:
        geojson_path = _resources_dir() / "counties-geojson.json"
        _COUNTY_GEOJSON = json.loads(geojson_path.read_text(encoding="utf-8"))
    return _COUNTY_GEOJSON


def _load_county_labels() -> dict[str, str]:
    global _COUNTY_LABEL_MAP
    if _COUNTY_LABEL_MAP is not None:
        return _COUNTY_LABEL_MAP

    label_map: dict[str, str] = {}
    with (_resources_dir() / "county_labels.csv").open("r", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            code = row.get("GISJOIN", "").strip()
            label = row.get("label", "").strip()
            if code:
                label_map[code] = label
    _COUNTY_LABEL_MAP = label_map
    return label_map


def _resources_dir() -> Path:
    return Path(__file__).resolve().parent / "resources"


def _state_label_positions() -> dict[str, tuple[float, float]]:
    global _STATE_LABEL_CACHE
    if _STATE_LABEL_CACHE is not None:
        return _STATE_LABEL_CACHE

    label_file = _resources_dir() / "state_label_positions.json"
    positions = json.loads(label_file.read_text(encoding="utf-8"))
    cache: dict[str, tuple[float, float]] = {
        key: (float(value[0]), float(value[1])) for key, value in positions.items()
    }
    _STATE_LABEL_CACHE = cache
    return cache
