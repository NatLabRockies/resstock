"""
Data processor module for standard plots
-----------------------------------------
Handles loading and processing of simulation result data using Polars
"""
import polars as pl
import os
from typing import Dict, List, Optional, Any
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec, VizType, ComparisonTypes
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup


class DataProcessor:
    """
    Processes simulation result data for plotting
    """
    def __init__(self, results_dir: str, upgrades: List[int]):
        """
        Initialize the data processor
        
        Args:
            results_dir: Directory containing the simulation result CSV files
            upgrades: List of upgrade numbers to process
        """
        self.results_dir = results_dir
        self.upgrades = upgrades
        self.lazyframes: Dict[int, pl.LazyFrame] = {}
        self._load_data()
        
    def _load_data(self) -> None:
        """Load data for each upgrade using Polars LazyFrames from CSV or Parquet files"""
        for upgrade in self.upgrades:
            patterns = [f"results_up{upgrade:02d}", f"up{upgrade:02d}", f"upgrade{upgrade:02d}"]
            if upgrade == 0:
                patterns.append("baseline")
            
            possible_paths = [os.path.join(self.results_dir, f"{pattern}{ext}") 
                             for pattern in patterns
                             for ext in ['.csv', '.parquet']]
            file_path = next((path for path in possible_paths if os.path.exists(path)), None)
            
            if file_path is None:
                print(f"Warning: No result file found for upgrade {upgrade}")
                continue

            self.lazyframes[upgrade] = (
                pl.scan_csv(file_path) if file_path.endswith('.csv') 
                else pl.scan_parquet(file_path)
            )
            
            if upgrade == 0:
                self.lazyframes[upgrade] = self.lazyframes[upgrade].with_columns(
                    pl.lit("baseline").alias("upgrade_name")
                )
    
    def prepare_data_for_plot(self, plot_spec: PlotSpec) -> pl.DataFrame:
        """
        Prepare data for plotting by grouping and aggregating using mean
        
        Args:
            plot_spec: PlotSpec object containing the plot configuration
            
        Returns:
            DataFrame prepared for plotting with aggregated (mean) values
        """        
        combined_df = pl.concat(self.lazyframes.values(), how="diagonal")
        all_cols = combined_df.collect_schema().names()
        quantities = []
        if isinstance(plot_spec.quantity, str):
            quantities.append(plot_spec.quantity)
        elif isinstance(plot_spec.quantity, QuantityGroup):
            quantities.extend(plot_spec.quantity.constituents)
            if plot_spec.quantity.sum:
                quantities.append(plot_spec.quantity.sum)

        if missing_quantity_cols:= set(quantities) - set(all_cols):
            combined_df = combined_df.with_columns(
                pl.lit(0).alias(quantity) for quantity in missing_quantity_cols
            )
    
        if plot_spec.visualization_type == VizType.box:
            assert isinstance(plot_spec.quantity, str)
            return self.prepare_data_for_box_plot(combined_df, plot_spec.quantity, plot_spec.group_by)
        elif plot_spec.visualization_type == VizType.bar:
            return self.prepare_data_for_bar_plot(combined_df, quantities, plot_spec.group_by)
        else:
            raise ValueError(f"Unsupported visualization type: {plot_spec.visualization_type}")
        
    def prepare_data_for_box_plot(self, combined_df: pl.LazyFrame, quantity: str, group_by: str | None) -> pl.DataFrame:
        """
        Prepare data for box plotting WITHOUT aggregation to preserve distribution
        
        Args:
            combined_df: Combined DataFrame containing all data
            quantities: List of quantities to plot
            group_by: List of columns to group by
            
        Returns:
            DataFrame prepared for box plotting with all individual data points preserved
        """        
        group_by_cols = ["upgrade", "upgrade_name"]
        if group_by:
            group_by_cols.append(group_by)
        columns_to_select = group_by_cols + [quantity]
        data = (combined_df
                .select(columns_to_select)
                .sort(group_by_cols))
        
        data = (
            data.group_by(group_by_cols)
            .agg(
                pl.col(quantity).quantile(0.25).alias("q1"),
                pl.col(quantity).median().alias("median"),
                pl.col(quantity).quantile(0.75).alias("q3"),
                pl.col(quantity).min().alias("lowerfence"),
                pl.col(quantity).max().alias("upperfence"),
                pl.col(quantity).count().alias("n_points"),
            )
        )
        return data.collect()
        
    def prepare_data_for_bar_plot(self, combined_df: pl.LazyFrame, quantities: List[str], group_by: str | None) -> pl.DataFrame:
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
        
        agg_exprs = [pl.col(quantity).mean().alias(quantity) for quantity in quantities]
        result = (filtered_df
                  .group_by(grouping_cols)
                  .agg(agg_exprs)
                  .sort(grouping_cols))
        
        return result.collect()