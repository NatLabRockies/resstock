import polars as pl
import math
from collections.abc import Sequence


def human_sort(df: pl.LazyFrame, cols: str | Sequence[str]) -> pl.LazyFrame:
    """
    Numeric-aware sort for one or many label columns.
    For example, 1 ACH50, 10 ACH50, 2 ACH50 will be sorted in the correct order of 1 ACH50, 2 ACH50, 10 ACH50.

    Examples
    --------
    df = human_sort(df, "ach_label")                      # single column
    df = human_sort(df, ["income_bin", "ach_label"])      # primary + secondary
    """
    if isinstance(cols, str):
        cols = [cols]

    helpers, helper_names, sort_keys = [], [], []

    for c in cols:
        num_col = f"__num_{c}"  # temp names

        # Extract numeric part from string and handle special cases
        numeric_expr = pl.col(c).cast(pl.String).str.extract(r"(-?\d+(?:\.\d+)?)", 1).cast(pl.Float64)

        helpers.append(
            pl.when(pl.col(c).cast(pl.String).str.starts_with("<"))
            .then(numeric_expr - 0.5)
            .when(pl.col(c).cast(pl.String).str.ends_with("+"))
            .then(numeric_expr + 0.5)
            .otherwise(numeric_expr)
            .fill_null(math.inf)
            .alias(num_col),
        )
        helper_names.append(num_col)
        sort_keys += [pl.col(num_col), pl.col(c)]  # numeric, then lexicographic

    return df.with_columns(helpers).sort(sort_keys, maintain_order=True).drop(helper_names)
