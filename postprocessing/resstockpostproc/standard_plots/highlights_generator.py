"""
Generation utilities for highlight plots.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Literal
from collections.abc import Iterable, Sequence

from plotly.graph_objects import Figure

from resstockpostproc.standard_plots.all_plots_generator import get_plotting_function
from resstockpostproc.standard_plots.data_processing.data_processor import prepare_data_for_plot
from resstockpostproc.standard_plots.io_managers.input_manager import download_data, load_data
from resstockpostproc.standard_plots.io_managers.output_manager import (
    get_plot_base_dir,
    write_html_file,
    write_svg_file,
    write_workflow_snapshot,
)
from resstockpostproc.standard_plots.utils import load_highlight_config, load_workflow_config
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import (
    AggregationType,
    BuildingInclusion,
    QuantityGroup,
    QuantityType,
    VacancyInclusion,
    VizType,
    WorkflowConfig,
)

__all__ = ["generate_highlights"]

DEFAULT_OUTPUT_TYPES: Sequence[Literal["html", "svg"]] = ("html", "svg")
ENERGY_DISTRIBUTION_GROUPS = {"Fuel Totals"}
BILL_DISTRIBUTION_GROUPS = {"Bills"}


def generate_highlights(
    config: str | dict | WorkflowConfig,
    *,
    highlights_config: str | Path | dict | None = None,
    output_types: Sequence[Literal["svg", "html"]] | None = None,
    overwrite: bool = False,
) -> None:
    """Generate highlight plots defined by highlights configuration."""
    workflow = load_workflow_config(config)
    highlights = _load_highlights(highlights_config, workflow)

    start_dir = get_plot_base_dir(workflow)
    start_dir.mkdir(parents=True, exist_ok=True)
    write_workflow_snapshot(workflow, start_dir)

    download_data(workflow)
    combined_df = load_data(workflow)

    highlight_specs = _get_highlight_specs(highlights, workflow)
    total = len(highlight_specs)
    html_root = start_dir / "Highlights (html)"
    svg_root = start_dir / "Highlights (svg)"

    output_selection = list(output_types or DEFAULT_OUTPUT_TYPES)

    for index, spec in enumerate(highlight_specs, start=1):
        spec_title = _resolve_spec_title(spec)
        print(f"{index:,}/{total:,}: Generating highlight '{spec_title}'")
        if spec.is_valid() is False:
            error = spec.get_error()
            print(f"  Skipping invalid highlight specification: {error}")
            continue

        try:
            df = prepare_data_for_plot(combined_df, spec)
        except Exception as exc:
            print(f"Error preparing data for highlight {spec_title}: {exc}")
            raise

        if df.height == 0:
            print(f"{index:,}/{total:,}: No data for highlight '{spec_title}', skipping")
            continue

        plotting_function = get_plotting_function(spec.visualization_type)
        try:
            fig = plotting_function(df, spec)
        except Exception as exc:
            print(f"Error creating highlight figure '{spec_title}': {exc}")
            raise

        _apply_title(fig, spec.title)

        _save_highlight(
            fig=fig,
            spec=spec,
            html_root=html_root,
            svg_root=svg_root,
            output_types=output_selection,
            overwrite=overwrite,
        )


def _load_highlights(
    highlights_config: str | Path | dict | None,
    workflow: WorkflowConfig,
) -> list[dict[str, Any]]:
    data = load_highlight_config(highlights_config)

    highlights = data.get("Highlights", [])
    if not isinstance(highlights, Iterable):
        raise ValueError("Highlights configuration must define a list under 'Highlights'.")

    entries: list[dict[str, Any]] = []
    for raw_entry in highlights:
        if raw_entry is None:
            continue
        entry = _coerce_entry(raw_entry)
        _validate_quantity_group(entry, workflow)
        entries.append(entry)
    return entries


def _coerce_entry(raw_entry: dict[str, Any]) -> dict[str, Any]:
    try:
        return {
            "title": raw_entry["title"],
            "building_inclusion": BuildingInclusion(raw_entry["building_inclusion"]),
            "vacancy_inclusion": VacancyInclusion(raw_entry["vacancy_inclusion"]),
            "quantity_type": QuantityType(raw_entry["quantity_type"]),
            "aggregation_type": AggregationType(raw_entry["aggregation_type"]),
            "visualization_type": VizType(raw_entry["visualization_type"]),
            "quantity_group_name": raw_entry["quantity_group_name"],
            "group_by": raw_entry.get("group_by"),
        }
    except KeyError as exc:
        missing = exc.args[0]
        raise ValueError(f"Missing required key '{missing}' in highlight entry: {raw_entry}") from exc


def _validate_quantity_group(entry: dict[str, Any], workflow: WorkflowConfig) -> None:
    if entry["quantity_type"] == QuantityType.prevalence:
        candidates = workflow.categorical_quantities
    else:
        candidates = workflow.numerical_quantities
    if not any(group.name == entry["quantity_group_name"] for group in candidates):
        raise ValueError(
            f"Highlight '{entry['title']}' references quantity_group_name '{entry['quantity_group_name']}' "
            "which was not found in the workflow configuration.",
        )


def _get_highlight_specs(
    highlights: Sequence[dict[str, Any]],
    workflow: WorkflowConfig,
) -> list[PlotSpec]:
    quantity_map = {group.name: group for group in (*workflow.numerical_quantities, *workflow.categorical_quantities)}
    upgrade_lookup = dict(zip(workflow.upgrades, workflow.upgrade_names))

    base_specs: list[PlotSpec] = []
    grouped_specs: list[PlotSpec] = []

    for highlight in highlights:
        quantity_group = quantity_map[highlight["quantity_group_name"]]
        specs_for_entry = _build_base_specs(highlight, quantity_group, workflow, upgrade_lookup)
        base_specs.extend(specs_for_entry)
        for spec in specs_for_entry:
            grouped_specs.extend(_build_group_by_specs(spec, workflow))

    return [*base_specs, *grouped_specs]


def _build_base_specs(
    highlight: dict[str, Any],
    quantity_group: QuantityGroup,
    workflow: WorkflowConfig,
    upgrade_lookup: dict[int, str],
) -> list[PlotSpec]:
    base_specs: list[PlotSpec] = []
    upgrades: Sequence[int | None]
    is_choropleth = highlight["visualization_type"] == VizType.choropleth
    if is_choropleth:
        upgrades = [upgrade for upgrade in workflow.upgrades if upgrade != 0]
        if not upgrades:
            upgrades = [None]
    elif highlight["quantity_type"] == QuantityType.prevalence:
        upgrades: Sequence[int | None] = list(workflow.upgrades)
    else:
        upgrades = [None]

    for upgrade in upgrades:
        upgrade_suffix = _format_upgrade_suffix(upgrade, upgrade_lookup)
        title = highlight["title"]
        if upgrade_suffix:
            title = f"{highlight['title']} - {upgrade_suffix}"

        plot_spec = PlotSpec(
            building_inclusion=highlight["building_inclusion"],
            vacancy_inclusion=highlight["vacancy_inclusion"],
            quantity_type=highlight["quantity_type"],
            aggregation_type=highlight["aggregation_type"],
            visualization_type=highlight["visualization_type"],
            group_by=highlight["group_by"],
            quantity=quantity_group,
            quantity_group_name=quantity_group.name,
            upgrade=upgrade,
            title=title,
        )

        if plot_spec.visualization_type == VizType.hist and isinstance(plot_spec.quantity, QuantityGroup):
            base_title = _resolve_spec_title(plot_spec)
            quantities = list(quantity_group.constituents)
            if quantity_group.sum and quantity_group.sum not in quantities:
                quantities.append(quantity_group.sum)
            for quantity in quantities:
                quantity_label = quantity.replace("_", " ")
                quantity_title = f"{base_title}<br>({quantity_label})"
                hist_spec = plot_spec.model_copy(
                    update={
                        "quantity": quantity,
                        "title": quantity_title,
                    }
                )
                if hist_spec.is_valid():
                    base_specs.append(hist_spec)
            continue

        if not plot_spec.is_valid():
            continue

        base_specs.append(plot_spec)
    return base_specs


def _build_group_by_specs(
    base_spec: PlotSpec,
    workflow: WorkflowConfig,
) -> list[PlotSpec]:
    base_title = _resolve_spec_title(base_spec)

    variants: list[PlotSpec] = []
    for group_col in workflow.group_by:
        if base_spec.group_by == group_col:
            continue

        title_suffix = _format_group_title(group_col)
        title = _insert_group_into_title(base_title, title_suffix)

        grouped_spec = base_spec.model_copy(
            update={
                "group_by": group_col,
                "title": title,
            }
        )
        if grouped_spec.visualization_type == VizType.box and isinstance(grouped_spec.quantity, QuantityGroup):
            base_group_title = _resolve_spec_title(grouped_spec)
            for quantity in grouped_spec.quantity.constituents:
                quantity_label = quantity.replace("_", " ")
                quantity_title = f"{base_group_title}<br>({quantity_label})"
                variants.append(
                    grouped_spec.model_copy(
                        update={
                            "quantity": quantity,
                            "title": quantity_title,
                        }
                    )
                )
            continue

        variants.append(grouped_spec)
    return variants


def _format_group_folder(group_col: str) -> str:
    clean = group_col.removeprefix("in.").removeprefix("out.")
    return f"by {clean}"


def _format_group_title(group_col: str) -> str:
    clean = group_col.removeprefix("in.").removeprefix("out.")
    return clean.replace("_", " ")


def _insert_group_into_title(base_title: str, group_title: str) -> str:
    if " (" in base_title:
        head, tail = base_title.split(" (", 1)
        return f"{head}<br>by {group_title} ({tail}"
    return f"{base_title}<br>by {group_title}"


def _format_upgrade_suffix(upgrade: int | None, upgrade_lookup: dict[int, str]) -> str | None:
    if upgrade is None:
        return None
    name = upgrade_lookup.get(upgrade)
    if name:
        return name
    return f"Upgrade {upgrade}"


def _sanitize_filename(name: str) -> str:
    cleaned = name.replace("<br>", " ")
    cleaned = re.sub(r"[\\/]+", "-", cleaned)
    cleaned = re.sub(r"[:*?\"<>|]", "", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned


def _apply_title(fig: Figure, title: str | None) -> None:
    if title:
        fig.update_layout(title_text=title)


def _resolve_spec_title(spec: PlotSpec) -> str:
    if spec.title:
        return spec.title
    if isinstance(spec.quantity, QuantityGroup):
        return spec.quantity_group_name
    return str(spec.quantity)


def _resolve_group_directory(spec: PlotSpec) -> Path | None:
    if not spec.group_by:
        return None
    return Path(_format_group_folder(spec.group_by))


def _resolve_distribution_directory(spec: PlotSpec) -> Path | None:
    if spec.aggregation_type != AggregationType.distribution:
        return None
    if spec.quantity_group_name in ENERGY_DISTRIBUTION_GROUPS:
        return Path("energy_savings_distributions")
    if spec.quantity_group_name in BILL_DISTRIBUTION_GROUPS:
        return Path("bill_savings_distributions")
    return None


def _save_highlight(
    *,
    fig: Figure,
    spec: PlotSpec,
    html_root: Path,
    svg_root: Path,
    output_types: Sequence[str],
    overwrite: bool,
) -> None:
    spec_title = _resolve_spec_title(spec)
    file_name = _sanitize_filename(spec_title)
    if not file_name:
        file_name = "highlight"

    subdirectory = _resolve_group_directory(spec)
    distribution_dir = _resolve_distribution_directory(spec)

    html_dir = html_root
    svg_dir = svg_root
    if subdirectory is not None:
        html_dir = html_dir / subdirectory
        svg_dir = svg_dir / subdirectory
    if distribution_dir is not None:
        html_dir = html_dir / distribution_dir
        svg_dir = svg_dir / distribution_dir
    html_dir.mkdir(parents=True, exist_ok=True)
    svg_dir.mkdir(parents=True, exist_ok=True)

    if "html" in output_types:
        html_path = html_dir / f"{file_name}.html"
        write_html_file(fig, html_path, overwrite)
    if "svg" in output_types:
        svg_path = svg_dir / f"{file_name}.svg"
        write_svg_file(fig, svg_path, overwrite)
