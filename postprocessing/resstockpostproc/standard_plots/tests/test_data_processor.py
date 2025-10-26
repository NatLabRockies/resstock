"""Tests for functional data processor helpers.

These tests run fully in-memory using small Polars DataFrames that cover the core
filter / aggregation logic.
"""

from __future__ import annotations

import polars as pl
import pytest

from resstockpostproc.standard_plots.plotters import choropleth_plotter
from resstockpostproc.standard_plots.data_processing.data_processor import (
    prepare_data_for_plot,
)
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import (
    QuantityType,
    QuantityGroup,
    BuildingInclusion,
    VacancyInclusion,
    AggregationType,
    VizType,
)

# -----------------------------------------------------------------------------
# Helpers / fixtures
# -----------------------------------------------------------------------------


@pytest.fixture(scope="module")
def combined_df() -> pl.LazyFrame:
    """Return a LazyFrame holding a minimal but representative dataset."""

    # ---------------------------
    # Baseline (upgrade 0)
    # ---------------------------
    bldg_ids = [1, 2, 3, 4]
    weights = [10, 10, 10, 10]
    heating_fuel = ["Electric", "Gas", "Electric", "Gas"]
    vacancy_status = ["Vacant", "Occupied", "Occupied", "Occupied"]
    building_type = ["Single Family", "Single Family", "Single Family", "Single Family"]
    states = ["CO", "CO", "CA", "CA"]
    counties = ["G0800010", "G0800050", "G0600370", "G0600710"]
    # Base energy use: electric buildings draw all electricity, gas buildings draw mostly gas
    elec_kwh_base = [100.0, 20.0, 110.0, 0.0]
    gas_kwh_base = [0.0, 80.0, 0.0, 75.0]
    total_kwh_base = [e + g for e, g in zip(elec_kwh_base, gas_kwh_base)]

    baseline = pl.DataFrame(
        {
            "upgrade": 0,
            "upgrade_name": "baseline",
            "bldg_id": bldg_ids,
            "weight": weights,
            "in.building_type": building_type,
            "in.state": states,
            "in.county": counties,
            "applicability": True,
            "in.vacancy_status": vacancy_status,
            "in.heating_fuel": heating_fuel,
            "elec_kwh": elec_kwh_base,
            "gas_kwh": gas_kwh_base,
            "total_kwh": total_kwh_base,
        }
    ).with_columns([pl.col(["elec_kwh", "gas_kwh", "total_kwh"]).cast(pl.Float64)])

    # Helper to construct an upgrade dataframe from the baseline
    def _make_upgrade(df: pl.DataFrame, up_num: int, not_applicable_ids: list[int], reduction: float) -> pl.DataFrame:
        """Return an upgrade copy of *df* with modified applicability & energy use."""
        return (
            df.with_columns(
                [
                    pl.lit(up_num).alias("upgrade"),
                    pl.lit(f"Upgrade{up_num}").alias("upgrade_name"),
                    (~pl.col("bldg_id").is_in(not_applicable_ids)).alias("applicability"),
                ]
            )
            .with_columns(
                [
                    (
                        pl.when(pl.col("applicability"))
                        .then(pl.col("elec_kwh") * reduction)
                        .otherwise(pl.col("elec_kwh"))
                    ).alias("elec_kwh"),
                    (
                        pl.when(pl.col("applicability"))
                        .then(pl.col("gas_kwh") * reduction)
                        .otherwise(pl.col("gas_kwh"))
                    ).alias("gas_kwh"),
                ]
            )
            .with_columns((pl.col("elec_kwh") + pl.col("gas_kwh")).alias("total_kwh"))
            .with_columns(pl.col(["elec_kwh", "gas_kwh", "total_kwh"]).cast(pl.Float64))
        )

    upgrade1 = _make_upgrade(baseline, 1, not_applicable_ids=[1], reduction=0.9)
    upgrade2 = _make_upgrade(baseline, 2, not_applicable_ids=[1, 2], reduction=0.5)

    combined = pl.concat([baseline, upgrade1, upgrade2], how="vertical_relaxed")
    # for building 4 in upgrade 2, make elec_kwh 10 from 0 and gas_kwh 0 from 75 to mimic fuel switch
    combined = combined.with_columns(
        pl.when((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4))
        .then(10)
        .otherwise(pl.col("elec_kwh"))
        .alias("elec_kwh"),
        pl.when((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4))
        .then(0)
        .otherwise(pl.col("gas_kwh"))
        .alias("gas_kwh"),
    )
    return combined.lazy()


