"""Tests for HTML generation and viz cell parsing."""

import csv
from pathlib import Path

import pytest

from resstockpostproc.baseline_validation.create_html import (
    append_html_row,
    create_html_from_csv,
    create_html_shell,
    parse_viz_cell,
)


class TestParseVizCell:
    def test_success_format(self):
        display, url = parse_viz_cell("tilemap(eia plots/path/to/file.html)")
        assert display == "tilemap"
        assert url == "eia plots/path/to/file.html"

    def test_failed_with_traceback(self):
        display, tb = parse_viz_cell("FAILED: tilemap(Traceback (most recent call last):\n  File ...)")
        assert display == "FAILED"
        assert "Traceback" in tb

    def test_failed_without_traceback(self):
        display, tb = parse_viz_cell("FAILED: tilemap")
        assert display == "FAILED"
        assert tb is None

    def test_empty_string(self):
        display, url = parse_viz_cell("")
        assert display == ""
        assert url is None

    def test_whitespace_only(self):
        display, url = parse_viz_cell("   ")
        assert display == ""
        assert url is None


class TestHtmlRoundTrip:
    """Test the incremental shell + append protocol."""

    def test_shell_and_append(self, tmp_path):
        html_path = tmp_path / "test.html"
        headers = ["Index", "Name", "Main Visualization"]

        suffix_size = create_html_shell(html_path, headers)
        assert html_path.exists()
        assert suffix_size > 0

        # Append two rows
        append_html_row(
            html_path,
            {"Index": "1", "Name": "plot_a", "Main Visualization": "tilemap(a.html)"},
            headers,
            suffix_size,
        )
        append_html_row(
            html_path,
            {"Index": "2", "Name": "plot_b", "Main Visualization": "FAILED: bar"},
            headers,
            suffix_size,
        )

        content = html_path.read_text()

        # The HTML should be well-formed (suffix intact)
        assert content.endswith("</script>\n</body>\n</html>\n")

        # Extract the CSV data block
        csv_start = content.index('<script id="csvdata" type="text/csv">')
        csv_end = content.index("</script>", csv_start)
        csv_block = content[csv_start:csv_end]
        # The CSV data is after the closing >
        csv_data = csv_block.split(">", 1)[1].strip()

        lines = csv_data.split("\n")
        assert len(lines) == 3  # header + 2 data rows
        assert "plot_a" in lines[1]
        assert "plot_b" in lines[2]

    def test_batch_from_csv(self, tmp_path):
        csv_path = tmp_path / "input.csv"
        html_path = tmp_path / "output.html"

        # Write a CSV
        with open(csv_path, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["Index", "Name"])
            writer.writeheader()
            writer.writerow({"Index": "1", "Name": "row1"})
            writer.writerow({"Index": "2", "Name": "row2"})

        create_html_from_csv(csv_path, html_path)

        content = html_path.read_text()
        assert "row1" in content
        assert "row2" in content
        assert content.endswith("</script>\n</body>\n</html>\n")
