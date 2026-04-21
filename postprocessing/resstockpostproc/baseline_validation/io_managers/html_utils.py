"""HTML post-processing utilities for individual plot pages.

Handles resizable container wrapping, custom modebar buttons,
and footer injection (Data Sources + Notes).
"""

import html as html_lib
import re
from pathlib import Path

from resstockpostproc.baseline_validation.dashboard_paths import relative_href_from_file
from resstockpostproc.shared_utils.timing import timed


_BODY_RE = re.compile(r"<body[^>]*>\n?(.*?)</body>", re.DOTALL)
_HEAD_RE = re.compile(r"(<head>.*?</head>)", re.DOTALL)
_PLOTLY_DIV_STYLE_RE = re.compile(
    r'class="plotly-graph-div"\s+style="height:([^;"]+);\s*width:([^;"]+);"'
)
_PLOTLY_CONFIG_RE = re.compile(
    r'<script[^>]*>\s*window\.PlotlyConfig\s*=\s*\{MathJaxConfig:\s*[\'"]local[\'"]\};\s*</script>',
    re.DOTALL,
)
_PLOTLY_CDN_SCRIPT_RE = re.compile(
    r'<script[^>]+src="https://cdn\.plot\.ly/plotly-[^"]+\.min\.js"[^>]*></script>',
    re.DOTALL,
)


def _build_plotly_loader_html(
    plotly_cdn_src: str,
    local_plotly_src: str | None = None,
    sibling_plotly_src: str | None = None,
) -> str:
    """Return a blocking Plotly loader with CDN-first, multi-step fallback behavior."""
    escaped_cdn = html_lib.escape(plotly_cdn_src, quote=True)
    fallback_steps: list[str] = []
    if local_plotly_src:
        escaped_local = html_lib.escape(local_plotly_src, quote=True)
        fallback_steps.append(
            '<script type="text/javascript">\n'
            "if (!window.Plotly) {\n"
            f"  document.write('<script charset=\"utf-8\" src=\"{escaped_local}\"><\\\\/script>');\n"
            "}\n"
            "</script>\n"
        )
    if sibling_plotly_src:
        escaped_sibling = html_lib.escape(sibling_plotly_src, quote=True)
        fallback_steps.append(
            '<script type="text/javascript">\n'
            "if (!window.Plotly) {\n"
            f"  document.write('<script charset=\"utf-8\" src=\"{escaped_sibling}\"><\\\\/script>');\n"
            "}\n"
            "</script>\n"
        )
    return (
        "<script type=\"text/javascript\">window.PlotlyConfig = {MathJaxConfig: 'local'};</script>\n"
        f'<script charset="utf-8" src="{escaped_cdn}"></script>\n'
        + "".join(fallback_steps)
        +
        '<script type="text/javascript">\n'
        "(function() {\n"
        "  if (!window.Plotly || window.Plotly.__baselineDashboardPatched) return;\n"
        "  var originalNewPlot = window.Plotly.newPlot;\n"
        "  var icon = window.Plotly.Icons.camera;\n"
        "  var extraButtons = [\n"
        "    {\n"
        "      name: 'Download PNG',\n"
        "      icon: icon,\n"
        "      click: function(gd) {\n"
        "        window.Plotly.downloadImage(gd, {format: 'png', filename: 'plot', width: gd.offsetWidth, height: gd.offsetHeight, scale: 2});\n"
        "      }\n"
        "    },\n"
        "    {\n"
        "      name: 'Download SVG',\n"
        "      icon: icon,\n"
        "      click: function(gd) {\n"
        "        window.Plotly.downloadImage(gd, {format: 'svg', filename: 'plot', width: gd.offsetWidth, height: gd.offsetHeight});\n"
        "      }\n"
        "    }\n"
        "  ];\n"
        "  window.Plotly.newPlot = function(gd, data, layout, config) {\n"
        "    var mergedConfig = Object.assign({}, config || {});\n"
        "    var existingButtons = Array.isArray(mergedConfig.modeBarButtonsToAdd)\n"
        "      ? mergedConfig.modeBarButtonsToAdd.slice()\n"
        "      : [];\n"
        "    mergedConfig.modeBarButtonsToAdd = existingButtons.concat(extraButtons);\n"
        "    return originalNewPlot.call(window.Plotly, gd, data, layout, mergedConfig);\n"
        "  };\n"
        "  window.Plotly.__baselineDashboardPatched = true;\n"
        "})();\n"
        "</script>\n"
    )


def _coerce_plotly_dim(value: str, default: int) -> int:
    """Convert a Plotly div dimension string into a pixel integer."""
    match = re.match(r"\s*([\d.]+)px\s*$", value)
    if not match:
        return default
    return int(float(match.group(1)))


def _strip_plotly_bootstrap(body_content: str) -> str:
    """Remove Plotly bootstrap scripts so the page can provide a shared loader once."""
    body_content = _PLOTLY_CONFIG_RE.sub("", body_content, count=1)
    body_content = _PLOTLY_CDN_SCRIPT_RE.sub("", body_content, count=1)
    return body_content