def prepare_data(
    df: pl.LazyFrame,
    spec: PlotSpec,
    *,
    selected_upgrades: list[int] | None = None,
    enduse_group_mapping: dict[str, list[str]] | None = None,
) -> pl.DataFrame:
    """Thin wrapper around prepare_data_for_plot for clearer tests."""
    return prepare_data_for_plot(
        df,
        spec,
        selected_upgrades=selected_upgrades,
        enduse_group_mapping=enduse_group_mapping,
    )


def _quantities_for_spec(spec: PlotSpec) -> list[str]:
    if isinstance(spec.quantity, str):
        return [spec.quantity]
    if isinstance(spec.quantity, QuantityGroup):
        result = list(spec.quantity.constituents)
        if spec.quantity.sum:
            result.append(spec.quantity.sum)
        return result
    return []


# -----------------------------------------------------------------------------
# Test cases
# -----------------------------------------------------------------------------


def _build_base_spec(**kwargs) -> PlotSpec:  # type: ignore[return-value]
    """Convenience for building PlotSpec objects with sensible defaults."""

    defaults = {
        "building_inclusion": BuildingInclusion.all,
        "vacancy_inclusion": VacancyInclusion.all,
        "quantity_type": QuantityType.absolute,
        "visualization_type": VizType.bar,
        "aggregation_type": AggregationType.total,
        "group_by": None,
        "quantity": "elec_kwh",
        "quantity_group_name": "dummy_group",
    }
    defaults.update(kwargs)
    return PlotSpec(**defaults)  # type: ignore[arg-type]


