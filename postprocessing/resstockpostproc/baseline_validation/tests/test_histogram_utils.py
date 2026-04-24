"""Tests for weighted histogram binning utilities."""

import polars as pl
import pytest

from resstockpostproc.shared_utils.histogram_utils import build_weighted_histogram_with_overflow


class TestBuildWeightedHistogramWithOverflow:
    def test_exact_bin_count_and_overflow(self):
        data = pl.DataFrame(
            {
                "source": ["recs_2020"] * 5 + ["resstock_2025"] * 5,
                "value": [0.0, 10.0, 20.0, 30.0, 500.0, 0.0, 5.0, 15.0, 25.0, 600.0],
                "weight": [1.0] * 10,
            }
        )
        out = build_weighted_histogram_with_overflow(data, n_core_bins=49)

        for source in ["recs_2020", "resstock_2025"]:
            sub = out.filter(pl.col("source") == source)
            assert len(sub) == 50
            assert sub["bin"].min() == 0
            assert sub["bin"].max() == 49
            assert sub["count_pct"].sum() == pytest.approx(100.0, abs=1e-9)

        # Overflow bin is always present as the final bin index, though step cutoffs
        # may legitimately leave it empty for some inputs.
        overflow_rows = out.filter(pl.col("bin") == 49)
        assert len(overflow_rows) == 2

    def test_weighted_counts_are_preserved_per_source(self):
        data = pl.DataFrame(
            {
                "source": ["recs_2020", "recs_2020", "resstock_2025", "resstock_2025"],
                "value": [1.0, 2.0, 1.0, 2.0],
                "weight": [2.0, 3.0, 10.0, 30.0],
            }
        )
        out = build_weighted_histogram_with_overflow(data, n_core_bins=49)

        totals = out.group_by("source").agg(pl.col("count").sum().alias("total_weight"))
        recs_total = totals.filter(pl.col("source") == "recs_2020")["total_weight"].item()
        rs_total = totals.filter(pl.col("source") == "resstock_2025")["total_weight"].item()

        assert recs_total == pytest.approx(5.0)
        assert rs_total == pytest.approx(40.0)

        pct_totals = out.group_by("source").agg(pl.col("count_pct").sum().alias("pct"))
        assert pct_totals.filter(pl.col("source") == "recs_2020")["pct"].item() == pytest.approx(100.0)
        assert pct_totals.filter(pl.col("source") == "resstock_2025")["pct"].item() == pytest.approx(100.0)

    def test_geometry_cols_share_one_overflow_across_groups(self):
        data = pl.DataFrame(
            {
                "group": ["A"] * 10 + ["B"] * 10,
                "source": (["recs_2020"] * 5 + ["resstock_2025"] * 5) * 2,
                "value": [
                    0.0,
                    10.0,
                    20.0,
                    30.0,
                    500.0,
                    0.0,
                    5.0,
                    15.0,
                    25.0,
                    600.0,
                    0.0,
                    100.0,
                    200.0,
                    300.0,
                    5000.0,
                    0.0,
                    30.0,
                    60.0,
                    90.0,
                    400.0,
                ],
                "weight": [
                    1.0,
                    2.0,
                    3.0,
                    4.0,
                    5.0,
                    6.0,
                    7.0,
                    8.0,
                    9.0,
                    10.0,
                    11.0,
                    12.0,
                    13.0,
                    14.0,
                    15.0,
                    16.0,
                    17.0,
                    18.0,
                    19.0,
                    20.0,
                ],
            }
        )

        out = build_weighted_histogram_with_overflow(
            data,
            group_cols=["group"],
            geometry_cols=[],
            n_core_bins=4,
        )

        overflow = out.filter(pl.col("bin") == 4)
        assert overflow["bin_left"].n_unique() == 1

        width_min, width_max = (
            out.filter(pl.col("bin") != 4)
            .select(
                (pl.col("bin_right") - pl.col("bin_left")).min().alias("min_width"),
                (pl.col("bin_right") - pl.col("bin_left")).max().alias("max_width"),
            )
            .row(0)
        )
        assert width_min == pytest.approx(width_max)

        totals = out.group_by(["group", "source"]).agg(
            pl.col("count").sum().alias("total_weight"),
            pl.col("count_pct").sum().alias("pct"),
        )
        expected = data.group_by(["group", "source"]).agg(pl.col("weight").sum().alias("expected_weight"))
        joined = totals.join(expected, on=["group", "source"], how="inner")

        for row in joined.iter_rows(named=True):
            assert row["total_weight"] == pytest.approx(row["expected_weight"])
            assert row["pct"] == pytest.approx(100.0)

    def test_geometry_source_uses_weighted_recs_cutoff_and_source_specific_overflow_range(self):
        data = pl.DataFrame(
            {
                "source": ["recs_2020"] * 3 + ["resstock_2025"] * 3,
                "value": [10.0, 100.0, 200.0, 10.0, 150.0, 300.0],
                "weight": [98.0, 1.0, 1.0, 1.0, 1.0, 1.0],
            }
        )

        out = build_weighted_histogram_with_overflow(
            data,
            geometry_source="recs_2020",
            n_core_bins=4,
        )

        overflow = out.filter(pl.col("bin") == 4)
        assert overflow["bin_left"].n_unique() == 1
        assert overflow["bin_left"].unique().item() == pytest.approx(10.0)

        recs_overflow = overflow.filter(pl.col("source") == "recs_2020")
        resstock_overflow = overflow.filter(pl.col("source") == "resstock_2025")
        assert recs_overflow["bin_right"].item() == pytest.approx(200.0)
        assert resstock_overflow["bin_right"].item() == pytest.approx(300.0)
        assert recs_overflow["count_pct"].item() == pytest.approx(2.0)

        core_widths = out.filter(pl.col("bin") != 4).select((pl.col("bin_right") - pl.col("bin_left")).alias("width"))
        assert core_widths["width"].n_unique() == 1
        assert core_widths["width"].unique().item() == pytest.approx(2.5)

    def test_step_quantile_two_point_example_keeps_overflow_at_zero(self):
        data = pl.DataFrame(
            {
                "source": ["recs_2020", "recs_2020", "resstock_2025", "resstock_2025"],
                "value": [0.0, 100.0, 0.0, 200.0],
                "weight": [97.66, 2.34, 1.0, 1.0],
            }
        )

        out = build_weighted_histogram_with_overflow(
            data,
            geometry_source="recs_2020",
            n_core_bins=4,
        )

        overflow = out.filter(pl.col("bin") == 4)
        assert overflow["bin_left"].n_unique() == 1
        assert overflow["bin_left"].unique().item() == pytest.approx(100.0)

        recs_overflow = overflow.filter(pl.col("source") == "recs_2020")
        assert recs_overflow["count_pct"].item() == pytest.approx(0.0)

    def test_recs_geometry_avoids_pooled_overflow_skew(self):
        recs_values = list(range(100))
        pooled_resstock_values = list(range(50)) * 20
        data = pl.DataFrame(
            {
                "source": ["recs_2020"] * len(recs_values) + ["resstock_2025"] * len(pooled_resstock_values),
                "value": recs_values + pooled_resstock_values,
                "weight": [1.0] * (len(recs_values) + len(pooled_resstock_values)),
            }
        )

        pooled = build_weighted_histogram_with_overflow(
            data,
            n_core_bins=49,
        )
        anchored = build_weighted_histogram_with_overflow(
            data,
            geometry_source="recs_2020",
            n_core_bins=49,
        )

        pooled_recs_overflow = pooled.filter((pl.col("source") == "recs_2020") & (pl.col("bin") == 49))[
            "count_pct"
        ].item()
        anchored_recs_overflow = anchored.filter((pl.col("source") == "recs_2020") & (pl.col("bin") == 49))[
            "count_pct"
        ].item()

        assert pooled_recs_overflow > 15.0
        assert anchored_recs_overflow <= 2.0 + 1e-9

    def test_step_quantile_caps_recs_overflow_below_top_jump(self):
        data = pl.DataFrame(
            {
                "source": ["recs_2020"] * 3 + ["resstock_2025"] * 3,
                "value": [0.0, 100.0, 200.0, 0.0, 100.0, 200.0],
                "weight": [97.66, 1.0, 1.34, 1.0, 1.0, 1.0],
            }
        )

        out = build_weighted_histogram_with_overflow(
            data,
            geometry_source="recs_2020",
            n_core_bins=4,
        )

        recs_overflow = out.filter((pl.col("source") == "recs_2020") & (pl.col("bin") == 4))["count_pct"].item()
        assert recs_overflow == pytest.approx(1.34)
