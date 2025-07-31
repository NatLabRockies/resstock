"""Tests for DataProcessor.prepare_data_for_plot

These tests run fully in-memory: we monkeypatch the private load_data method so
that no file-system access is required. Small Polars DataFrames are used that
cover the core filter / aggregation logic.
"""

from __future__ import annotations

import polars as pl
import pytest

from resstockpostproc.standard_plots.data_processor import DataProcessor
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import (
    QuantityType,
    QuantityGroup,
    BuildingInclusion,
    VacancyInclusion,
    AggregationType,
    VizType,
    WorkflowConfig,
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
    heating_fuel = ["Electric", "Gas", "Electric", "Gas"]
    vacancy_status = ["Vacant", "Occupied", "Occupied", "Occupied"]
    building_type = ["Single Family", "Single Family", "Single Family", "Single Family"]
    # Base energy use: electric buildings draw all electricity, gas buildings draw mostly gas
    elec_kwh_base = [100.0, 20.0, 110.0, 0.0]
    gas_kwh_base = [0.0, 80.0, 0.0, 75.0]
    total_kwh_base = [e + g for e, g in zip(elec_kwh_base, gas_kwh_base)]

    baseline = pl.DataFrame(
        {
            "upgrade": 0,
            "upgrade_name": "baseline",
            "bldg_id": bldg_ids,
            "in.building_type": building_type,
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
    # for building 4 in upgrade 2, make elec_kwh 10 to mimic fuel switch
    combined = combined.with_columns(
        pl.when((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4))
        .then(10)
        .otherwise(pl.col("elec_kwh"))
        .alias("elec_kwh")
    )
    return combined.lazy()


@pytest.fixture
def processor(monkeypatch: pytest.MonkeyPatch, combined_df: pl.LazyFrame) -> DataProcessor:
    """Return a DataProcessor whose data has been monkey-patched with the fixture."""

    def _fake_load(_):
        return combined_df

    # Patch the private _load_data before instantiation
    monkeypatch.setattr(DataProcessor, "load_data", _fake_load, raising=True)
    monkeypatch.setattr(DataProcessor, "get_available_upgrades", lambda _, __: [0, 1, 2], raising=True)
    proc = DataProcessor(
        WorkflowConfig(
            s3_results_dir="dummy",
            output_dir="dummy",
            run_name="dummy",
            upgrades=(0, 1, 2),
            upgrade_names=("Baseline", "Upgrade1", "Upgrade2"),
            selection_logic=None,
            quantities=(QuantityGroup(name="dummy", constituents=("dummy",), sum="dummy"),),
            group_by=("in.heating_fuel",),
            aggregation_types=(AggregationType.total,),
            visualization_types=(VizType.bar,),
            quantity_types=(QuantityType.absolute,),
            building_inclusion=(BuildingInclusion.all,),
            vacancy_inclusion=(VacancyInclusion.all,),
        )
    )
    # all_cols is computed in __init__, but we ensure it matches our fixture
    proc.all_cols = set(combined_df.collect_schema().names())
    return proc


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
    processor: DataProcessor,
    building_inclusion: BuildingInclusion,
    vacancy_inclusion: VacancyInclusion,
    aggregation_type: AggregationType,
    quantity_type: QuantityType,
    viz_type: VizType,
    group_by: str | None,
    expected_rows: int,
):
    """Baseline sanity check for box & bar plots without additional filters."""
    if quantity_type == QuantityType.percent_savings and aggregation_type == AggregationType.total:
        # skip
        return

    spec = PlotSpec(
        visualization_type=viz_type,
        quantity_type=quantity_type,
        group_by=group_by,
        building_inclusion=building_inclusion,
        aggregation_type=aggregation_type,
        vacancy_inclusion=vacancy_inclusion,
        quantity="elec_kwh",
        quantity_group_name="energy",
    )
    df = processor.prepare_data_for_plot(spec)
    if quantity_type in [QuantityType.percent_savings, QuantityType.savings] or (
        building_inclusion == BuildingInclusion.applied_only
    ):
        expected_rows = (expected_rows * 2) // 3  # No baseline
    assert isinstance(df, pl.DataFrame)
    assert df.height == expected_rows


def test_vacancy_filter(processor: DataProcessor):
    """vacancy_inclusion=occupied_only should drop rows with Vacant status."""

    spec = _build_base_spec(vacancy_inclusion=VacancyInclusion.occupied_only)
    df = processor.prepare_data_for_plot(spec)

    # After filtering for occupied_only, resulting frame should have 3 rows (one per upgrade-fuel combo)
    assert df.height == 3
    # Column in.vacancy_status is dropped during aggregation; ensure it is absent
    assert "in.vacancy_status" not in df.columns


def test_upgrade_applied_only(processor: DataProcessor):
    """building_inclusion=applied_only removes rows where applicability==False."""

    spec = _build_base_spec(building_inclusion=BuildingInclusion.applied_only, group_by="in.heating_fuel")
    df = processor.prepare_data_for_plot(spec)

    # After removing non-applicable rows, Gas should remain for each upgrade (1, 2)
    # Baseline should be gone since we haven't picked an upgrade
    assert (df["in.heating_fuel"] == "Gas").sum() == 2


def test_quantity_group_mean_aggregation(processor: DataProcessor):
    """Mean aggregation with a quantity group returns expected columns & values."""

    qgroup = QuantityGroup(
        name="energy",
        constituents=("elec_kwh", "gas_kwh"),
        sum="total_kwh",
    )
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        aggregation_type=AggregationType.average,
        quantity_type=QuantityType.absolute,
        quantity=qgroup,
        group_by="in.heating_fuel",
        quantity_group_name="energy",
    )
    df = processor.prepare_data_for_plot(spec)

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

    # For upgrade=1 & Electric fuel, mean(elec_kwh) should be ≈99.5 ((100 + 99) / 2)
    row = df.filter((pl.col("upgrade") == 1) & (pl.col("in.heating_fuel") == "Electric")).select("elec_kwh").item()
    assert row == pytest.approx(99.5)


def test_savings_calculation(processor: DataProcessor):
    """Absolute savings should equal (baseline - upgrade) for applicable buildings."""

    spec = _build_base_spec(
        visualization_type=VizType.bar,
        group_by="bldg_id",
        quantity_type=QuantityType.savings,
        aggregation_type=AggregationType.average,  # mean over single-building groups -> identity
    )
    df = processor.prepare_data_for_plot(spec)

    # Building 2, Upgrade 1: baseline 20 kWh -> 18 kWh after 10% reduction => savings = 2
    saving = df.filter((pl.col("upgrade") == 1) & (pl.col("bldg_id") == 2)).select("elec_kwh").item()
    assert saving == pytest.approx(2.0)

    # Building 1, Upgrade 1 not applicable -> savings should be 0
    saving_na = df.filter((pl.col("upgrade") == 1) & (pl.col("bldg_id") == 1)).select("elec_kwh").item()
    assert saving_na == pytest.approx(0.0)


def test_percent_savings_calculation(processor: DataProcessor):
    """percent_savings should equal 100 * upgraded / baseline per current implementation."""

    spec = _build_base_spec(
        visualization_type=VizType.bar,
        group_by="bldg_id",
        quantity_type=QuantityType.percent_savings,
        aggregation_type=AggregationType.average,
        quantity="gas_kwh",
    )
    df = processor.prepare_data_for_plot(spec)

    # Building 3, Upgrade 1: baseline 20 kWh -> 18 kWh after 10% reduction => savings = 2
    pct = df.filter((pl.col("upgrade") == 1) & (pl.col("bldg_id") == 4)).select("gas_kwh").item()
    assert pct == pytest.approx(10)
    # Building 3, Upgrade 2: baseline 20 kWh -> 10 kWh after 50% reduction => savings = 10
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4)).select("gas_kwh").item()
    assert pct == pytest.approx(50)
    # Building 2, Upgrade 2: non-applicable building should have 0% savings
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 2)).select("gas_kwh").item()
    assert pct == pytest.approx(0.0)
    # There should be no baseline when doing percent_savings
    assert len(df.filter(pl.col("upgrade") == 0)) == 0

    # % savings for box-plot is not weighted by baseline values
    spec = _build_base_spec(
        visualization_type=VizType.box,
        group_by="bldg_id",
        quantity_type=QuantityType.percent_savings,
        aggregation_type=AggregationType.average,
        quantity="elec_kwh",
    )
    df = processor.prepare_data_for_plot(spec)
    # Building 4, Upgrade 2: baseline 0 kWh -> 10 kWh.
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4)).select("median").item()
    assert pct == pytest.approx(-1e9)  # minimum assumed value for baseline is 1e-6 so, 100*10/(1e-6) = 1e9

    # % savings for bar-plot is weighted by baseline values
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        group_by="bldg_id",
        quantity_type=QuantityType.percent_savings,
        aggregation_type=AggregationType.average,
        quantity="elec_kwh",
    )
    df = processor.prepare_data_for_plot(spec)
    # Building 4, Upgrade 2: baseline 0 kWh -> 10 kWh.
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4)).select("elec_kwh").item()
    assert pct == pytest.approx(0)  # since baseline is 0 kWh, savings is 0% when weighted by baseline

    # Change the baseline value for elec_kwh to 0.001 from 0.0 for building 4
    processor.combined_df = processor.combined_df.with_columns(
        pl.when((pl.col("bldg_id") == 4) & (pl.col("upgrade") == 0))
        .then(pl.lit(0.001))
        .otherwise(pl.col("elec_kwh"))
        .alias("elec_kwh")
    )
    df = processor.prepare_data_for_plot(spec)
    # Building 4, Upgrade 2: baseline 0.001 kWh -> 10 kWh. % savings = 100 * (10-0.001)/0.001 = 100000
    pct = df.filter((pl.col("upgrade") == 2) & (pl.col("bldg_id") == 4)).select("elec_kwh").item()
    assert pct == pytest.approx(-999900)
