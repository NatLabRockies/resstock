"""Functions for saving plots and data."""

import re
from pathlib import Path
from typing import Literal

import plotly.graph_objects as go
import polars as pl

from resstockpostproc.baseline_validation.schema.plot_spec import PlotSpec, FileType
from resstockpostproc.baseline_validation.utils import ensure_directory
from resstockpostproc.baseline_validation.schema.workflow_schema import workflow
from resstockpostproc.shared_utils.timing import timed


FIGURE_FORMATS = {FileType.html, FileType.svg, FileType.pdf}

# Plotly HTML config: editable titles/labels + custom download buttons
PLOTLY_HTML_CONFIG: dict = {
    "editable": True,
    "modeBarButtonsToRemove": ["toImage"],
}


@timed
def save_figure(
    fig: go.Figure,
    plot_spec: PlotSpec,
    formats: list[FileType] = [FileType.html],
) -> None:
    """Save a Plotly figure in multiple formats."""

    for fmt in formats:
        if fmt not in FIGURE_FORMATS:
            continue
        output_dir = workflow.output.output_dir / workflow.output.run_name / f"{plot_spec.truth_source} plots ({fmt})"
        path_seg, title = plot_spec.get_file_path_and_name()
        filepath = output_dir / path_seg
        ensure_directory(filepath)
        fullpath = filepath / f"{title}.{fmt.value}"
        if fmt == FileType.html:
            fig.write_html(fullpath, include_plotlyjs="cdn", config=PLOTLY_HTML_CONFIG)
            _make_html_resizable(fullpath)
        else:
            # For PDF/SVG, use larger scale and ensure proper dimensions
            # Get dimensions from figure layout, or use defaults
            width = fig.layout.width if fig.layout.width else 1950
            height = fig.layout.height if fig.layout.height else 1100

            # Use scale=2 for better quality and proper sizing
            fig.write_image(fullpath, width=width, height=height, scale=2)
        print(f"Saved: {filepath}")


def _make_html_resizable(html_path: Path) -> None:
    """Post-process a Plotly HTML file to make the chart resizable via drag."""
    html = html_path.read_text(encoding="utf-8")

    # Extract the original fixed dimensions from the plotly-graph-div style
    m = re.search(r'class="plotly-graph-div"\s+style="height:([\d.]+)px;\s*width:([\d.]+)px;"', html)
    if not m:
        return
    orig_h, orig_w = m.group(1), m.group(2)

    # 1. Hide "Click to enter ..." placeholder text from editable mode
    placeholder_css = (
        '<style>.js-placeholder{opacity:0!important;pointer-events:none!important}</style>\n'
    )
    html = html.replace("</head>", placeholder_css + "</head>")

    # 2. Make the plotly div fill its container
    html = html.replace(
        f'style="height:{orig_h}px; width:{orig_w}px;"',
        'style="width:100%; height:100%;"',
    )

    # 3. Remove fixed width/height from Plotly layout JSON so autosize takes effect
    html = re.sub(r'"width":\s*[\d.]+,\s*"height":\s*[\d.]+,', '"autosize":true,', html)

    # 4. Wrap <body> content in a resizable container + add ResizeObserver
    resize_wrapper = (
        f'<div id="resize-container" style="resize:both; overflow:hidden; '
        f'width:{orig_w}px; height:{orig_h}px; border:1px solid #ddd; '
        f'position:relative; padding:0; margin:10px;">\n'
    )
    resize_script = """
<script>
(function() {
  var container = document.getElementById('resize-container');
  var chart = container.querySelector('.plotly-graph-div');
  if (!container || !chart) return;

  new ResizeObserver(function() { Plotly.Plots.resize(chart); }).observe(container);

  // Add custom PNG and SVG download buttons to the modebar
  var icon = Plotly.Icons.camera;
  Plotly.newPlot(chart, chart.data, chart.layout, Object.assign({}, chart._context, {
    editable: true,
    modeBarButtonsToRemove: ['toImage'],
    modeBarButtonsToAdd: [
      {
        name: 'Download PNG',
        icon: icon,
        click: function(gd) {
          Plotly.downloadImage(gd, {format: 'png', filename: 'plot', width: gd.offsetWidth, height: gd.offsetHeight, scale: 2});
        }
      },
      {
        name: 'Download SVG',
        icon: icon,
        click: function(gd) {
          Plotly.downloadImage(gd, {format: 'svg', filename: 'plot', width: gd.offsetWidth, height: gd.offsetHeight});
        }
      }
    ]
  }));
})();
</script>
"""

    html = html.replace("<body>\n", "<body>\n" + resize_wrapper)
    html = html.replace("</body>", "</div>\n" + resize_script + "</body>")

    html_path.write_text(html, encoding="utf-8")


def save_dataframe(
    df: pl.DataFrame,
    output_dir: Path,
    filename: str,
    formats: tuple[Literal["parquet", "csv"], ...] = ("parquet",),
) -> None:
    """Save a Polars DataFrame in multiple formats."""
    data_dir = ensure_directory(output_dir / "data")

    for fmt in formats:
        filepath = data_dir / f"{filename}.{fmt}"

        if fmt == "parquet":
            df.write_parquet(filepath)
        elif fmt == "csv":
            df.write_csv(filepath)

        print(f"Saved: {filepath}")
