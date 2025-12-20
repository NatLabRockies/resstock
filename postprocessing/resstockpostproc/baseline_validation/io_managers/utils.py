"""
Utility functions for data loading and processing
"""

import polars as pl
from typing import Literal
from resstockpostproc.shared_utils.mapping import NUM2MONTH


def add_us_total(
    df: pl.DataFrame,
    by: str,
    group_cols: list[str] | None = None,
    exclude_cols: list[str] | None = None,
) -> pl.DataFrame:
    """
    Add a "US Total" pseudo-entity by summing all values across all entities.
    
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
    """
    Make sure all states are present in the dataframe.
    Older ResStock runs sometimes lack HI and AK which makes comparisons difficult.
    Add null rows for missing states.
    
    Args:
        df: DataFrame to add All States to. Must contain a 'state' column.
        additional_join_cols: Additional columns to join on when adding missing states.
                              This is useful for monthly data where 'month' is also a grouping column.
    Returns:
        DataFrame with missing states added
    """
    too_add_states = ["AK", "HI"]
    existing_states = set(df["state"].unique().to_list())
    missing_states = set(too_add_states) - existing_states
    if not missing_states:
        return df
    
    if "month" in df.columns:
        missing_data = []
        for state in missing_states:
            for month in NUM2MONTH.values():
                missing_data.append({"state": state, "month": month})
        missing_df = pl.DataFrame(missing_data)
        join_cols = ["state", "month"]
    else:
        missing_df = pl.DataFrame({"state": list(missing_states)})
        join_cols = ["state"]
    
    df = df.join(missing_df, on=join_cols, how="outer", coalesce=True)
    return df
