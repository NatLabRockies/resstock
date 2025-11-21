"""
Utility functions for data loading and processing
"""

import polars as pl
from typing import Literal


def add_us_total(
    df: pl.DataFrame,
    by: str,
    group_cols: list[str] | None = None,
) -> pl.DataFrame:
    """
    Add a "US Total" pseudo-entity by summing all values across all entities.
    
    Args:
        df: DataFrame to add US Total to
        by: The column name that contains the entity identifiers (e.g., 'state', 'eiaid')
        group_cols: Additional columns to group by (e.g., ['month'] for monthly data).
                   If None, assumes annual data with no grouping needed.
    
    Returns:
        DataFrame with US Total row(s) added
    """
    # Check if US Total already exists
    if "US Total" in df[by].unique().to_list():
        return df
    
    # Determine which columns to sum (all except the grouping columns)
    if group_cols is None:
        group_cols = []
    
    cols_to_exclude = {by, *group_cols}
    value_cols = [col for col in df.columns if col not in cols_to_exclude]
    
    if group_cols:
        # Monthly or other grouped data - group by the additional columns and sum
        us_total_data = df.group_by(group_cols).agg(
            [pl.col(col).sum().alias(col) for col in value_cols]
        )
        us_total_data = us_total_data.with_columns(pl.lit("US Total").alias(by))
        # Reorder columns to match original dataframe
        us_total_data = us_total_data.select(df.columns)
    else:
        # Annual data - just sum everything
        us_total_data = df.select(value_cols).sum()
        us_total_data = us_total_data.with_columns(pl.lit("US Total").alias(by))
        # Reorder columns to match original dataframe
        us_total_data = us_total_data.select(df.columns)
    
    # Concatenate with original data
    return pl.concat([df, us_total_data])
