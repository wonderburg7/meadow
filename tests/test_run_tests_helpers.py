"""Unit tests for tools/run_tests.py's timing, module and worker helpers.

Tests load_timings, save_timings, module_file, local_imports, expand_cases,
and default_workers without touching real timing files or repository state.
"""
import os
import sys
import tempfile
import unittest
from pathlib import Path

# Ensure repo root is on sys.path so tools can be imported.
ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools import run_tests  # noqa: E402


class TestRunTestsTimings(unittest.TestCase):
    def test_save_and_load_timings(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "timings.json"
            data = {"tests.test_a": 1.543, "tests.test_b": 2.0}
            run_tests.save_timings(file_path, data)

            loaded = run_tests.load_timings(file_path)
            self.assertEqual(loaded, {"tests.test_a": 1.5, "tests.test_b": 2.0})

    def test_load_timings_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "nonexistent.json"
            loaded = run_tests.load_timings(file_path)
            self.assertEqual(loaded, {})

    def test_load_timings_corrupt_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = Path(tmpdir) / "corrupt.json"
            file_path.write_text("not a valid json {", encoding="utf-8")
            loaded = run_tests.load_timings(file_path)
            self.assertEqual(loaded, {})

    def test_load_timings_none_path(self) -> None:
        self.assertEqual(run_tests.load_timings(None), {})


class TestRunTestsModuleHelpers(unittest.TestCase):
    def test_module_file(self) -> None:
        path = run_tests.module_file("tests.test_run_tests")
        self.assertEqual(path, run_tests.ROOT / "tests" / "test_run_tests.py")

    def test_local_imports(self) -> None:
        with tempfile.NamedTemporaryFile(suffix=".py", mode="w", delete=False, encoding="utf-8") as tmp:
            tmp.write("import run_tests\nfrom admission import find_item\nimport sys\n")
            tmp_path = Path(tmp.name)
        try:
            imports = run_tests.local_imports(tmp_path)
            # Expecting tools/run_tests.py and tools/admission.py to be identified as local imports
            expected = {run_tests.ROOT / "tools" / "run_tests.py", run_tests.ROOT / "tools" / "admission.py"}
            self.assertEqual(imports, expected)
        finally:
            tmp_path.unlink(missing_ok=True)

    def test_expand_cases(self) -> None:
        cases = run_tests.expand_cases(["tests.test_admission_helpers"])
        self.assertTrue(any("test_admission_helpers" in c for c in cases))


class TestRunTestsWorkerHelpers(unittest.TestCase):
    def test_default_workers_minimum(self) -> None:
        old_val = os.environ.get("MEADOW_TEST_WORKERS")
        try:
            if "MEADOW_TEST_WORKERS" in os.environ:
                del os.environ["MEADOW_TEST_WORKERS"]
            workers = run_tests.default_workers()
            self.assertGreaterEqual(workers, 1)
        finally:
            if old_val is not None:
                os.environ["MEADOW_TEST_WORKERS"] = old_val

    def test_default_workers_env_override(self) -> None:
        old_val = os.environ.get("MEADOW_TEST_WORKERS")
        try:
            os.environ["MEADOW_TEST_WORKERS"] = "5"
            self.assertEqual(run_tests.default_workers(), 5)
        finally:
            if old_val is not None:
                os.environ["MEADOW_TEST_WORKERS"] = old_val
            else:
                os.environ.pop("MEADOW_TEST_WORKERS", None)


if __name__ == "__main__":
    unittest.main()
