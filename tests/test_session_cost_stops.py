"""Regression tests for the stop-ledger report."""

import contextlib
import io
import json
import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import session_cost


class StopLedgerReportTest(unittest.TestCase):
    def test_preflight_refusals_are_tallied_separately_from_steps(self):
        records = [
            {"command": "finish", "step": "verify", "cause": "tests failed"},
            {"command": "start", "step": "", "cause": "Codex lane already has an open worktree: ST-1"},
            {"command": "start", "cause": "Codex lane already has an open worktree: ST-1"},
            {"command": "start", "step": None, "cause": "lifecycle is busy"},
        ]
        with tempfile.TemporaryDirectory() as temp_dir:
            ledger = Path(temp_dir) / "meadow-slice-stops.jsonl"
            ledger.write_text(
                "\n".join(json.dumps(record) for record in records) + "\n",
                encoding="utf-8",
            )
            output = io.StringIO()
            with mock.patch.object(session_cost, "_stops_ledger_path", return_value=ledger):
                with contextlib.redirect_stdout(output):
                    session_cost.run_stops()

        report = output.getvalue()
        self.assertIn("stops recorded               4", report)
        self.assertIn("stops in steps               1", report)
        self.assertIn("preflight refusals           3", report)
        self.assertIn("preflight refusals by cause:", report)
        self.assertIn("    2  Codex lane already has an open worktree: ST-1", report)
        self.assertIn("    1  lifecycle is busy", report)
        total = int(re.search(r"stops recorded\s+(\d+)", report).group(1))
        step_total = int(re.search(r"stops in steps\s+(\d+)", report).group(1))
        preflight_total = int(re.search(r"preflight refusals\s+(\d+)", report).group(1))
        self.assertEqual(step_total + preflight_total, total)

        ranking = report.split("most expensive steps (each stop is a read, a fix and a retry):\n", 1)[1]
        self.assertEqual(ranking, "    1  verify\n")
        self.assertNotIn("open worktree", ranking)


    def test_days_keeps_only_stops_inside_the_window(self):
        from datetime import datetime, timedelta
        recent = (datetime.now() - timedelta(days=1)).isoformat(timespec="seconds")
        old = (datetime.now() - timedelta(days=30)).isoformat(timespec="seconds")
        records = [
            {"at": recent, "command": "finish", "step": "verify", "cause": "tests failed"},
            {"at": old, "command": "finish", "step": "verify", "cause": "tests failed"},
            {"at": old, "command": "start", "step": "", "cause": "lifecycle is busy"},
        ]
        with tempfile.TemporaryDirectory() as temp_dir:
            ledger = Path(temp_dir) / "meadow-slice-stops.jsonl"
            ledger.write_text("\n".join(json.dumps(r) for r in records) + "\n", encoding="utf-8")
            reports = []
            for days in (7, None):
                output = io.StringIO()
                with mock.patch.object(session_cost, "_stops_ledger_path", return_value=ledger):
                    with contextlib.redirect_stdout(output):
                        session_cost.run_stops(days)
                reports.append(output.getvalue())

        self.assertIn("window                       last 7 days", reports[0])
        self.assertIn("stops recorded               1", reports[0])
        self.assertIn("preflight refusals           0", reports[0])
        self.assertNotIn("window", reports[1])
        self.assertIn("stops recorded               3", reports[1])


if __name__ == "__main__":
    unittest.main()