@pytest.mark.parametrize(
    ("building_inclusion"),
    [
        (BuildingInclusion.all),
        (BuildingInclusion.applied_only),
    ],
)
@pytest.mark.parametrize(
    ("vacancy_inclusion"),
    [
        (VacancyInclusion.all),
        (VacancyInclusion.occupied_only),
    ],
)
@pytest.mark.parametrize(
    ("aggregation_type"),
    [
        (AggregationType.total),
        (AggregationType.average),
        (AggregationType.distribution),
    ],
)
@pytest.mark.parametrize(
    ("quantity_type"),
    [
        (QuantityType.absolute),
        (QuantityType.savings),
        (QuantityType.percent_savings),
    ],
)
@pytest.mark.parametrize(
    ("viz_type"),
    [
        (VizType.box),
        (VizType.bar),
        (VizType.heatmap),
        (VizType.hist),
        (VizType.choropleth),
    ],
)
@pytest.mark.parametrize(
    ("quantity"),
    [
        ("elec_kwh"),
        (QuantityGroup(name="energy", constituents=("elec_kwh", "gas_kwh"), sum="total_kwh")),
    ],
)
@pytest.mark.parametrize(
    ("group_by", "expected_rows"),
    [
        (None, 3),
        ("in.heating_fuel", 6),
        ("in.building_type", 3),
    ],
)
def test_prepare_basic(
    combined_df: pl.LazyFrame,
    building_inclusion: BuildingInclusion,
    vacancy_inclusion: VacancyInclusion,
    aggregation_type: AggregationType,
    quantity_type: QuantityType,
    viz_type: VizType,
    group_by: str | None,
    quantity: str | QuantityGroup,
    expected_rows: int,
):
    """Baseline sanity check for box & bar plots without additional filters."""
    spec = PlotSpec(
        visualization_type=viz_type,
        quantity_type=quantity_type,
        group_by=group_by,
        building_inclusion=building_inclusion,
        aggregation_type=aggregation_type,
        vacancy_inclusion=vacancy_inclusion,
        quantity=quantity,
        quantity_group_name="energy",
    )
    if not spec.is_valid():
        pytest.skip(f"Invalid spec: {spec.get_error()}")
    df = prepare_data(combined_df, spec)
    assert isinstance(df, pl.DataFrame)

    if viz_type == VizType.choropleth:
        assert "in.state" in df.columns
        assert df["in.state"].is_not_null().all()
        assert "model_count" in df.columns
        assert "upgrade_name" in df.columns
        if spec.group_by:
            assert spec.group_by in df.columns
        key_cols = ["upgrade", "in.state"]
        if spec.group_by and spec.group_by != "in.state":
            key_cols.append(spec.group_by)
        assert df.select(key_cols).unique().height == df.height
        assert df.height > 0
        return

    if quantity_type in [QuantityType.percent_savings, QuantityType.savings] or (
        building_inclusion == BuildingInclusion.applied_only
    ):
        expected_rows = (expected_rows * 2) // 3  # No baseline
    quantities = _quantities_for_spec(spec)
    if isinstance(quantity, QuantityGroup) and viz_type == VizType.box:
        for col in quantities:
            assert len(df.filter(pl.col("End Use") == col)) == expected_rows
    elif isinstance(quantity, str) and viz_type == VizType.box:
        assert len(df) == expected_rows
    elif isinstance(quantity, str) and viz_type == VizType.hist:
        assert len(df) == expected_rows * 102  # 100 bins and 2 overflow/underflow per upgrade-group
    else:
        assert df.height == expected_rows
        for col in quantities:
            assert col in df.columns


def test_vacancy_filter(combined_df: pl.LazyFrame):
    """vacancy_inclusion=occupied_only should drop rows with Vacant status."""

    spec = _build_base_spec(vacancy_inclusion=VacancyInclusion.occupied_only)
    df = prepare_data(combined_df, spec)

    # After filtering for occupied_only, resulting frame should have 3 rows (one per upgrade-fuel combo)
    assert df.height == 3
    # Column in.vacancy_status is dropped during aggregation; ensure it is absent
    assert "in.vacancy_status" not in df.columns


def test_upgrade_applied_only(combined_df: pl.LazyFrame):
    """building_inclusion=applied_only removes rows where applicability==False."""

    spec = _build_base_spec(building_inclusion=BuildingInclusion.applied_only, group_by="in.heating_fuel")
    df = prepare_data(combined_df, spec)

    # After removing non-applicable rows, Gas should remain for each upgrade (1, 2)
    # Baseline should be gone since we haven't picked an upgrade
    assert (df["in.heating_fuel"] == "Gas").sum() == 2


def test_specific_upgrade_filter(combined_df: pl.LazyFrame):
    """Setting plot_spec.upgrade filters to baseline + that upgrade.

    For savings/percent_savings, baseline rows are removed after computations.
    """
    # Absolute values: should include baseline (0) and selected upgrade (1)
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        aggregation_type=AggregationType.average,
        quantity_type=QuantityType.absolute,
        upgrade=1,
    )
    df_abs = prepare_data(combined_df, spec)
    assert set(df_abs["upgrade"].to_list()) == {0, 1}

    # Savings: baseline excluded
    spec.quantity_type = QuantityType.savings
    df_savings = prepare_data(combined_df, spec)
    assert set(df_savings["upgrade"].to_list()) == {1}

    # Percent savings: baseline excluded
    spec.quantity_type = QuantityType.percent_savings
    df_pct = prepare_data(combined_df, spec)
    assert set(df_pct["upgrade"].to_list()) == {1}


