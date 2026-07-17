"""Shared sorting helpers for categorical labels across postprocessing modules."""

from __future__ import annotations

import math
from collections.abc import Sequence

import polars as pl


# Values that should always sort to the end when no explicit custom order is used.
keep_last_keys: list[str] = ["None", "No", "Never", "Not Available", "No Constraint"]


# Minimal custom sort definitions needed for baseline validation RECS grouped views.
custom_sorts: dict[str, list[str]] = {
    "census_division_recs": [
        "US Total",
        "New England",
        "Middle Atlantic",
        "East North Central",
        "West North Central",
        "South Atlantic",
        "East South Central",
        "West South Central",
        "Mountain North",
        "Mountain South",
        "Pacific",
    ],
    "geometry_building_type_recs": [
        "Single-Family Detached",
        "Single-Family Attached",
        "Multi-Family 2-4",
        "Multi-Family with 2 - 4 Units",
        "Multi-Family 5+",
        "Multi-Family with 5+ Units",
        "Mobile Home",
    ],
    "heating_fuel": ["Electricity", "Natural Gas", "Fuel Oil", "Propane", "Wood", "Other Fuel", "None"],
    "building_america_climate_zone": [
        "Hot-Dry",
        "Hot-Humid",
        "Mixed-Dry",
        "Mixed-Humid",
        "Marine",
        "Cold",
        "Very Cold",
        "Very-Cold",
        "Subarctic",
    ],
}


def _resolve_custom_sort(column: str) -> list[str]:
    """Return custom sort order for a column, handling optional in.* prefixes."""
    candidates = [column]
    if column.startswith("in."):
        candidates.append(column.removeprefix("in."))
    else:
        candidates.append(f"in.{column}")

    for key in candidates:
        if key in custom_sorts:
            return custom_sorts[key]
    return []


def human_sort(df: pl.LazyFrame, cols: str | Sequence[str]) -> pl.LazyFrame:
    """Natural/semantic sort for one or more label columns.

    Priority per column:
    1) Explicit custom sort rank (if defined)
    2) keep_last_keys ranking (to push common "missing/none" values to the end)
    3) First numeric token (e.g., 2 < 10, <1950 < 1950s)
    4) Lexicographic value
    """
    if isinstance(cols, str):
        cols = [cols]

    helpers: list[pl.Expr] = []
    sort_keys: list[pl.Expr] = []

    for col in cols:
        num_col_name = f"__num_{col}"
        rank_col_name = f"__rank_{col}"
        last_rank_col_name = f"__last_rank_{col}"

        custom_rank = {val: i for i, val in enumerate(_resolve_custom_sort(col))}
        rank_col = pl.col(col).cast(pl.String).replace_strict(custom_rank, default=math.inf).alias(rank_col_name)

        last_rank = {val: i for i, val in enumerate(keep_last_keys)}
        last_rank_col = pl.col(col).cast(pl.String).replace_strict(last_rank, default=-1).alias(last_rank_col_name)

        numeric_expr = pl.col(col).cast(pl.String).str.extract(r"(\d+(?:\.\d+)?)", 1).cast(pl.Float64)
        num_col = (
            pl.when(pl.col(col).cast(pl.String).str.starts_with("<"))
            .then(numeric_expr - 0.5)
            .when(pl.col(col).cast(pl.String).str.ends_with("+"))
            .then(numeric_expr + 0.5)
            .otherwise(numeric_expr)
            .fill_null(math.inf)
            .alias(num_col_name)
        )

        helpers.extend([rank_col, last_rank_col, num_col])
        sort_keys.extend([rank_col, last_rank_col, num_col, pl.col(col)])

    helper_names = [expr.meta.output_name() for expr in helpers]
    return df.with_columns(helpers).sort(sort_keys, maintain_order=True).drop(helper_names)
