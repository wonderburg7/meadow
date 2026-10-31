"""Unit tests for tools/stop_causes.py's helper functions."""

from contextlib import redirect_stdout
from datetime import date
from io import StringIO
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import stop_causes  # noqa: E402


class StopCausesHelpersTests(unittest.TestCase):
    def test_load_baseline_returns_dict_when_valid(self):
        with tempfile.TemporaryDirectory() as scratch:
            baseline_path = Path(scratch) / "baseline.json"
            baseline_path.write_text('{"failures": [{"test": "t1", "expires": "2026-11-01"}]}', encoding="utf-8")
            data = stop_causes.load_baseline(baseline_path)
            self.assertEqual(data, {"failures": [{"test": "t1", "expires": "2026-11-01"}]})

    def test_load_baseline_returns_empty_failures_on_missing_file(self):
        with tempfile.TemporaryDirectory() as scratch:
            missing_path = Path(scratch) / "nonexistent.json"
            data = stop_causes.load_baseline(missing_path)
            self.assertEqual(data, {"failures": []})

    def test_load_baseline_returns_empty_failures_on_corrupt_json(self):
        with tempfile.TemporaryDirectory() as scratch:
            corrupt_path = Path(scratch) / "corrupt.json"
            corrupt_path.write_text("invalid json content {{{", encoding="utf-8")
            data = stop_causes.load_baseline(corrupt_path)
            self.assertEqual(data, {"failures": []})

    def test_load_baseline_returns_empty_failures_on_non_dict_json(self):
        with tempfile.TemporaryDirectory() as scratch:
            array_path = Path(scratch) / "array.json"
            array_path.write_text('[1, 2, 3]', encoding="utf-8")
            self.assertEqual(stop_causes.load_baseline(array_path), {"failures": []})

            int_path = Path(scratch) / "int.json"
            int_path.write_text('42', encoding="utf-8")
            self.assertEqual(stop_causes.load_baseline(int_path), {"failures": []})

    def test_load_baseline_uses_default_baseline_file_when_unspecified(self):
        with tempfile.TemporaryDirectory() as scratch:
            fake_default = Path(scratch) / "default_baseline.json"
            fake_default.write_text('{"failures": [{"test": "default_test"}]}', encoding="utf-8")
            with patch.object(stop_causes, "BASELINE_FILE", fake_default):
                data = stop_causes.load_baseline()
                self.assertEqual(data, {"failures": [{"test": "default_test"}]})

    def test_live_ids_loads_baseline_when_none(self):
        fake_baseline = {
            "failures": [
                {"test": "auto_loaded_test", "expires": "2026-12-01"}
            ]
        }
        with patch.object(stop_causes, "load_baseline", return_value=fake_baseline):
            live = stop_causes.live_ids(baseline=None, today=date(2026, 10, 31))
            self.assertEqual(live, {"auto_loaded_test"})

    def test_expired_entries_loads_baseline_when_none(self):
        fake_baseline = {
            "failures": [
                {"test": "expired_test", "expires": "2026-10-01", "owner": "Dave", "disposition": "fix"}
            ]
        }
        with patch.object(stop_causes, "load_baseline", return_value=fake_baseline):
            problems = stop_causes.expired_entries(baseline=None, today=date(2026, 10, 31))
            self.assertEqual(len(problems), 1)
            self.assertIn("expired 2026-10-01", problems[0])

    def test_read_helper_reads_file_contents(self):
        with tempfile.TemporaryDirectory() as scratch:
            target = Path(scratch) / "sample.txt"
            target.write_text("sample content line\nsecond line", encoding="utf-8")
            self.assertEqual(stop_causes._read(str(target)), "sample content line\nsecond line")

    def test_read_helper_reads_stdin_when_dash(self):
        with patch("sys.stdin", StringIO("standard input text")):
            self.assertEqual(stop_causes._read("-"), "standard input text")

    def test_main_displays_usage_on_invalid_arguments(self):
        out = StringIO()
        with redirect_stdout(out):
            code = stop_causes.main(["stop_causes.py"])
        self.assertEqual(code, 2)
        self.assertIn("Name a stop cause instead of rediagnosing it", out.getvalue())

        out_bad = StringIO()
        with redirect_stdout(out_bad):
            code_bad = stop_causes.main(["stop_causes.py", "unknown_subcommand", "-"])
        self.assertEqual(code_bad, 2)
        self.assertIn("Usage:", out_bad.getvalue())

    def test_main_classify_subcommand(self):
        out = StringIO()
        sample_log = "error: cannot find Godot"
        with tempfile.TemporaryDirectory() as scratch:
            log_file = Path(scratch) / "log.txt"
            log_file.write_text(sample_log, encoding="utf-8")
            with redirect_stdout(out):
                code = stop_causes.main(["stop_causes.py", "classify", str(log_file)])
            self.assertEqual(code, 0)
            self.assertIn("cause:", out.getvalue())
            self.assertIn("remedy:", out.getvalue())

    def test_main_baseline_subcommand(self):
        with tempfile.TemporaryDirectory() as scratch:
            log_file = Path(scratch) / "log.txt"
            log_file.write_text("random log text with no failures", encoding="utf-8")
            out = StringIO()
            with redirect_stdout(out):
                code = stop_causes.main(["stop_causes.py", "baseline", str(log_file)])
            # when no failures found, returns 1
            self.assertEqual(code, 1)

            # when failing test is in baseline, returns 0 and prints line
            failing_log = (
                "FAIL: test_x (module.Class)\n"
            )
            log_file.write_text(failing_log, encoding="utf-8")
            fake_baseline = {
                "failures": [
                    {"test": "module.Class.test_x", "expires": "2099-01-01"}
                ]
            }
            with patch.object(stop_causes, "load_baseline", return_value=fake_baseline):
                out_baseline = StringIO()
                with redirect_stdout(out_baseline):
                    code_baseline = stop_causes.main(["stop_causes.py", "baseline", str(log_file)])
                self.assertEqual(code_baseline, 0)
                self.assertIn("baseline, not this branch: module.Class.test_x", out_baseline.getvalue())


if __name__ == "__main__":
    unittest.main()
