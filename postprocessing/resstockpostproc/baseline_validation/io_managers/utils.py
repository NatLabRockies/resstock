"""Utility functions for data loading and processing."""

import polars as pl
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.baseline_validation.schema.plot_spec import DataKey, Metric, CoverageType


def add_us_total(
    df: pl.DataFrame,
    by: str,
    group_cols: list[str] | None = None,
    exclude_cols: list[str] | None = None,
) -> pl.DataFrame:
    """Append a "US Total" pseudo-entity summed across ``by``.

    ``exclude_cols`` are left out of the sum and set to None in the new row.
    No-op if ``by`` already contains "US Total".
    """
    # Check if US Total already exists
    if "US Total" in df[by].unique().to_list():
        return df

    # Determine which columns to sum (all except the grouping columns)
    if group_cols is None:
        group_cols = []
    if exclude_cols is None:
        exclude_cols = []

    cols_to_exclude = {by, *group_cols, *exclude_cols}
    value_cols = [col for col in df.columns if col not in cols_to_exclude]

    if group_cols:
        # Monthly or other grouped data - group by the additional columns and sum
        us_total_data = df.group_by(group_cols, maintain_order=True).agg(
            [pl.col(col).sum().alias(col) for col in value_cols]
        )
        us_total_data = us_total_data.with_columns(pl.lit("US Total").alias(by))
        # Add null values for excluded columns
        for col in exclude_cols:
            us_total_data = us_total_data.with_columns(pl.lit(None).alias(col))
        # Reorder columns to match original dataframe
        us_total_data = us_total_data.select(df.columns)
    else:
        # Annual data - just sum everything
        us_total_data = df.select(value_cols).sum()
        us_total_data = us_total_data.with_columns(pl.lit("US Total").alias(by))
        # Add null values for excluded columns
        for col in exclude_cols:
            us_total_data = us_total_data.with_columns(pl.lit(None).alias(col))
        # Reorder columns to match original dataframe
        us_total_data = us_total_data.select(df.columns)

    # Concatenate with original data
    return pl.concat([df, us_total_data])


def add_missing_states(df: pl.DataFrame) -> pl.DataFrame:
    """Add null rows for any missing AK/HI states.

    Older ResStock runs drop these, which breaks state-by-state comparisons.
    Joins on ``month`` too when the column is present.
    """
    states_to_add = ["AK", "HI"]
    existing_states = set(df["state"].unique().to_list())
    missing_states = [s for s in states_to_add if s not in existing_states]
    if not missing_states:
        return df

    if "month" in df.columns:
        missing_data = [{"state": state, "month": month} for state in missing_states for month in NUM2MONTH.values()]
        missing_df = pl.DataFrame(missing_data)
        join_cols = ["state", "month"]
    else:
        missing_df = pl.DataFrame({"state": missing_states})
        join_cols = ["state"]

    return df.join(missing_df, on=join_cols, how="full", coalesce=True, maintain_order="left_right")


def apply_aggregation(data_key: DataKey, df: pl.DataFrame) -> pl.DataFrame:
    """Divide ``_value`` columns by per-unit denominator matching ``data_key.coverage``."""
    if data_key.aggregation_type == Metric.total:
        return df  # No transformation needed

    if data_key.coverage == CoverageType.all_units:
        value_cols = [col for col in df.columns if col.endswith("_value")]
        df = df.with_columns([(pl.col(col) / pl.col("units_count")).alias(col) for col in value_cols])
    elif data_key.coverage == CoverageType.users_only:
        value_cols = [col for col in df.columns if col.endswith("_value")]
        percent_users_cols = [col.replace("_value", "_percent_users") for col in value_cols]
        df = df.with_columns(
            [
                (pl.col(value_col) / (pl.col(percent_users_col) / 100 * pl.col("units_count"))).alias(value_col)
                for value_col, percent_users_col in zip(value_cols, percent_users_cols)
                if percent_users_col in df.columns
            ]
        )
    else:
        raise ValueError(f"Unsure how to apply aggregation for {data_key.coverage} coverage.")
    return df
