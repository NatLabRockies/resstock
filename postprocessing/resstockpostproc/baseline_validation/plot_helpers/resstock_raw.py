"""Helpers for resolving ResStock raw parquet columns across schema variants."""

from __future__ import annotations

import polars as pl

from resstockpostproc.baseline_validation.schema.recs_chars_mapping import RECS_CHARS_MAPPING, PartialMap
from resstockpostproc.shared_utils.db_column_names import DataCol, DBSchema, get_db_enduse_colnames_map
from resstockpostproc.shared_utils.mapping import STATE2CENSUS_DIVISION_RECS


def resstock_group_expr(col: str, available_cols: set[str]) -> pl.Expr:
    """Build mapped ResStock expression for one grouping/filter column."""
    if col not in RECS_CHARS_MAPPING:
        known = ", ".join(sorted(RECS_CHARS_MAPPING))
        raise ValueError(f"Unsupported ResStock grouping column {col!r}. Known: {known}")
    spec = RECS_CHARS_MAPPING[col]["ResStock"]
    if col == DataCol.CENSUS_DIVISION and spec["column_name"] not in available_cols:
        return _census_division_from_state(available_cols).alias(col)
    raw_col = resolve_existing_char_column(spec["column_name"], available_cols)
    mapping = spec["mapping"]

    if isinstance(mapping, PartialMap):
        expr = pl.col(raw_col).cast(pl.String)
        if mapping:
            expr = expr.replace(mapping)
        return expr.alias(col)
    return pl.col(raw_col).replace_strict(mapping, default=None).cast(pl.String).alias(col)


class UnavailableDimension(ValueError):
    """A characteristic the run's data cannot supply at all.

    Distinct from a failure to plot: there is nothing wrong with the request, the
    publication simply does not carry that dimension. Comparisons needing it are left out
    rather than approximated from a different column, and rather than stopping the run.
    Subclasses ValueError so existing handlers keep working.
    """


def _census_division_from_state(available_cols: set[str]) -> pl.Expr:
    """Derive the RECS census division from the state.

    A division is a fixed partition of the states, so this loses nothing and is the one
    geography a state-grain publication can still be compared at. Everything finer -- county,
    climate zone, utility -- genuinely needs the allocated geography and is refused instead.
    """
    state_col = resolve_existing_char_column(
        RECS_CHARS_MAPPING[DataCol.STATE]["ResStock"]["column_name"], available_cols)
    return pl.col(state_col).replace_strict(STATE2CENSUS_DIVISION_RECS, default=None).cast(pl.String)


def resolve_existing_char_column(col: str, available_cols: set[str]) -> str:
    """Resolve characteristic column names across known naming variants."""
    bare = col.removeprefix("in.")
    # Deliberately NOT tried: `in.as_simulated_<bare>`. It names where the building was
    # simulated, not where its dwelling units are, so it is a different variable.
    tried = [col, bare, f"build_existing_model.{bare}"]
    for candidate in tried:
        if candidate in available_cols:
            return candidate
    raise UnavailableDimension(
        f"Missing required characteristic column {col!r} in raw histogram parquet. "
        f"Tried variants: {tried}. Sample of available cols (first 10): "
        f"{sorted(available_cols)[:10]} (of {len(available_cols)} total)."
    )


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
        schemas_tried = ", ".join(s.value if hasattr(s, "value") else str(s) for s in DBSchema)
        raise ValueError(
            f"Quantity {quantity!r} has no ResStock raw mapping for any known schema "
            f"({schemas_tried}). Add it to get_db_enduse_colnames_map for at least one schema."
        )

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
    nearby = [c for c in available_cols if col.split(".")[0] in c]
    raise ValueError(
        f"Missing required quantity column {col!r} in raw histogram parquet. "
        f"Tried candidates: {candidates}. "
        f"Columns containing the same base prefix (sample, max 10): {sorted(nearby)[:10]}."
    )


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
