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
    html_path: Path,
    footnotes: list[str] | None = None,
    source_labels: dict | None = None,
    truth_source: str | None = None,
) -> None:
    """Post-process a Plotly HTML file: make the chart resizable and add a footer."""
    html = html_path.read_text(encoding="utf-8")

    # Extract the original fixed dimensions from the plotly-graph-div style
    m = re.search(r'class="plotly-graph-div"\s+style="height:([\d.]+)px;\s*width:([\d.]+)px;"', html)
    if not m:
        return
    orig_h, orig_w = m.group(1), m.group(2)

    # 1. Inject CSS: hide editable-mode placeholder text + footer styles
    css = (
        '<style>'
        '.js-placeholder{opacity:0!important;pointer-events:none!important}'
        f'.plot-footer{{margin:10px;padding:12px 16px;font-family:Arial,sans-serif;font-size:13px;color:#444;border-top:1px solid #ddd;max-width:{orig_w}px}}'
        '.plot-sources ul{margin:4px 0 0 20px;padding:0}'
        '.plot-sources li{margin-bottom:2px}'
        '.plot-sources a{color:#1a73e8;text-decoration:none}'
        '.plot-sources a:hover{text-decoration:underline}'
        '.plot-notes{margin-top:8px}'
        '.plot-notes li{margin-bottom:4px;font-style:italic}'
        '</style>\n'
    )
    html = html.replace("</head>", css + "</head>")

    # 2. Make the plotly div fill its container
    html = html.replace(
        f'style="height:{orig_h}px; width:{orig_w}px;"',
        'style="width:100%; height:100%;"',
    )

    # 3. Wrap <body> content in a resizable container
    resize_wrapper = (
        f'<div id="resize-container" style="resize:both; overflow:hidden; '
        f'width:{orig_w}px; height:{orig_h}px; border:1px solid #ddd; '
        f'position:relative; padding:0; margin:10px;">\n'
    )

    # 4. ResizeObserver + custom download buttons
    resize_script = """
<script>
(function() {
  var container = document.getElementById('resize-container');
  var chart = container.querySelector('.plotly-graph-div');
  if (!container || !chart) return;

  new ResizeObserver(function() { Plotly.Plots.resize(chart); }).observe(container);

  // Remove fixed dimensions so autosize works with the resizable container
  delete chart.layout.width;
  delete chart.layout.height;
  chart.layout.autosize = true;

  // Add custom PNG and SVG download buttons to the modebar
  var icon = Plotly.Icons.camera;
  Plotly.newPlot(chart, chart.data, chart.layout, Object.assign({}, chart._context, {
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
})();
</script>
"""

    html = html.replace("<body>\n", "<body>\n" + resize_wrapper)

    # 5. Build and inject footer with Data Sources and Notes
    footer_html = _build_footer_html(source_labels, truth_source, footnotes)

    html = html.replace("</body>", "</div>\n" + footer_html + resize_script + "</body>")

    html_path.write_text(html, encoding="utf-8")


@timed
def _build_footer_html(
    source_labels: dict | None,
    truth_source: str | None,
    footnotes: list[str] | None,
) -> str:
    """Build the Data Sources + Notes footer HTML for an individual plot page."""
    parts: list[str] = []

    # Data Sources section
    if source_labels and truth_source:
        relevant_keys = [k for k in source_labels if truth_source in k or "resstock" in k]
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
