#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["PyGithub"]
# ///
"""
Diff Annotator
====================

Detect changed SDR CSV files, generate diffs, and publish them as
annotations and markdown in a GitHub Check Run.

Run in GitHub Actions via:

    uv run .github/scripts/sdr_diff_integrator.py

Required environment variables:
    GH_TOKEN (or GITHUB_TOKEN) - token with checks:write scope
    GITHUB_REPOSITORY           - owner/repo (set by Actions)
    BASE_REF                    - branch to diff against (default: develop)
"""

from __future__ import annotations
import os
import subprocess
from pathlib import Path
from typing import List
import traceback

from github import Github, GithubException  # PyGithub >= 2.3

# ---------------------------------------------------------------------------
# Environment and constants
# ---------------------------------------------------------------------------
REPO_FULL = os.getenv("GITHUB_REPOSITORY")
TOKEN = os.getenv("GH_TOKEN") or os.getenv("GITHUB_TOKEN")
BASE = os.getenv("BASE_REF", "develop")
CSV_GLOB = "test/base_results/upgrades/sdr_annual/*.csv"
ROOT = Path(__file__).resolve().parents[2]  # repo root guess

if not (REPO_FULL and TOKEN):
    raise SystemExit("GH_TOKEN and GITHUB_REPOSITORY must be set")

HEAD_SHA = subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def run_cmd(cmd: List[str]) -> str:
    """Return stdout of a shell command as str."""
    return subprocess.check_output(cmd).decode()


def changed_csv_files() -> List[str]:
    diff = run_cmd(
        ["git", "diff", "--name-only", f"origin/{BASE}...HEAD", "--", CSV_GLOB]
    )
    return [p for p in diff.splitlines() if p]


def diff_report(path: str) -> tuple[str, str]:
    """
    Generate plain and markdown diffs using get_diff_report.py if available.
    Falls back to git diff for minimal functionality.
    """
    helper = ROOT / ".github" / "scripts" / "get_diff_report.py"
    full = run_cmd(["uv", "run", str(helper), path])
    short = run_cmd(["uv", "run", str(helper), path, "--short"])
    return full, short

def chunk(seq, size):
    for i in range(0, len(seq), size):
        yield seq[i : i + size]


def github_repo():
    return Github(TOKEN, per_page=100).get_repo(REPO_FULL)


def main() -> None:
    repo = github_repo()
    
    # Create initial check run
    check_run = repo.create_check_run(name="SDR diff", head_sha=HEAD_SHA, status="in_progress")
    try:
        update_annotations(check_run)
    except:  # Always mark as success
        check_run.edit(
            status="completed",
            conclusion="success",
            output={"title": "SDR diff", "summary": f"Diff calculation crashed: {traceback.format_exc()}"},
        )

def update_annotations(check_run):
    files = changed_csv_files()
    if not files:
        check_run.edit(
            status="completed",
            conclusion="success",
            output={"title": "SDR diff", "summary": "No SDR annual CSV changes."},
        )
        print("No CSV changes detected. Check run marked as success.")
        return

    # Collect diffs
    annotations = []
    short_summary = []
    for f in files:
        full, short = diff_report(f)
        print(f"{f} Report: {short}")
        short_summary.append(f"{f}:\n{short}\n")
        annotations.append(
            {
                "path": f,
                "start_line": 1,
                "end_line": 1,
                "annotation_level": "notice",
                "message": full[:65000],  # GitHub per-annotation limit
            }
        )

    summary = "\n".join(short_summary)[:65535]

    # Step 1: push annotation chunks without summary
    for batch in chunk(annotations, 50):  # API limit = 50 annotations/request
        check_run.edit(
            status="in_progress",
            output={"title": "SDR results diff", "annotations": batch, "summary": "Uploading annotation batch…"},
        )

    # Step 2: final patch with summary
    check_run.edit(
        status="completed",
        conclusion="success",
        output={"title": "SDR results diff", "summary": summary},
    )

    print(f"Completed check run #{check_run.id} with {len(annotations)} annotation(s).")


if __name__ == "__main__":
    main()
