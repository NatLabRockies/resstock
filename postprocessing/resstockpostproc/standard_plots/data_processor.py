"""
Data processor module for standard plots
-----------------------------------------
Handles transformation and processing of simulation result data using Polars
"""

import logging
import math

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


class DataProcessor:
    """
    Processes simulation result data for plotting
    """

    def __init__(self, combined_df: pl.LazyFrame, enduse_group_mapping: dict[str, list[str]] = EnduseGroupToEnduses):
        """
        Initialize the data processor with pre-loaded data

        Args:
            combined_df: Pre-loaded LazyFrame from InputManager containing all upgrade data
        """
        self.combined_df = combined_df
        self.enduse_group_mapping = enduse_group_mapping.copy()

    def _fill_missing_quantities(self, combined_df: pl.LazyFrame, quantities: list[str]) -> pl.LazyFrame:
        """
        Fills missing quantity columns in a LazyFrame. If a quantity can be
        calculated by summing existing columns, it does so. Otherwise, it fills
        the quantity with 0.
        """
        # Work off of the provided LazyFrame's current schema
        current_cols: set[str] = set(combined_df.collect_schema().names())
        missing_quantity_cols: set[str] = set(quantities) - current_cols

        if not missing_quantity_cols:
            return combined_df

        # They could be either be defined in enduse_group_mapping
        defined_quantity = [quantity for quantity in missing_quantity_cols if quantity in self.enduse_group_mapping]
        truly_missing_quantity = [quantity for quantity in missing_quantity_cols if quantity not in defined_quantity]
        new_column_exprs = []
        used_cols = []  # which of the cols in combined_df are used to calculate the missing quantity
        for quantity in defined_quantity:
            available_constituent_cols = [col for col in self.enduse_group_mapping[quantity] if col in current_cols]
            missing_constituent_cols = set(self.enduse_group_mapping[quantity]) - set(available_constituent_cols)
            if available_constituent_cols:
                expression = pl.sum_horizontal([pl.col(c) for c in available_constituent_cols]).alias(quantity)
                new_column_exprs.append(expression)
                used_cols.extend(available_constituent_cols)
                if missing_constituent_cols:
                    logger.warning(
                        f"Quantity group {quantity} is defined but only some of the constituent are available. "
                        f"Missing constituents: {missing_constituent_cols}"
                    )
            else:
                logger.warning(f"Quantity group {quantity} is defined but none of the constituent are available")
                expression = pl.lit(0, dtype=pl.Int32).alias(quantity)
                new_column_exprs.append(expression)
        # Or they are truly missing. If they are truly missing, we will fill them with 0
        for quantity in truly_missing_quantity:
            logger.warning(f"Quantity {quantity} is not available and is not a defined group in end_use_dict")
            expression = pl.lit(0, dtype=pl.Int32).alias(quantity)
            new_column_exprs.append(expression)

        return combined_df.with_columns(new_column_exprs)

    def _convert_quantity_type(
        self, quantities: list[str], quantity_type: QuantityType, combined_df: pl.LazyFrame
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
            return combined_df

        if quantity_type in [QuantityType.savings, QuantityType.percent_savings]:
            df = self._attach_baseline(combined_df, quantities, join_key="bldg_id")
            df = self._compute_savings(df, quantities)
            if quantity_type == QuantityType.savings:
                return df.drop([f"baseline_{q}" for q in quantities])

            df = self._compute_percent_savings(df, quantities)
            return df
        raise ValueError(f"Unsupported quantity type: {quantity_type}")

    def _attach_baseline(
        self,
        lf: pl.LazyFrame,
        quantities: list[str],
        *,
        join_key: str = BLDG_ID_COL,
    ) -> pl.LazyFrame:
        """Attach baseline columns for quantities to the given LazyFrame.

        Produces columns named baseline_<q> via a left join on the join_key.
        """
        if join_key not in lf.collect_schema().names():
            raise ValueError(f"'{join_key}' column not found in data - cannot compute savings per building.")
        baseline_cols = [join_key, *quantities]
        baseline_df = (
            lf.filter(pl.col(UPGRADE_COL) == 0)
            .select(baseline_cols)
            .rename({q: f"baseline_{q}" for q in quantities})
        )
        return lf.join(baseline_df, on=join_key, how="left", validate="m:1", maintain_order='left')

    def _compute_savings(self, lf: pl.LazyFrame, quantities: list[str]) -> pl.LazyFrame:
        """Replace quantity columns with savings = baseline - value."""
        savings_exprs = [(pl.col(f"baseline_{q}") - pl.col(q)).alias(q) for q in quantities]
        return lf.with_columns(savings_exprs)

    def _compute_percent_savings(self, lf: pl.LazyFrame, quantities: list[str]) -> pl.LazyFrame:
        """Convert savings columns into percent savings using safe non-zero baseline as denominator."""
        pct_exprs = [
            (100 * pl.col(q) / _safe_nonzero(pl.col(f"baseline_{q}"))).alias(q)
            for q in quantities
        ]
        return lf.with_columns(pct_exprs)

    def prepare_data_for_plot(self, plot_spec: PlotSpec, *, selected_upgrades: list[int] | None = None) -> pl.DataFrame:
        """
        Prepare data for plotting by grouping and aggregating using mean

        Args:
            plot_spec: PlotSpec object containing the plot configuration
            selected_upgrades: Optional list of upgrades to include in the plot. If None, include all upgrades.

        Returns:
            DataFrame prepared for plotting with aggregated (mean) values
        """

        quantities = self._get_quantities(plot_spec)

        combined_df = self._fill_missing_quantities(self.combined_df, quantities)
        combined_df = self._convert_quantity_type(quantities, plot_spec.quantity_type, combined_df)
        combined_df = self._process_upgrades_inclusion(plot_spec, selected_upgrades, combined_df)
        combined_df = self._process_building_inclusion(plot_spec, combined_df)
        combined_df = self._process_vacancy_inclusion(plot_spec, combined_df)

        if plot_spec.quantity_type in [QuantityType.savings, QuantityType.percent_savings]:
            # baseline should not be included when plotting savings
            combined_df = combined_df.filter(pl.col(UPGRADE_COL) != 0)

        if plot_spec.visualization_type == VizType.box:
            if not isinstance(plot_spec.quantity, str):
                combined_df = combined_df.unpivot(
                    quantities,
                    index=[UPGRADE_COL, UPGRADE_NAME_COL, BLDG_ID_COL],
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

    def _process_vacancy_inclusion(self, plot_spec, combined_df):
        if plot_spec.vacancy_inclusion == VacancyInclusion.occupied_only:
            combined_df = combined_df.filter(pl.col(VACANCY_STATUS_COL) == "Occupied")
        return combined_df

    def _process_building_inclusion(self, plot_spec, combined_df):
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

    def _process_upgrades_inclusion(self, plot_spec, selected_upgrades, combined_df):
        if selected_upgrades is not None:
            keep_upgrades = set([0, *selected_upgrades])  # keep baseline because needed for certain calculations
            combined_df = combined_df.filter(pl.col(UPGRADE_COL).is_in(keep_upgrades))
        if plot_spec.upgrade is not None:
            combined_df = combined_df.filter(pl.col(UPGRADE_COL).is_in([0, plot_spec.upgrade]))
        return combined_df

    @classmethod
    def _get_quantities(cls, plot_spec):
        quantities = []
        if isinstance(plot_spec.quantity, str):
            quantities.append(plot_spec.quantity)
        elif isinstance(plot_spec.quantity, QuantityGroup):
            quantities.extend(plot_spec.quantity.constituents)
            if plot_spec.quantity.sum:
                quantities.append(plot_spec.quantity.sum)
        return quantities

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
        group_keys = [UPGRADE_COL, UPGRADE_NAME_COL, group_by, "bin"] if group_by else [UPGRADE_COL, UPGRADE_NAME_COL, "bin"]
        counts = lf_binned.group_by(group_keys, maintain_order=True).agg(pl.count().alias("count"))

        # ---------- 4. Build full grid ----------
        full_bins = pl.Series("bin", [-1, *list(range(100)), 100], dtype=pl.Int32)

        groups = combined_df.select(UPGRADE_COL, UPGRADE_NAME_COL, *(group_by,) if group_by else ()).unique(
            maintain_order=True
        )

        grid = groups.lazy().join(pl.DataFrame({"bin": full_bins}).lazy(), how="cross", maintain_order='left')

        # ---------- 5. Merge counts → zerofill ----------
        hist_full = (
            grid.join(counts.lazy(), on=group_keys, how="left", maintain_order='left')
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
                UPGRADE_COL,
                UPGRADE_NAME_COL,
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

        # ─── 1. keys ──────────────────────────────────────────────────────────────
        gcols = [UPGRADE_COL, UPGRADE_NAME_COL]
        if group_by:
            gcols.append(group_by)
        max_items_per_group = max(combined_df.group_by(gcols).agg(pl.len()).collect()['len'].to_list())
        if max_items_per_group < 30000:
            cutoff = 0.01  # Upto 30K datapoints, show 1% outliers
        elif max_items_per_group < 100000:
            cutoff = 0.001  # Upto 100K datapoints, show 0.1% outliers
        else:
            cutoff = 0.0001  # very large groups, use 0.01% outliers
        lazy = (
            combined_df.fill_null(0)
            .group_by(gcols, maintain_order=True)
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

        grouping_cols = [UPGRADE_COL, UPGRADE_NAME_COL]
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
