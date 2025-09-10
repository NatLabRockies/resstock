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
import math
from scipy.stats import gaussian_kde
import numpy as np

import boto3
import polars as pl
import s3fs  # type: ignore[import-untyped]
from botocore.config import Config
from prefect import flow, task
from prefect.futures import wait
from prefect.task_runners import ConcurrentTaskRunner

from resstockpostproc.standard_plots.schema.end_use_dicts import EnduseGroupToEnduses
from resstockpostproc.standard_plots.schema.plot_spec import (
    QuantityType,
    PlotSpec,
    BuildingInclusion,
    VacancyInclusion,
    VizType,
)
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, AggregationType, WorkflowConfig
from resstockpostproc.standard_plots.utils import human_sort

logger = logging.getLogger(__name__)
s3_client = boto3.client("s3", config=Config(read_timeout=60 * 60, max_pool_connections=50))
MIN_BASELINE = 1e-6  # used in denominator of percent savings calculation to avoid division by zero


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
                lazyframes[upgrade] = pl.scan_parquet(file, glob=False)
            else:
                lazyframes[upgrade] = pl.scan_parquet(
                    f"s3://{file}",
                    storage_options={"endpoint_url": minio_endpoint, "skip_signature": "true"},
                    glob=False,
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

    def convert_quantity_type(
        self, combined_df: pl.LazyFrame, quantities: list[str], quantity_type: QuantityType
    ) -> pl.LazyFrame:
        """Convert the values in ``combined_df`` according to the desired quantity type.

        Args:
            combined_df: LazyFrame containing all upgrades (including baseline with ``upgrade == 0``)
            quantities: List of quantity columns that should be transformed.
            quantity_type: Whether to convert to *absolute* values or *savings* (baseline - value).

        Returns
        -------
        pl.LazyFrame
            A LazyFrame where the requested ``quantities`` columns have been transformed as requested.
        """
        if quantity_type in [QuantityType.absolute, QuantityType.model_count]:
            # No transformation required
            return combined_df

        if quantity_type in [QuantityType.savings, QuantityType.percent_savings]:
            join_key = "bldg_id"
            if join_key not in combined_df.collect_schema().names():
                raise ValueError(f"'{join_key}' column not found in data - cannot compute savings per building.")
            baseline_cols = [join_key, *quantities]
            baseline_df = (
                combined_df.filter(pl.col("upgrade") == 0)
                .select(baseline_cols)
                .rename({q: f"baseline_{q}" for q in quantities})
            )

            # 2. Join the baseline values back to the full dataset on `building_id`.
            df_with_baseline = combined_df.join(baseline_df, on=join_key, how="left", validate="m:1")

            # 3. Replace the quantity columns with the calculated savings.
            savings_exprs = [(pl.col(f"baseline_{q}") - pl.col(q)).alias(q) for q in quantities]
            result = df_with_baseline.with_columns(savings_exprs)
            if quantity_type == QuantityType.savings:
                result = result.drop([f"baseline_{q}" for q in quantities])  # Clean-up helper columns
                return result
            # percent savings
            percent_savings_exprs = [
                (
                    100
                    * pl.col(q)
                    / pl.when(pl.col(f"baseline_{q}").abs() < MIN_BASELINE)
                    .then(
                        pl.when(pl.col(f"baseline_{q}").sign() == 0)
                        .then(MIN_BASELINE)
                        .otherwise(pl.col(f"baseline_{q}").sign() * MIN_BASELINE)
                    )
                    .otherwise(pl.col(f"baseline_{q}"))
                ).alias(q)
                for q in quantities
            ]
            # Keep the baseline values for the percent savings so they can be used for weighted average
            result = result.with_columns(percent_savings_exprs)
            return result
        raise ValueError(f"Unsupported quantity type: {quantity_type}")

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
        combined_df = self.convert_quantity_type(combined_df, quantities, plot_spec.quantity_type)

        if plot_spec.upgrade is not None:
            combined_df = combined_df.filter(pl.col("upgrade").is_in([0, plot_spec.upgrade]))

        if plot_spec.building_inclusion == BuildingInclusion.applied_only:
            if plot_spec.upgrade is None:  # Applied in respective upgrades (No Baseline)
                combined_df = combined_df.filter(pl.col("applicability") & (pl.col("upgrade") != 0))
            else:  # Applied in a specific upgrade including baseline filtered to applicable buildings in that upgrade
                is_upgrade_applicable = (
                    ((pl.col("upgrade") == plot_spec.upgrade) & pl.col("applicability")).any().over("bldg_id")
                )
                combined_df = combined_df.filter(
                    ((pl.col("upgrade") == plot_spec.upgrade) & pl.col("applicability"))
                    | ((pl.col("upgrade") == 0) & is_upgrade_applicable)
                )

        if plot_spec.vacancy_inclusion == VacancyInclusion.occupied_only:
            combined_df = combined_df.filter(pl.col("in.vacancy_status") == "Occupied")

        if plot_spec.quantity_type in [QuantityType.savings, QuantityType.percent_savings]:
            # remove baseline for savings calculation
            combined_df = combined_df.filter(pl.col("upgrade") != 0)

        if plot_spec.visualization_type == VizType.box:
            if not isinstance(plot_spec.quantity, str):
                combined_df = combined_df.unpivot(
                    quantities,
                    index=["upgrade", "upgrade_name", "bldg_id"],
                    variable_name="End Use",
                    value_name="value (kWh)",
                )
                quantity = "value (kWh)"
                group_by: str | None = "End Use"
            else:
                quantity = plot_spec.quantity
                group_by = plot_spec.group_by
            plot_data = self.prepare_data_for_box_plot(combined_df, quantity, group_by)
        elif plot_spec.visualization_type in (VizType.bar, VizType.heatmap):
            plot_data = self.prepare_data_for_bar_plot(
                combined_df, quantities, plot_spec.group_by, plot_spec.aggregation_type, plot_spec.quantity_type
            )
        elif plot_spec.visualization_type == VizType.hist:
            assert isinstance(plot_spec.quantity, str)  # noqa: S101 Use of `assert` detected
            plot_data = self.prepare_data_for_histogram_plot(combined_df, plot_spec.quantity, plot_spec.group_by)
        else:
            raise ValueError(f"Unsupported visualization type: {plot_spec.visualization_type}")

        if plot_spec.group_by:
            plot_data = human_sort(plot_data.lazy(), plot_spec.group_by).collect()

        return plot_data

    def prepare_data_for_histogram_plot(
        self,
        combined_df: pl.LazyFrame,
        quantity: str,
        group_by: str | None = None,
    ) -> pl.DataFrame:
        """
        Build a 102-bin histogram of `quantity` per (upgrade, upgrade_name[, group_by]).
        Every bin (-1, 0-99, 100) is present; empty bins have count == 0.
        """

        # ---------- 1. Percentile bounds ----------
        q1, q99 = (
            combined_df.select(
                pl.col(quantity).quantile(0.01, "midpoint").alias("q1"),
                pl.col(quantity).quantile(0.99, "midpoint").alias("q99"),
            )
            .collect()
            .row(0)
        )
        minimum, maximum = (
            combined_df.select(pl.col(quantity).min().alias("minimum"), pl.col(quantity).max().alias("maximum"))
            .collect()
            .row(0)
        )
        if q1 == q99:
            q1, q99 = minimum, maximum

        is_degenerate = math.isclose(q1, q99, rel_tol=1e-9, abs_tol=1e-12)
        bin_width = 1.0 if is_degenerate else (q99 - q1) / 100.0

        # ---------- 2. Bin assignment ----------
        if is_degenerate:
            # avoid divide-by-zero while keeping the same control-flow
            bin_expr = (
                pl.when(pl.col(quantity) < q1)
                .then(-1)
                .when(pl.col(quantity) > q1)
                .then(100)
                .otherwise(0)  # everything equal to q1 ends up here
                .alias("bin")
            )
        else:
            bin_expr = (
                pl.when(pl.col(quantity) < q1)
                .then(-1)
                .when(pl.col(quantity) > q99)
                .then(100)
                .otherwise(((pl.col(quantity) - q1 - 1e-9) / bin_width).floor())
                .cast(pl.Int32)
                .alias("bin")
            )

        lf_binned = combined_df.with_columns(bin_expr)

        # ---------- 3. Aggregate real counts ----------
        group_keys = ["upgrade", "upgrade_name", group_by, "bin"] if group_by else ["upgrade", "upgrade_name", "bin"]
        counts = lf_binned.group_by(group_keys, maintain_order=True).agg(pl.count().alias("count"))

        # ---------- 4. Build full grid ----------
        full_bins = pl.Series("bin", [-1, *list(range(100)), 100], dtype=pl.Int32)

        groups = combined_df.select("upgrade", "upgrade_name", *(group_by,) if group_by else ()).unique(
            maintain_order=True
        )

        grid = groups.lazy().join(pl.DataFrame({"bin": full_bins}).lazy(), how="cross")

        # ---------- 5. Merge counts → zerofill ----------
        hist_full = (
            grid.join(counts.lazy(), on=group_keys, how="left")
            .with_columns(pl.col("count").fill_null(0).cast(pl.UInt32))
            # ---------- 6. Bin boundaries ----------
            .with_columns(
                # left edge
                pl.when(pl.col("bin") == -1)
                .then(minimum)
                .when(pl.col("bin") == 100)  # noqa: PLR2004
                .then(q99)
                .otherwise(q1 + pl.col("bin") * bin_width)
                .alias("bin_left"),
                # right edge
                pl.when(pl.col("bin") == -1)
                .then(q1)
                .when(pl.col("bin") == 100)  # noqa: PLR2004
                .then(maximum)
                .otherwise(q1 + (pl.col("bin") + 1) * bin_width)
                .alias("bin_right"),
            )
            .with_columns(((pl.col("bin_left") + pl.col("bin_right")) / 2).alias("bin_center"))
            .select(
                "upgrade",
                "upgrade_name",
                *(group_by,) if group_by else (),
                "bin",
                "bin_left",
                "bin_right",
                "count",
            )
            .collect()
        )

        return hist_full

    def prepare_data_for_box_plot(
        self,
        combined_df: pl.LazyFrame,
        quantity: str,
        group_by: str | None = None,
        *,
        include_kde: bool = True,
        kde_points: int = 100,
    ) -> pl.DataFrame:
        """
        Return one row per group with:
            q1, median, q3, mean, n_points,
            lower_whisker, upper_whisker, outliers [list]
        +   kde_x / kde_y                (only when include_kde=True)

        All cheap stats stay in Polars.  SciPy's gaussian_kde is called
        *per group* only when include_kde=True.
        """
        # ─── 1. keys ──────────────────────────────────────────────────────────────
        gcols = ["upgrade", "upgrade_name"]
        if group_by:
            gcols.append(group_by)

        lazy = (
            combined_df.fill_null(0)
            .group_by(gcols, maintain_order=True)
            .agg(
                pl.col(quantity).alias("vals"),
                pl.col("bldg_id").alias("bldg_ids"),
                pl.col(quantity).min().alias("min"),
                pl.col(quantity).quantile(0.01).alias("lower_cutoff"),
                pl.col(quantity).quantile(0.25).alias("q1"),
                pl.col(quantity).median().alias("median"),
                pl.col(quantity).quantile(0.75).alias("q3"),
                pl.col(quantity).quantile(0.99).alias("upper_cutoff"),
                pl.col(quantity).max().alias("max"),
                pl.col(quantity).mean().alias("mean"),
                pl.count().alias("n_points"),
            )
            .with_columns(
                (iqr_col := (pl.col("q3") - pl.col("q1")).alias("iqr")),
                (pl.col("q1") - 1.5 * iqr_col).alias("lower_fence"),
                (pl.col("q3") + 1.5 * iqr_col).alias("upper_fence"),
            )
            .with_columns(
                [
                    pl.struct(["vals", "lower_fence"])
                    .map_elements(
                        lambda s: float(min((v for v in s["vals"] if v >= s["lower_fence"]), default=np.nan)),
                        return_dtype=pl.Float64,
                    )
                    .alias("lower_whisker"),
                    pl.struct(["vals", "upper_fence"])
                    .map_elements(
                        lambda s: float(max((v for v in s["vals"] if v <= s["upper_fence"]), default=np.nan)),
                        return_dtype=pl.Float64,
                    )
                    .alias("upper_whisker"),
                ]
            )
            .with_columns(
                pl.struct(["vals", "lower_cutoff", "upper_cutoff"])
                .map_elements(
                    lambda s: [v for v in s["vals"] if (v < s["lower_cutoff"]) or (v > s["upper_cutoff"])],
                    return_dtype=pl.List(pl.Float64),
                )
                .alias("outliers"),
            )
            .with_columns(
                pl.struct(["vals", "bldg_ids", "lower_cutoff", "upper_cutoff"])
                .map_elements(
                    lambda s: [
                        b
                        for v, b in zip(s["vals"], s["bldg_ids"])
                        if (v < s["lower_cutoff"]) or (v > s["upper_cutoff"])
                    ],
                    return_dtype=pl.List(pl.Int32),
                )
                .alias("outlier_buildings"),
            )
            .drop(["iqr", "lower_fence", "upper_fence"])
        )

        df = lazy.collect()

        # ─── 3. optional KDE step ─────────────────────────────────────────────────
        if include_kde:
            kde_x_all, kde_y_all = [], []  # will append in group order

            for i, vals in enumerate(df["vals"]):
                arr = np.asarray(vals)
                lower_cutoff = df["lower_cutoff"][i]
                upper_cutoff = df["upper_cutoff"][i]

                if len(arr) < 2 or np.isclose(arr.max(), arr.min()):  # noqa: PLR2004
                    # degenerate group
                    xs = np.array([arr.min()])
                    ys = np.array([1.0])
                else:
                    # Filter data between fences for KDE calculation
                    filtered_arr = arr[(arr > lower_cutoff) & (arr < upper_cutoff)]
                    # filtered_arr = arr
                    if len(filtered_arr) < 2:  # noqa: PLR2004
                        # If not enough points after filtering, use a single point
                        xs = np.array([np.mean(filtered_arr) if len(filtered_arr) > 0 else arr.mean()])
                        ys = np.array([1.0])
                    else:
                        try:
                            kde = gaussian_kde(filtered_arr)
                            xs = np.linspace(filtered_arr.min(), filtered_arr.max(), kde_points)
                            ys = kde(xs)
                        except np.linalg.LinAlgError:
                            xs = np.linspace(filtered_arr.min(), filtered_arr.max(), kde_points)
                            ys = np.array([1.0])

                kde_x_all.append(xs.tolist())
                kde_y_all.append(ys.tolist())

            df = df.with_columns(
                pl.Series("kde_x", kde_x_all, dtype=pl.List(pl.Float64)),
                pl.Series("kde_y", kde_y_all, dtype=pl.List(pl.Float64)),
            )

        # ─── 4. final tidy ────────────────────────────────────────────────────────
        return df.drop(["vals", "bldg_ids"]).with_columns(  # raw vectors no longer needed
            [
                pl.col("lower_whisker").cast(pl.Float64),
                pl.col("upper_whisker").cast(pl.Float64),
            ]
        )

    def prepare_data_for_bar_plot(
        self,
        combined_df: pl.LazyFrame,
        quantities: list[str],
        group_by: str | None,
        aggregation_type: AggregationType,
        quantity_type: QuantityType,
    ) -> pl.DataFrame:
        """
        Prepare data for bar plotting by grouping and aggregating

        Args:
            combined_df: Combined DataFrame containing all data
            quantities: List of quantities to plot
            group_by: Column to group by
            aggregation_type: Whether to calculate average or sum
            quantity_type: Whether to calculate absolute or savings

        Returns:
            DataFrame prepared for plotting with all requested quantities
        """

        grouping_cols = ["upgrade", "upgrade_name"]
        if group_by:
            grouping_cols.append(group_by)
        columns_to_select = grouping_cols + quantities + ["model_count"]

        if quantity_type == QuantityType.model_count:
            agg_exprs = [pl.col(quantity).count().alias(quantity) for quantity in quantities]
        elif aggregation_type == AggregationType.average and quantity_type == QuantityType.percent_savings:
            # Calculate weighted average of percent savings using baseline values as weights
            # weighted_average = (sum(savings * baseline)) / (non_zero(sum(baseline)))
            # where non_zero ensures that denominator is at least MIN_BASELINE
            agg_exprs = [
                (
                    (pl.col(quantity) * pl.col(f"baseline_{quantity}")).sum()
                    / pl.when(pl.col(f"baseline_{quantity}").sum().abs() < MIN_BASELINE)
                    .then(
                        pl.when(pl.col(f"baseline_{quantity}").sum().sign() == 0)
                        .then(MIN_BASELINE)
                        .otherwise(pl.col(f"baseline_{quantity}").sum().sign() * MIN_BASELINE)
                    )
                    .otherwise(pl.col(f"baseline_{quantity}").sum())
                ).alias(quantity)
                for quantity in quantities
            ]
        elif aggregation_type == AggregationType.total and quantity_type == QuantityType.percent_savings:
            raise ValueError("Percent savings can only be aggregated as weighted average")
        elif aggregation_type == AggregationType.average:
            agg_exprs = [pl.col(quantity).mean().alias(quantity) for quantity in quantities]
        elif aggregation_type == AggregationType.total:
            agg_exprs = [(pl.col(quantity) * pl.col("weight")).sum().alias(quantity) for quantity in quantities]
        else:
            raise ValueError(f"Unsupported value type: {aggregation_type}")
        agg_exprs.append(pl.col("bldg_id").count().alias("model_count"))
        result = combined_df.group_by(grouping_cols, maintain_order=True).agg(agg_exprs)
        result = result.select(columns_to_select)
        return result.collect()
