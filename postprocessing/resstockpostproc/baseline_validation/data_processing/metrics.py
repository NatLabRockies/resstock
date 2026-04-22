"""Data-analysis metrics used by baseline validation plots.

Pure analysis helpers — compute statistics over already-loaded DataFrames;
do not touch rendering or I/O.
"""

from __future__ import annotations

import polars as pl

from resstockpostproc.baseline_validation.plot_helpers.plot_semantics import (
    format_source_label,
    resolve_timeseries_column,
)
from resstockpostproc.baseline_validation.plotters.plot_config import (
    get_second_category_column,
)
from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.timing import timed


@timed
def compute_discrepancy(data: pl.DataFrame, plot_spec: PlotSpec) -> dict[str, float]:
    """Compute MAPE (%) for each ResStock source.

    MAPE = mean(|ResStock - Ref| / |Ref|) * 100

    Rows with zero reference values are excluded. Returns a dict keyed by
    formatted source label (e.g. "ResStock 2025"), with per-source MAPE (%)
    values. Empty dict when metrics cannot be computed.
    """
    if plot_spec.is_all_enduses:
        return {}
    if plot_spec.is_distribution_metric:
        return {}

    val_col = _value_column_for(plot_spec)
    if val_col not in data.columns:
        return {}

    comparison = plot_spec.comparison_dataset.value
    ref_rows = data.filter(pl.col("source").str.to_lowercase().str.contains(comparison))
    rs_sources = sorted(s for s in data["source"].unique().to_list() if "resstock" in s.lower())

    if len(ref_rows) == 0 or not rs_sources:
        return {}

    agg_col = get_second_category_column(plot_spec)
    join_cols = [agg_col]
    ts_col = resolve_timeseries_column(plot_spec)
    if ts_col and str(ts_col) in data.columns:
        join_cols.append(str(ts_col))

    is_us_total_focus = any(val == "US Total" for _, val in plot_spec.focus_on)
    if not is_us_total_focus:
        ref_rows = ref_rows.filter(pl.col(agg_col) != "US Total")

    ref_selected = ref_rows.select(join_cols + [pl.col(val_col).alias("ref_val")])

    metrics: dict[str, float] = {}
    for rs_source in rs_sources:
        mape = _mape_for_source(data, rs_source, val_col, join_cols, ref_selected, agg_col, is_us_total_focus)
        if mape is not None:
            metrics[format_source_label(rs_source)] = mape

    return metrics


def _value_column_for(plot_spec: PlotSpec) -> str:
    """Pick the value column MAPE compares against."""
    if plot_spec.quantity == DataCol.UNITS_COUNT:
        return "units_count"
    if plot_spec.is_penetration_metric:
        return f"{plot_spec.quantity}_percent_users"
    return f"{plot_spec.quantity}_value"


def _mape_for_source(
    data: pl.DataFrame,
    rs_source: str,
    val_col: str,
    join_cols: list[str],
    ref_selected: pl.DataFrame,
    agg_col: str,
    is_us_total_focus: bool,
) -> float | None:
    """Return MAPE (%) for a single ResStock source, or None if uncomputable."""
    rs_rows = data.filter(pl.col("source") == rs_source)
    if not is_us_total_focus:
        rs_rows = rs_rows.filter(pl.col(agg_col) != "US Total")

    rs_selected = rs_rows.select(join_cols + [pl.col(val_col).alias("rs_val")])
    paired = rs_selected.join(ref_selected, on=join_cols, how="inner", maintain_order="left_right")
    paired = paired.drop_nulls(["ref_val", "rs_val"])
    paired = paired.with_columns(
        pl.col("ref_val").fill_nan(0),
        pl.col("rs_val").fill_nan(0),
    )
    if len(paired) == 0:
        return None

    term_df = paired.filter(pl.col("ref_val").abs() > 0).with_columns(
        ((pl.col("rs_val") - pl.col("ref_val")).abs() / pl.col("ref_val").abs()).alias("mape_term")
    )
    if len(term_df) == 0:
        return None

    return float(term_df["mape_term"].mean() * 100.0)
