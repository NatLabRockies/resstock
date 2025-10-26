"""
Functional helpers for loading and downloading simulation result data.
"""

from __future__ import annotations

import logging
import os
import pathlib
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from collections.abc import Iterable

import boto3
import polars as pl
import s3fs  # type: ignore[import-untyped]
from botocore.config import Config

from resstockpostproc.standard_plots.schema.workflow_schema import WorkflowConfig

logger = logging.getLogger(__name__)
if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setLevel(logging.INFO)
    formatter = logging.Formatter("%(asctime)s | %(levelname)-7s | %(message)s", datefmt="%H:%M:%S")
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)

s3_client = boto3.client("s3", config=Config(read_timeout=60 * 60, max_pool_connections=50))


def load_data(workflow: WorkflowConfig, selected_upgrades: list[int] | None = None) -> pl.LazyFrame:
    """Load and concatenate parquet files from filesystem or MinIO."""
    lazyframes: dict[int, pl.LazyFrame] = {}
    minio_endpoint = "http://minio:10000"
    local_results_dir = _get_local_results_dir(workflow)
    upgrades_to_names = dict(zip(workflow.upgrades, workflow.upgrade_names))

    if workflow.storage_backend == "filesystem":
        all_files = [str(file) for file in pathlib.Path(local_results_dir).glob("**/*.parquet")]
    else:
        fs = s3fs.S3FileSystem(anon=True, client_kwargs={"endpoint_url": minio_endpoint})
        all_files = [
            f for f in fs.find(workflow.s3_results_dir.removeprefix("s3://"), withdirs=False) if f.endswith(".parquet")
        ]

    upgrade_to_file = _filter_upgrade_files(workflow, all_files, selected_upgrades)

    for upgrade, file in upgrade_to_file.items():
        if workflow.storage_backend == "filesystem":
            lazy = pl.scan_parquet(file, glob=False)
        else:
            lazy = pl.scan_parquet(
                f"s3://{file}",
                storage_options={"endpoint_url": minio_endpoint, "skip_signature": "true"},
                glob=False,
            )
        upgrade_name = upgrades_to_names.get(upgrade, str(upgrade))
        lazy = lazy.with_columns(pl.lit(upgrade_name).alias("upgrade_name"))

        schema = lazy.collect_schema()
        if "applicability" in schema and schema["applicability"] != pl.Boolean:
            truthy_values = ["true", "True", "1"]
            lazy = lazy.with_columns(
                pl.when(pl.col("applicability").is_in(truthy_values))
                .then(True)
                .otherwise(False)
                .alias("applicability")
                .cast(pl.Boolean)
            )

        lazyframes[upgrade] = lazy

    if not lazyframes:
        raise ValueError(f"No data found in {local_results_dir}. Make sure the s3_results_dir is synced.")
    return pl.concat(lazyframes.values(), how="diagonal")


def download_data(workflow: WorkflowConfig) -> None:
    """Check for missing upgrades and download them if needed (filesystem backend only)."""
    if workflow.storage_backend != "filesystem":
        logger.info("Storage backend is not filesystem, skipping download")
        return

    available_upgrades = _get_available_upgrades(workflow)
    missing_upgrades = set(workflow.upgrades) - set(available_upgrades)
    if missing_upgrades:
        _download_data(workflow, sorted(missing_upgrades))
    else:
        print(f"All upgrades are available at {_get_local_results_dir(workflow)}, skipping download")


def _get_local_results_dir(workflow: WorkflowConfig) -> Path:
    return Path(workflow.output_dir) / "s3_data" / workflow.s3_results_dir.removeprefix("s3://")


def _get_available_upgrades(workflow: WorkflowConfig) -> list[int]:
    local_dir = _get_local_results_dir(workflow)
    local_files = [str(file) for file in pathlib.Path(local_dir).glob("**/*.parquet")]
    upgrade_to_file = _filter_upgrade_files(workflow, local_files)
    return list(upgrade_to_file.keys())


def _filter_upgrade_files(
    workflow: WorkflowConfig,
    all_files: Iterable[str],
    selected_upgrades: list[int] | None = None,
) -> dict[int, str]:
    """Map upgrade IDs to file paths by matching against known patterns."""
    upgrade_to_file: dict[int, str] = {}
    upgrades_to_consider = selected_upgrades if selected_upgrades is not None else workflow.upgrades

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


def _download_file(bucket: str, key: str, local_file: str, max_retries: int = 3) -> str:
    """Download a single file from S3 with retry logic."""
    for attempt in range(max_retries):
        try:
            s3_client.download_file(Bucket=bucket, Key=key, Filename=local_file)
            logger.info("Downloaded %s to %s", key, local_file)
            return local_file
        except Exception as exc:
            if attempt == max_retries - 1:
                logger.error("Failed to download %s after %d attempts: %s", key, max_retries, exc)
                raise
            logger.warning("Download attempt %d failed for %s, retrying...", attempt + 1, key)
            time.sleep(1)
    return local_file


def _download_data(workflow: WorkflowConfig, missing_upgrades: list[int]) -> None:
    """Download multiple files from S3 concurrently using ThreadPoolExecutor."""
    s3_results_dir = workflow.s3_results_dir
    bucket = s3_results_dir.removeprefix("s3://").split("/")[0]
    s3_prefix = "/".join(s3_results_dir.removeprefix("s3://").split("/")[1:])
    local_results_dir = _get_local_results_dir(workflow)

    response = s3_client.list_objects_v2(Bucket=bucket, Prefix=s3_prefix)
    contents = response.get("Contents", [])
    all_files = [obj["Key"] for obj in contents]
    upgrade_to_file = _filter_upgrade_files(workflow, all_files)

    missing_files = []
    for upgrade in missing_upgrades:
        s3_key = upgrade_to_file.get(upgrade)
        if not s3_key:
            logger.warning("No file found in S3 for upgrade %s", upgrade)
            continue
        local_file = local_results_dir / os.path.basename(s3_key)
        missing_files.append((s3_key, str(local_file)))

    os.makedirs(local_results_dir, exist_ok=True)

    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = [executor.submit(_download_file, bucket, key, local, max_retries=3) for key, local in missing_files]
        for future in as_completed(futures):
            future.result()
