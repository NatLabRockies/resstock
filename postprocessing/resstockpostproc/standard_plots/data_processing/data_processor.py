"""
Data processing utilities for standard plots
--------------------------------------------
Provides transformation and aggregation helpers for simulation result data using Polars.
"""

import logging
import math
from collections.abc import Sequence

import numpy as np
import polars as pl
from scipy.stats import gaussian_kde

from resstockpostproc.standard_plots.schema.end_use_dicts import EnduseGroupToEnduses
from resstockpostproc.standard_plots.schema.plot_spec import (
    BuildingInclusion,
    PlotSpec,
    QuantityType,
    VacancyInclusion,
    VizType,
)
from resstockpostproc.standard_plots.schema.workflow_schema import AggregationType, QuantityGroup
from resstockpostproc.standard_plots.utils import human_sort

logger = logging.getLogger(__name__)
MIN_BASELINE = 1e-6  # used in denominator of percent savings calculation to avoid division by zero

# Column name constants to avoid typos and centralize schema changes
BLDG_ID_COL = "bldg_id"
UPGRADE_COL = "upgrade"
UPGRADE_NAME_COL = "upgrade_name"
APPLICABILITY_COL = "applicability"
VACANCY_STATUS_COL = "in.vacancy_status"
WEIGHT_COL = "weight"

def _safe_nonzero(expr: pl.Expr) -> pl.Expr:
    """Return an expression guaranteed to be at least MIN_BASELINE in magnitude.

    Preserves the sign of the input expression when it's very close to zero,
    using MIN_BASELINE as the floor. If the sign is exactly zero, uses +MIN_BASELINE.
    """
    return (
        pl.when(expr.abs() < MIN_BASELINE)
        .then(
            pl.when(expr.sign() == 0)
            .then(MIN_BASELINE)
            .otherwise(expr.sign() * MIN_BASELINE)
        )
        .otherwise(expr)
    )


def prepare_data_for_plot(
    combined_df: pl.LazyFrame,
    plot_spec: PlotSpec,
    *,
    selected_upgrades: list[int] | None = None,
    enduse_group_mapping: dict[str, list[str]] | None = None,
) -> pl.DataFrame:
    """
    Prepare data for plotting by applying filters, transformations, and aggregations.

    Args:
        combined_df: LazyFrame containing all upgrades (including baseline with ``upgrade == 0``)
        plot_spec: PlotSpec object containing the plot configuration
        selected_upgrades: Optional list of upgrades to include in the plot. If None, include all upgrades.
        enduse_group_mapping: Optional mapping for derived quantities; defaults to EnduseGroupToEnduses.

    Returns:
        DataFrame prepared for plotting with aggregated values according to ``plot_spec``.
    """

    mapping = dict(enduse_group_mapping or EnduseGroupToEnduses)
    grouping_cols = _get_grouping_cols(plot_spec)
    quantities = _get_quantities(plot_spec)

    working_df = combined_df
    if plot_spec.quantity_type != QuantityType.prevalence and quantities:
        working_df = _fill_missing_quantities(working_df, quantities, mapping)
        working_df = _convert_quantity_type(working_df, quantities, plot_spec.quantity_type)

    working_df = _process_upgrades_inclusion(plot_spec, selected_upgrades, working_df)
    working_df = _process_building_inclusion(plot_spec, working_df)
    working_df = _process_vacancy_inclusion(plot_spec, working_df)

    if plot_spec.quantity_type == QuantityType.prevalence:
        assert plot_spec.upgrade is not None, "Prevalence plots require a specific upgrade to be selected."  # noqa: S101 Use of `assert` detected
        return prepare_data_for_prevalence_plot(
            combined_df=working_df.filter(pl.col(UPGRADE_COL) == plot_spec.upgrade),
            quantity=plot_spec.quantity,
            quantity_group_name=plot_spec.quantity_group_name,
            grouping_cols=grouping_cols,
        )

    if plot_spec.quantity_type in (QuantityType.savings, QuantityType.percent_savings):
        working_df = working_df.filter(pl.col(UPGRADE_COL) != 0)

    if plot_spec.visualization_type == VizType.box:
        if isinstance(plot_spec.quantity, QuantityGroup):
            working_df = working_df.unpivot(
                quantities,
                index=[UPGRADE_COL, UPGRADE_NAME_COL, BLDG_ID_COL],
                variable_name="End Use",
                value_name="value (kWh)",
            )
            quantity_col = "value (kWh)"
            box_grouping_cols = [*grouping_cols, "End Use"]
        else:
            assert isinstance(plot_spec.quantity, str)  # noqa: S101 Use of `assert` detected
            quantity_col = plot_spec.quantity
            box_grouping_cols = [*grouping_cols]
        plot_data = prepare_data_for_box_plot(working_df, quantity_col, box_grouping_cols)
    elif plot_spec.visualization_type in (VizType.bar, VizType.heatmap, VizType.choropleth):
        plot_data = prepare_data_for_bar_plot(
            working_df,
            quantities,
            grouping_cols,
            plot_spec.aggregation_type,
            plot_spec.quantity_type,
        )
    elif plot_spec.visualization_type == VizType.hist:
        assert isinstance(plot_spec.quantity, str)  # noqa: S101 Use of `assert` detected
        plot_data = prepare_data_for_histogram_plot(working_df, plot_spec.quantity, grouping_cols)
    else:
        raise ValueError(f"Unsupported visualization type: {plot_spec.visualization_type}")

    return human_sort(plot_data.lazy(), grouping_cols).collect()


