"""Tests for the baseline validation CLI entry point."""

from types import SimpleNamespace

import pytest

import resstockpostproc.baseline_validation.main as main_module


class TestBaselineValidationMain:
    def test_main_runs_standard_generator_path(self, tmp_path, monkeypatch):
        config_path = tmp_path / "workflow.yaml"
        config_path.write_text("workgroup: rescore\noutput:\n  output_dir: /tmp\n  run_name: test\n", encoding="utf-8")

        calls = []
        monkeypatch.setattr(
            main_module,
            "workflow",
            SimpleNamespace(ensure_resstock_data_files=lambda: calls.append("ensure")),
        )
        monkeypatch.setattr(main_module, "generate_plots", lambda: calls.append("generate"))
        monkeypatch.setattr(
            main_module.sys,
            "argv",
            ["main.py", "--config", str(config_path)],
        )

        assert main_module.main() == 0
        assert calls == ["ensure", "generate"]

    @pytest.mark.parametrize("removed_flag", ["--output", "--plot-type"])
    def test_main_rejects_removed_cli_flags(self, monkeypatch, removed_flag):
        monkeypatch.setattr(
            main_module.sys,
            "argv",
            ["main.py", removed_flag, "html"],
        )

        with pytest.raises(SystemExit) as err:
            main_module.main()

        assert err.value.code == 2