def test_specific_upgrade_with_applied_only(combined_df: pl.LazyFrame):
    """Applied-only with a specific upgrade includes only applicable buildings, plus baseline for those buildings."""
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        aggregation_type=AggregationType.total,
        quantity_type=QuantityType.absolute,
        upgrade=1,
        building_inclusion=BuildingInclusion.applied_only,
        group_by="bldg_id",
    )
    df = prepare_data(combined_df, spec)

    # Only baseline (0) and upgrade 1 should be present
    assert set(df["upgrade"].to_list()) <= {0, 1}
    assert 2 not in set(df["upgrade"].to_list())

    # For upgrade 1 in the fixture, bldg_id 1 is not applicable. Applied-only should
    # exclude bldg_id 1 for both upgrade 1 and its corresponding baseline row.
    baseline_ids = set(df.filter(pl.col("upgrade") == 0)["bldg_id"].to_list())
    up1_ids = set(df.filter(pl.col("upgrade") == 1)["bldg_id"].to_list())
    assert baseline_ids == {2, 3, 4}
    assert up1_ids == {2, 3, 4}


def test_selected_upgrades_filters_including_baseline(combined_df: pl.LazyFrame):
    """selected_upgrades keeps baseline plus listed upgrades for absolute quantities."""
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        aggregation_type=AggregationType.total,
        quantity_type=QuantityType.absolute,
    )
    df = prepare_data(combined_df, spec, selected_upgrades=[2])
    assert set(df["upgrade"].to_list()) == {0, 2}


def test_selected_upgrades_with_percent_savings(combined_df: pl.LazyFrame):
    """For percent_savings, baseline is used for calc but excluded from results."""
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        aggregation_type=AggregationType.average,
        quantity_type=QuantityType.percent_savings,
    )
    df = prepare_data(combined_df, spec, selected_upgrades=[1, 2])
    assert set(df["upgrade"].to_list()) == {1, 2}


def test_histogram_is_degenerate_all_equal(combined_df: pl.LazyFrame):
    """Histogram degenerate case: all values equal -> all counts in bin 0 per group."""
    # Create a constant column used for histogram; ensures q1==q99==min==max
    df_source = combined_df.with_columns(pl.lit(7.0).alias("toy_deg"))
    spec = _build_base_spec(
        visualization_type=VizType.hist,
        quantity_type=QuantityType.absolute,
        aggregation_type=AggregationType.distribution,
        quantity="toy_deg",
        group_by=None,
    )
    df = prepare_data(df_source, spec)

    # For each upgrade group, only bin 0 should have non-zero count; totals equal rows per upgrade
    for up in [0, 1, 2]:
        grp = df.filter(pl.col("upgrade") == up)
        total = int(grp["count"].sum())
        nonzero_bins = grp.filter(pl.col("count") > 0)["bin"].to_list()
        assert set(nonzero_bins) == {0}
        # Our fixture has 4 rows per upgrade
        assert total == 4
        pct_total = grp["count_pct"].sum()
        pct_bin0 = grp.filter(pl.col("bin") == 0)["count_pct"].sum()
        assert pct_total == pytest.approx(100.0)
        assert pct_bin0 == pytest.approx(100.0)


