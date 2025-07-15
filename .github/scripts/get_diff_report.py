#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["polars", "datacompy"]
# ///
"""
Prints a CSV diff report for results and other csv files.
Compares the working-tree CSV against the same path on the *develop* branch and
prints a summary of differences.  Designed to be pasted directly as a pull-request comment.

Usage
-----
uv run .github/scripts/get_diff_report.py path/to/file.csv

"""
import io
import subprocess
import sys
from pathlib import Path
import polars as pl
import contextlib

# This is necessary to suppress datacompy's import time logging
with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
    import datacompy

# ─────────────────── project‑specific knobs ────────────────────
REF_BRANCH = "develop"        # git reference to diff against
KEY_COLUMN = "bldg_id"     # unique row identifier(s)
MAX_LIST_COLS = 20           # number of columns to list as mismatched
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
    if len(sys.argv) != 2:
        sys.exit("Usage: get_diff_report.py <csv_path>")

    csv_path = Path(sys.argv[1])
    if not csv_path.exists():
        sys.exit(f"File not found: {csv_path}")

    current_df = pl.read_csv(csv_path, infer_schema_length=0)
    ref_df = _load_csv(_git_show(REF_BRANCH, csv_path))

    #current_df = current_df.drop("out.bills.electricity.usd.savings")
    # add 10 to all columns that start with out.
    current_df = current_df.with_columns([
        (pl.col(c) + '0').alias(c) for c in current_df.columns if c.startswith("out.bills.")
    ])
    
    if ref_df is None:
        print(f"{csv_path} is new on this branch (no counterpart on `{REF_BRANCH}`).")
        sys.exit(0)

    cmp = datacompy.PolarsCompare(
        ref_df,
        current_df,
        df1_name=REF_BRANCH,
        df2_name="current",
        join_columns=[KEY_COLUMN],
        cast_column_names_lower=True,
    )
    cmp.report(html_file="report.html")

    if cmp.matches(ignore_extra_columns=False):
        print(f"No differences with `{REF_BRANCH}`.")
        sys.exit(0)

    report_text = ""
    if len(cmp.df2_unq_rows) > 0:
        report_text += f"Rows with {KEY_COLUMN}={list(cmp.df2_unq_rows[KEY_COLUMN])} are added.\n"
    if len(cmp.df1_unq_rows) > 0:
        report_text += f"Rows with {KEY_COLUMN}={list(cmp.df1_unq_rows[KEY_COLUMN])} are removed.\n"
    
    if len(cmp.df1_unq_columns()) > 0:
        report_text += f"Columns {list(cmp.df1_unq_columns())} are removed.\n"
    if len(cmp.df2_unq_columns()) > 0:
        report_text += f"Columns {list(cmp.df2_unq_columns())} are added.\n"

    mismatched_cols = [s["column"] for s in cmp.column_stats if s.get("unequal_cnt", 0)]
    matched_cols = [s["column"] for s in cmp.column_stats if not s.get("unequal_cnt", 0)]
    if mismatched_cols and len(mismatched_cols) < len(matched_cols):
        if len(mismatched_cols) < MAX_LIST_COLS:
            report_text += f"These {len(mismatched_cols)} columns have value changes: {', '.join(mismatched_cols)}\n"
        else:
            report_text += f"{len(mismatched_cols)} columns have value changes\n"
    elif mismatched_cols and len(mismatched_cols) >= len(matched_cols):
        if len(matched_cols) < MAX_LIST_COLS:
            report_text += f"All columns except these {len(matched_cols)} columns have value changes: {', '.join(matched_cols)}\n"
        else:
            report_text += f"All columns except {len(matched_cols)} columns have value changes\n"
    full_report = cmp.report().strip()
    markdown = (
        f"Diff for `{csv_path}` vs `{REF_BRANCH}`\n\n"
        f"{report_text}\n\n"
        "<details><summary>Full datacompy report</summary>\n\n"
        "```text\n"
        f"{full_report}\n"
        "```\n"
        "</details>"
    )

    print(markdown)


if __name__ == "__main__":
    main()
