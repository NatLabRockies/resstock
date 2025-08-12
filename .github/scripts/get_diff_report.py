#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["polars", "datacompy"]
# ///
"""
Prints a CSV diff report for results and other csv files.
Compares the working-tree CSV against the same path on the *develop* branch and
prints a summary of differences.  It is used by the post_run workflow to generate
annotations for the SDR diff check-run so that the diff is visible in the PR.

Usage
-----
Can be run locally with:
uv run .github/scripts/get_diff_report.py path/to/file.csv

"""
import io
import subprocess
import sys
from pathlib import Path
import polars as pl
import contextlib
import argparse

# This is necessary to suppress datacompy's import time logging
with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
    import datacompy

# ─────────────────── project‑specific knobs ────────────────────
REF_BRANCH = "origin/develop"        # git reference to diff against
DEFAULT_KEY_COLUMN = "bldg_id"       # default unique row identifier
MAX_LIST_COLS = 20                    # number of columns to list as mismatched
# ───────────────────────────────────────────────────────────────

def _git_show(ref: str, file_path: Path) -> str | None:
    """Return file contents at *ref* or ``None`` if the file doesn’t exist there."""
    try:
        return subprocess.check_output(
            ["git", "show", f"{ref}:{file_path.as_posix()}"], text=True
        )
    except subprocess.CalledProcessError:
        return None


def _load_csv(text: str | None) -> pl.DataFrame | None:
    return pl.read_csv(io.StringIO(text), infer_schema_length=0) if text is not None else None


def main() -> int:  # pragma: no cover
    """Entry point for diff report script."""
    parser = argparse.ArgumentParser(
        description="Print a CSV diff report comparing the working-tree file with the same file on the reference branch.",
    )
    parser.add_argument(
        "csv_path",
        type=Path,
        help="Path to the CSV file to compare",
    )
    parser.add_argument(
        "-k",
        "--key-column",
        dest="key_columns",
        action="append",
        default=[],
        help=(
            "Unique column(s) used to join rows between the two CSVs. "
            "Pass this flag multiple times to join on multiple columns, e.g. "
            "`-k bldg_id -k upgrade_name`."
        ),
    )
    md_group = parser.add_mutually_exclusive_group()
    md_group.add_argument(
        "--markdown",
        dest="markdown",
        action="store_true",
        help="Output report with markdown formatting.",
    )
    md_group.add_argument(
        "--plain",
        dest="markdown",
        action="store_false",
        help="Output report as plain text (default).",
    )
    md_group.add_argument(
        "--short",
        dest="short",
        action="store_true",
        help="Output only the short text report",
    )
    parser.set_defaults(markdown=False)
    parser.set_defaults(short=False)

    args = parser.parse_args()
    csv_path: Path = args.csv_path
    key_columns: list[str] = args.key_columns
    if not key_columns:
        key_columns = [DEFAULT_KEY_COLUMN]
    markdown_output: bool = args.markdown

    if not csv_path.exists():
        sys.exit(f"File not found: {csv_path}")

    current_df = pl.read_csv(csv_path, infer_schema_length=0)
    ref_df = _load_csv(_git_show(REF_BRANCH, csv_path))

    if ref_df is None:
        print(f"{csv_path} is new on this branch (no counterpart on `{REF_BRANCH}`).")
        sys.exit(0)

    cmp = datacompy.PolarsCompare(
        ref_df,
        current_df,
        df1_name=REF_BRANCH,
        df2_name="current",
        join_columns=key_columns,
        cast_column_names_lower=False,
    )

    if cmp.matches(ignore_extra_columns=False):
        print(f"No differences with `{REF_BRANCH}`.")
        sys.exit(0)

    report_text = ""
    if len(cmp.df2_unq_rows) > 0:
        report_text += f"Rows with {key_columns}={list(cmp.df2_unq_rows[key_columns])} are added.\n"
    if len(cmp.df1_unq_rows) > 0:
        report_text += f"Rows with {key_columns}={list(cmp.df1_unq_rows[key_columns])} are removed.\n"

    if len(cmp.df1_unq_columns()) > 0:
        report_text += f"Columns {list(cmp.df1_unq_columns())} are removed.\n"
    if len(cmp.df2_unq_columns()) > 0:
        report_text += f"Columns {list(cmp.df2_unq_columns())} are added.\n"

    mismatched_cols = [s["column"] for s in cmp.column_stats if s.get("unequal_cnt", 0)]
    matched_cols = [s["column"] for s in cmp.column_stats if not s.get("unequal_cnt", 0)]
    if mismatched_cols and len(mismatched_cols) < len(matched_cols):
        if len(mismatched_cols) < MAX_LIST_COLS:
            report_text += (
                f"These {len(mismatched_cols)} columns have value changes: {', '.join(mismatched_cols)}\n"
            )
        else:
            report_text += f"{len(mismatched_cols)} columns have value changes\n"
    elif mismatched_cols and len(mismatched_cols) >= len(matched_cols):
        if len(matched_cols) < MAX_LIST_COLS:
            report_text += (
                f"All columns except these {len(matched_cols)} columns have value changes: {', '.join(matched_cols)}\n"
            )
        else:
            report_text += f"All but {len(matched_cols)} columns have value changes\n"

    if args.short:
        print(report_text)
        return 0

    full_report = cmp.report().strip()

    if markdown_output:
        output = (
            f"{report_text}"
            "<details><summary>Full datacompy report</summary>\n\n"
            "```text\n"
            f"{full_report}\n"
            "```\n"
            "</details>\n"
        )
    else:
        output = (
            f"{report_text}\n"
            f"{full_report}"
        )

    print(output)
    return 0


if __name__ == "__main__":
    main()
