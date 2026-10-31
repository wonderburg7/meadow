"""Unit tests for pure helper functions in tools/foraging_evidence_report.py."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.foraging_evidence_report import _summary


class TestForagingEvidenceReportHelpers(unittest.TestCase):
	def test_summary_extracts_summary_and_runtime(self) -> None:
		with tempfile.TemporaryDirectory() as tmp_dir:
			root = Path(tmp_dir)
			run_dir = root / "case1" / "run1"
			run_dir.mkdir(parents=True)

			result_data = {
				"process": {
					"wall_seconds": 12.5,
				},
			}
			(run_dir / "result.json").write_text(json.dumps(result_data), encoding="utf-8")

			report_data = {
				"summary": {
					"flower_visits": 42,
					"forager_deliveries": 10,
				},
			}
			(run_dir / "report.json").write_text(json.dumps(report_data), encoding="utf-8")

			run_info = {"result": "case1/run1/result.json"}
			summary = _summary(run_info, root)

			self.assertEqual(summary["flower_visits"], 42)
			self.assertEqual(summary["forager_deliveries"], 10)
			self.assertEqual(summary["runtime_seconds"], 12.5)

	def test_summary_defaults_runtime_when_missing(self) -> None:
		with tempfile.TemporaryDirectory() as tmp_dir:
			root = Path(tmp_dir)
			run_dir = root / "case_empty" / "run1"
			run_dir.mkdir(parents=True)

			(run_dir / "result.json").write_text(json.dumps({}), encoding="utf-8")

			report_data = {
				"summary": {
					"flower_visits": 0,
				},
			}
			(run_dir / "report.json").write_text(json.dumps(report_data), encoding="utf-8")

			run_info = {"result": "case_empty/run1/result.json"}
			summary = _summary(run_info, root)

			self.assertEqual(summary["flower_visits"], 0)
			self.assertEqual(summary["runtime_seconds"], 0.0)


if __name__ == "__main__":
	unittest.main()