def test_histogram_q1_equals_q99_non_degenerate():
    """When q1==q99 but min<max, code resets to min/max and uses non-degenerate binning."""
    # Build a synthetic dataset: for each upgrade, 99 zeros and 1 one-hundred
    # Use a larger n so that both 1st and 99th percentiles exactly equal 0.0
    # ensuring q1 == q99, but min < max to trigger the reset path.
    n = 1000
    base_vals = [0.0] * (n - 1) + [100.0]
    up_vals = [0.0] * (n - 1) + [100.0]

    df = pl.DataFrame(
        {
            "upgrade": [0] * n + [1] * n,
            "upgrade_name": ["baseline"] * n + ["Upgrade1"] * n,
            "bldg_id": list(range(1, n + 1)) + list(range(1, n + 1)),
            "weight": [1] * (2 * n),
            "in.building_type": ["Single Family"] * (2 * n),
            "applicability": [True] * (2 * n),
            "in.vacancy_status": ["Occupied"] * (2 * n),
            "toy_q": base_vals + up_vals,
        }
    ).lazy()

    spec = _build_base_spec(
        visualization_type=VizType.hist,
        quantity_type=QuantityType.absolute,
        aggregation_type=AggregationType.distribution,
        quantity="toy_q",
        group_by=None,
    )
    hist = prepare_data(df, spec)

    # For each upgrade group: n-1 entries in bin -1 (zeros) and 1 in bin 99 (max value)
    for up in [0, 1]:
        grp = hist.filter(pl.col("upgrade") == up)
        count_m1 = grp.filter(pl.col("bin") == -1)["count"].sum()
        count_99 = grp.filter(pl.col("bin") == 99)["count"].sum()
        # Assert expected counts
        assert int(count_m1) == n - 1
        assert int(count_99) == 1
        pct_m1 = grp.filter(pl.col("bin") == -1)["count_pct"].sum()
        pct_99 = grp.filter(pl.col("bin") == 99)["count_pct"].sum()
        assert grp["count_pct"].sum() == pytest.approx(100.0)
        assert pct_m1 == pytest.approx(100.0 * (n - 1) / n)
        assert pct_99 == pytest.approx(100.0 / n)


def test_model_count_per_upgrade(combined_df: pl.LazyFrame):
    """model_count returns number of models per (upgrade, upgrade_name)."""
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        aggregation_type=AggregationType.total,
        quantity_type=QuantityType.model_count,
        quantity="elec_kwh",
        group_by=None,
    )
    df = prepare_data(combined_df, spec)

    # Expect 3 rows (baseline + 2 upgrades), each with 4 models in our fixture
    assert set(df["upgrade"].to_list()) == {0, 1, 2}
    for up in [0, 1, 2]:
        row = df.filter(pl.col("upgrade") == up).row(0, named=True)
        assert row["model_count"] == 4


def test_model_count_grouped_by_fuel(combined_df: pl.LazyFrame):
    """model_count grouped by fuel yields correct counts per upgrade."""
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        aggregation_type=AggregationType.total,
        quantity_type=QuantityType.model_count,
        quantity="elec_kwh",
        group_by="in.heating_fuel",
    )
    df = prepare_data(combined_df, spec)

    # For each upgrade, we have 2 Electric and 2 Gas buildings in the fixture
    for up in [0, 1, 2]:
        grp = df.filter(pl.col("upgrade") == up)
        assert grp.filter(pl.col("in.heating_fuel") == "Electric")["model_count"].item() == 2
        assert grp.filter(pl.col("in.heating_fuel") == "Gas")["model_count"].item() == 2


@pytest.mark.parametrize(
    "aggregation_type",
    [AggregationType.average, AggregationType.total],
)
def test_quantity_group_mean_aggregation(combined_df: pl.LazyFrame, aggregation_type: AggregationType):
    """Quantity group aggregation returns expected columns & values."""

    qgroup = QuantityGroup(
        name="energy",
        constituents=("elec_kwh", "gas_kwh"),
        sum="total_kwh",
    )
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        aggregation_type=aggregation_type,
        quantity_type=QuantityType.absolute,
        quantity=qgroup,
        group_by="in.heating_fuel",
        quantity_group_name="energy",
    )
    df = prepare_data(combined_df, spec)

    # Expected output columns:
    expected_cols = {
        "upgrade",
        "upgrade_name",
        "in.heating_fuel",
        "elec_kwh",
        "gas_kwh",
        "total_kwh",
    }
    assert expected_cols.issubset(set(df.columns))
    row = df.filter((pl.col("upgrade") == 1) & (pl.col("in.heating_fuel") == "Electric")).select("elec_kwh").item()
    multiplier = 1 if aggregation_type == AggregationType.average else 20  # weight of 10 and two samples
    assert row == pytest.approx(99.5 * multiplier)


