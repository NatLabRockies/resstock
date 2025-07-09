"""
Data processor module for standard plots
-----------------------------------------
Handles loading and processing of simulation result data using Polars
"""

import pathlib

import polars as pl

from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec, UpgradeInclusion, VacancyInclusion, VizType
from resstockpostproc.standard_plots.schema.plot_spec import ComparisonTypes
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup
from resstockpostproc.standard_plots.schema.end_use_dicts import EnduseGroupToEnduses
import logging

logger = logging.getLogger(__name__)


class DataProcessor:
    """
    Processes simulation result data for plotting
    """

    def __init__(self, annual_results_dir: str, upgrades: list[int]):
        """
        Initialize the data processor

        Args:
            annual_results_dir: Directory containing the simulation result CSV files
            upgrades: List of upgrade numbers to process
        """
        self.annual_results_dir = annual_results_dir
        self.upgrades = upgrades
        self.combined_df = self._load_data()
        self.all_cols: set[str] = set(self.combined_df.collect_schema().names())

    def _load_data(self) -> pl.LazyFrame:
        """Load data for each upgrade using Polars LazyFrames from CSV or Parquet files"""
        lazyframes: dict[int, pl.LazyFrame] = {}
        for upgrade in self.upgrades:
            base_patterns = [f"up{upgrade:02d}", f"upgrade{upgrade:02d}"]
            if upgrade == 0:
                base_patterns.append("baseline")

            # Use regex-like pattern matching to find files with the base pattern anywhere in the name
            matching_files: list[pathlib.Path] = []
            for pattern in base_patterns:
                for file_path in pathlib.Path(self.annual_results_dir).glob(f"**/*{pattern}*.csv") or []:
                    matching_files.append(file_path)
                for file_path in pathlib.Path(self.annual_results_dir).glob(f"**/*{pattern}*.parquet") or []:
                    matching_files.append(file_path)

            if not matching_files:
                print(f"Warning: No result file found for upgrade {upgrade}")
                continue

            if len(matching_files) > 1:
                raise ValueError(f"Multiple result files found for upgrade {upgrade}: {matching_files}")

            file_path = matching_files[0]
            lazyframes[upgrade] = pl.scan_csv(file_path) if file_path.suffix == ".csv" else pl.scan_parquet(file_path)

            if upgrade == 0:
                lazyframes[upgrade] = lazyframes[upgrade].with_columns(pl.lit("baseline").alias("upgrade_name"))
            elif "upgrade_name" not in lazyframes[upgrade].collect_schema().names():
                lazyframes[upgrade] = lazyframes[upgrade].with_columns(
                    pl.concat_str(pl.lit("Upgrade"), pl.col("upgrade").cast(pl.String)).alias("upgrade_name")
                )

            # ----- Data coercion -----------------------------------------------------------------
            # Convert the 'applicability' column to Boolean if it exists and is not already Boolean.
            # Can be removed after https://github.com/NREL/resstock/pull/1439 is merged.
            schema = lazyframes[upgrade].collect_schema()
            if "applicability" in schema and schema["applicability"] != pl.Boolean:
                truthy_values = ["true", "True", "1"]
                lazyframes[upgrade] = lazyframes[upgrade].with_columns(
                    pl.when(pl.col("applicability").is_in(truthy_values))
                    .then(True)
                    .otherwise(False)
                    .alias("applicability")
                    .cast(pl.Boolean)
                )
            # ------------------------------------------------------------------------------------

            print(f"Scanned data for upgrade {upgrade}")
        return pl.concat(lazyframes.values(), how="diagonal")

    def fill_missing_quantities(self, combined_df: pl.LazyFrame, quantities: list[str]) -> pl.LazyFrame:
        """
        Fills missing quantity columns in a LazyFrame. If a quantity can be
        calculated by summing existing columns, it does so. Otherwise, it fills
        the quantity with 0.
        """
        missing_quantity_cols: set[str] = set(quantities) - set(self.all_cols)

        if not missing_quantity_cols:
            return combined_df

        # They could be either be defined in EnduseGroupToEnduses or are truly missing
        defined_quantity = [quantity for quantity in missing_quantity_cols if quantity in EnduseGroupToEnduses]
        truly_missing_quantity = [quantity for quantity in missing_quantity_cols if quantity not in defined_quantity]
        new_column_exprs = []
        used_cols = []  # which of the cols in combined_df are used to calculate the missing quantity
        for quantity in defined_quantity:
            available_constituent_cols = [col for col in EnduseGroupToEnduses[quantity] if col in self.all_cols]
            if available_constituent_cols:
                expression = pl.sum_horizontal([pl.col(c) for c in available_constituent_cols]).alias(quantity)
                new_column_exprs.append(expression)
                used_cols.extend(available_constituent_cols)
            else:
                logger.warning(f"Quantity group {quantity} is defined but none of the constituent are available")
                expression = pl.lit(0, dtype=pl.Int32).alias(quantity)
                new_column_exprs.append(expression)
        # Since they are truly missing, we will fill them with 0
        for quantity in truly_missing_quantity:
            logger.warning(f"Quantity {quantity} is not available and is not a defined group in end_use_dict")
            expression = pl.lit(0, dtype=pl.Int32).alias(quantity)
            new_column_exprs.append(expression)

        return combined_df.with_columns(new_column_exprs)

    def prepare_data_for_plot(self, plot_spec: PlotSpec) -> pl.DataFrame:
        """
        Prepare data for plotting by grouping and aggregating using mean

        Args:
            plot_spec: PlotSpec object containing the plot configuration

        Returns:
            DataFrame prepared for plotting with aggregated (mean) values
        """
        quantities = []
        if isinstance(plot_spec.quantity, str):
            quantities.append(plot_spec.quantity)
        elif isinstance(plot_spec.quantity, QuantityGroup):
            quantities.extend(plot_spec.quantity.constituents)
            if plot_spec.quantity.sum:
                quantities.append(plot_spec.quantity.sum)

        combined_df = self.fill_missing_quantities(self.combined_df, quantities)

        if plot_spec.upgrade_inclusion == UpgradeInclusion.applied_only:
            combined_df = combined_df.filter(pl.col("applicability"))
        if plot_spec.vacancy_inclusion == VacancyInclusion.occupied_only:
            combined_df = combined_df.filter(pl.col("in.vacancy_status") == "Occupied")

        if plot_spec.visualization_type == VizType.box:
            assert isinstance(plot_spec.quantity, str)  # noqa: S101 Use of `assert` detected
            return self.prepare_data_for_box_plot(combined_df, plot_spec.quantity, plot_spec.group_by)
        elif plot_spec.visualization_type == VizType.bar:
            return self.prepare_data_for_bar_plot(
                combined_df, quantities, plot_spec.group_by, plot_spec.comparison_type
            )
        else:
            raise ValueError(f"Unsupported visualization type: {plot_spec.visualization_type}")

    def prepare_data_for_box_plot(self, combined_df: pl.LazyFrame, quantity: str, group_by: str | None) -> pl.DataFrame:
        """
        Prepare data for box plotting WITHOUT aggregation to preserve distribution

        Args:
            combined_df: Combined DataFrame containing all data
            quantity: List of quantities to plot
            group_by: List of columns to group by

        Returns:
            DataFrame prepared for box plotting with all individual data points preserved
        """
        group_by_cols = ["upgrade", "upgrade_name"]
        if group_by:
            group_by_cols.append(group_by)
        columns_to_select = [*group_by_cols, quantity]
        data = combined_df.select(columns_to_select).sort(group_by_cols)

        data = data.group_by(group_by_cols).agg(
            pl.col(quantity).quantile(0.25).alias("q1"),
            pl.col(quantity).median().alias("median"),
            pl.col(quantity).quantile(0.75).alias("q3"),
            pl.col(quantity).min().alias("lowerfence"),
            pl.col(quantity).max().alias("upperfence"),
            pl.col(quantity).count().alias("n_points"),
        )
        return data.collect()

    def prepare_data_for_bar_plot(
        self, combined_df: pl.LazyFrame, quantities: list[str], group_by: str | None, comparison_type: ComparisonTypes
    ) -> pl.DataFrame:
        """
        Prepare data for bar plotting by grouping and aggregating

        Args:
            combined_df: Combined DataFrame containing all data
            quantities: List of quantities to plot
            group_by: Column to group by

        Returns:
            DataFrame prepared for plotting with all requested quantities
        """

        grouping_cols = ["upgrade", "upgrade_name"]
        if group_by:
            grouping_cols.append(group_by)
        columns_to_select = grouping_cols + quantities
        filtered_df = combined_df.select(columns_to_select)

        if comparison_type == ComparisonTypes.mean:
            agg_exprs = [pl.col(quantity).mean().alias(quantity) for quantity in quantities]
        else:
            agg_exprs = [pl.col(quantity).sum().alias(quantity) for quantity in quantities]
        result = filtered_df.group_by(grouping_cols).agg(agg_exprs).sort(grouping_cols)

        return result.collect()
