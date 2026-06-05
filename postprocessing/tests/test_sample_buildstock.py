import pandas as pd
import numpy as np
from pathlib import Path
import pytest

from resstockpostproc.sample_buildstock import calculate_sample_size, downselect_buildstock


@pytest.fixture
def sample_df():
    """Create a synthetic buildstock DataFrame for testing."""
    rng = np.random.default_rng(42)
    n = 500
    return pd.DataFrame({
        "Building": range(1, n + 1),
        "Geometry Building Type RECS": ["Single-Family Detached"] * n,
        "HVAC Has Ducts": ["Yes"] * n,
        "HVAC Shared Efficiencies": ["None"] * n,
        "ASHRAE IECC Climate Zone 2004": rng.choice(["4A", "5A", "3A"], size=n, p=[0.5, 0.3, 0.2]),
        "Heating Fuel": rng.choice(["Natural Gas", "Electricity"], size=n, p=[0.6, 0.4]),
        "Geometry Floor Area": rng.choice(["1500-1999", "2000-2499", "2500-2999"], size=n),
        "Vintage": rng.choice(["1980s", "1990s", "2000s"], size=n),
    })


class TestCalculateSampleSize:
    def test_sum_equals_max_units(self, sample_df):
        maintain_params = ["ASHRAE IECC Climate Zone 2004"]
        max_units = 100
        result = calculate_sample_size(sample_df, maintain_params, max_units)
        assert result.sum() == max_units

    def test_sum_equals_max_units_multi_params(self, sample_df):
        maintain_params = ["ASHRAE IECC Climate Zone 2004", "Heating Fuel"]
        max_units = 200
        result = calculate_sample_size(sample_df, maintain_params, max_units)
        assert result.sum() == max_units

    def test_all_values_non_negative(self, sample_df):
        maintain_params = ["ASHRAE IECC Climate Zone 2004"]
        max_units = 100
        result = calculate_sample_size(sample_df, maintain_params, max_units)
        assert (result >= 0).all()

    def test_proportions_approximately_maintained(self, sample_df):
        maintain_params = ["ASHRAE IECC Climate Zone 2004"]
        max_units = 200
        result = calculate_sample_size(sample_df, maintain_params, max_units)

        original_proportions = sample_df.groupby(maintain_params).size() / len(sample_df)
        sampled_proportions = result / result.sum()

        # Proportions should be close (within 5% absolute difference)
        diff = (original_proportions - sampled_proportions).abs()
        assert (diff < 0.05).all()


class TestDownselectBuildstock:
    def test_output_file_created(self, sample_df, tmp_path):
        input_path = tmp_path / "buildstock.csv"
        sample_df.to_csv(input_path, index=False)
        output_path = tmp_path / "output.csv"

        downselect_buildstock(
            str(input_path),
            output_path=str(output_path),
            max_units=100,
            maintain_params=["ASHRAE IECC Climate Zone 2004"],
        )

        assert output_path.exists()

    def test_output_respects_max_units(self, sample_df, tmp_path):
        input_path = tmp_path / "buildstock.csv"
        sample_df.to_csv(input_path, index=False)
        output_path = tmp_path / "output.csv"

        max_units = 100
        downselect_buildstock(
            str(input_path),
            output_path=str(output_path),
            max_units=max_units,
            maintain_params=["ASHRAE IECC Climate Zone 2004"],
        )

        result = pd.read_csv(output_path)
        assert len(result) == max_units

    def test_no_sampling_when_below_max(self, sample_df, tmp_path):
        input_path = tmp_path / "buildstock.csv"
        sample_df.to_csv(input_path, index=False)
        output_path = tmp_path / "output.csv"

        downselect_buildstock(
            str(input_path),
            output_path=str(output_path),
            max_units=1000,
            maintain_params=["ASHRAE IECC Climate Zone 2004"],
        )

        result = pd.read_csv(output_path)
        assert len(result) == len(sample_df)

    def test_default_output_path(self, sample_df, tmp_path):
        input_path = tmp_path / "buildstock.csv"
        sample_df.to_csv(input_path, index=False)

        downselect_buildstock(
            str(input_path),
            max_units=100,
            maintain_params=["ASHRAE IECC Climate Zone 2004"],
        )

        expected_output = tmp_path / "downselected_buildstock.csv"
        assert expected_output.exists()

    def test_multi_param_sampling(self, sample_df, tmp_path):
        input_path = tmp_path / "buildstock.csv"
        sample_df.to_csv(input_path, index=False)
        output_path = tmp_path / "output.csv"

        maintain_params = ["ASHRAE IECC Climate Zone 2004", "Heating Fuel"]
        max_units = 150
        downselect_buildstock(
            str(input_path),
            output_path=str(output_path),
            max_units=max_units,
            maintain_params=maintain_params,
        )

        result = pd.read_csv(output_path)
        assert len(result) == max_units

    def test_reproducibility(self, sample_df, tmp_path):
        input_path = tmp_path / "buildstock.csv"
        sample_df.to_csv(input_path, index=False)
        output1 = tmp_path / "output1.csv"
        output2 = tmp_path / "output2.csv"

        kwargs = dict(
            max_units=100,
            maintain_params=["ASHRAE IECC Climate Zone 2004"],
            random_state=42,
        )
        downselect_buildstock(str(input_path), output_path=str(output1), **kwargs)
        downselect_buildstock(str(input_path), output_path=str(output2), **kwargs)

        df1 = pd.read_csv(output1)
        df2 = pd.read_csv(output2)
        pd.testing.assert_frame_equal(df1, df2)
