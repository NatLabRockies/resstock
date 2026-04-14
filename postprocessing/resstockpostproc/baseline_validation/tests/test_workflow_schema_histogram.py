"""Tests for histogram raw-data workflow path inference and validation."""

from pathlib import Path

import pytest
from pydantic import ValidationError

from resstockpostproc.baseline_validation.schema.workflow_schema import WorkflowConfig


def _base_cfg(root: Path, output_dir: Path) -> dict:
    return {
        "workgroup": "rescore",
        "resstock_histogram_data_root": str(root),
        "data_sources": [
            {
                "name": "resstock_2024",
                "db_name": "db_a",
                "table_name": "table_a",
                "db_schema": "resstock_oedi_new",
            },
            {
                "name": "resstock_2025",
                "db_name": "db_b",
                "table_name": "table_b",
                "db_schema": "resstock_oedi_new",
            },
        ],
        "output": {
            "output_dir": str(output_dir),
            "run_name": "unit-test",
        },
    }


class TestWorkflowHistogramPathInference:
    def test_infers_upgrade0_paths_for_each_data_source(self, tmp_path: Path):
        root = tmp_path / "data"
        file_2024 = root / "ResStock Data" / "resstock_2024" / "upgrade0.parquet"
        file_2025 = root / "ResStock Data" / "resstock_2025" / "upgrade0.parquet"
        file_2024.parent.mkdir(parents=True, exist_ok=True)
        file_2025.parent.mkdir(parents=True, exist_ok=True)
        file_2024.touch()
        file_2025.touch()

        cfg = WorkflowConfig.model_validate(_base_cfg(root=root, output_dir=tmp_path / "out"))

        assert cfg.get_resstock_histogram_raw_file("resstock_2024") == file_2024
        assert cfg.get_resstock_histogram_raw_file("resstock_2025") == file_2025

    def test_missing_raw_files_fail_fast_with_actionable_error(self, tmp_path: Path):
        root = tmp_path / "data"
        file_2024 = root / "ResStock Data" / "resstock_2024" / "upgrade0.parquet"
        file_2024.parent.mkdir(parents=True, exist_ok=True)
        file_2024.touch()

        with pytest.raises(ValidationError, match="Missing required ResStock histogram raw parquet files") as exc:
            WorkflowConfig.model_validate(_base_cfg(root=root, output_dir=tmp_path / "out"))

        err_text = str(exc.value)
        expected_missing = root / "ResStock Data" / "resstock_2025" / "upgrade0.parquet"
        assert str(expected_missing) in err_text
