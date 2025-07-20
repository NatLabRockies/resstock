#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["PyGithub"]
# ///
"""
Diff Annotator
====================

Detect changed CSV files, generate diffs, and publish them as
annotations and markdown in a GitHub Check Run.

Run in GitHub Actions via:

    uv run .github/scripts/diff_annotator.py

Can be run locally via:

    uv run .github/scripts/diff_annotator.py --local

Required environment variables when running in GitHub Actions:
    GH_TOKEN (or GITHUB_TOKEN) - token with checks:write scope
    GITHUB_REPOSITORY           - owner/repo (set by Actions)
    BASE_REF                    - branch to diff against (default: develop)
"""

from __future__ import annotations
import os
import subprocess
from pathlib import Path
from typing import List, TypedDict
import traceback
from github import Github  # PyGithub >= 2.3
import argparse

# ---------------------------------------------------------------------------
# Environment and constants
# ---------------------------------------------------------------------------
REPO_FULL = os.getenv("GITHUB_REPOSITORY")
TOKEN = os.getenv("GH_TOKEN") or os.getenv("GITHUB_TOKEN")
BASE = os.getenv("BASE_REF", "develop")
ROOT = Path(__file__).resolve().parents[2]  # repo root guess

HEAD_SHA = subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()

class CsvScanItem(TypedDict):
    path: str
    key_columns: List[str]   # or list[str] on Python ≥3.9


CSV_TO_SCAN: list[CsvScanItem] = [
    {
        "path": "test/base_results/upgrades/sdr_annual/*.csv",
        "key_columns": ["bldg_id"]
    },
    {
        "path": "test/base_results/baseline/timeseries/buildstockbatch.csv",
        "key_columns": ["PROJECT", "time"],
    },
    {
        "path": "test/base_results/baseline/timeseries/results_output.csv",
        "key_columns": ["PROJECT", "Time"],
    },
    {
        "path": "test/base_results/baseline/annual/buildstock.csv",
        "key_columns": ["Building"],
    },
    {
        "path": "test/base_results/baseline/annual/results_characteristics.csv",
        "key_columns": ["OSW"],
    },
    {
        "path": "test/base_results/baseline/annual/results_output.csv",
        "key_columns": ["OSW"],
    }
]
# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def run_cmd(cmd: List[str]) -> str:
    """Return stdout of a shell command as str."""
    return subprocess.check_output(cmd).decode()


def changed_csv_files() -> List[CsvScanItem]:
    changed_files: list[CsvScanItem] = []
    for csv_group in CSV_TO_SCAN:
        diff = run_cmd(
            ["git", "diff", "--name-only", f"origin/{BASE}...HEAD", "--", csv_group["path"]]
        )
        changed_files.extend([{"path": p, "key_columns": csv_group["key_columns"]} for p in diff.splitlines() if p])
    return changed_files


def diff_report(path: str, key_columns: list[str]) -> tuple[str, str]:
    helper = ROOT / ".github" / "scripts" / "get_diff_report.py"
    command = ["uv", "run", str(helper), path]
    for key_column in key_columns:
        command.append("--key-column")
        command.append(key_column)
    full = run_cmd(command)
    if "DataComPy Comparison" in full:
        short = full[:full.index("DataComPy Comparison")].strip()
    else:
        short = full
    return full, short

def chunk(seq, size):
    for i in range(0, len(seq), size):
        yield seq[i : i + size]


def github_repo():
    return Github(TOKEN, per_page=100).get_repo(REPO_FULL)


def get_all_changes():
    files = changed_csv_files()
    if not files:
        return []
    changes = []
    for file in files:
        full, short = diff_report(file["path"], file["key_columns"])
        changes.append(
            {
                "path": file['path'],
                "full_report": full,
                "short_report": short,
            }
        )
    return changes

def print_changes(changes):
    print("These files have changes:")
    for change in changes:
        print(f"{change['path']} Report: {change['short_report']}")
    print("\nHere are the full reports:")
    for change in changes:
        print(f"{change['path']} Report: {change['full_report']}")

def main() -> None:
    """CLI entry point.

    Without arguments, prints diff reports for any changed CSVs. If the
    optional ``--local`` flag is supplied, the script prints the diff reports
    to the console and exits without creating a GitHub Check Run annotations.
    """

    parser = argparse.ArgumentParser(description="Generate CSV diffs and optionally annotate the commit.")
    parser.add_argument(
        "--local",
        action="store_true",
        help="Create a GitHub Check Run containing the diff annotations.",
    )
    args = parser.parse_args()

    # Gather diff information
    try:
        changes = get_all_changes()
    except Exception:
        print(f"Failed to get changes: {traceback.format_exc()}")
        return

    if not changes:
        print("No changes detected.")
        return

    # Exit early when --local is requested
    if args.local:
        print_changes(changes)
        return

    if not (REPO_FULL and TOKEN):
        raise SystemExit("GH_TOKEN and GITHUB_REPOSITORY must be set to annotate. Use --local to print the diff reports to the console.")

    repo = github_repo()
    check_run = repo.create_check_run(name="CSV diff", head_sha=HEAD_SHA, status="in_progress")
    try:
        update_annotations(check_run, changes)
    except Exception:
        check_run.edit(
            status="completed",
            conclusion="success",
            output={"title": "CSV diff", "summary": f"Diff calculation crashed: {traceback.format_exc()}"},
        )

def update_annotations(check_run, changes):
    annotations = []
    short_summary = []
    for change in changes:
        print(f"{change['path']} Report: {change['short_report']}")
        short_summary.append(f"{change['path']}:\n{change['short_report']}\n")
        annotations.append(
            {
                "path": change['path'],
                "start_line": 1,
                "end_line": 1,
                "annotation_level": "notice",
                "message": change['full_report'][:65000],  # GitHub per-annotation limit
            }
        )

    summary = "\n".join(short_summary)[:65535]

    # Step 1: push annotation chunks without summary
    for batch in chunk(annotations, 50):  # API limit = 50 annotations/request
        check_run.edit(
            status="in_progress",
            output={"title": "CSV diff results", "annotations": batch, "summary": "Uploading annotation batch…"},
        )

    # Step 2: final patch with summary
    check_run.edit(
        status="completed",
        conclusion="success",
        output={"title": "CSV diff results", "summary": summary},
    )

    print(f"Completed check run #{check_run.id} with {len(annotations)} annotation(s).")


if __name__ == "__main__":
    main()