def test_normalize_county_code():
    """GIS-style codes should convert to 5-digit county FIPS strings."""
    assert choropleth_plotter._normalize_county_code("G3600050") == "36005"
    assert choropleth_plotter._normalize_county_code("G0100010") == "01001"
    assert choropleth_plotter._normalize_county_code("36005") == "36005"
    assert choropleth_plotter._normalize_county_code("123") == "00123"


@pytest.mark.parametrize(
    "aggregation_type",
    [AggregationType.average, AggregationType.total],
)
def test_savings_calculation(combined_df: pl.LazyFrame, aggregation_type: AggregationType):
    """Absolute savings should equal (baseline - upgrade) for applicable buildings."""

    spec = _build_base_spec(
        visualization_type=VizType.bar,
        group_by="bldg_id",
        quantity_type=QuantityType.savings,
        aggregation_type=aggregation_type,  # test both average and total
    )
    df = prepare_data(combined_df, spec)

    multiplier = 1 if aggregation_type == AggregationType.average else 10

    # Building 2, Upgrade 1: baseline 20 kWh -> 18 kWh after 10% reduction => savings = 2
    saving = df.filter((pl.col("upgrade") == 1) & (pl.col("bldg_id") == 2)).select("elec_kwh").item()
    assert saving == pytest.approx(2.0 * multiplier)

    # Building 1, Upgrade 1 not applicable -> savings should be 0
    saving_na = df.filter((pl.col("upgrade") == 1) & (pl.col("bldg_id") == 1)).select("elec_kwh").item()
    assert saving_na == pytest.approx(0.0)


def test_percent_savings_calculation(combined_df: pl.LazyFrame):
    """percent_savings should equal 100 * upgraded / baseline per current implementation."""

    spec = _build_base_spec(
        visualization_type=VizType.bar,
        group_by="bldg_id",
        quantity_type=QuantityType.percent_savings,
        aggregation_type=AggregationType.average,
        quantity="gas_kwh",
    )
    df = prepare_data(combined_df, spec)

    # elec_kwh_base = [100.0, 20.0, 110.0, 0.0]
    # gas_kwh_base = [0.0, 80.0, 0.0, 75.0]

    # Building 2, upgrade 1: baseline 75 kwh -> 0.9 * 75 (10% reduction)
    pct = df.filter((pl.col("upgrade") == 1) & (pl.col("bldg_id") == 4)).select("gas_kwh").item()
    assert pct == pytest.approx(10)
    # Building 4, Upgrade 2: baseline 75 kWh -> 0 kWh -- 100% reduction
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4)).select("gas_kwh").item()
    assert pct == pytest.approx(100)
    # Building 2, Upgrade 2: non-applicable building should have 0% savings
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 2)).select("gas_kwh").item()
    assert pct == pytest.approx(0.0)
    # There should be no baseline when doing percent_savings
    assert len(df.filter(pl.col("upgrade") == 0)) == 0

    spec = _build_base_spec(
        visualization_type=VizType.box,
        group_by="bldg_id",
        quantity_type=QuantityType.percent_savings,
        aggregation_type=AggregationType.average,
        quantity="elec_kwh",
    )
    df = prepare_data(combined_df, spec)
    # Building 4, Upgrade 2: baseline 0 kWh -> 10 kWh. % savings = 100 * (10-0)/(1e-6) = -1e9 (per current impl)
    # Using 1e-6 as the "small number" to avoid division by zero
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4)).select("median").item()
    assert pct == pytest.approx(-1e9)

    spec = _build_base_spec(
        visualization_type=VizType.bar,
        group_by="bldg_id",
        quantity_type=QuantityType.percent_savings,
        aggregation_type=AggregationType.average,
        quantity="elec_kwh",
    )
    df = prepare_data(combined_df, spec)
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4)).select("elec_kwh").item()
    assert pct == pytest.approx(-1e9)

    modified_df = combined_df.with_columns(
        pl.when((pl.col("bldg_id") == 4) & (pl.col("upgrade") == 0))
        .then(pl.lit(0.001))
        .otherwise(pl.col("elec_kwh"))
        .alias("elec_kwh")
    )
    df = prepare_data(modified_df, spec)
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4)).select("elec_kwh").item()
    assert pct == pytest.approx(-999900)


