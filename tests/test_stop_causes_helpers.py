"""Unit tests for pure helper load_baseline in tools/stop_causes.py."""

import json
import tempfile
import unittest
from pathlib import Path

from tools.stop_causes import BASELINE_FILE, load_baseline


class TestStopCausesLoadBaseline(unittest.TestCase):
    def test_default_path(self) -> None:
        """load_baseline() with default path loads the repo baseline file."""
        data = load_baseline()
        self.assertIsInstance(data, dict)
        self.assertIn("failures", data)
        self.assertIsInstance(data["failures"], list)

    def test_explicit_valid_file(self) -> None:
        """load_baseline(path) loads valid json correctly."""
        with tempfile.TemporaryDirectory() as tmpdir:
            sample_file = Path(tmpdir) / "baseline.json"
            sample_data = {"failures": [{"test": "test_foo", "expires": "2099-01-01"}]}
            sample_file.write_text(json.dumps(sample_data), encoding="utf-8")

            loaded = load_baseline(sample_file)
            self.assertEqual(loaded, sample_data)

    def test_missing_file_returns_empty_failures(self) -> None:
        """load_baseline(path) returns empty failures dict when file does not exist."""
        missing = Path("/nonexistent/path/baseline_failures.json")
        loaded = load_baseline(missing)
        self.assertEqual(loaded, {"failures": []})

    def test_malformed_json_returns_empty_failures(self) -> None:
        """load_baseline(path) returns empty failures dict when json is malformed."""
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "bad.json"
            bad_file.write_text("{ not json", encoding="utf-8")

            loaded = load_baseline(bad_file)
            self.assertEqual(loaded, {"failures": []})

    def test_non_dict_json_returns_empty_failures(self) -> None:
        """load_baseline(path) returns empty failures dict when json root is not a dict."""
        with tempfile.TemporaryDirectory() as tmpdir:
            list_file = Path(tmpdir) / "list.json"
            list_file.write_text("[]", encoding="utf-8")

            loaded = load_baseline(list_file)
            self.assertEqual(loaded, {"failures": []})


if __name__ == "__main__":
    unittest.main()
