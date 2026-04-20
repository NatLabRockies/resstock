"""Exact histogram data preparation for baseline-validation distribution plots."""

from __future__ import annotations

from functools import cache
import logging
from pathlib import Path

import polars as pl

from resstockpostproc.baseline_validation.resstock_raw import (
    resolve_existing_char_column as _resolve_existing_char_column,
    resstock_group_expr as _resstock_group_expr,
    resstock_quantity_expr as _resstock_quantity_expr,
)
from resstockpostproc.baseline_validation.schema.plot_spec import (
    CoverageType,
    DataKey,
    DataCol,
    PlotSpec,
)
from resstockpostproc.baseline_validation.schema.recs_chars_mapping import RECS_CHARS_MAPPING, PartialMap
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow, DataSourceConfig
from resstockpostproc.baseline_validation.plot_semantics import apply_source_labels
from resstockpostproc.baseline_validation.io_managers import comparison_data_paths as s3_paths
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3
from resstockpostproc.shared_utils.db_column_names import get_db_characteristics_colnames
from resstockpostproc.shared_utils.histogram_utils import build_weighted_histogram_with_overflow
from resstockpostproc.shared_utils.timing import timed


_LOCAL_RECS_DATA_DIR = Path(f"{workflow.output.output_dir}/data")
logger = logging.getLogger(__name__)


@timed
def get_distribution_histogram_data(plot_spec: PlotSpec) -> pl.DataFrame:
    """Get exact histogram data for one distribution histogram plot spec."""
    geometry_cols = tuple(col for col in plot_spec.effective_group_by if col != plot_spec.group_by)
    hist = _get_distribution_histogram_base(
        plot_spec.data_key,
        plot_spec.quantity,
        plot_spec.coverage,
        geometry_cols,
        "recs_2020",
    )

    # Apply focus filters on histogram rows (US Total is represented explicitly).
    out = hist
    for col, val in plot_spec.focus_on:
        if col in out.columns:
            out = out.filter(pl.col(col) == val)

    # Drop focus_on filter columns (already applied) but keep group_by column.
    cols_to_keep = {plot_spec.group_by} if plot_spec.group_by else set()
    drop_cols = [col for col in plot_spec.effective_group_by if col in out.columns and col not in cols_to_keep]
    if drop_cols:
        out = out.drop(drop_cols)

    out = apply_source_labels(out, workflow.data_source_labels)
    sort_cols = ["source", "bin"]
    if plot_spec.group_by and plot_spec.group_by in out.columns:
        sort_cols = [plot_spec.group_by] + sort_cols
    return out.sort(sort_cols)


@cache
def _get_distribution_histogram_base(
    data_key: DataKey,
    quantity: DataCol,
    coverage: CoverageType,
    geometry_cols: tuple[str, ...],
    geometry_source: str | None,
) -> pl.DataFrame:
    """Compute cached exact histogram base data for one DataKey/quantity/coverage."""
    group_cols = list(data_key.effective_group_by)
    frames = [_load_recs_hist_rows(quantity, coverage, group_cols)]

    for source in workflow.data_sources:
        frames.append(_load_resstock_hist_rows(source, quantity, coverage, group_cols))

    rows = pl.concat(frames, how="diagonal_relaxed")
    if rows.is_empty():
        return rows

    return build_weighted_histogram_with_overflow(
        rows,
        source_col="source",
        value_col="value",
        weight_col="weight",
        group_cols=group_cols,
        geometry_cols=list(geometry_cols),
        geometry_source=geometry_source,
        n_core_bins=49,
    )


def _load_recs_hist_rows(
    quantity: DataCol,
    coverage: CoverageType,
    group_cols: list[str],
) -> pl.DataFrame:
    """Load RECS microdata rows needed for histogram binning."""
    mdf = get_df_from_s3(s3_paths.RECS_2020_microdata, _LOCAL_RECS_DATA_DIR)
    group_exprs = [_recs_group_expr(col) for col in group_cols]
    value_expr = _recs_quantity_expr(quantity).alias("value")
    out = mdf.select(
        *group_exprs,
        value_expr,
        pl.col("NWEIGHT").cast(pl.Float64).alias("weight"),
        pl.lit("recs_2020").alias("source"),
    )
    if coverage == CoverageType.users_only:
        out = out.filter(pl.col("value") > 0)
    return _add_us_total_rows(out, group_cols)