@pytest.mark.parametrize(
    "quantity",
    ["elec_kwh", "gas_kwh", "total_kwh"],
)
def test_integrity(combined_df: pl.LazyFrame, quantity: str):
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        group_by=None,
        quantity_type=QuantityType.percent_savings,
        aggregation_type=AggregationType.average,
        quantity=quantity,
    )
    avg_percent_savings_df = prepare_data(combined_df, spec)
    spec.quantity_type = QuantityType.savings
    spec.aggregation_type = AggregationType.total
    savings_df = prepare_data(combined_df, spec)
    spec.quantity_type = QuantityType.absolute
    absolute_df = prepare_data(combined_df, spec)
    absolute_df = absolute_df.filter(pl.col("upgrade") == 0).select(
        pl.col(quantity).alias("baseline_value")
    )  # % savings calculated in reference to baseline
    all_df = avg_percent_savings_df.join(savings_df, on="upgrade", suffix="_savings").join(absolute_df, how="cross")
    all_df = all_df.with_columns(
        (100 * pl.col(f"{quantity}_savings") / pl.col("baseline_value")).alias("calc_percent_savings")
    )
    assert (all_df[quantity] == all_df["calc_percent_savings"]).all()


def test_missing_quantities_are_filled(combined_df: pl.LazyFrame, caplog: pytest.LogCaptureFixture):
    """Request a quantity group SUM column that isn't present to trigger fill.

    We use a QuantityGroup whose `sum` field (a synthetic group name) is not in
    the dataset columns. This forces prepare_data_for_plot to call
    the helper that fills missing quantities, which should create the grouped
    SUM column by combining its constituents. We don't call the helper directly.
    """

    # Provide an explicit enduse_group_mapping so we can control behavior:
    # - "My Group" should sum existing columns elec_kwh + gas_kwh
    # - "Defined But Missing" is defined but its constituents do not exist
    # - Anything else (e.g., "Truly Missing") is not defined at all
    mapping = {
        "My Group": ["elec_kwh", "gas_kwh"],
        "Defined But All Missing": ["does_not_exist_1", "does_not_exist_2"],
        "Defined But Partially Missing": ["elec_kwh", "does_not_exist_2"],
    }

    # Create a group with constituents that exist in the fixture, and a sum
    qgroup = QuantityGroup(name="energy", constituents=("elec_kwh", "gas_kwh"), sum="My Group")

    spec = _build_base_spec(
        visualization_type=VizType.bar,
        aggregation_type=AggregationType.total,
        quantity_type=QuantityType.absolute,
        quantity=qgroup,
        group_by=None,
        quantity_group_name="energy",
    )

    caplog.set_level("WARNING")
    caplog.clear()
    df = prepare_data(combined_df, spec, enduse_group_mapping=mapping)

    # The group sum column should now exist because it was filled.
    assert "My Group" in df.columns

    # And it should equal elec_kwh + gas_kwh (total aggregation with weights).
    assert ((df["My Group"] - df["elec_kwh"] - df["gas_kwh"]).abs() < 1e-9).all()
    # No warnings expected for successful summation
    assert not caplog.records

    # Now request a defined group whose constituents are missing -> should be zero-filled
    spec.quantity = QuantityGroup(name="energy", constituents=("elec_kwh", "gas_kwh"), sum="Defined But All Missing")
    caplog.clear()
    df2 = prepare_data(combined_df, spec, enduse_group_mapping=mapping)
    assert "Defined But All Missing" in df2.columns
    assert (df2["Defined But All Missing"] == 0).all()
    assert any("defined but none of the constituent are available" in rec.getMessage() for rec in caplog.records)

    # Now request a defined group whose some constituents are missing -> should sum existing ones
    spec.quantity = QuantityGroup(
        name="energy", constituents=("elec_kwh", "gas_kwh"), sum="Defined But Partially Missing"
    )
    caplog.clear()
    df2 = prepare_data(combined_df, spec, enduse_group_mapping=mapping)
    assert "Defined But Partially Missing" in df2.columns
    assert ((df2["Defined But Partially Missing"] - df2["elec_kwh"]).abs() < 1e-9).all()
    # No warning expected here because at least one constituent exists and is used
    assert any(
        "is defined but only some of the constituent are available" in rec.getMessage() for rec in caplog.records
    )

    # Finally request a completely undefined group -> also zero-filled
    spec.quantity = QuantityGroup(name="energy", constituents=("elec_kwh", "gas_kwh"), sum="Truly Missing")
    caplog.clear()
    df3 = prepare_data(combined_df, spec, enduse_group_mapping=mapping)
    assert "Truly Missing" in df3.columns
    assert (df3["Truly Missing"] == 0).all()
    assert any("is not available and is not a defined group" in rec.getMessage() for rec in caplog.records)


