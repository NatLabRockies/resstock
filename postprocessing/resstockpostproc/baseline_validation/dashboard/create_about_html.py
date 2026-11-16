"""Render about_dashboard.md to a standalone about.html for the viewer modal."""

from __future__ import annotations

from pathlib import Path

import markdown


ABOUT_FILENAME = "about.html"
ABOUT_MARKDOWN_PATH = Path(__file__).parent / "about_dashboard.md"
MARKDOWN_EXTENSIONS = ["tables", "fenced_code", "attr_list", "sane_lists"]

_PAGE_TEMPLATE = """<!DOCTYPE html>
<html>
<head>
  <meta charset='UTF-8'>
  <title>About this dashboard</title>
  <style>
    html, body {{
      margin: 0;
      padding: 0;
      background: #fff;
      color: #1a1a1a;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.55;
    }}
    .content {{
      max-width: 920px;
      margin: 0 auto;
      padding: 28px 36px 56px;
    }}
    h1 {{ font-size: 24px; margin: 0 0 18px; }}
    h2 {{ font-size: 18px; margin: 28px 0 10px; border-bottom: 1px solid #e5e5e5; padding-bottom: 4px; }}
    h3 {{ font-size: 15px; margin: 20px 0 8px; }}
    p, ul, ol {{ font-size: 14px; }}
    ul, ol {{ padding-left: 22px; }}
    li {{ margin: 4px 0; }}
    code {{ background: #f4f4f4; padding: 1px 4px; border-radius: 3px; font-size: 13px; }}
    a {{ color: #1a73e8; text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
    table {{
      border-collapse: collapse;
      margin: 12px 0 16px;
      font-size: 13px;
      width: 100%;
    }}
    th, td {{
      border: 1px solid #d8d8d8;
      padding: 8px 10px;
      text-align: left;
      vertical-align: top;
    }}
    th {{ background: #f4f4f4; font-weight: 600; }}
    blockquote {{
      border-left: 3px solid #d8d8d8;
      padding: 4px 12px;
      margin: 12px 0;
      color: #555;
    }}
  </style>
</head>
<body>
  <div class='content'>
{body}
  </div>
</body>
</html>
"""


def render_about_html() -> str:
    """Render about_dashboard.md to a standalone HTML page."""
    md_text = ABOUT_MARKDOWN_PATH.read_text(encoding="utf-8")
    body = markdown.markdown(md_text, extensions=MARKDOWN_EXTENSIONS, output_format="html5")
    return _PAGE_TEMPLATE.format(body=body)


def write_about_html(output_dir: Path) -> Path:
    """Write about.html next to the main dashboard HTML."""
    output_dir.mkdir(parents=True, exist_ok=True)
    out_path = output_dir / ABOUT_FILENAME
    out_path.write_text(render_about_html(), encoding="utf-8")
    return out_path
