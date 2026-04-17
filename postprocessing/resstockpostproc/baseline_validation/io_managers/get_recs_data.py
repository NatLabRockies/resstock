"""Reference Data Loader
---------------------
Functions for loading and processing reference data (EIA, LRD, etc.) for validation
"""

import logging
from pathlib import Path

import numpy as np
import polars as pl
from resstockpostproc.shared_utils.mapping import NUM2MONTH
from resstockpostproc.shared_utils.s3_manager import get_df_from_s3
from . import comparison_data_paths as s3_paths
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.baseline_validation.schema.recs_enduse_mapping import RECS_ENDUSE_MAP
from resstockpostproc.baseline_validation.data_processing.recs_rse import CI_Z, calculate_bounds_batch
from resstockpostproc.shared_utils.caching import cached
from resstockpostproc.shared_utils.timing import timed
from resstockpostproc.baseline_validation.schema.plot_spec import DataKey, Metric, CoverageType
from resstockpostproc.baseline_validation.schema.recs_chars_mapping import RECS_CHARS_MAPPING, PartialMap

logger = logging.getLogger(__name__)


local_data_dir = Path(f"{workflow.output.output_dir}/data")


def _apply_recs_pre_filter(mdf: pl.DataFrame, pre_filter: tuple[str, str]) -> pl.DataFrame:
    """Filter RECS microdata by a pre-filter using RECS_CHARS_MAPPING.

    Inverts the RECS mapping (display_value → raw_code) to filter raw microdata.
    For PartialMap (identity mapping), filter values are used directly.
    """
    char, value = pre_filter
    recs_spec = RECS_CHARS_MAPPING[char]["RECS"]
    recs_col = recs_spec["column_name"]
    mapping = recs_spec["mapping"]

    if isinstance(mapping, PartialMap):
        # PartialMap: mostly identity. Check explicit entries first, else use value directly.
        inv_explicit = {}
        for raw, display in mapping.items():
            inv_explicit.setdefault(display, []).append(raw)
        if value in inv_explicit:
            return mdf.filter(pl.col(recs_col).is_in(inv_explicit[value]))
        else:
            # Identity: display value == raw value
            return mdf.filter(pl.col(recs_col) == value)
    else:
        # Regular dict: invert mapping
        inv_map: dict[str, list] = {}
        for raw, display in mapping.items():
            inv_map.setdefault(display, []).append(raw)
        if value not in inv_map:
            raise ValueError(
                f"Pre-filter value '{value}' not found in RECS mapping for '{char}'. "
                f"Valid values: {sorted(set(mapping.values()))}"
            )
        return mdf.filter(pl.col(recs_col).is_in(inv_map[value]))


def _calculate_weighted_quantiles(data: np.ndarray, weights: np.ndarray, quantiles: list[float]) -> np.ndarray:
    """Calculate weighted quantiles.

    Args:
        data: Data values
        weights: Weights for each data value
        quantiles: List of quantiles to calculate (between 0 and 1)

    Returns:
        Array of quantile values
    """
    # Sort data and weights by data values
    sorted_indices = np.argsort(data)
    sorted_data = data[sorted_indices]
    sorted_weights = weights[sorted_indices]

    # Calculate cumulative weights
    cumsum_weights = np.cumsum(sorted_weights)
    total_weight = cumsum_weights[-1]

    # Normalize cumulative weights to [0, 1]
    cumsum_normalized = cumsum_weights / total_weight

    # Calculate quantiles
    result = np.zeros(len(quantiles))
    for i, q in enumerate(quantiles):
        if q == 0:
            result[i] = sorted_data[0]
        elif q == 1:
            result[i] = sorted_data[-1]
        else:
            # Find the index where cumulative weight exceeds quantile
            idx = np.searchsorted(cumsum_normalized, q)
            if idx == 0:
                result[i] = sorted_data[0]
            elif idx >= len(sorted_data):
                result[i] = sorted_data[-1]
            else:
                # Linear interpolation
                w0 = cumsum_normalized[idx - 1]
                w1 = cumsum_normalized[idx]
                v0 = sorted_data[idx - 1]
                v1 = sorted_data[idx]
                if w1 - w0 > 0:
                    result[i] = v0 + (v1 - v0) * (q - w0) / (w1 - w0)
                else:
                    result[i] = v0

    return result


