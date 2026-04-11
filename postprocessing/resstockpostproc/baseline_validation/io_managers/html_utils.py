"""HTML post-processing utilities for individual plot pages.

Handles resizable container wrapping, custom modebar buttons,
and footer injection (Data Sources + Notes).
"""

import html as html_lib
import re
from pathlib import Path
from resstockpostproc.shared_utils.timing import timed


@timed
def postprocess_plot_html(
    html_paths: Path | list[Path],
    output_path: Path | None = None,
    headings: list[str] | None = None,
    footnotes: list[str] | None = None,
    source_labels: dict | None = None,
    comparison_dataset: str | None = None,
    scale: float = 1.0,
) -> None:
    """Post-process Plotly HTML file(s): make chart(s) resizable and add a footer.

    For a single input, produces a self-contained page with one resizable chart.
    For multiple inputs, stacks all charts vertically in a single resizable
    container with ``<h2>`` headings between them.

    Args:
        html_paths: One or more raw Plotly HTML files (from ``fig.write_html``).
        output_path: Where to write the enhanced HTML. Defaults to overwriting
            the (single) input path.
        headings: Per-chart ``<h2>`` headings (only used when len(html_paths) > 1).
        footnotes: Note strings for the footer.
        source_labels: Data source labels for the footer.
        comparison_dataset: Raw enum value (e.g. ``"eia"``) for footer filtering.
    """
    if isinstance(html_paths, Path):
        html_paths = [html_paths]
    if output_path is None:
        output_path = html_paths[0]

    # Read all input HTMLs and extract chart sections
    chart_sections = []
    orig_w, orig_h = "1200", "600"
    for i, path in enumerate(html_paths):
        html = path.read_text(encoding="utf-8")
        m = re.search(r'class="plotly-graph-div"\s+style="height:([\d.]+)px;\s*width:([\d.]+)px;"', html)
        if not m:
            continue
        orig_h, orig_w = m.group(1), m.group(2)

        # Make the plotly div fill its container
        html = html.replace(
            f'style="height:{orig_h}px; width:{orig_w}px;"',
            'style="width:100%; height:100%;"',
        )

        # Extract the <body> content (between <body> and </body>)
        body_match = re.search(r"<body[^>]*>\n?(.*?)</body>", html, re.DOTALL)
        if not body_match:
            continue
        body_content = body_match.group(1).strip()

        # Add heading for stacked (multi-chart) pages
        if len(html_paths) > 1 and headings and i < len(headings):
            heading = f'<h2 style="margin:28px 0 8px;font-size:16px;font-weight:600;color:#1a1a1a;">{html_lib.escape(headings[i])}</h2>\n'
            body_content = heading + body_content

        chart_sections.append(body_content)

    if not chart_sections:
        return

    # Apply scale and compute container dimensions
    scaled_w = int(float(orig_w) * scale)
    scaled_h = int(float(orig_h) * scale)
    if len(chart_sections) > 1:
        container_h = scaled_h * len(chart_sections)
    else:
        container_h = scaled_h

    # Build CSS
    css = (
        '<style>'
        '.js-placeholder{opacity:0!important;pointer-events:none!important}'
        '#resize-container{display:flex;flex-direction:column}'
        '#resize-container>*{flex:1 1 0;min-height:0}'
        '#resize-container>h2{flex:0 0 auto}'
        f'.plot-footer{{margin:10px;padding:12px 16px;font-family:Arial,sans-serif;font-size:13px;color:#444;border-top:1px solid #ddd;max-width:{scaled_w}px}}'
        '.plot-sources ul{margin:4px 0 0 20px;padding:0}'
        '.plot-sources li{margin-bottom:2px}'
        '.plot-sources a{color:#1a73e8;text-decoration:none}'
        '.plot-sources a:hover{text-decoration:underline}'
        '.plot-notes{margin-top:8px}'
        '.plot-notes li{margin-bottom:4px;font-style:italic}'
        '</style>\n'
    )

    # Resizable container
    resize_wrapper = (
        f'<div id="resize-container" style="resize:both; overflow:hidden; '
        f'width:{scaled_w}px; height:{container_h}px; border:1px solid #ddd; '
        f'position:relative; padding:0; margin:10px;">\n'
    )

    # ResizeObserver + custom download buttons (handles multiple charts)
    resize_script = """
<script>
(function() {
  var container = document.getElementById('resize-container');
  var charts = container.querySelectorAll('.plotly-graph-div');
  if (!container || !charts.length) return;

  new ResizeObserver(function() {
    charts.forEach(function(c) { Plotly.Plots.resize(c); });
  }).observe(container);

  charts.forEach(function(chart) {
    delete chart.layout.width;
    delete chart.layout.height;
    chart.layout.autosize = true;

    var icon = Plotly.Icons.camera;
    Plotly.newPlot(chart, chart.data, chart.layout, Object.assign({}, chart._context || {}, {
      edits: {
        annotationPosition: true,
        annotationText: true,
        axisTitleText: true,
        legendPosition: true,
        legendText: true,
        shapePosition: false,
        titleText: true,
      },
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
  });
})();
</script>
"""

    # Take the <head> from the first input (contains Plotly CDN script)
    first_html = html_paths[0].read_text(encoding="utf-8")
    head_match = re.search(r"(<head>.*?</head>)", first_html, re.DOTALL)
    head = head_match.group(1) if head_match else "<head></head>"
    head = head.replace("</head>", css + "</head>")

    # Build footer
    footer_html = _build_footer_html(source_labels, comparison_dataset, footnotes)

    # Assemble final HTML
    body_inner = "\n".join(chart_sections)
    final_html = (
        "<!DOCTYPE html>\n<html>\n" + head + "\n<body>\n"
        + resize_wrapper + body_inner + "\n</div>\n"
        + footer_html + resize_script
        + "</body>\n</html>"
    )

    output_path.write_text(final_html, encoding="utf-8")


@timed
def _build_footer_html(
    source_labels: dict | None,
    comparison_dataset: str | None,
    footnotes: list[str] | None,
) -> str:
    """Build the Data Sources + Notes footer HTML for an individual plot page."""
    parts: list[str] = []

    # Data Sources section
    if source_labels and comparison_dataset:
        relevant_keys = [k for k in source_labels if comparison_dataset in k or "resstock" in k]
        if relevant_keys:
            items = []
            for key in sorted(relevant_keys):
                sl = source_labels[key]
                escaped_label = html_lib.escape(sl.label)
                entry_parts = []
                for entry in sl.entries:
                    escaped_desc = html_lib.escape(entry.description)
                    if entry.url:
                        entry_parts.append(
                            f'<a href="{html_lib.escape(entry.url)}" target="_blank">{escaped_desc}</a>'
                        )
                    else:
                        entry_parts.append(escaped_desc)
                items.append(f'<li><strong>{escaped_label}:</strong> {", ".join(entry_parts)}</li>')
            parts.append(
                '<div class="plot-sources"><strong>Data Sources:</strong><ul>'
                + "".join(items)
                + "</ul></div>"
            )

    # Notes section
    if footnotes:
        note_items = "".join(f"<li>{html_lib.escape(n)}</li>" for n in footnotes)
        parts.append(f'<div class="plot-notes"><strong>Notes:</strong><ul>{note_items}</ul></div>')

    if not parts:
        return ""
    return '<div class="plot-footer">' + "\n".join(parts) + "</div>\n"
