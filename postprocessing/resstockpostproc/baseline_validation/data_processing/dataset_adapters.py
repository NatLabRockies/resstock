"""Reference-dataset loaders that pair source data with ResStock data for percent-difference computation."""

import polars as pl

from resstockpostproc.baseline_validation.schema.plot_spec import (
    DataKey,
    Resolution,
    Metric,
    CoverageType,
)
from resstockpostproc.baseline_validation.io_managers import get_eia_data
from resstockpostproc.baseline_validation.io_managers import get_recs_data
from resstockpostproc.baseline_validation.io_managers import get_resstock_data
from resstockpostproc.baseline_validation.io_managers import get_lrd_data
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.shared_utils.mapping import UtilityName2ID


def load_eia(io_data_key: DataKey) -> tuple[pl.DataFrame, pl.DataFrame, list[str]]:
    """Load EIA reference + ResStock data and the join-groups for percent_difference."""
    io_group_by = io_data_key.effective_group_by
    resolution = io_data_key.resolution
    by = "state" if "state" in io_group_by else "eiaid"
    assert by in ["state", "eiaid"], "EIA data only supports group_by='state' or group_by='eiaid'."
    if resolution == Resolution.month:
        source_data = get_eia_data.get_monthly_all(
            data_key=io_data_key, years=workflow.reference_years.get("eia", [2018])
        )
        resstock_data = get_resstock_data.get_timeseries_all(data_key=io_data_key)
        groups = [by, "month"]
    else:
        assert resolution == Resolution.year, "EIA data only supports 'year' or 'month' resolutions."
        source_data = get_eia_data.get_annual_all(
            data_key=io_data_key, years=workflow.reference_years.get("eia", [2018])
        )
        resstock_data = get_resstock_data.get_annual_all(data_key=io_data_key)
        groups = [by]
    return source_data, resstock_data, groups


def load_recs(io_data_key: DataKey) -> tuple[pl.DataFrame, pl.DataFrame, list[str]]:
    """Load RECS reference + ResStock data and the join-groups for percent_difference."""
    io_group_by = io_data_key.effective_group_by
    resolution = io_data_key.resolution
    if resolution == Resolution.month:
        assert len(io_group_by) == 1, "RECS monthly only supports single-column groupby."
        source_data = get_recs_data.get_monthly_all(data_key=io_data_key, year=2020)
        resstock_data = get_resstock_data.get_timeseries_all(data_key=io_data_key, occupied_only=True)
        groups = ["state", "month"]
    else:
        assert resolution == Resolution.year, "RECS data only supports 'year' or 'month' resolutions."
        source_data = get_recs_data.get_annual_all(data_key=io_data_key, year=2020)
        resstock_data = get_resstock_data.get_annual_all(data_key=io_data_key, occupied_only=True)
        groups = list(io_group_by)
    return source_data, resstock_data, groups


def load_lrd(io_data_key: DataKey) -> tuple[pl.DataFrame, pl.DataFrame | None, list[str]]:
    """Load LRD reference + ResStock data and the join-groups for percent_difference."""
    resolution = io_data_key.resolution
    assert io_data_key.aggregation_type == Metric.average, "LRD only supports 'average' aggregation"
    assert io_data_key.coverage == CoverageType.all_units, "LRD only supports 'all_units' coverage"
    eiaidlist = tuple([str(eiaid) for eiaid in UtilityName2ID.values()])
    source_data = get_lrd_data.get_lrd_aggregated(year=2018, resolution=resolution, restrict_list=eiaidlist)
    if resolution == Resolution.year:
        resstock_data = get_resstock_data.get_annual_all(data_key=io_data_key)
        groups = ["eiaid"]
    elif resolution == Resolution.hour_of_day_matrix:
        resstock_data = get_resstock_data.get_timeseries_all(data_key=io_data_key, restrict_list=eiaidlist)
        groups = ["eiaid", "month", "day_type", "hour of day"]
    else:
        resstock_data = get_resstock_data.get_timeseries_all(data_key=io_data_key, restrict_list=eiaidlist)
        groups = ["eiaid", resolution]
    return source_data, resstock_data, groups