def _resolve_recs_value_stat_type(data_key: DataKey) -> str:
    """Return the bound estimator that matches the plotted RECS value statistic."""
    if data_key.aggregation_type == Metric.total:
        return "total"
    if data_key.coverage == CoverageType.users_only:
        return "avg_nonzero"
    return "avg"


def _normalize_bounds(bounds: tuple[float, float] | None) -> tuple[float | None, float | None]:
    if bounds is None:
        return None, None
    return bounds


def _build_bounds_row(
    bounds_by_request: dict[tuple[str, str], tuple[float, float] | None],
    enduse_cols: tuple,
    value_stat_type: str,
) -> dict[str, float | None]:
    """Map batched bound results onto dataframe column names."""
    row: dict[str, float | None] = {}
    for col in enduse_cols:
        value_lower, value_upper = _normalize_bounds(bounds_by_request.get((col, value_stat_type)))
        pct_lower, pct_upper = _normalize_bounds(bounds_by_request.get((col, "percent")))
        row[f"{col}_value_lower_bound"] = value_lower
        row[f"{col}_value_upper_bound"] = value_upper
        row[f"{col}_percent_users_lower_bound"] = pct_lower
        row[f"{col}_percent_users_upper_bound"] = pct_upper
    return row


def _add_symmetric_bounds_from_rse(df: pl.DataFrame) -> pl.DataFrame:
    """Convert published monthly RSE columns into explicit lower/upper bounds."""
    rse_columns = [col for col in df.columns if col.endswith("_rse")]
    if not rse_columns:
        return df

    exprs: list[pl.Expr] = []
    for rse_col in rse_columns:
        base_col = rse_col.removesuffix("_rse")
        margin = pl.col(base_col) * pl.col(rse_col).fill_null(0).abs() / 100.0 * CI_Z
        exprs.append((pl.col(base_col) + margin).alias(f"{base_col}_upper_bound"))
        exprs.append((pl.col(base_col) - margin).alias(f"{base_col}_lower_bound"))

    return df.with_columns(exprs).drop(rse_columns)


