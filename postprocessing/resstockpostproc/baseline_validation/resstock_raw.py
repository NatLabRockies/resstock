"""Helpers for resolving ResStock raw parquet columns across schema variants."""

from __future__ import annotations

import polars as pl

from resstockpostproc.baseline_validation.schema.recs_chars_mapping import RECS_CHARS_MAPPING, PartialMap
from resstockpostproc.shared_utils.db_column_names import DataCol, DBSchema, get_db_enduse_colnames_map


def resstock_group_expr(col: str, available_cols: set[str]) -> pl.Expr:
    """Build mapped ResStock expression for one grouping/filter column."""
    if col not in RECS_CHARS_MAPPING:
        raise ValueError(f"Unsupported ResStock grouping column: {col}")
    spec = RECS_CHARS_MAPPING[col]["ResStock"]
    raw_col = resolve_existing_char_column(spec["column_name"], available_cols)
    mapping = spec["mapping"]

    if isinstance(mapping, PartialMap):
        expr = pl.col(raw_col).cast(pl.String)
        if mapping:
            expr = expr.replace(mapping)
        return expr.alias(col)
    return pl.col(raw_col).replace_strict(mapping, default=None).cast(pl.String).alias(col)


def resolve_existing_char_column(col: str, available_cols: set[str]) -> str:
    """Resolve characteristic column names across known naming variants."""
    if col in available_cols:
        return col
    if col.startswith("in.") and col.removeprefix("in.") in available_cols:
        return col.removeprefix("in.")
    alt = f"build_existing_model.{col.removeprefix('in.')}"
    if alt in available_cols:
        return alt
    raise ValueError(f"Missing required characteristic column '{col}' in raw histogram parquet")


def resstock_quantity_expr(
    quantity: DataCol,
    db_schema: DBSchema,
    available_cols: set[str],
) -> pl.Expr:
    """Build ResStock quantity expression from mapped raw column(s)."""
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
            resolved_cols = [resolve_resstock_quantity_col(col, available_cols) for col in raw_cols]
        except ValueError as exc:
            last_error = exc
            continue

        exprs = [pl.col(col).cast(pl.Float64) for col in resolved_cols]
        if len(exprs) == 1:
            return exprs[0]
        return pl.sum_horizontal(exprs)

    assert last_error is not None
    raise last_error


def resolve_resstock_quantity_col(col: str, available_cols: set[str]) -> str:
    """Resolve an end-use column name against available raw parquet columns."""
    candidates = quantity_col_candidates(col)
    for cand in candidates:
        if cand in available_cols:
            return cand
    raise ValueError(f"Missing required quantity column '{col}' in raw histogram parquet")


def quantity_col_candidates(col: str) -> list[str]:
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
    return list(dict.fromkeys(candidates))
