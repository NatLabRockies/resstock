"""Box-plot quartile helpers for the stacked plot family.

Builds the scalar q1/median/q3/whisker/min/max columns that ``box_plotter``
consumes from the list-valued ``_quartiles`` / ``_nonzero_quartiles``
column produced upstream, and prepares the dataframe shape
(``n_points``, ``mean``, ``outliers``) expected by the box-plot renderer.

Extracted from stacked_plotter.py in refactor plan V2 step 6.2.
"""

import polars as pl

from resstockpostproc.baseline_validation.plot_semantics import QUARTILE_INDICES, quartile_list_column
from resstockpostproc.baseline_validation.schema.plot_spec import CoverageType
from resstockpostproc.shared_utils.timing import timed


# Box plotter reads whisker columns separately from min/max; alias them
# from the shared quartile indices so there's one source of truth.
_WHISKER_ALIASES = {"min": "lower_whisker", "max": "upper_whisker"}


def add_quartile_cols(df: pl.DataFrame, quartile_column: str) -> pl.DataFrame:
    """Extract scalar q1/median/q3/min/max (+ whisker aliases) from the list column."""
    exprs: list[pl.Expr] = []
    for idx, name in QUARTILE_INDICES:
        col = pl.col(quartile_column).list.get(idx).cast(pl.Float64)
        exprs.append(col.alias(name))
        if name in _WHISKER_ALIASES:
            exprs.append(col.alias(_WHISKER_ALIASES[name]))
    return df.with_columns(exprs)

@timed
def prepare_box_plot_data(df: pl.DataFrame, quantity: str, coverage: CoverageType) -> pl.DataFrame:
    """Prepare the data for box plot by adding necessary columns.

    Args:
        df: Input DataFrame
        quantity: The quantity column name (without suffix)
        coverage: CoverageType.all_units uses _quartiles, CoverageType.users_only uses _nonzero_quartiles.
            For non-ALL users_only plots, model_count is already normalized upstream to the
            exact nonzero model/sample count for this quantity, so box-plot n_points should
            use it directly.

    """
    df = df.with_columns(pl.lit([]).alias("outliers"))
    df = df.with_columns(pl.lit([]).alias("outlier_buildings"))
    df = df.with_columns(pl.col(f"{quantity}_value").alias("mean"))

    if coverage == CoverageType.all_units:
        df = df.with_columns(pl.col("model_count").alias("n_points"))
    elif coverage == CoverageType.users_only:
        df = df.with_columns(
            pl.col("model_count").fill_null(0).fill_nan(0).cast(pl.Int32).alias("n_points")
        )
    else:
        raise ValueError(f"Unsupported coverage type for box plot: {coverage}")
    df = add_quartile_cols(df, quartile_list_column(quantity, coverage))
    return df
