"""Unit tests for tools/run_tests.py's timing, module and worker helpers.

Tests load_timings, save_timings, module_file, local_imports, expand_cases,
and default_workers without touching real timing files or repository state.
"""
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

# Ensure repo root is on sys.path so tools can be imported.
ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools import run_tests  # noqa: E402


class TestRunTestsTimings(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dir = Path(self._tmp.name)

    def test_save_and_load_timings(self) -> None:
        file_path = self.dir / "timings.json"
        run_tests.save_timings(file_path, {"tests.test_a": 1.543, "tests.test_b": 2.0})
        self.assertEqual(run_tests.load_timings(file_path), {"tests.test_a": 1.5, "tests.test_b": 2.0})

    def test_save_timings_merges_with_existing(self) -> None:
        file_path = self.dir / "timings.json"
        run_tests.save_timings(file_path, {"tests.test_a": 1.0, "tests.test_b": 2.0})
        run_tests.save_timings(file_path, {"tests.test_b": 7.26})
        self.assertEqual(run_tests.load_timings(file_path), {"tests.test_a": 1.0, "tests.test_b": 7.3})
        self.assertEqual([p.name for p in self.dir.iterdir()], ["timings.json"], "no temp file left behind")

    def test_save_timings_skips_empty_and_none(self) -> None:
        file_path = self.dir / "timings.json"
        run_tests.save_timings(file_path, {})
        run_tests.save_timings(None, {"tests.test_a": 1.0})
        self.assertFalse(file_path.exists())

    def test_load_timings_missing_file(self) -> None:
        self.assertEqual(run_tests.load_timings(self.dir / "nonexistent.json"), {})

    def test_load_timings_corrupt_file(self) -> None:
        file_path = self.dir / "corrupt.json"
        file_path.write_text("not a valid json {", encoding="utf-8")
        self.assertEqual(run_tests.load_timings(file_path), {})

    def test_load_timings_drops_non_numbers_and_non_dicts(self) -> None:
        file_path = self.dir / "timings.json"
        file_path.write_text(json.dumps({"tests.test_a": 3, "tests.test_b": "slow", "tests.test_c": None}), encoding="utf-8")
        self.assertEqual(run_tests.load_timings(file_path), {"tests.test_a": 3.0})
        file_path.write_text(json.dumps([1.0, 2.0]), encoding="utf-8")
        self.assertEqual(run_tests.load_timings(file_path), {})

    def test_load_timings_none_path(self) -> None:
        self.assertEqual(run_tests.load_timings(None), {})


class TestRunTestsModuleHelpers(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dir = Path(self._tmp.name)

    def write_source(self, text: str) -> Path:
        path = self.dir / "sample.py"
        path.write_text(text, encoding="utf-8")
        return path

    def test_module_file(self) -> None:
        path = run_tests.module_file("tests.test_run_tests")
        self.assertEqual(path, run_tests.ROOT / "tests" / "test_run_tests.py")

    def test_local_imports(self) -> None:
        path = self.write_source("import run_tests\nfrom admission import find_item\nimport sys\n")
        expected = {run_tests.TOOLS / "run_tests.py", run_tests.TOOLS / "admission.py"}
        self.assertEqual(run_tests.local_imports(path), expected)

    def test_local_imports_dotted_names_and_tests_folder(self) -> None:
        # A dotted name resolves by its last part, in tools/ or tests/.
        path = self.write_source("import tools.admission\nfrom tests import test_run_tests\nimport tests.test_run_tests\n")
        expected = {run_tests.TOOLS / "admission.py", run_tests.TESTS / "test_run_tests.py"}
        self.assertEqual(run_tests.local_imports(path), expected)

    def test_local_imports_ignores_relative_imports(self) -> None:
        path = self.write_source("from .admission import find_item\nfrom . import run_tests\n")
        self.assertEqual(run_tests.local_imports(path), set())

    def test_local_imports_unreadable_source(self) -> None:
        self.assertEqual(run_tests.local_imports(self.write_source("def broken(:\n")), set())
        self.assertEqual(run_tests.local_imports(self.dir / "missing.py"), set())

    def test_expand_cases(self) -> None:
        cases = run_tests.expand_cases(["tests.test_admission_helpers"])
        self.assertTrue(cases)
        self.assertTrue(all(c.startswith("tests.test_admission_helpers.") for c in cases), cases)


class TestRunTestsWorkerHelpers(unittest.TestCase):
    def test_default_workers_minimum(self) -> None:
        with mock.patch.dict(os.environ):
            os.environ.pop("MEADOW_TEST_WORKERS", None)
            self.assertGreaterEqual(run_tests.default_workers(), 1)

    def test_default_workers_env_override(self) -> None:
        with mock.patch.dict(os.environ, {"MEADOW_TEST_WORKERS": "5"}):
            self.assertEqual(run_tests.default_workers(), 5)

    def test_default_workers_ignores_invalid_override(self) -> None:
        with mock.patch.dict(os.environ):
            os.environ.pop("MEADOW_TEST_WORKERS", None)
            fallback = run_tests.default_workers()
            for value in ("0", "-2", "many", ""):
                os.environ["MEADOW_TEST_WORKERS"] = value
                self.assertEqual(run_tests.default_workers(), fallback, value)


if __name__ == "__main__":
    unittest.main()
