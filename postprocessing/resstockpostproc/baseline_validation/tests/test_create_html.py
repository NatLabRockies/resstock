"""Tests for HTML generation and viz cell parsing."""

import csv


from resstockpostproc.baseline_validation.dashboard.dashboard_paths import (
    comparisons_index_data_dir,
    dashboard_html_path,
)
from resstockpostproc.baseline_validation.dashboard.create_html import (
    init_html_index,
    append_index_row,
    finalize_html_index,
    create_html_from_csv,
    parse_viz_cell,
)


class TestParseVizCell:
    def test_success_format(self):
        display, url = parse_viz_cell("tilemap||eia plots/path/to/file.html")
        assert display == "tilemap"
        assert url == "eia plots/path/to/file.html"

    def test_success_with_parentheses_in_label(self):
        display, url = parse_viz_cell("tilemap bar plot (difference)||eia plots (html)/path.html")
        assert display == "tilemap bar plot (difference)"
        assert url == "eia plots (html)/path.html"

    def test_failed_with_traceback(self):
        display, tb = parse_viz_cell("FAILED: tilemap||Traceback (most recent call last):\n  File ...")
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


class TestShardedIndex:
    """Test the sharded HTML index generation."""

    def test_init_creates_data_dir(self, tmp_path):
        html_path = dashboard_html_path(tmp_path)
        data_dir = comparisons_index_data_dir(tmp_path)
        headers = ["Index", "Filter 1", "Name", "Main Visualization"]

        init_html_index(html_path, headers, data_dir=data_dir)

        # HTML is NOT written yet (deferred to finalize)
        assert not html_path.exists()
        assert data_dir.is_dir()

    def test_finalize_writes_html_with_script_tags(self, tmp_path):
        html_path = dashboard_html_path(tmp_path)
        data_dir = comparisons_index_data_dir(tmp_path)
        headers = ["Index", "Filter 1", "Name", "Main Visualization"]
        state = init_html_index(html_path, headers, data_dir=data_dir)

        append_index_row(
            state,
            {
                "Index": "1",
                "Filter 1": "",
                "Name": "overview",
                "Main Visualization": "tilemap(a.html)",
            },
        )
        append_index_row(
            state,
            {
                "Index": "2",
                "Filter 1": "Alaska",
                "Name": "ak_plot",
                "Main Visualization": "bar(b.html)",
            },
        )

        finalize_html_index(state)

        content = html_path.read_text()
        assert content.endswith("</html>\n")
        # Should have static script tags for both shards
        assert 'src="dashboard_data/comparisons_index/data-_none_.js"' in content
        assert 'src="dashboard_data/comparisons_index/data-Alaska.js"' in content
        # Should have inline manifest
        assert "window.shardManifest" in content

    def test_append_creates_shard_files(self, tmp_path):
        html_path = dashboard_html_path(tmp_path)
        data_dir = comparisons_index_data_dir(tmp_path)
        headers = ["Index", "Filter 1", "Name", "Main Visualization"]
        state = init_html_index(html_path, headers, data_dir=data_dir)

        append_index_row(
            state,
            {
                "Index": "1",
                "Filter 1": "",
                "Name": "overview",
                "Main Visualization": "tilemap(a.html)",
            },
        )
        append_index_row(
            state,
            {
                "Index": "2",
                "Filter 1": "Alaska",
                "Name": "ak_plot",
                "Main Visualization": "bar(b.html)",
            },
        )

        none_shard = data_dir / "data-_none_.js"
        alaska_shard = data_dir / "data-Alaska.js"

        assert none_shard.exists()
        assert alaska_shard.exists()

        none_content = none_shard.read_text()
        assert "window.addRows(`" in none_content
        assert "overview" in none_content
        assert none_content.strip().endswith("`);")

        alaska_content = alaska_shard.read_text()
        assert "ak_plot" in alaska_content

    def test_multiple_rows_same_shard(self, tmp_path):
        html_path = dashboard_html_path(tmp_path)
        data_dir = comparisons_index_data_dir(tmp_path)
        headers = ["Index", "Filter 1", "Name", "Main Visualization"]
        state = init_html_index(html_path, headers, data_dir=data_dir)

        append_index_row(
            state,
            {
                "Index": "1",
                "Filter 1": "Alaska",
                "Name": "plot_a",
                "Main Visualization": "",
            },
        )
        append_index_row(
            state,
            {
                "Index": "2",
                "Filter 1": "Alaska",
                "Name": "plot_b",
                "Main Visualization": "",
            },
        )

        shard = (data_dir / "data-Alaska.js").read_text()
        assert "plot_a" in shard
        assert "plot_b" in shard
        assert shard.strip().startswith("window.addRows(`")
        assert shard.strip().endswith("`);")

    def test_batch_from_tsv(self, tmp_path):
        tsv_path = tmp_path / "input.tsv"
        html_path = dashboard_html_path(tmp_path)
        data_dir = comparisons_index_data_dir(tmp_path)

        with open(tsv_path, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["Index", "Filter 1", "Name"], delimiter="\t")
            writer.writeheader()
            writer.writerow({"Index": "1", "Filter 1": "", "Name": "row1"})
            writer.writerow({"Index": "2", "Filter 1": "TX", "Name": "row2"})

        create_html_from_csv(tsv_path, html_path, data_dir=data_dir)

        assert html_path.exists()
        assert (data_dir / "data-_none_.js").exists()
        assert (data_dir / "data-TX.js").exists()

        content = html_path.read_text()
        assert 'src="dashboard_data/comparisons_index/data-_none_.js"' in content
        assert 'src="dashboard_data/comparisons_index/data-TX.js"' in content