def _fill_missing_quantities(
    combined_df: pl.LazyFrame,
    quantities: list[str],
    enduse_group_mapping: dict[str, list[str]],
) -> pl.LazyFrame:
    """Ensure requested quantity columns exist by summing mapped constituents or zero-filling."""
    if not quantities:
        return combined_df

    current_cols: set[str] = set(combined_df.collect_schema().names())
    missing_cols: set[str] = set(quantities) - current_cols
    if not missing_cols:
        return combined_df

    mapping = enduse_group_mapping
    defined_cols = {q for q in missing_cols if q in mapping}
    not_found_cols = missing_cols - defined_cols

    # Map each defined quantity to its available constituents in the current dataframe
    avail_map: dict[str, list[str]] = {
        q: [c for c in mapping[q] if c in current_cols] for q in defined_cols
    }
    defined_all_missing = {q for q, cols in avail_map.items() if not cols}
    defined_partial_missing = {q for q, cols in avail_map.items() if cols and len(cols) < len(mapping[q])}
    defined_not_missing = {q for q, cols in avail_map.items() if len(cols) == len(mapping[q])}

    new_columns: list[pl.Expr] = []

    # Build sum expressions for groups with at least one available constituent
    for defined_col in (*sorted(defined_not_missing), *sorted(defined_partial_missing)):
        cols = avail_map[defined_col]
        new_columns.append(pl.sum_horizontal([pl.col(c) for c in cols]).alias(defined_col))

    # Emit warnings for partial availability
    for defined_col in sorted(defined_partial_missing):
        missing_set = set(mapping[defined_col]) - set(avail_map[defined_col])
        logger.warning(
            "Quantity group %s is defined but only some of the constituent are available. Missing constituents: %s",
            defined_col,
            missing_set,
        )

    # For defined groups with no available constituents: warn + zero-fill
    for defined_col in sorted(defined_all_missing):
        logger.warning(
            "Quantity group %s is defined but none of the constituent are available",
            defined_col,
        )
        new_columns.append(pl.lit(0, dtype=pl.Int32).alias(defined_col))

    # For completely undefined quantities: warn + zero-fill
    for not_found_col in sorted(not_found_cols):
        logger.warning(
            "Quantity %s is not available and is not a defined group in end_use_dict",
            not_found_col,
        )
        new_columns.append(pl.lit(0, dtype=pl.Int32).alias(not_found_col))

    return combined_df.with_columns(new_columns)


