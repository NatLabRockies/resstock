"""Tests for the published column dtypes produced by simulation_outputs."""

import polars as pl

from resstockpostproc.simulation_outputs import adjust_col_dtypes

# The seven in.* columns that reach the publication as integers: six
# makeIntegerArgument arguments on the BuildExistingModel measure, plus
# units_represented, which buildstockbatch casts with int(). SightGlass rejects any
# in.* column that Athena reads as BIGINT, so these must be published as strings.
INT_CHARACTERISTIC_COLS = [
    "in.units_represented",
    "in.simulation_control_run_period_begin_day_of_month",
    "in.simulation_control_run_period_begin_month",
    "in.simulation_control_run_period_calendar_year",
    "in.simulation_control_run_period_end_day_of_month",
    "in.simulation_control_run_period_end_month",
    "in.simulation_control_timestep",
]


def _sample_df() -> pl.LazyFrame:
    data = {
        "upgrade": pl.Series([0, 0], dtype=pl.Int64),
        "bldg_id": pl.Series([1, 2], dtype=pl.Int64),
        # A characteristic that already comes from a TSV as a string
        "in.bedrooms": pl.Series(["3", "4"], dtype=pl.String),
        # A genuinely numeric characteristic, which SightGlass allows as a float
        "in.sqft..ft2": pl.Series([1200.0, 900.0], dtype=pl.Float64),
        "in.has_pv": pl.Series([True, False], dtype=pl.Boolean),
        "out.electricity.total..kwh": pl.Series([10, 20], dtype=pl.Int64),
    }
    for col in INT_CHARACTERISTIC_COLS:
        data[col] = pl.Series([1, 1], dtype=pl.Int64)
    return pl.LazyFrame(data)


def test_integer_characteristics_are_published_as_strings():
    schema = adjust_col_dtypes(_sample_df()).collect_schema()
    for col in INT_CHARACTERISTIC_COLS:
        assert schema[col] == pl.String, f"{col} must not be published as an integer"


def test_boolean_characteristics_are_published_as_yes_no():
    df = adjust_col_dtypes(_sample_df()).collect()
    assert df.schema["in.has_pv"] == pl.String
    # "Yes"/"No" rather than polars' "true"/"false", matching the published enumerations
    assert df["in.has_pv"].to_list() == ["Yes", "No"]


def test_null_characteristics_stay_null():
    df = pl.LazyFrame(
        {
            "upgrade": pl.Series([0], dtype=pl.Int64),
            "in.units_represented": pl.Series([None], dtype=pl.Int64),
            "in.has_pv": pl.Series([None], dtype=pl.Boolean),
        }
    )
    out = adjust_col_dtypes(df).collect()
    assert out["in.units_represented"].to_list() == [None]
    assert out["in.has_pv"].to_list() == [None]


def test_other_columns_are_untouched():
    out = adjust_col_dtypes(_sample_df()).collect()
    # Integer output columns are unaffected -- the rule is specific to in.*
    assert out.schema["out.electricity.total..kwh"] == pl.Int64
    # Float characteristics stay floats; SightGlass only rejects bigints and booleans
    assert out.schema["in.sqft..ft2"] == pl.Float64
    # String characteristics are passed through unchanged
    assert out["in.bedrooms"].to_list() == ["3", "4"]
    # upgrade and bldg_id are required to be Athena bigints
    assert out.schema["upgrade"] == pl.Int64
    assert out.schema["bldg_id"] == pl.Int64


def test_column_order_is_preserved():
    before = _sample_df().collect_schema().names()
    after = adjust_col_dtypes(_sample_df()).collect_schema().names()
    assert before == after
