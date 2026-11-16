"""Tests for Plotly HTML post-processing and fallback asset loading."""

from pathlib import Path

import plotly.graph_objects as go

from resstockpostproc.baseline_validation.io_managers.html_utils import postprocess_plot_html
from resstockpostproc.baseline_validation.io_managers.output_manager import plotly_asset_filename, plotly_cdn_url


def _write_raw_plot(tmp_path: Path, name: str) -> Path:
    raw_path = tmp_path / f"{name}.raw.html"
    go.Figure(go.Scatter(x=[1, 2], y=[3, 4])).write_html(raw_path, include_plotlyjs="cdn")
    return raw_path


def test_postprocess_plot_html_uses_cdn_then_local_fallback(tmp_path):
    raw_path = _write_raw_plot(tmp_path, "single")
    output_path = tmp_path / "dashboard_data" / "eia plots (html)" / "nested" / "single.html"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    asset_path = tmp_path / "dashboard_data" / "assets" / plotly_asset_filename()

    postprocess_plot_html(
        raw_path,
        output_path=output_path,
        plotly_cdn_src=plotly_cdn_url(),
        plotly_asset_path=asset_path,
    )

    html = output_path.read_text(encoding="utf-8")
    sibling_href = plotly_asset_filename()
    assert plotly_cdn_url() in html
    assert "../../assets/" + plotly_asset_filename() in html
    assert f'src="{sibling_href}"' in html
    assert (
        html.index(plotly_cdn_url())
        < html.index("../../assets/" + plotly_asset_filename())
        < html.index(f'src="{sibling_href}"')
        < html.index("Plotly.newPlot")
    )
    assert html.count("window.PlotlyConfig") == 1
    assert "window.Plotly.newPlot = function" in html
    assert "modeBarButtonsToAdd = existingButtons.concat(extraButtons)" in html
    assert "if (!container || !window.Plotly) return;" in html
    assert "container.querySelectorAll('.plotly-graph-div')" in html
    assert "waitForCharts(0);" in html
    assert "Plotly.newPlot(chart, chart.data, chart.layout" not in html
    assert html.count("document.write") == 2


def test_postprocess_plot_html_deduplicates_loader_for_stacked_pages(tmp_path):
    raw_paths = [_write_raw_plot(tmp_path, "stacked_a"), _write_raw_plot(tmp_path, "stacked_b")]
    output_path = tmp_path / "dashboard_data" / "eia plots (html)" / "nested" / "stacked.html"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    asset_path = tmp_path / "dashboard_data" / "assets" / plotly_asset_filename()

    postprocess_plot_html(
        raw_paths,
        output_path=output_path,
        plotly_cdn_src=plotly_cdn_url(),
        plotly_asset_path=asset_path,
    )

    html = output_path.read_text(encoding="utf-8")
    local_href = "../../assets/" + plotly_asset_filename()
    assert html.count(plotly_cdn_url()) == 1
    assert html.count(local_href) == 1
    assert html.count(f'src="{plotly_asset_filename()}"') == 1
    assert html.count("window.PlotlyConfig") == 1
    assert html.count("document.write") == 2
    assert html.count('class="plotly-graph-div"') == 2
    assert html.count("window.Plotly.newPlot = function") == 1