@timed
def postprocess_plot_html(
    html_paths: Path | list[Path],
    output_path: Path | None = None,
    headings: list[str] | None = None,
    footnotes: list[str] | None = None,
    source_labels: dict | None = None,
    comparison_dataset: str | None = None,
    scale_x: float = 1.0,
    scale_y: float = 1.0,
    plotly_cdn_src: str | None = None,
    plotly_asset_path: Path | None = None,
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
        scale_x: Horizontal scale factor applied to the initial container width.
        scale_y: Vertical scale factor applied to the initial per-chart height.
    """
    if isinstance(html_paths, Path):
        html_paths = [html_paths]
    if output_path is None:
        output_path = html_paths[0]

    local_plotly_src = None
    sibling_plotly_src = None
    if output_path is not None and plotly_asset_path is not None:
        local_plotly_src = relative_href_from_file(plotly_asset_path, output_path)
        sibling_plotly_src = relative_href_from_file(output_path.with_name(plotly_asset_path.name), output_path)

    # Read all input HTMLs and extract chart sections
    chart_sections = []
    orig_w, orig_h = "1200", "600"
    for i, path in enumerate(html_paths):
        html = path.read_text(encoding="utf-8")
        m = _PLOTLY_DIV_STYLE_RE.search(html)
        if m:
            orig_h_raw, orig_w_raw = m.group(1).strip(), m.group(2).strip()
            orig_h = str(_coerce_plotly_dim(orig_h_raw, 600))
            orig_w = str(_coerce_plotly_dim(orig_w_raw, 1200))

            # Make the plotly div fill its container
            html = html.replace(
                f'style="height:{orig_h_raw}; width:{orig_w_raw};"',
                'style="width:100%; height:100%;"',
                1,
            )

        # Extract the <body> content (between <body> and </body>)
        body_match = _BODY_RE.search(html)
        if not body_match:
            continue
        body_content = body_match.group(1).strip()
        if plotly_cdn_src and (local_plotly_src or sibling_plotly_src):
            body_content = _strip_plotly_bootstrap(body_content).strip()

        # Add heading for stacked (multi-chart) pages
        if len(html_paths) > 1 and headings and i < len(headings):
            heading = f'<h2 style="margin:28px 0 8px;font-size:16px;font-weight:600;color:#1a1a1a;">{html_lib.escape(headings[i])}</h2>\n'
            body_content = heading + body_content

        chart_sections.append(body_content)

    if not chart_sections:
        return

    # Apply scale and compute container dimensions
    scaled_w = int(float(orig_w) * scale_x)
    scaled_h = int(float(orig_h) * scale_y)
    if len(chart_sections) > 1:
        container_h = scaled_h * len(chart_sections)
    else:
        container_h = scaled_h

    # Build CSS
    css = (
        "<style>"
        ".js-placeholder{opacity:0!important;pointer-events:none!important}"
        "#resize-container{display:flex;flex-direction:column}"
        "#resize-container>*{flex:1 1 0;min-height:0}"
        "#resize-container>h2{flex:0 0 auto}"
        f".plot-footer{{margin:10px;padding:12px 16px;font-family:Arial,sans-serif;font-size:13px;color:#444;border-top:1px solid #ddd;max-width:{scaled_w}px}}"
        ".plot-sources ul{margin:4px 0 0 20px;padding:0}"
        ".plot-sources li{margin-bottom:2px}"
        ".plot-sources a{color:#1a73e8;text-decoration:none}"
        ".plot-sources a:hover{text-decoration:underline}"
        ".plot-notes{margin-top:8px}"
        ".plot-notes li{margin-bottom:4px;font-style:italic}"
        "</style>\n"
    )

    # Resizable container
    resize_wrapper = (
        f'<div id="resize-container" style="resize:both; overflow:hidden; '
        f'width:{scaled_w}px; height:{container_h}px; border:1px solid #ddd; '
        f'position:relative; padding:0; margin:10px;">\n'
    )

    # ResizeObserver + autosize handling (download buttons are injected by the loader patch)
    resize_script = """
<script>
(function() {
  function initResizeBehavior() {
    var container = document.getElementById('resize-container');
    if (!container || !window.Plotly) return;

    var charts = Array.prototype.slice.call(container.querySelectorAll('.plotly-graph-div'));
    if (!charts.length) return;

    function chartsReady() {
      return charts.every(function(chart) {
        return !!(chart.layout && chart._fullLayout);
      });
    }

    function autosizeCharts() {
      charts.forEach(function(chart) {
        if (!chart.layout) return;
        delete chart.layout.width;
        delete chart.layout.height;
        chart.layout.autosize = true;
        window.Plotly.Plots.resize(chart);
      });
    }

    function waitForCharts(attempt) {
      if (!chartsReady()) {
        if (attempt >= 100) return;
        window.setTimeout(function() { waitForCharts(attempt + 1); }, 50);
        return;
      }

      autosizeCharts();
      new ResizeObserver(function() {
        charts.forEach(function(chart) {
          if (chart.layout) window.Plotly.Plots.resize(chart);
        });
      }).observe(container);
    }

    waitForCharts(0);
  }

  if (document.readyState === 'complete') {
    initResizeBehavior();
  } else {
    window.addEventListener('load', initResizeBehavior, { once: true });
  }
})();
</script>
"""

    plotly_loader_html = ""
    if plotly_cdn_src and (local_plotly_src or sibling_plotly_src):
        plotly_loader_html = _build_plotly_loader_html(
            plotly_cdn_src,
            local_plotly_src=local_plotly_src,
            sibling_plotly_src=sibling_plotly_src,
        )

    # Take the <head> from the first input and inject page CSS there.
    first_html = html_paths[0].read_text(encoding="utf-8")
    head_match = _HEAD_RE.search(first_html)
    head = head_match.group(1) if head_match else "<head></head>"
    head = head.replace("</head>", css + "</head>")

    # Build footer
    footer_html = _build_footer_html(source_labels, comparison_dataset, footnotes)

    # Assemble final HTML
    body_inner = "\n".join(chart_sections)
    final_html = (
        "<!DOCTYPE html>\n<html>\n" + head + "\n<body>\n"
        + plotly_loader_html
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
