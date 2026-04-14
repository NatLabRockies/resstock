"""Exact histogram data preparation for baseline-validation distribution plots."""

from __future__ import annotations

from functools import cache
from pathlib import Path

import polars as pl

from resstockpostproc.baseline_validation.schema.plot_spec import (
    CoverageType,
    DataKey,
    DataCol,
    PlotSpec,
)
from resstockpostproc.baseline_validation.schema.recs_chars_mapping import RECS_CHARS_MAPPING, PartialMap
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow, DataSourceConfig
from resstockpostproc.baseline_validation.io_managers import comparison_data_paths as s3_paths
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3
from resstockpostproc.shared_utils.db_column_names import DBSchema, get_db_enduse_colnames_map
from resstockpostproc.shared_utils.histogram_utils import build_weighted_histogram_with_overflow
from resstockpostproc.shared_utils.timing import timed


_LOCAL_RECS_DATA_DIR = Path(f"{workflow.output.output_dir}/data")


@timed
def get_distribution_histogram_data(plot_spec: PlotSpec) -> pl.DataFrame:
    """Get exact histogram data for one distribution histogram plot spec."""
    hist = _get_distribution_histogram_base(
        plot_spec.data_key,
        plot_spec.quantity,
        plot_spec.coverage,
    )

    # Apply focus filters on histogram rows (US Total is represented explicitly).
    out = hist
    for col, val in plot_spec.focus_on:
        if col in out.columns:
            out = out.filter(pl.col(col) == val)

    # Histogram layout is no-group only; drop grouping columns after filtering.
    drop_cols = [col for col in plot_spec.effective_group_by if col in out.columns]
    if drop_cols:
        out = out.drop(drop_cols)

    source_label_map = {k: v.label for k, v in workflow.data_source_labels.items()}
    if source_label_map and "source" in out.columns:
        out = out.with_columns(
            pl.col("source").replace_strict(source_label_map, default=pl.col("source"))
        )
    return out.sort(["source", "bin"])


@cache
def _get_distribution_histogram_base(
    data_key: DataKey,
    quantity: DataCol,
    coverage: CoverageType,
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
    raw_path = workflow.get_resstock_histogram_raw_file(data_source.name)
    lf = pl.scan_parquet(raw_path)
    schema = lf.collect_schema()
    available = set(schema.names())
    if "weight" not in available:
        raise ValueError(
            f"Missing required 'weight' column in ResStock histogram file: {raw_path}"
        )

    group_exprs = [_resstock_group_expr(col, available) for col in group_cols]
    value_expr = _resstock_quantity_expr(quantity, data_source.db_schema, available).alias("value")

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


def _resstock_group_expr(col: str, available_cols: set[str]) -> pl.Expr:
    """Build mapped ResStock expression for one grouping/filter column."""
    if col not in RECS_CHARS_MAPPING:
        raise ValueError(f"Unsupported ResStock grouping column for histogram: {col}")
    spec = RECS_CHARS_MAPPING[col]["ResStock"]
    raw_col = _resolve_existing_char_column(spec["column_name"], available_cols)
    mapping = spec["mapping"]

    if isinstance(mapping, PartialMap):
        expr = pl.col(raw_col).cast(pl.String)
        if mapping:
            expr = expr.replace(mapping)
        return expr.alias(col)
    return pl.col(raw_col).replace_strict(mapping, default=None).cast(pl.String).alias(col)


def _resolve_existing_char_column(col: str, available_cols: set[str]) -> str:
    """Resolve characteristic column names across known naming variants."""
    if col in available_cols:
        return col
    if col.startswith("in.") and col.removeprefix("in.") in available_cols:
        return col.removeprefix("in.")
    alt = f"build_existing_model.{col.removeprefix('in.')}"
    if alt in available_cols:
        return alt
    raise ValueError(f"Missing required characteristic column '{col}' in raw histogram parquet")


def _recs_quantity_expr(quantity: DataCol) -> pl.Expr:
    """Build RECS quantity expression in kWh for a DataCol."""
    if quantity not in RECS_ENDUSE_MAP:
        raise ValueError(f"Quantity {quantity} not supported in RECS histogram mapping")
    spec = RECS_ENDUSE_MAP[quantity]
    if isinstance(spec, tuple):
        exprs = [pl.col(item["column_name"]).cast(pl.Float64) * float(item["factor"]) for item in spec]
        return pl.sum_horizontal(exprs)
    return pl.col(spec["column_name"]).cast(pl.Float64) * float(spec["factor"])


def _resstock_quantity_expr(
    quantity: DataCol,
    db_schema: DBSchema,
    available_cols: set[str],
) -> pl.Expr:
    """Build ResStock quantity expression from mapped raw column(s).

    Handles raw parquet schema variants by trying:
    1) the configured schema map first,
    2) then the alternate schema map(s),
    while normalizing unit suffix variants (bare, .kwh, ..kwh, .c, ..c).
    """
    mapping_options: list[str | tuple[str, ...]] = []
    primary = get_db_enduse_colnames_map(db_schema).get(quantity)
    if primary is not None:
        mapping_options.append(primary)

    for schema_option in DBSchema:
        if schema_option == db_schema:
            continue
        alt = get_db_enduse_colnames_map(schema_option).get(quantity)
        if alt is not None and alt not in mapping_options:
            mapping_options.append(alt)

    if not mapping_options:
        raise ValueError(f"Quantity {quantity} has no ResStock raw mapping for any known schema")

    last_error: ValueError | None = None
    for mapped in mapping_options:
        raw_cols = [mapped] if isinstance(mapped, str) else list(mapped)
        try:
            resolved_cols = [_resolve_resstock_quantity_col(col, available_cols) for col in raw_cols]
        except ValueError as exc:
            last_error = exc
            continue

        exprs = [pl.col(col).cast(pl.Float64) for col in resolved_cols]
        if len(exprs) == 1:
            return exprs[0]
        return pl.sum_horizontal(exprs)

    assert last_error is not None
    raise last_error


def _resolve_resstock_quantity_col(col: str, available_cols: set[str]) -> str:
    """Resolve an end-use column name against available raw parquet columns."""
    candidates = _quantity_col_candidates(col)
    for cand in candidates:
        if cand in available_cols:
            return cand
    raise ValueError(f"Missing required quantity column '{col}' in raw histogram parquet")


def _quantity_col_candidates(col: str) -> list[str]:
    """Generate candidate raw-column variants for one mapped quantity column."""
    base = col
    for suffix in ("..kwh", ".kwh", "..c", ".c"):
        if base.endswith(suffix):
            base = base.removesuffix(suffix)
            break

    candidates = [
        col,
        base,
        f"{base}.kwh",
        f"{base}..kwh",
        f"{base}.c",
        f"{base}..c",
    ]
    # preserve order while de-duplicating
    return list(dict.fromkeys(candidates))


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
