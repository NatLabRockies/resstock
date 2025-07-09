"""Tests for DataProcessor.prepare_data_for_plot

These tests run fully in-memory: we monkeypatch the private _load_data method so
that no file-system access is required. Small Polars DataFrames are used that
cover the core filter / aggregation logic.
"""

from __future__ import annotations

import polars as pl
import pytest

from resstockpostproc.standard_plots.data_processor import DataProcessor
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import (
    ComparisonTypes,
    QuantityGroup,
    UpgradeInclusion,
    VacancyInclusion,
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
    heating_fuel = ["Electric", "Gas", "Electric", "Gas"]
    vacancy_status = ["Vacant", "Occupied", "Occupied", "Occupied"]
    building_type = ["Single Family", "Single Family", "Single Family", "Single Family"]
    # Base energy use: electric buildings draw all electricity, gas buildings draw mostly gas
    elec_kwh_base = [100, 20, 110, 25]
    gas_kwh_base = [0, 80, 0, 75]
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
    return combined.lazy()


@pytest.fixture
def processor(monkeypatch: pytest.MonkeyPatch, combined_df: pl.LazyFrame) -> DataProcessor:
    """Return a DataProcessor whose data has been monkey-patched with the fixture."""

    def _fake_load(_):
        return combined_df

    # Patch the private _load_data before instantiation
    monkeypatch.setattr(DataProcessor, "_load_data", _fake_load, raising=True)
    proc = DataProcessor(annual_results_dir="dummy", upgrades=[0, 1])
    # all_cols is computed in __init__, but we ensure it matches our fixture
    proc.all_cols = set(combined_df.collect_schema().names())
    return proc


# -----------------------------------------------------------------------------
# Test cases
# -----------------------------------------------------------------------------


def _build_base_spec(**kwargs) -> PlotSpec:  # type: ignore[return-value]
    """Convenience for building PlotSpec objects with sensible defaults."""

    defaults = {
        "upgrade_inclusion": UpgradeInclusion.all,
        "vacancy_inclusion": VacancyInclusion.all,
        "comparison_type": ComparisonTypes.absolute,
        "visualization_type": VizType.bar,
        "group_by": None,
        "quantity": "elec_kwh",
        "quantity_group_name": "dummy_group",
    }
    defaults.update(kwargs)
    return PlotSpec(**defaults)  # type: ignore[arg-type]


@pytest.mark.parametrize(
    ("upgrade_inclusion"),
    [
        (UpgradeInclusion.all),
        (UpgradeInclusion.applied_only),
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
    ("comparison_type"),
    [
        (ComparisonTypes.absolute),
        (ComparisonTypes.mean),
        (ComparisonTypes.savings),
        (ComparisonTypes.percent_savings),
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
    upgrade_inclusion: UpgradeInclusion,
    vacancy_inclusion: VacancyInclusion,
    comparison_type: ComparisonTypes,
    viz_type: VizType,
    group_by: str | None,
    expected_rows: int,
):
    """Baseline sanity check for box & bar plots without additional filters."""

    # spec = _build_base_spec(visualization_type=viz_type, group_by=group_by,
    #  comparison_type=comparison_type, vacancy_inclusion=vacancy_inclusion)
    spec = PlotSpec(
        visualization_type=viz_type,
        comparison_type=comparison_type,
        group_by=group_by,
        upgrade_inclusion=upgrade_inclusion,
        vacancy_inclusion=vacancy_inclusion,
        quantity="elec_kwh",
        quantity_group_name="energy",
    )
    df = processor.prepare_data_for_plot(spec)
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
    """upgrade_inclusion=applied_only removes rows where applicability==False."""

    spec = _build_base_spec(upgrade_inclusion=UpgradeInclusion.applied_only)
    df = processor.prepare_data_for_plot(spec)

    # After removing non-applicable rows, Gas should remain for each upgrade (baseline, 1, 2)
    assert (df["in.heating_fuel"] == "Gas").sum() == 3


def test_quantity_group_mean_aggregation(processor: DataProcessor):
    """Mean aggregation with a quantity group returns expected columns & values."""

    qgroup = QuantityGroup(
        name="energy",
        constituents=["elec_kwh", "gas_kwh"],
        sum="total_kwh",
    )
    spec = _build_base_spec(
        visualization_type=VizType.bar,
        comparison_type=ComparisonTypes.mean,
        quantity=qgroup,
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


def test_unsupported_viz_type_raises(processor: DataProcessor):
    """An unsupported visualization type should raise ValueError."""

    spec = _build_base_spec(visualization_type=VizType.hist)
    with pytest.raises(ValueError, match="Unsupported visualization type"):
        _ = processor.prepare_data_for_plot(spec)
