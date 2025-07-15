"""
Data processor module for standard plots
-----------------------------------------
Handles loading and processing of simulation result data using Polars
"""

import logging
import os
import pathlib
import time
from pathlib import Path

import boto3
import polars as pl
import s3fs  # type: ignore[import-untyped]
from botocore.config import Config
from prefect import flow, task
from prefect.futures import wait
from prefect.task_runners import ConcurrentTaskRunner
from resstockpostproc.standard_plots.schema.end_use_dicts import EnduseGroupToEnduses
from resstockpostproc.standard_plots.schema.plot_spec import (
    PlotSpec,
    UpgradeInclusion,
    VacancyInclusion,
    VizType,
)
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, ValueTypes, WorkflowConfig

logger = logging.getLogger(__name__)
s3_client = boto3.client("s3", config=Config(read_timeout=60 * 60, max_pool_connections=50))


class DataProcessor:
    """
    Processes simulation result data for plotting
    """

    def __init__(self, workflow: WorkflowConfig):
        """
        Initialize the data processor

        Args:
            workflow: WorkflowConfig object containing the workflow configuration
        """
        self.workflow = workflow
        self.local_results_dir = self.get_local_results_dir(workflow)
        self.upgrades = workflow.upgrades
        self.upgrade_names = workflow.upgrade_names
        if workflow.storage_backend == "filesystem":
            # These steps are already complete in the case of using MinIO
            available_upgrades = self.get_available_upgrades(workflow)
            if missing_upgrades := set(workflow.upgrades) - set(available_upgrades):
                self.download_data(workflow, sorted(missing_upgrades))
            else:
                print("All upgrades are available, skipping download")
        self.combined_df = self.load_data()
        self.all_cols = set(self.combined_df.collect_schema().names())

    @staticmethod
    def get_available_upgrades(workflow: WorkflowConfig) -> list[int]:
        local_results_dir = DataProcessor.get_local_results_dir(workflow)
        local_files = [str(file) for file in pathlib.Path(local_results_dir).glob("**/*.parquet")]
        upgrade_to_file = DataProcessor.filter_upgrade_files(workflow, local_files)
        return list(upgrade_to_file.keys())

    @staticmethod
    def filter_upgrade_files(workflow: WorkflowConfig, all_files: list[str]) -> dict[int, str]:
        # Filter all_files to only include files that match the upgrade patterns
        upgrade_to_file: dict[int, str] = {}
        for upgrade in workflow.upgrades:
            base_patterns = [
                f"up{upgrade:02d}",
                f"upgrade{upgrade:02d}",
                f"results_up{upgrade:02d}",
                f"results_upgrade{upgrade:02d}",
                f"upgrade{upgrade:02d}_metadata_and_annual_results",
            ]
            if upgrade == 0:
                base_patterns.extend(["baseline", "results_baseline", "baseline_metadata_and_annual_results"])
            matching_files = []
            for pattern in base_patterns:
                matches = [file for file in all_files if os.path.basename(file) == f"{pattern}.parquet"]
                if matches:
                    matching_files.append((pattern, matches[0]))
            if len(matching_files) > 1:
                raise ValueError(f"Multiple files ({matching_files}) found for upgrade {upgrade}")
            if not matching_files:
                continue
            upgrade_to_file[upgrade] = matching_files[0][1]
        return upgrade_to_file

    @staticmethod
    def get_local_results_dir(workflow: WorkflowConfig) -> Path:
        return Path(workflow.output_dir) / "s3_data" / workflow.s3_results_dir.removeprefix("s3://")

    @staticmethod
    @task(retries=3, retry_delay_seconds=1)
    def download_file(bucket: str, key: str, local_file: str) -> str:
        s3_client.download_file(Bucket=bucket, Key=key, Filename=local_file)
        print(f"Downloaded {key} to {local_file}")
        return local_file

    @staticmethod
    @flow(
        timeout_seconds=60 * 60,
        task_runner=ConcurrentTaskRunner(max_workers=5),  # type: ignore
        log_prints=True,
    )
    def download_data(workflow: WorkflowConfig, missing_upgrades: list[int]):
        # download the files from s3_results_dir to local_results_dir using boto3
        s3_results_dir = workflow.s3_results_dir
        bucket = s3_results_dir.removeprefix("s3://").split("/")[0]
        s3_prefix = "/".join(s3_results_dir.removeprefix("s3://").split("/")[1:])
        local_results_dir = DataProcessor.get_local_results_dir(workflow)
        response = s3_client.list_objects_v2(Bucket=bucket, Prefix=s3_prefix)
        all_files = [obj["Key"] for obj in response["Contents"]]
        upgrade_to_file = DataProcessor.filter_upgrade_files(workflow, all_files)
        local_results_dir.mkdir(parents=True, exist_ok=True)
        start_time = time.time()
        print(f"Downloading {len(upgrade_to_file)} files to {local_results_dir}")
        downloaded_files = []
        for upgrade in missing_upgrades:
            file = upgrade_to_file[upgrade]
            local_file = local_results_dir / os.path.basename(file)
            local_path = local_file.parent
            local_path.mkdir(parents=True, exist_ok=True)
            print(f"Downloading {file} for upgrade {upgrade} to {local_file}")
            downloaded_files.append(DataProcessor.download_file.submit(bucket, file, str(local_file)))
        wait(downloaded_files)
        print(f"Downloaded {len(upgrade_to_file)} files in {time.time() - start_time:.2f} seconds")

    def load_data(self) -> pl.LazyFrame:
        """Load data for each upgrade using Polars LazyFrames from Parquet files"""
        lazyframes: dict[int, pl.LazyFrame] = {}
        minio_endpoint = "http://minio:10000"

        if self.workflow.storage_backend == "filesystem":
            all_files = [str(file) for file in pathlib.Path(self.local_results_dir).glob("**/*.parquet")]
        else:
            fs = s3fs.S3FileSystem(anon=True, client_kwargs={"endpoint_url": minio_endpoint})
            all_files = [
                f
                for f in fs.find(self.workflow.s3_results_dir.removeprefix("s3://"), withdirs=False)
                if f.endswith(".parquet")
            ]

        upgrade_to_file = self.filter_upgrade_files(self.workflow, all_files)
        upgrade_to_name = dict(zip(self.workflow.upgrades, self.workflow.upgrade_names))
        for upgrade, file in upgrade_to_file.items():
            if self.workflow.storage_backend == "filesystem":
                lazyframes[upgrade] = pl.scan_parquet(file)
            else:
                lazyframes[upgrade] = pl.scan_parquet(
                    f"s3://{file}",
                    storage_options={"endpoint_url": minio_endpoint, "skip_signature": "true"},
                )
            upgrade_name = upgrade_to_name[upgrade]
            lazyframes[upgrade] = lazyframes[upgrade].with_columns(pl.lit(upgrade_name).alias("upgrade_name"))
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

        if not lazyframes:
            raise ValueError(f"No data found in {self.local_results_dir}. Make sure the s3_results_dir is synced.")
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
            return self.prepare_data_for_bar_plot(combined_df, quantities, plot_spec.group_by, plot_spec.value_type)
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
        self, combined_df: pl.LazyFrame, quantities: list[str], group_by: str | None, value_type: ValueTypes
    ) -> pl.DataFrame:
        """
        Prepare data for bar plotting by grouping and aggregating

        Args:
            combined_df: Combined DataFrame containing all data
            quantities: List of quantities to plot
            group_by: Column to group by
            value_type: Whether to calculate average or sum

        Returns:
            DataFrame prepared for plotting with all requested quantities
        """

        grouping_cols = ["upgrade", "upgrade_name"]
        if group_by:
            grouping_cols.append(group_by)
        columns_to_select = grouping_cols + quantities
        filtered_df = combined_df.select(columns_to_select)

        if value_type == ValueTypes.average:
            agg_exprs = [pl.col(quantity).mean().alias(quantity) for quantity in quantities]
        else:
            agg_exprs = [pl.col(quantity).sum().alias(quantity) for quantity in quantities]
        result = filtered_df.group_by(grouping_cols).agg(agg_exprs).sort(grouping_cols)

        return result.collect()
