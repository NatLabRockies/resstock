"""Common abstract base class for all plotters.

Provides shared helpers (column guards, etc.) so concrete plotters do not have to duplicate boilerplate.
"""

from abc import ABC

import polars as pl
from plotly.graph_objects import Figure
from typing import overload

from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec, QuantityGroup, QuantityType


class BasePlotter(ABC):
    """Abstract base plotter - every concrete plotter inherits this."""
    # ------------------------------------------------------------------
    # Shared helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _ensure_columns_exist(df: pl.DataFrame, cols: list[str]) -> pl.DataFrame:
        """Ensure *cols* are present in *df* (add with zeros if missing)."""
        for col in cols:
            if col not in df.columns:
                df = df.with_columns(pl.lit(0).alias(col))
        return df

    # ------------------------------------------------------------------
    # Mandatory interface
    # ------------------------------------------------------------------
    def create_plot(self, data: pl.DataFrame, plot_spec: PlotSpec) -> Figure:
        """Placeholder fallback; subclasses typically override for convenience."""
        raise NotImplementedError("Subclasses should implement `create_plot` or use specific helpers.")

    def get_quantity_unit(self, quantity: str | QuantityGroup):
        if isinstance(quantity, QuantityGroup):
            constituents = QuantityGroup.resolve_quantities(quantity.constituents)
            return constituents[0].split(".")[-1]
        return quantity.split(".")[-1]

    def get_quantity_name(self, quantity: str | QuantityGroup) -> str:
        if isinstance(quantity, QuantityGroup):
            return self.format_label(quantity.name)
        if quantity == "bldg_id":
            return "Number of Models"
        return self.format_label(quantity)

    @overload
    def format_label(self, label: None) -> None: ...

    @overload
    def format_label(self, label: str) -> str: ...

    def format_label(self, label: str | None) -> str | None:
        """Cleans up a column name to be a human-readable label."""
        if label is None:
            return None
        if "." in label and label.startswith("out."):  # the last portion is unit - remove it
            label = ".".join(label.split(".")[:-1])
        label = (label.removeprefix("in.").removeprefix("out.").replace("_", " ").replace(".", " ")).title()
        return label

    def get_quantity_title(self, plot_spec: PlotSpec) -> str:
        """Get the y-axis title based on the plot spec."""
        type_suffix, unit_suffix = "", ""
        if plot_spec.quantity_type == QuantityType.model_count:
            type_suffix = ""
            unit_suffix = ""
        elif plot_spec.quantity_type == QuantityType.prevalence:
            type_suffix = " Prevalence"
            unit_suffix = " (%)"
        elif plot_spec.quantity_type == QuantityType.percent_savings:
            type_suffix = " Percentage Savings"
            unit_suffix = ""
        elif plot_spec.quantity_type == QuantityType.savings:
            type_suffix = " Savings"
            unit_suffix = f" ({self.get_quantity_unit(plot_spec.quantity)})"
        else:
            type_suffix = ""
            unit_suffix = f" ({self.get_quantity_unit(plot_spec.quantity)})"
        name = self.get_quantity_name(plot_spec.quantity)
        return f"{name}{type_suffix}{unit_suffix}"
