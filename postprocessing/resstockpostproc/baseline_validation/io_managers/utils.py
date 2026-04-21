"""Utility functions for data loading and processing
"""

import polars as pl
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.baseline_validation.schema.plot_spec import DataKey, Metric, CoverageType



def add_us_total(
    df: pl.DataFrame,
    by: str,
    group_cols: list[str] | None = None,
    exclude_cols: list[str] | None = None,
) -> pl.DataFrame:
    """Add a "US Total" pseudo-entity by summing all values across all entities.

    Args:
        df: DataFrame to add US Total to
        by: The column name that contains the entity identifiers (e.g., 'state', 'eiaid')
        group_cols: Additional columns to group by (e.g., ['month'] for monthly data).
                   If None, assumes annual data with no grouping needed.
        exclude_cols: Columns to exclude from summation (e.g., sample_count, RSE columns).
                     These will be set to None in the US Total row.

    Returns:
        DataFrame with US Total row(s) added

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
    """Make sure all states are present in the dataframe.
    Older ResStock runs sometimes lack HI and AK which makes comparisons difficult.
    Add null rows for missing states.

    Args:
        df: DataFrame to add All States to. Must contain a 'state' column.
        additional_join_cols: Additional columns to join on when adding missing states.
                              This is useful for monthly data where 'month' is also a grouping column.

    Returns:
        DataFrame with missing states added

    """
    states_to_add = ["AK", "HI"]
    existing_states = set(df["state"].unique().to_list())
    missing_states = [s for s in states_to_add if s not in existing_states]
    if not missing_states:
        return df

    if "month" in df.columns:
        missing_data = [
            {"state": state, "month": month}
            for state in missing_states
            for month in NUM2MONTH.values()
        ]
        missing_df = pl.DataFrame(missing_data)
        join_cols = ["state", "month"]
    else:
        missing_df = pl.DataFrame({"state": missing_states})
        join_cols = ["state"]

    return df.join(missing_df, on=join_cols, how="full", coalesce=True, maintain_order="left_right")


def apply_aggregation(data_key: DataKey, df: pl.DataFrame) -> pl.DataFrame:
    """Apply aggregation transformation based on DataKey.

    Args:
        data_key: DataKey containing aggregation_type and coverage
        df: DataFrame with _value columns and units_count

    Returns:
        DataFrame with values transformed according to aggregation type

    """
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
