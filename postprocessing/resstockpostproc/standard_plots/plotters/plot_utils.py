"""Common plotting utilities shared across standard plot modules."""

from __future__ import annotations

import polars as pl
from typing import overload

from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec, QuantityGroup, QuantityType


@overload
def format_label(label: None) -> None: ...


@overload
def format_label(label: str) -> str: ...


def format_label(label: str | None) -> str | None:
    """Return a human-readable label for an input or output column name."""
    if label is None:
        return None
    if label.startswith("out.") and "." in label:
        label = ".".join(label.split(".")[:-1])
    return label.removeprefix("in.").removeprefix("out.").replace("_", " ").replace(".", " ").title()


def ensure_columns_exist(df: pl.DataFrame, cols: list[str]) -> pl.DataFrame:
    """Ensure each column in *cols* exists in *df*, creating zero-filled columns when missing."""
    for col in cols:
        if col not in df.columns:
            df = df.with_columns(pl.lit(0).alias(col))
    return df


def get_quantity_name(quantity: str | QuantityGroup) -> str:
    """Return a formatted quantity name appropriate for labelling."""
    if isinstance(quantity, QuantityGroup):
        return format_label(quantity.name)
    if quantity == "bldg_id":
        return "Number of Models"
    return format_label(quantity)


def get_quantity_unit(quantity: str | QuantityGroup, quantity_type: QuantityType | None = None) -> str:
    """Return the unit suffix for the given quantity and type."""
    if quantity_type == QuantityType.model_count:
        return ""
    elif quantity_type == QuantityType.prevalence:
        return " (%)"
    elif quantity_type == QuantityType.percent_savings:
        return ""

    if isinstance(quantity, QuantityGroup):
        constituents = QuantityGroup.resolve_quantities(quantity.constituents)
        unit = constituents[0].split(".")[-1]
    else:
        unit = quantity.split(".")[-1]

    return f" ({unit})" if unit else ""


def get_quantity_type_suffix(quantity_type: QuantityType) -> str:
    """Return the type suffix for the given quantity type."""
    if quantity_type == QuantityType.prevalence:
        return " Prevalence"
    elif quantity_type == QuantityType.percent_savings:
        return " Percentage Savings"
    elif quantity_type == QuantityType.savings:
        return " Savings"
    else:
        return ""


def get_quantity_title(plot_spec: PlotSpec) -> str:
    """Return the y-axis title for the given plot specification."""
    name = get_quantity_name(plot_spec.quantity)
    type_suffix = get_quantity_type_suffix(plot_spec.quantity_type)
    unit_suffix = get_quantity_unit(plot_spec.quantity, plot_spec.quantity_type)
    return f"{name}{type_suffix}{unit_suffix}"
