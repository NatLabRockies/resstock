"""Tests for ResStock baseline parquet path inference and lazy download."""

from pathlib import Path

from resstockpostproc.baseline_validation.schema import workflow_schema
from resstockpostproc.baseline_validation.schema.workflow_schema import WorkflowConfig


def _base_cfg(output_dir: Path) -> dict:
    return {
        "workgroup": "rescore",
        "data_sources": [
            {
                "name": "resstock_2024",
                "db_name": "db_a",
                "table_name": "table_a",
                "db_schema": "resstock_oedi_new",
                "baseline_metadata_and_annual_results_parquet_url": "s3://bucket-a/path/to/a.parquet",
            },
            {
                "name": "resstock_2025",
                "db_name": "db_b",
                "table_name": "table_b",
                "db_schema": "resstock_oedi_new",
                "baseline_metadata_and_annual_results_parquet_url": "s3://bucket-b/path/to/b.parquet",
            },
        ],
        "output": {
            "output_dir": str(output_dir),
            "run_name": "unit-test",
        },
    }


class TestWorkflowHistogramPathInference:
    def test_infers_upgrade0_paths_under_output_data_root(self, tmp_path: Path):
        output_dir = tmp_path / "out"
        file_2024 = output_dir / "data" / "ResStock Data" / "resstock_2024" / "upgrade0.parquet"
        file_2025 = output_dir / "data" / "ResStock Data" / "resstock_2025" / "upgrade0.parquet"
        file_2024.parent.mkdir(parents=True, exist_ok=True)
        file_2025.parent.mkdir(parents=True, exist_ok=True)
        file_2024.touch()
        file_2025.touch()

        cfg = WorkflowConfig.model_validate(_base_cfg(output_dir=output_dir))

        assert cfg.resstock_data_root == output_dir / "data"
        assert cfg.get_resstock_data_file_path("resstock_2024") == file_2024
        assert cfg.get_resstock_data_file_path("resstock_2025") == file_2025

    def test_missing_local_file_downloads_from_configured_s3_url(self, tmp_path: Path, monkeypatch):
        cfg = WorkflowConfig.model_validate(_base_cfg(output_dir=tmp_path / "out"))
        downloaded = []

        def _fake_download(s3_url: str, local_path: Path) -> Path:
            downloaded.append((s3_url, local_path))
            local_path.parent.mkdir(parents=True, exist_ok=True)
            local_path.touch()
            return local_path

        monkeypatch.setattr(workflow_schema, "download_s3_file", _fake_download)

        local_path = cfg.get_resstock_data_file("resstock_2025")

        assert local_path == cfg.get_resstock_data_file_path("resstock_2025")
        assert local_path.exists()
        assert downloaded == [("s3://bucket-b/path/to/b.parquet", local_path)]

    def test_missing_url_raises_actionable_error(self, tmp_path: Path):
        cfg_dict = _base_cfg(output_dir=tmp_path / "out")
        cfg_dict["data_sources"][1]["baseline_metadata_and_annual_results_parquet_url"] = None
        cfg = WorkflowConfig.model_validate(cfg_dict)

        expected_path = cfg.get_resstock_data_file_path("resstock_2025")
        try:
            cfg.get_resstock_data_file("resstock_2025")
        except ValueError as err:
            err_text = str(err)
        else:
            raise AssertionError("Expected missing parquet URL to raise ValueError")

        assert "baseline_metadata_and_annual_results_parquet_url" in err_text
        assert str(expected_path) in err_text
