"""Reference Data Loader
---------------------
Functions for loading and processing reference data (EIA, LRD, etc.) for validation
"""

import logging
from pathlib import Path

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
from resstockpostproc.baseline_validation.io_managers.stats import ANNUAL_QUANTILES, weighted_quantiles

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


_ZERO_QUARTILES = [0.0] * 9


def _value_expr(col: str, data_key: DataKey) -> pl.Expr:
    """Weighted value expression per RECS aggregation/coverage rules."""
    weighted = (pl.col(col) * pl.col("NWEIGHT")).sum()
    if data_key.aggregation_type == Metric.total:
        return weighted.alias(f"{col}_value")
    if data_key.coverage == CoverageType.all_units:
        return (weighted / pl.col("NWEIGHT").sum()).alias(f"{col}_value")
    return (weighted / ((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum()).alias(f"{col}_value")


def _percent_users_expr(col: str) -> pl.Expr:
    return (((pl.col(col) > 0).cast(pl.Int64) * pl.col("NWEIGHT")).sum() / pl.col("NWEIGHT").sum() * 100).alias(
        f"{col}_percent_users"
    )


def _enduse_value_exprs(enduse_cols: tuple, data_key: DataKey, *, include_group_counts: bool) -> list[pl.Expr]:
    """Build the list of value/percent_users/nonzero_sample_count exprs for agg() or select()."""
    exprs: list[pl.Expr] = [
        pl.len().alias("sample_count"),
        pl.col("NWEIGHT").sum().alias("units_count"),
        *(_value_expr(col, data_key) for col in enduse_cols),
    ]
    if include_group_counts:
        exprs.extend(_percent_users_expr(col) for col in enduse_cols)
        exprs.extend((pl.col(col) > 0).sum().alias(f"{col}_nonzero_sample_count") for col in enduse_cols)
    return exprs


def _bounds_for_group(group_data_pd, enduse_cols: tuple, value_stat_type: str) -> dict:
    """Run bounds_batch and map onto dataframe column names; returns empty on failure."""
    bound_requests = [req for col in enduse_cols for req in ((col, value_stat_type), (col, "percent"))]
    try:
        batched_bounds = calculate_bounds_batch(group_data_pd, bound_requests)
    except Exception:
        batched_bounds = dict.fromkeys(bound_requests)
    return _build_bounds_row(batched_bounds, enduse_cols, value_stat_type)


def _weighted_quartiles_or_zeros(values, weights) -> list[float]:
    try:
        if len(values) == 0:
            return _ZERO_QUARTILES.copy()
        return weighted_quantiles(values, weights, ANNUAL_QUANTILES).tolist()
    except Exception:
        return _ZERO_QUARTILES.copy()


def _quartiles_for_group(group_data_pd, enduse_cols: tuple) -> tuple[dict, dict]:
    """Return (quartiles, nonzero_quartiles) dicts keyed by downstream column names."""
    quartiles: dict = {}
    nonzero_quartiles: dict = {}
    weights = group_data_pd["NWEIGHT"].values
    for col in enduse_cols:
        values = group_data_pd[col].values
        quartiles[f"{col}_quartiles"] = _weighted_quartiles_or_zeros(values, weights)
        mask = values > 0
        nonzero_quartiles[f"{col}_nonzero_quartiles"] = _weighted_quartiles_or_zeros(values[mask], weights[mask])
    return quartiles, nonzero_quartiles


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
    """Load annual RECS data aggregated by ``data_key.effective_group_by``.

    Only ``year=2020`` is supported; anything else raises.
    """
    if year != 2020:
        raise ValueError("RECS data is only available for the year 2020.")

    by_cols = list(data_key.effective_group_by)
    by = by_cols[0] if by_cols else None  # primary groupby column (used for US Total)
    mdf = get_df_from_s3(s3_paths.RECS_2020_microdata, local_data_dir)

    enduse_cols = tuple(RECS_ENDUSE_MAP.keys())

    if by_cols:
        result_df = mdf.group_by(by_cols, maintain_order=True).agg(
            _enduse_value_exprs(enduse_cols, data_key, include_group_counts=True)
        )

        # Calculate confidence bounds and quartiles by group
        mdf_pd = mdf.to_pandas()
        bounds_results = []
        quartile_results = []
        nonzero_quartile_results = []

        value_stat_type = _resolve_recs_value_stat_type(data_key)

        unique_groups = mdf.select(by_cols).unique(maintain_order=True)
        n_groups = len(unique_groups)
        logger.info(f"Computing RECS confidence bounds/quartiles for {n_groups} groups ({by_cols})...")
        for gi, group_row in enumerate(unique_groups.iter_rows(named=True)):
            if gi > 0 and gi % 50 == 0:
                logger.info(f"  RECS uncertainty progress: {gi}/{n_groups}")
            mask = True
            for col_name in by_cols:
                mask = mask & (mdf_pd[col_name] == group_row[col_name])
            group_data = mdf_pd[mask]
            quartiles, nonzero_quartiles = _quartiles_for_group(group_data, enduse_cols)
            bounds_results.append({**group_row, **_bounds_for_group(group_data, enduse_cols, value_stat_type)})
            quartile_results.append({**group_row, **quartiles})
            nonzero_quartile_results.append({**group_row, **nonzero_quartiles})

        # Convert bound and quartile results to polars and join with value results
        bounds_df = pl.DataFrame(bounds_results)
        quartile_df = pl.DataFrame(quartile_results)
        nonzero_quartile_df = pl.DataFrame(nonzero_quartile_results)
        result_df = result_df.join(bounds_df, on=by_cols, how="left", maintain_order="left_right")
        result_df = result_df.join(quartile_df, on=by_cols, how="left", maintain_order="left_right")
        result_df = result_df.join(nonzero_quartile_df, on=by_cols, how="left", maintain_order="left_right")

        # Add US Total values.
        # For multi-column groupby, compute one US Total per secondary dimension value.
        secondary_cols = by_cols[1:]  # empty for single-column
        if secondary_cols:
            secondary_combos = list(mdf.select(secondary_cols).unique(maintain_order=True).iter_rows(named=True))
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
                us_total_values[f"{col}_nonzero_sample_count"] = int((mdf_subset[col] > 0).sum())

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
                    us_total_values[f"{col}_value"] = weighted_sum / nonzero_weight_sum if nonzero_weight_sum > 0 else 0
                    us_total_values[f"{col}_percent_users"] = (
                        (nonzero_weight_sum / weight_sum * 100) if weight_sum > 0 else 0
                    )

            us_total_df = pl.DataFrame([us_total_values])
            result_df = pl.concat([result_df, us_total_df], how="diagonal_relaxed")

            us_bounds = _bounds_for_group(mdf_subset_pd, enduse_cols, value_stat_type)
            us_quartiles, us_nonzero_quartiles = _quartiles_for_group(mdf_subset_pd, enduse_cols)

            us_mask = pl.col(by) == "US Total"
            for sc, sv in sec_vals.items():
                us_mask = us_mask & (pl.col(sc) == sv)

            for stats_dict in (us_bounds, us_quartiles, us_nonzero_quartiles):
                for col, value in stats_dict.items():
                    result_df = result_df.with_columns(
                        pl.when(us_mask).then(pl.lit(value)).otherwise(pl.col(col)).alias(col)
                    )
    else:
        result_df = mdf.select(_enduse_value_exprs(enduse_cols, data_key, include_group_counts=False))

        mdf_pd = mdf.to_pandas()
        value_stat_type = _resolve_recs_value_stat_type(data_key)
        bounds = _bounds_for_group(mdf_pd, enduse_cols, value_stat_type)
        quartiles, nonzero_quartiles = _quartiles_for_group(mdf_pd, enduse_cols)
        stats_row = {
            **{k: [v] for k, v in bounds.items()},
            **{k: [v] for k, v in quartiles.items()},
            **{k: [v] for k, v in nonzero_quartiles.items()},
        }
        result_df = pl.concat([result_df, pl.DataFrame(stats_row)], how="horizontal")

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
    """Load monthly RECS data aggregated by state; only ``year=2020`` is supported."""
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
    nonzero_sample_cols = [
        col.replace("_value", "_nonzero_sample_count") for col in monthly_df.columns if col.endswith("_value")
    ]
    annual_df = get_annual_all(data_key=data_key, year=year)
    available_nonzero = [c for c in nonzero_sample_cols if c in annual_df.columns]
    join_cols = [by] + percent_users_cols + ["units_count", "sample_count"] + available_nonzero
    monthly_df = monthly_df.join(annual_df.select(join_cols), on=by, how="left", maintain_order="left_right")

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
            group_enduses = [str(e) for e in enduse_cols if str(e).startswith(spec) and not str(e).endswith("_total")]
        result[group_name] = sorted(group_enduses, key=lambda e: totals.get(e, 0), reverse=True)

    return result