@timed
@cached(cache_file="recs_annual_data_cache_v2")
def get_annual_all(
    data_key: DataKey,
    year: int = 2020,
) -> pl.DataFrame:
    """Get annual RECS data aggregated by the specified level.

    Args:
        data_key: DataKey containing effective_group_by, aggregation_type, and coverage
        year: Year of RECS data (only 2020 supported)
    """
    if year != 2020:
        raise ValueError("RECS data is only available for the year 2020.")

    by_cols = list(data_key.effective_group_by)
    by = by_cols[0] if by_cols else None  # primary groupby column (used for US Total)
    mdf = get_df_from_s3(s3_paths.RECS_2020_microdata, local_data_dir)

    enduse_cols = tuple(RECS_ENDUSE_MAP.keys())

    if by_cols:
        # Calculate value columns based on aggregation type
        if data_key.aggregation_type == Metric.total:
            # Stock energy: weighted sum
            result_df = mdf.group_by(by_cols).agg(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *((pl.col(col) * pl.col("NWEIGHT")).sum().alias(f"{col}_value") for col in enduse_cols),
                *(
                    (
                        ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum() * 100
                    ).alias(f"{col}_percent_users")
                    for col in enduse_cols
                ),
            )
        elif data_key.coverage == CoverageType.all_units:
            # Per-unit energy: weighted mean (sum of weighted values / sum of all weights)
            result_df = mdf.group_by(by_cols).agg(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *(
                    ((pl.col(col) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum()).alias(f"{col}_value")
                    for col in enduse_cols
                ),
                *(
                    (
                        ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum() * 100
                    ).alias(f"{col}_percent_users")
                    for col in enduse_cols
                ),
            )
        else:
            # Per-user energy: weighted mean (sum of weighted values / sum of weights for non-zero values only)
            result_df = mdf.group_by(by_cols).agg(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *(
                    (
                        (pl.col(col) * pl.col("NWEIGHT")).sum()
                        / ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum()
                    ).alias(f"{col}_value")
                    for col in enduse_cols
                ),
                *(
                    (
                        ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum() * 100
                    ).alias(f"{col}_percent_users")
                    for col in enduse_cols
                ),
            )

        # Calculate confidence bounds and quartiles by group
        mdf_pd = mdf.to_pandas()
        bounds_results = []
        quartile_results = []
        nonzero_quartile_results = []

        value_stat_type = _resolve_recs_value_stat_type(data_key)

        unique_groups = mdf.select(by_cols).unique()
        n_groups = len(unique_groups)
        logger.info(f"Computing RECS confidence bounds/quartiles for {n_groups} groups ({by_cols})...")
        for gi, group_row in enumerate(unique_groups.iter_rows(named=True)):
            if gi > 0 and gi % 50 == 0:
                logger.info(f"  RECS uncertainty progress: {gi}/{n_groups}")
            mask = True
            for col_name in by_cols:
                mask = mask & (mdf_pd[col_name] == group_row[col_name])
            group_data = mdf_pd[mask]
            bounds_row = dict(group_row)
            quartile_row = dict(group_row)
            nonzero_quartile_row = dict(group_row)

            bound_requests = []
            for col in enduse_cols:
                bound_requests.append((col, value_stat_type))
                bound_requests.append((col, "percent"))
            try:
                batched_bounds = calculate_bounds_batch(group_data, bound_requests)
            except Exception:
                batched_bounds = dict.fromkeys(bound_requests)
            bounds_row.update(_build_bounds_row(batched_bounds, enduse_cols, value_stat_type))

            for col in enduse_cols:
                # Calculate quartiles for the column
                try:
                    data_values = group_data[col].values
                    weights = group_data["NWEIGHT"].values
                    if len(data_values) > 0:
                        # Calculate weighted quartiles
                        quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                        quartiles = _calculate_weighted_quantiles(data_values, weights, quantiles)
                        quartile_row[f"{col}_quartiles"] = quartiles.tolist()
                    else:
                        quartile_row[f"{col}_quartiles"] = [0.0] * 9
                except Exception:
                    quartile_row[f"{col}_quartiles"] = [0.0] * 9

                # Calculate nonzero quartiles for the column (exclude zeros)
                try:
                    data_values = group_data[col].values
                    weights = group_data["NWEIGHT"].values
                    non_zero_mask = data_values > 0
                    data_values_nonzero = data_values[non_zero_mask]
                    weights_nonzero = weights[non_zero_mask]
                    if len(data_values_nonzero) > 0:
                        # Calculate weighted quartiles for non-zero values
                        quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                        nonzero_quartiles = _calculate_weighted_quantiles(
                            data_values_nonzero, weights_nonzero, quantiles
                        )
                        nonzero_quartile_row[f"{col}_nonzero_quartiles"] = nonzero_quartiles.tolist()
                    else:
                        nonzero_quartile_row[f"{col}_nonzero_quartiles"] = [0.0] * 9
                except Exception:
                    nonzero_quartile_row[f"{col}_nonzero_quartiles"] = [0.0] * 9

            bounds_results.append(bounds_row)
            quartile_results.append(quartile_row)
            nonzero_quartile_results.append(nonzero_quartile_row)

        # Convert bound and quartile results to polars and join with value results
        bounds_df = pl.DataFrame(bounds_results)
        quartile_df = pl.DataFrame(quartile_results)
        nonzero_quartile_df = pl.DataFrame(nonzero_quartile_results)
        result_df = result_df.join(bounds_df, on=by_cols, how="left")
        result_df = result_df.join(quartile_df, on=by_cols, how="left")
        result_df = result_df.join(nonzero_quartile_df, on=by_cols, how="left")

        # Add US Total values.
        # For multi-column groupby, compute one US Total per secondary dimension value.
        secondary_cols = by_cols[1:]  # empty for single-column
        if secondary_cols:
            secondary_combos = list(mdf.select(secondary_cols).unique().iter_rows(named=True))
            logger.info(f"Computing US Total for {len(secondary_combos)} secondary groups...")
        else:
            secondary_combos = [{}]  # single iteration for single-column

        for sec_vals in secondary_combos:
            # Filter microdata to this secondary dimension subset
            mdf_subset = mdf
            for sc, sv in sec_vals.items():
                mdf_subset = mdf_subset.filter(pl.col(sc) == sv)
            mdf_subset_pd = mdf_subset.to_pandas()

            us_total_values = {by: "US Total"}
            us_total_values.update(sec_vals)
            us_total_values["sample_count"] = len(mdf_subset)
            us_total_values["units_count"] = mdf_subset["NWEIGHT"].sum()

            for col in enduse_cols:
                weighted_sum = (mdf_subset[col] * mdf_subset["NWEIGHT"]).sum()
                weight_sum = mdf_subset["NWEIGHT"].sum()
                nonzero_weight_sum = ((mdf_subset[col] > 0).cast(pl.Int64) * mdf_subset["NWEIGHT"]).sum()

                if data_key.aggregation_type == Metric.total:
                    us_total_values[f"{col}_value"] = weighted_sum
                    us_total_values[f"{col}_percent_users"] = (
                        (nonzero_weight_sum / weight_sum * 100) if weight_sum > 0 else 0
                    )
                elif data_key.coverage == CoverageType.all_units:
                    us_total_values[f"{col}_value"] = weighted_sum / weight_sum if weight_sum > 0 else 0
                    us_total_values[f"{col}_percent_users"] = (
                        (nonzero_weight_sum / weight_sum * 100) if weight_sum > 0 else 0
                    )
                else:  # users_only
                    us_total_values[f"{col}_value"] = (
                        weighted_sum / nonzero_weight_sum if nonzero_weight_sum > 0 else 0
                    )
                    us_total_values[f"{col}_percent_users"] = (
                        (nonzero_weight_sum / weight_sum * 100) if weight_sum > 0 else 0
                    )

            us_total_df = pl.DataFrame([us_total_values])
            result_df = pl.concat([result_df, us_total_df], how="diagonal_relaxed")

            # Calculate confidence bounds and quartiles for this US Total row
            us_total_bounds_dict = {}
            us_total_quartile_dict = {}
            us_total_nonzero_quartile_dict = {}

            bound_requests = []
            for col in enduse_cols:
                bound_requests.append((col, value_stat_type))
                bound_requests.append((col, "percent"))
            try:
                batched_bounds = calculate_bounds_batch(mdf_subset_pd, bound_requests)
            except Exception:
                batched_bounds = dict.fromkeys(bound_requests)
            us_total_bounds_dict.update(_build_bounds_row(batched_bounds, enduse_cols, value_stat_type))

            for col in enduse_cols:
                try:
                    data_values = mdf_subset_pd[col].values
                    weights = mdf_subset_pd["NWEIGHT"].values
                    if len(data_values) > 0:
                        quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                        quartiles = _calculate_weighted_quantiles(data_values, weights, quantiles)
                        us_total_quartile_dict[f"{col}_quartiles"] = quartiles.tolist()
                    else:
                        us_total_quartile_dict[f"{col}_quartiles"] = [0.0] * 9
                except Exception:
                    us_total_quartile_dict[f"{col}_quartiles"] = [0.0] * 9

                try:
                    data_values = mdf_subset_pd[col].values
                    weights = mdf_subset_pd["NWEIGHT"].values
                    non_zero_mask = data_values > 0
                    data_values_nonzero = data_values[non_zero_mask]
                    weights_nonzero = weights[non_zero_mask]
                    if len(data_values_nonzero) > 0:
                        quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                        nonzero_quartiles = _calculate_weighted_quantiles(data_values_nonzero, weights_nonzero, quantiles)
                        us_total_nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = nonzero_quartiles.tolist()
                    else:
                        us_total_nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = [0.0] * 9
                except Exception:
                    us_total_nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = [0.0] * 9

            # Build a mask for this specific US Total row
            us_mask = pl.col(by) == "US Total"
            for sc, sv in sec_vals.items():
                us_mask = us_mask & (pl.col(sc) == sv)

            for col, bound_value in us_total_bounds_dict.items():
                result_df = result_df.with_columns(
                    pl.when(us_mask).then(pl.lit(bound_value)).otherwise(pl.col(col)).alias(col)
                )
            for col, quartile_value in us_total_quartile_dict.items():
                result_df = result_df.with_columns(
                    pl.when(us_mask).then(pl.lit(quartile_value)).otherwise(pl.col(col)).alias(col)
                )
            for col, nonzero_quartile_value in us_total_nonzero_quartile_dict.items():
                result_df = result_df.with_columns(
                    pl.when(us_mask).then(pl.lit(nonzero_quartile_value)).otherwise(pl.col(col)).alias(col)
                )
    else:
        # Calculate value columns based on aggregation type
        if data_key.aggregation_type == Metric.total:
            # Stock energy: weighted sum
            result_df = mdf.select(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *((pl.col(col) * pl.col("NWEIGHT")).sum().alias(f"{col}_value") for col in enduse_cols),
            )
        elif data_key.coverage == CoverageType.all_units:
            # Per-unit energy: weighted mean (sum of weighted values / sum of all weights)
            result_df = mdf.select(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *(
                    ((pl.col(col) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum()).alias(f"{col}_value")
                    for col in enduse_cols
                ),
            )
        else:  # data_key.coverage == CoverageType.users_only
            # Per-user energy: weighted mean (sum of weighted values / sum of weights for non-zero values only)
            result_df = mdf.select(
                pl.len().alias("sample_count"),
                pl.col("NWEIGHT").sum().alias("units_count"),
                *(
                    (
                        (pl.col(col) * pl.col("NWEIGHT")).sum()
                        / ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum()
                    ).alias(f"{col}_value")
                    for col in enduse_cols
                ),
            )

        # Calculate confidence bounds and quartiles
        mdf_pd = mdf.to_pandas()
        bounds_dict = {}
        quartile_dict = {}
        nonzero_quartile_dict = {}

        value_stat_type = _resolve_recs_value_stat_type(data_key)

        bound_requests = []
        for col in enduse_cols:
            bound_requests.append((col, value_stat_type))
            bound_requests.append((col, "percent"))
        try:
            batched_bounds = calculate_bounds_batch(mdf_pd, bound_requests)
        except Exception:
            batched_bounds = dict.fromkeys(bound_requests)
        for col_name, bound_value in _build_bounds_row(batched_bounds, enduse_cols, value_stat_type).items():
            bounds_dict[col_name] = [bound_value]

        for col in enduse_cols:
            # Calculate quartiles (including all values)
            try:
                data_values = mdf_pd[col].values
                weights = mdf_pd["NWEIGHT"].values

                if len(data_values) > 0:
                    quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                    quartiles = _calculate_weighted_quantiles(data_values, weights, quantiles)
                    quartile_dict[f"{col}_quartiles"] = quartiles.tolist()
                else:
                    quartile_dict[f"{col}_quartiles"] = [0.0] * 9
            except Exception:
                quartile_dict[f"{col}_quartiles"] = [0.0] * 9

            # Calculate nonzero quartiles (exclude zeros)
            try:
                data_values = mdf_pd[col].values
                weights = mdf_pd["NWEIGHT"].values
                non_zero_mask = data_values > 0
                data_values_nonzero = data_values[non_zero_mask]
                weights_nonzero = weights[non_zero_mask]

                if len(data_values_nonzero) > 0:
                    quantiles = [0, 0.02, 0.1, 0.25, 0.5, 0.75, 0.9, 0.98, 1]
                    nonzero_quartiles = _calculate_weighted_quantiles(data_values_nonzero, weights_nonzero, quantiles)
                    nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = nonzero_quartiles.tolist()
                else:
                    nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = [0.0] * 9
            except Exception:
                nonzero_quartile_dict[f"{col}_nonzero_quartiles"] = [0.0] * 9

        # Add bound and quartile columns to result
        bounds_df = pl.DataFrame(bounds_dict)
        quartile_df = pl.DataFrame(quartile_dict)
        nonzero_quartile_df = pl.DataFrame(nonzero_quartile_dict)
        result_df = pl.concat([result_df, bounds_df, quartile_df, nonzero_quartile_df], how="horizontal")

    # Note: US Total is only added when grouped by a column (e.g., state)
    # For ungrouped data, the result is already the US total
    result_df = result_df.with_columns(pl.lit("recs_2020").alias("source"))
    return result_df


@timed
@cached(cache_file="recs_monthly_data_cache_v2")
def get_monthly_all(
    data_key: DataKey,
    year: int = 2020,
) -> pl.DataFrame:
    """Get monthly RECS data aggregated by state.

    Args:
        data_key: DataKey containing group_by, aggregation_type, and coverage
        year: Year of RECS data (only 2020 supported)
    """
    if year != 2020:
        raise ValueError("RECS data is only available for the year 2020.")

    if len(data_key.effective_group_by) > 1:
        raise ValueError(
            "Multi-column groupby is not supported for monthly RECS data. "
            "Monthly RECS data is pre-aggregated and cannot be filtered by building characteristics."
        )

    by = data_key.effective_group_by[0]

    if by not in ("state",):
        raise ValueError("Monthly data only available aggregated by 'state'.")
    monthly_df = get_df_from_s3(s3_paths.RECS_2020_monthly, local_data_dir)

    # Rename "geography" column to "state" for backward compatibility
    monthly_df = monthly_df.rename({"geography": "state"})
    # Define valid state abbreviations (50 states + DC)
    valid_states = {
        "AL",
        "AK",
        "AZ",
        "AR",
        "CA",
        "CO",
        "CT",
        "DE",
        "FL",
        "GA",
        "HI",
        "ID",
        "IL",
        "IN",
        "IA",
        "KS",
        "KY",
        "LA",
        "ME",
        "MD",
        "MA",
        "MI",
        "MN",
        "MS",
        "MO",
        "MT",
        "NE",
        "NV",
        "NH",
        "NJ",
        "NM",
        "NY",
        "NC",
        "ND",
        "OH",
        "OK",
        "OR",
        "PA",
        "RI",
        "SC",
        "SD",
        "TN",
        "TX",
        "UT",
        "VT",
        "VA",
        "WA",
        "WV",
        "WI",
        "WY",
        "DC",
    }

    # Filter to keep only US Total and valid state abbreviations
    monthly_df = monthly_df.filter((pl.col("state") == "US Total") | (pl.col("state").is_in(valid_states)))

    monthly_df = monthly_df.with_columns(pl.col("month").replace_strict(NUM2MONTH, default=None))
    percent_users_cols = [
        f"{col.replace('_value', '_percent_users')}" for col in monthly_df.columns if col.endswith("_value")
    ]
    annual_df = get_annual_all(data_key=data_key, year=year)
    monthly_df = monthly_df.join(annual_df.select([by] + percent_users_cols + ["units_count"]), on=by, how="left")

    # Apply aggregation transformation if needed
    if data_key.coverage == CoverageType.all_units and data_key.aggregation_type == Metric.average:
        # For per-unit energy, divide value columns by units_count
        value_cols = [col for col in monthly_df.columns if col.endswith("_value")]
        avg_exprs = []
        for val_col in value_cols:
            # Divide value by units_count, handle division by zero
            avg_exprs.append(
                pl.when(pl.col("units_count") > 0)
                .then(pl.col(val_col) / pl.col("units_count"))
                .otherwise(0)
                .alias(val_col)
            )
        if avg_exprs:
            monthly_df = monthly_df.with_columns(avg_exprs)
    elif data_key.coverage == CoverageType.users_only and data_key.aggregation_type == Metric.average:
        # For per-user energy, divide value columns by customer columns
        value_cols = [col for col in monthly_df.columns if col.endswith("_value")]
        avg_exprs = []
        for val_col in value_cols:
            percent_users_col = val_col.replace("_value", "_percent_users")
            avg_exprs.append(
                pl.when(pl.col(percent_users_col) > 0)
                .then(pl.col(val_col) / (pl.col("units_count") * pl.col(percent_users_col) / 100))
                .otherwise(0)
                .alias(val_col)
            )
        if avg_exprs:
            monthly_df = monthly_df.with_columns(avg_exprs)

    monthly_df = _add_symmetric_bounds_from_rse(monthly_df)
    monthly_df = monthly_df.with_columns(pl.lit("recs_2020").alias("source"))
    return monthly_df


_FUEL_GROUPS = {
    "Fuel Totals": ["electricity_total", "natural_gas_total", "propane_total", "fuel_oil_total"],
    "Electricity End uses": "electricity_",
    "Natural Gas End uses": "natural_gas_",
    "Propane End uses": "propane_",
    "Fuel Oil End uses": "fuel_oil_",
}


@timed
@cached(cache_file="recs_enduse_order_cache")
def get_enduse_order() -> dict[str, list[str]]:
    """Return enduses sorted by US-level RECS total annual value (descending).

    Computes weighted sum of each enduse from the RECS microdata and returns
    a dict mapping fuel group name to an ordered list of enduse column names.
    The order is consistent across all entities and view types.
    """
    mdf = get_df_from_s3(s3_paths.RECS_2020_microdata, local_data_dir)
    enduse_cols = list(RECS_ENDUSE_MAP.keys())

    # Compute US-level weighted total for each enduse
    totals = {}
    for col in enduse_cols:
        totals[str(col)] = (mdf[col] * mdf["NWEIGHT"]).sum()

    result = {}
    for group_name, spec in _FUEL_GROUPS.items():
        if isinstance(spec, list):
            group_enduses = [e for e in spec if e in totals]
        else:
            group_enduses = [
                str(e) for e in enduse_cols
                if str(e).startswith(spec) and not str(e).endswith("_total")
            ]
        result[group_name] = sorted(group_enduses, key=lambda e: totals.get(e, 0), reverse=True)

    return result
