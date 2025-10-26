import math
from pathlib import Path
from collections.abc import Sequence
from typing import Any

import polars as pl
import yaml
from resstockpostproc.standard_plots.schema.custom_sort import custom_sorts, keep_last_keys
from resstockpostproc.standard_plots.schema.workflow_schema import WorkflowConfig


def load_workflow_config(config: str | dict | WorkflowConfig) -> WorkflowConfig:
    """Normalize various workflow configuration inputs to a WorkflowConfig."""
    if isinstance(config, WorkflowConfig):
        return config
    if isinstance(config, str):
        return WorkflowConfig.from_yaml(config)
    if isinstance(config, dict):
        return WorkflowConfig(**config)
    raise ValueError(f"Unsupported type for workflow config: {type(config)}")


def load_highlight_config(highlights_config: str | Path | dict | None) -> dict[str, Any]:
    """Normalize highlight configuration input into a dictionary."""
    if highlights_config is None:
        config_path = Path(__file__).with_name("highlights.yaml")
        data = yaml.safe_load(config_path.read_text(encoding="utf-8"))
        return data or {}
    if isinstance(highlights_config, str | Path):
        config_path = Path(highlights_config)
        data = yaml.safe_load(config_path.read_text(encoding="utf-8"))
        return data or {}
    if isinstance(highlights_config, dict):
        return highlights_config
    raise ValueError(f"Unsupported highlight config type: {type(highlights_config)}")


def human_sort(df: pl.LazyFrame, cols: str | Sequence[str]) -> pl.LazyFrame:
    """
    Numeric-aware sort for one or many label columns.
    For example, 1 ACH50, 10 ACH50, 2 ACH50 will be sorted in the correct order of 1 ACH50, 2 ACH50, 10 ACH50.
    If custom order is specified, it will be used first.
    If one or more of the values appear in keep_last_keys, they will be placed at the end, in the order they appear
    in keep_last_keys.
    Otherwise, will be sorted in lexical order ascending.
    Examples
    --------
    df = human_sort(df, "ach_label")                      # single column
    df = human_sort(df, ["income_bin", "ach_label"])      # primary + secondary
    """
    if isinstance(cols, str):
        cols = [cols]

    helpers, sort_keys = [], []

    for c in cols:
        num_col_name = f"__num_{c}"  # temp names
        rank_col_name = f"__rank_{c}"
        last_rank_col_name = f"__last_rank_{c}"

        # Sort by creating 3 helper columns with priority order for each column

        # Highest priority is custom sort
        custom_rank = {val: i for i, val in enumerate(custom_sorts.get(c, {}))}
        rank_col = pl.col(c).cast(pl.String).replace(custom_rank, default=math.inf).alias(rank_col_name)

        # Next priority is keep_last_keys should be last
        last_rank = {val: i for i, val in enumerate(keep_last_keys)}
        last_rank_col = pl.col(c).cast(pl.String).replace(last_rank, default=-1).alias(last_rank_col_name)

        # Next priority is the first numeric element in the value. For example 10 in '10 ACH50'
        numeric_expr = pl.col(c).cast(pl.String).str.extract(r"(\d+(?:\.\d+)?)", 1).cast(pl.Float64)
        num_col = (
            pl.when(pl.col(c).cast(pl.String).str.starts_with("<"))
            .then(numeric_expr - 0.5)
            .when(pl.col(c).cast(pl.String).str.ends_with("+"))
            .then(numeric_expr + 0.5)
            .otherwise(numeric_expr)
            .fill_null(math.inf)
            .alias(num_col_name)
        )

        helpers.extend([rank_col, last_rank_col, num_col])
        sort_keys.extend([rank_col, last_rank_col, num_col, pl.col(c)])  # numeric, then lexicographic

    return df.with_columns(helpers).sort(sort_keys, maintain_order=True).drop([c.meta.output_name() for c in helpers])