def _load_resstock_hist_rows(
    data_source: DataSourceConfig,
    quantity: DataCol,
    coverage: CoverageType,
    group_cols: list[str],
) -> pl.DataFrame:
    """Load one ResStock raw parquet's rows needed for histogram binning."""
    raw_path = workflow.get_resstock_data_file(data_source.name)
    lf = pl.scan_parquet(raw_path)
    schema = lf.collect_schema()
    available = set(schema.names())
    if "weight" not in available:
        raise ValueError(
            f"Missing required 'weight' column in ResStock histogram file: {raw_path}"
        )

    vacancy_col = _resolve_existing_char_column(
        get_db_characteristics_colnames(data_source.db_schema).VACANCY,
        available,
    )
    lf = lf.filter(pl.col(vacancy_col) == "Occupied")

    group_exprs = [_resstock_group_expr(col, available) for col in group_cols]
    try:
        value_expr = _resstock_quantity_expr(quantity, data_source.db_schema, available).alias("value")
    except ValueError as exc:
        if "Missing required quantity column" not in str(exc):
            raise
        logger.info(
            "Skipping histogram source %s for quantity %s because the raw parquet lacks that enduse column.",
            data_source.name,
            quantity,
        )
        return _empty_hist_rows(group_cols)

    out = lf.select(
        *group_exprs,
        value_expr,
        pl.col("weight").cast(pl.Float64).alias("weight"),
        pl.lit(data_source.name).alias("source"),
    ).collect()
    if coverage == CoverageType.users_only:
        out = out.filter(pl.col("value") > 0)
    return _add_us_total_rows(out, group_cols)


def _recs_group_expr(col: str) -> pl.Expr:
    """Build mapped RECS expression for one grouping/filter column."""
    if col not in RECS_CHARS_MAPPING:
        raise ValueError(f"Unsupported RECS grouping column for histogram: {col}")
    spec = RECS_CHARS_MAPPING[col]["RECS"]
    raw_col = spec["column_name"]
    mapping = spec["mapping"]

    if isinstance(mapping, PartialMap):
        expr = pl.col(raw_col).cast(pl.String)
        if mapping:
            expr = expr.replace(mapping)
        return expr.alias(col)
    return pl.col(raw_col).replace_strict(mapping, default=None).cast(pl.String).alias(col)

def _recs_quantity_expr(quantity: DataCol) -> pl.Expr:
    """Build RECS quantity expression in kWh for a DataCol."""
    if quantity not in RECS_ENDUSE_MAP:
        raise ValueError(f"Quantity {quantity} not supported in RECS histogram mapping")
    spec = RECS_ENDUSE_MAP[quantity]
    if isinstance(spec, tuple):
        exprs = [pl.col(item["column_name"]).cast(pl.Float64) * float(item["factor"]) for item in spec]
        return pl.sum_horizontal(exprs)
    return pl.col(spec["column_name"]).cast(pl.Float64) * float(spec["factor"])

def _add_us_total_rows(df: pl.DataFrame, group_cols: list[str]) -> pl.DataFrame:
    """Add US Total pseudo-group rows when state is one of the grouping columns."""
    if "state" not in group_cols or "state" not in df.columns:
        return df
    return pl.concat(
        [
            df,
            df.with_columns(pl.lit("US Total").alias("state")),
        ],
        how="diagonal_relaxed",
    )


def _empty_hist_rows(group_cols: list[str]) -> pl.DataFrame:
    """Return an empty histogram-row dataframe with the expected schema."""
    schema = {col: pl.String for col in group_cols}
    schema.update({
        "value": pl.Float64,
        "weight": pl.Float64,
        "source": pl.String,
    })
    return pl.DataFrame(schema=schema)