def _convert_quantity_type(
    combined_df: pl.LazyFrame,
    quantities: list[str],
    quantity_type: QuantityType,
) -> pl.LazyFrame:
    """Convert the values in ``combined_df`` according to the desired quantity type."""
    if not quantities:
        return combined_df

    if quantity_type in [QuantityType.absolute, QuantityType.model_count, QuantityType.prevalence]:
        return combined_df

    if quantity_type in [QuantityType.savings, QuantityType.percent_savings]:
        df = _attach_baseline(combined_df, quantities, join_key=BLDG_ID_COL)
        df = _compute_savings(df, quantities)
        if quantity_type == QuantityType.savings:
            return df.drop([f"baseline_{q}" for q in quantities])

        df = _compute_percent_savings(df, quantities)
        return df
    raise ValueError(f"Unsupported quantity type: {quantity_type}")


def _attach_baseline(
    lf: pl.LazyFrame,
    quantities: list[str],
    *,
    join_key: str = BLDG_ID_COL,
) -> pl.LazyFrame:
    """Attach baseline columns for quantities to the given LazyFrame."""
    if join_key not in lf.collect_schema().names():
        raise ValueError(f"'{join_key}' column not found in data - cannot compute savings per building.")
    baseline_cols = [join_key, *quantities]
    baseline_df = (
        lf.filter(pl.col(UPGRADE_COL) == 0)
        .select(baseline_cols)
        .rename({q: f"baseline_{q}" for q in quantities})
    )
    return lf.join(baseline_df, on=join_key, how="left", validate="m:1", maintain_order="left")


def _compute_savings(lf: pl.LazyFrame, quantities: list[str]) -> pl.LazyFrame:
    """Replace quantity columns with savings = baseline - value."""
    savings_exprs = [(pl.col(f"baseline_{q}") - pl.col(q)).alias(q) for q in quantities]
    return lf.with_columns(savings_exprs)


def _compute_percent_savings(lf: pl.LazyFrame, quantities: list[str]) -> pl.LazyFrame:
    """Convert savings columns into percent savings using safe non-zero baseline as denominator."""
    pct_exprs = [
        (100 * pl.col(q) / _safe_nonzero(pl.col(f"baseline_{q}"))).alias(q)
        for q in quantities
    ]
    return lf.with_columns(pct_exprs)


def _get_grouping_cols(plot_spec: PlotSpec) -> list[str]:
    grouping_cols = [UPGRADE_COL, UPGRADE_NAME_COL]
    if plot_spec.visualization_type == VizType.choropleth:
        grouping_cols.append("in.state")
    if plot_spec.group_by:
        grouping_cols.append(plot_spec.group_by)
    return grouping_cols


def _process_vacancy_inclusion(plot_spec: PlotSpec, combined_df: pl.LazyFrame) -> pl.LazyFrame:
    if plot_spec.vacancy_inclusion == VacancyInclusion.occupied_only:
        combined_df = combined_df.filter(pl.col(VACANCY_STATUS_COL) == "Occupied")
    return combined_df


def _process_building_inclusion(plot_spec: PlotSpec, combined_df: pl.LazyFrame) -> pl.LazyFrame:
    if plot_spec.building_inclusion == BuildingInclusion.applied_only:
        if plot_spec.upgrade is None:  # Applied in respective upgrades (No Baseline)
            combined_df = combined_df.filter(pl.col(APPLICABILITY_COL) & (pl.col(UPGRADE_COL) != 0))
        else:  # Applied in upgrade x (include baseline in this case)
            is_upgrade_applicable = (
                ((pl.col(UPGRADE_COL) == plot_spec.upgrade) & pl.col(APPLICABILITY_COL)).any().over(BLDG_ID_COL)
            )
            combined_df = combined_df.filter(
                ((pl.col(UPGRADE_COL) == plot_spec.upgrade) & pl.col(APPLICABILITY_COL))
                | ((pl.col(UPGRADE_COL) == 0) & is_upgrade_applicable)
            )

    return combined_df


def _process_upgrades_inclusion(
    plot_spec: PlotSpec,
    selected_upgrades: list[int] | None,
    combined_df: pl.LazyFrame,
) -> pl.LazyFrame:
    if selected_upgrades is not None:
        keep_upgrades = {0, *selected_upgrades}  # keep baseline because needed for certain calculations
        combined_df = combined_df.filter(pl.col(UPGRADE_COL).is_in(keep_upgrades))
    if plot_spec.upgrade is not None:
        combined_df = combined_df.filter(pl.col(UPGRADE_COL).is_in([0, plot_spec.upgrade]))
    return combined_df


