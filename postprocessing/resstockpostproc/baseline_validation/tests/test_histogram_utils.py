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

        # Overflow bin is the final bin index and should capture at least one row here.
        overflow_count = out.filter(pl.col("bin") == 49)["count"].sum()
        assert overflow_count > 0

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
