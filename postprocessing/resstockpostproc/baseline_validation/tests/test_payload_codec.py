"""Round-trip tests for the gzip+base64 dashboard payload encoding."""

import base64
import gzip
import json
import re

from resstockpostproc.baseline_validation.dashboard.create_html import create_html_from_rows
from resstockpostproc.baseline_validation.dashboard.payload_codec import encode_gzip_b64


def _decode(b64: str) -> str:
    return gzip.decompress(base64.b64decode(b64)).decode("utf-8")


def test_encode_round_trip():
    original = "col1\tcol2\nEIA 2018\tState: Wyoming\n"
    assert _decode(encode_gzip_b64(original)) == original


def test_encode_is_deterministic():
    text = "a\tb\tc\n" * 100
    assert encode_gzip_b64(text) == encode_gzip_b64(text)


_HEADERS = [
    "Comparison Dataset",
    "Quantity",
    "Metric",
    "Coverage",
    "Filter 1",
    "Filter 2",
    "Group By",
    "Comparison Plot",
    "Data",
]


def test_emitted_shard_and_combinations_decode(tmp_path):
    rows = [
        {
            "Filter 1": "State: Wyoming",
            "Comparison Plot": "Bar Plot||p.html",
            "Data": "",
            "Comparison Dataset": "EIA 2018",
            "Quantity": "Electricity",
            "Metric": "Total Annual Consumption",
        },
    ]
    html_path = tmp_path / "comparison_dashboard.html"
    create_html_from_rows(rows, _HEADERS, html_path)
    data_dir = html_path.parent / "comparisons_index"

    combo_js = (data_dir / "combinations.js").read_text(encoding="utf-8")
    combo_b64 = re.search(r'setCombinationsZ\("([^"]+)"\)', combo_js).group(1)
    combos = json.loads(_decode(combo_b64))
    assert isinstance(combos, list)
    assert combos

    shard_js = (data_dir / "data-State__Wyoming.js").read_text(encoding="utf-8")
    shard_b64 = re.search(r'addRowsZ\("([^"]+)"\)', shard_js).group(1)
    tsv = _decode(shard_b64)
    assert "State: Wyoming" in tsv
    assert tsv.endswith("\n")