def _get_quantities(plot_spec: PlotSpec) -> list[str]:
    quantities: list[str] = []
    if isinstance(plot_spec.quantity, str):
        quantities.append(plot_spec.quantity)
    elif isinstance(plot_spec.quantity, QuantityGroup):
        quantities.extend(plot_spec.quantity.constituents)
        if plot_spec.quantity.sum:
            quantities.append(plot_spec.quantity.sum)
    return quantities


def prepare_data_for_histogram_plot(
    combined_df: pl.LazyFrame,
    quantity: str,
    grouping_cols: list[str],
) -> pl.DataFrame:
    """
    Build a 102-bin histogram of `quantity` per (upgrade, upgrade_name[, group_by]).
    Every bin (-1, 0-99, 100) is present; empty bins have count == 0.
    """

    # ---------- 1. Percentile and absolute bounds (single pass) ----------
    q1, q99, minimum, maximum = (
        combined_df
        .select(
            pl.col(quantity).quantile(0.01, "midpoint").alias("q1"),
            pl.col(quantity).quantile(0.99, "midpoint").alias("q99"),
            pl.col(quantity).min().alias("minimum"),
            pl.col(quantity).max().alias("maximum"),
        )
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
    group_keys = [*grouping_cols, "bin"]
    counts = lf_binned.group_by(group_keys, maintain_order=True).agg(pl.count().alias("count"))

    # ---------- 4. Build full grid ----------
    full_bins = pl.Series("bin", [-1, *list(range(100)), 100], dtype=pl.Int32)

    groups = combined_df.select(grouping_cols).unique(maintain_order=True)

    grid = groups.lazy().join(pl.DataFrame({"bin": full_bins}).lazy(), how="cross", maintain_order="left")

    # ---------- 5. Merge counts → zerofill ----------
    hist_full = (
        grid.join(counts.lazy(), on=group_keys, how="left", maintain_order="left")
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
            *grouping_cols,
            "bin",
            "bin_left",
            "bin_right",
            "count",
        )
        .collect()
    )

    return hist_full