def test_prepare_data_for_prevalence_single_quantity(combined_df: pl.LazyFrame):
    """Prevalence plots should report percentage shares per category."""
    spec = PlotSpec(
        building_inclusion=BuildingInclusion.all,
        vacancy_inclusion=VacancyInclusion.all,
        quantity_type=QuantityType.prevalence,
        aggregation_type=AggregationType.total,
        visualization_type=VizType.bar,
        group_by=None,
        quantity="Electric",
        quantity_group_name="in.heating_fuel",
        upgrade=2,
    )

    df = prepare_data(combined_df, spec)
    assert df.shape[0] == 1
    assert set(df["in.heating_fuel"].to_list()) == {"Electric"}
    assert df["upgrade_name"].to_list() == ["Upgrade2"]
    prevalence_map = dict(zip(df["in.heating_fuel"].to_list(), df["prevalence"].to_list()))
    model_counts = dict(zip(df["in.heating_fuel"].to_list(), df["model_count"].to_list()))
    assert prevalence_map["Electric"] == pytest.approx(50.0)
    assert model_counts["Electric"] == 2


def test_prepare_data_for_prevalence_multi_quantities(combined_df: pl.LazyFrame):
    """Prevalence plots should report percentage shares per category."""
    spec = PlotSpec(
        building_inclusion=BuildingInclusion.all,
        vacancy_inclusion=VacancyInclusion.all,
        quantity_type=QuantityType.prevalence,
        aggregation_type=AggregationType.total,
        visualization_type=VizType.bar,
        group_by=None,
        quantity=QuantityGroup(constituents=("Electric", "Gas"), name="in.heating_fuel", sum=None),
        quantity_group_name="in.heating_fuel",
        upgrade=2,
    )

    df = prepare_data(combined_df, spec)
    assert df.shape[0] == 2
    assert set(df["in.heating_fuel"].to_list()) == {"Electric", "Gas"}
    assert set(df["upgrade_name"].to_list()) == {"Upgrade2"}
    prevalence_map = dict(zip(df["in.heating_fuel"].to_list(), df["prevalence"].to_list()))
    model_counts = dict(zip(df["in.heating_fuel"].to_list(), df["model_count"].to_list()))

    assert prevalence_map["Electric"] == pytest.approx(50.0)
    assert prevalence_map["Gas"] == pytest.approx(50.0)
    assert model_counts["Electric"] == 2
    assert model_counts["Gas"] == 2
