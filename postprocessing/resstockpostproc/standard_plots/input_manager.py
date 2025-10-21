"""
Input manager module for standard plots
----------------------------------------
Handles loading and downloading of simulation result data
"""

import logging
import os
import pathlib
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import boto3
import polars as pl
import s3fs  # type: ignore[import-untyped]
from botocore.config import Config

from resstockpostproc.standard_plots.schema.workflow_schema import WorkflowConfig

# Column name constants
UPGRADE_NAME_COL = "upgrade_name"
UPGRADE_COL = "upgrade"
APPLICABILITY_COL = "applicability"

# Configure logger to output to console
logger = logging.getLogger(__name__)
if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s | %(levelname)-7s | %(message)s', datefmt='%H:%M:%S')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)

s3_client = boto3.client("s3", config=Config(read_timeout=60 * 60, max_pool_connections=50))


class InputManager:
    """Manages data input operations including downloads and loading parquet files"""

    def __init__(self, workflow: WorkflowConfig):
        """
        Initialize the input manager

        Args:
            workflow: WorkflowConfig object containing the workflow configuration
        """
        self.workflow = workflow
        self.local_results_dir = self._get_local_results_dir()
        self.upgrade_to_name = dict(zip(self.workflow.upgrades, self.workflow.upgrade_names))

    def load_data(self, selected_upgrades: list[int] | None = None) -> pl.LazyFrame:
        """
        Public API: Load data, handling downloads if needed

        Returns:
            Combined LazyFrame with all upgrade data
        """
        return self._load_parquet_data(selected_upgrades)

    def download_data(self) -> None:
        """Check for missing upgrades and download if needed"""
        if not self.workflow.storage_backend == "filesystem":
            logger.info("Storage backend is not filesystem, skipping download")
            return

        available_upgrades = self._get_available_upgrades()
        if missing_upgrades := set(self.workflow.upgrades) - set(available_upgrades):
            self._download_data(self.workflow, sorted(missing_upgrades))
        else:
            print(f"All upgrades are available at {self.local_results_dir}, skipping download")

    def _load_parquet_data(self, selected_upgrades: list[int] | None) -> pl.LazyFrame:
        """Load and concatenate parquet files from filesystem or MinIO"""
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

        upgrade_to_file = self._filter_upgrade_files(self.workflow, all_files, selected_upgrades)
        
        for upgrade, file in upgrade_to_file.items():
            if self.workflow.storage_backend == "filesystem":
                lazyframes[upgrade] = pl.scan_parquet(file, glob=False)
            else:
                lazyframes[upgrade] = pl.scan_parquet(
                    f"s3://{file}",
                    storage_options={"endpoint_url": minio_endpoint, "skip_signature": "true"},
                    glob=False,
                )
            upgrade_name = self.upgrade_to_name[upgrade]
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

    def _get_local_results_dir(self) -> Path:
        """Get local cache directory path"""
        return Path(self.workflow.output_dir) / "s3_data" / self.workflow.s3_results_dir.removeprefix("s3://")

    def _get_available_upgrades(self) -> list[int]:
        """List locally available upgrades"""
        local_files = [str(file) for file in pathlib.Path(self.local_results_dir).glob("**/*.parquet")]
        upgrade_to_file = self._filter_upgrade_files(self.workflow, local_files)
        return list(upgrade_to_file.keys())

    @staticmethod
    def _filter_upgrade_files(workflow: WorkflowConfig, all_files: list[str], selected_upgrades: list[int] | None = None) -> dict[int, str]:
        """
        Map upgrade IDs to file paths by matching against known patterns

        Args:
            workflow: WorkflowConfig containing upgrade information
            all_files: List of all parquet file paths

        Returns:
            Dictionary mapping upgrade ID to file path
        """
        upgrade_to_file: dict[int, str] = {}
        if selected_upgrades is not None:
            upgrades_to_consider = selected_upgrades
        else:
            upgrades_to_consider = workflow.upgrades
        for upgrade in upgrades_to_consider:
            base_patterns = [
                f"up{upgrade:02d}",
                f"upgrade{upgrade:02d}",
                f"upgrade{upgrade}",
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

            if len(set(matching_files)) > 1:
                raise ValueError(f"Multiple files ({matching_files}) found for upgrade {upgrade}")
            if not matching_files:
                continue

            upgrade_to_file[upgrade] = matching_files[0][1]

        return upgrade_to_file

    @staticmethod
    def _download_file(bucket: str, key: str, local_file: str, max_retries: int = 3) -> str:
        """Download a single file from S3 with retry logic"""
        for attempt in range(max_retries):
            try:
                s3_client.download_file(Bucket=bucket, Key=key, Filename=local_file)
                logger.info(f"Downloaded {key} to {local_file}")
                return local_file
            except Exception as e:
                if attempt == max_retries - 1:
                    logger.error(f"Failed to download {key} after {max_retries} attempts: {e}")
                    raise
                logger.warning(f"Download attempt {attempt + 1} failed for {key}, retrying...")
                time.sleep(1)
        return local_file

    @staticmethod
    def _download_data(workflow: WorkflowConfig, missing_upgrades: list[int]) -> None:
        """Download multiple files from S3 concurrently using ThreadPoolExecutor"""
        s3_results_dir = workflow.s3_results_dir
        bucket = s3_results_dir.removeprefix("s3://").split("/")[0]
        s3_prefix = "/".join(s3_results_dir.removeprefix("s3://").split("/")[1:])
        local_results_dir = Path(workflow.output_dir) / "s3_data" / workflow.s3_results_dir.removeprefix("s3://")

        # List all files in S3
        response = s3_client.list_objects_v2(Bucket=bucket, Prefix=s3_prefix)
        all_files = [obj["Key"] for obj in response["Contents"]]
        upgrade_to_file = InputManager._filter_upgrade_files(workflow, all_files)

        # Create local directory
        local_results_dir.mkdir(parents=True, exist_ok=True)

        # Download files concurrently using ThreadPoolExecutor
        start_time = time.time()
        logger.info(f"Downloading {len(missing_upgrades)} files to {local_results_dir}")
        
        download_tasks = []
        for upgrade in missing_upgrades:
            file = upgrade_to_file[upgrade]
            local_file = local_results_dir / f"upgrade={upgrade}" / os.path.basename(file)
            local_path = local_file.parent
            local_path.mkdir(parents=True, exist_ok=True)
            logger.info(f"Queuing download: {file} for upgrade {upgrade} to {local_file}")
            download_tasks.append((bucket, file, str(local_file)))

        # Execute downloads with max 5 concurrent workers
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(InputManager._download_file, bucket, key, local) 
                      for bucket, key, local in download_tasks]
            
            # Wait for all downloads to complete
            for future in as_completed(futures):
                try:
                    future.result()  # This will raise if the download failed
                except Exception as e:
                    logger.error(f"Download failed: {e}")

        logger.info(f"Downloaded {len(missing_upgrades)} files in {time.time() - start_time:.2f} seconds")