def prepare_data_for_box_plot(
    combined_df: pl.LazyFrame,
    quantity: str,
    grouping_cols: list[str],
    *,
    include_kde: bool = True,
    kde_points: int = 100,
) -> pl.DataFrame:
    """Compute box-and-whisker statistics (and optional KDE) for grouped values."""

    max_items_per_group = max(
        combined_df.group_by(grouping_cols).agg(pl.len()).collect()["len"].to_list()
    )
    if max_items_per_group < 30000:
        cutoff = 0.01  # Upto 30K datapoints, show 1% outliers
    elif max_items_per_group < 100000:
        cutoff = 0.001  # Upto 100K datapoints, show 0.1% outliers
    else:
        cutoff = 0.0001  # very large groups, use 0.01% outliers

    lazy = (
        combined_df.fill_null(0)
        .group_by(grouping_cols, maintain_order=True)
        .agg(
            pl.col(quantity).alias("vals"),
            pl.col(BLDG_ID_COL).alias("bldg_ids"),
            pl.col(quantity).min().alias("min"),
            pl.col(quantity).quantile(cutoff).alias("lower_cutoff"),
            pl.col(quantity).quantile(0.25).alias("q1"),
            pl.col(quantity).median().alias("median"),
            pl.col(quantity).quantile(0.75).alias("q3"),
            pl.col(quantity).quantile(1 - cutoff).alias("upper_cutoff"),
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

    # Raw vectors no longer needed
    return df.drop(["vals", "bldg_ids"]).with_columns(
        [
            pl.col("lower_whisker").cast(pl.Float64),
            pl.col("upper_whisker").cast(pl.Float64),
        ]
    )


def prepare_data_for_prevalence_plot(
    combined_df: pl.LazyFrame,
    quantity: str | QuantityGroup,
    quantity_group_name: str,
    grouping_cols: list[str],
) -> pl.DataFrame:
    """
    Prepare data for prevalence plotting by grouping and counting.

    Args:
        combined_df: Combined DataFrame containing all data.
        quantity: Quantity or QuantityGroup to filter by.
        quantity_group_name: Column containing the category labels.
        grouping_cols: Columns that define the group keys (upgrade, upgrade_name, etc.).

    Returns:
        DataFrame with prevalence percentages per group/category.
    """
    combined_df = combined_df.with_columns(pl.col(quantity_group_name).cast(pl.String))
    full_df = _get_full_cross_product_df(combined_df, [*grouping_cols[1:], quantity_group_name])
    count_df = combined_df.group_by([*grouping_cols, quantity_group_name]).agg(pl.count().alias("model_count"))
    count_df = full_df.join(count_df, on=[*grouping_cols[1:], quantity_group_name], how="left").fill_null(0)
    group_total_df = combined_df.group_by(grouping_cols).agg(pl.count().alias("total_count"))
    count_df = count_df.join(group_total_df, on=grouping_cols, how="left").fill_null(1e-9)  # Avoid 0/0
    count_df = count_df.with_columns(
        (pl.col("model_count") / pl.col("total_count") * 100).round(2).alias("prevalence")
    ).drop("total_count")
    if isinstance(quantity, str):
        count_df = count_df.filter(pl.col(quantity_group_name).str.to_lowercase() == quantity.lower())
    else:
        valid_cats = {cat.lower() for cat in quantity.constituents}
        count_df = count_df.filter(pl.col(quantity_group_name).str.to_lowercase().is_in(valid_cats))
    return human_sort(count_df, [*grouping_cols, quantity_group_name]).collect()


def _get_full_cross_product_df(combined_df: pl.LazyFrame, cols: Sequence[str]) -> pl.LazyFrame:
    unique_dfs = [combined_df.select(pl.col(col)).unique() for col in cols]
    full_df = unique_dfs[0]
    for next_df in unique_dfs[1:]:
        full_df = full_df.join(next_df, how="cross")
    return full_df


def prepare_data_for_bar_plot(
    combined_df: pl.LazyFrame,
    quantities: list[str],
    grouping_cols: Sequence[str],
    aggregation_type: AggregationType,
    quantity_type: QuantityType,
) -> pl.DataFrame:
    """
    Prepare data for bar plotting by grouping and aggregating.

    Args:
        combined_df: Combined DataFrame containing all data
        quantities: List of quantities to plot
        grouping_cols: Columns to group by
        aggregation_type: Whether to calculate average or sum
        quantity_type: Whether to calculate absolute or savings

    Returns:
        DataFrame prepared for plotting with all requested quantities.
    """
    if not quantities:
        raise ValueError("At least one quantity is required for bar plots.")

    # Preserve order while removing potential duplicates
    grouping_cols = list(dict.fromkeys(grouping_cols))
    columns_to_select = grouping_cols + quantities + ["model_count"]

    if quantity_type == QuantityType.model_count:
        agg_exprs = [pl.col(quantity).count().alias(quantity) for quantity in quantities]
    elif aggregation_type == AggregationType.average and quantity_type == QuantityType.percent_savings:
        # Calculate weighted average of percent savings using baseline values as weights
        agg_exprs = [
            (
                (pl.col(quantity) * _safe_nonzero(pl.col(f"baseline_{quantity}"))).sum()
                / _safe_nonzero(pl.col(f"baseline_{quantity}").sum())
            ).alias(quantity)
            for quantity in quantities
        ]
    elif aggregation_type == AggregationType.total and quantity_type == QuantityType.percent_savings:
        raise ValueError("Percent savings can only be aggregated as weighted average")
    elif aggregation_type == AggregationType.average:
        agg_exprs = [pl.col(quantity).mean().alias(quantity) for quantity in quantities]
    elif aggregation_type == AggregationType.total:
        agg_exprs = [(pl.col(quantity) * pl.col(WEIGHT_COL)).sum().alias(quantity) for quantity in quantities]
    else:
        raise ValueError(f"Unsupported value type: {aggregation_type}")
    agg_exprs.append(pl.col(BLDG_ID_COL).count().alias("model_count"))
    result = combined_df.group_by(grouping_cols, maintain_order=True).agg(agg_exprs)
    result = result.select(columns_to_select)
    return result.collect()
