"""Unit tests for pure helper functions in tools/equivalence.py."""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from equivalence import _MISSING, _get_field, _load_scenario_with_forced_seed  # noqa: E402


class TestEquivalenceHelpers(unittest.TestCase):
    def test_get_field_top_level_and_nested(self):
        data = {
            "status": "passed",
            "simulated": {
                "seconds": 12.5,
                "nested": {
                    "count": 4,
                },
            },
        }
        self.assertEqual(_get_field(data, "status"), "passed")
        self.assertEqual(_get_field(data, "simulated.seconds"), 12.5)
        self.assertEqual(_get_field(data, "simulated.nested.count"), 4)

    def test_get_field_missing_key_returns_sentinel(self):
        data = {"status": "passed", "simulated": {"seconds": 12.5}}
        self.assertIs(_get_field(data, "missing"), _MISSING)
        self.assertIs(_get_field(data, "simulated.missing"), _MISSING)

    def test_get_field_intermediate_non_dict_returns_sentinel(self):
        data = {"count": 10, "items": ["a", "b"]}
        self.assertIs(_get_field(data, "count.sub"), _MISSING)
        self.assertIs(_get_field(data, "items.first"), _MISSING)

    def test_load_scenario_with_forced_seed_honours_existing_integer_seed(self):
        tmp_dir = Path(tempfile.mkdtemp(prefix="test-scenario-"))
        try:
            scenario_path = tmp_dir / "scenario.json"
            scenario_path.write_text(json.dumps({"name": "test", "random_seed": 12345}), encoding="utf-8")
            forced_path, seed, cleanup_dir = _load_scenario_with_forced_seed(scenario_path)
            try:
                self.assertEqual(seed, 12345)
                loaded = json.loads(forced_path.read_text(encoding="utf-8"))
                self.assertEqual(loaded["random_seed"], 12345)
                self.assertEqual(loaded["name"], "test")
            finally:
                shutil.rmtree(cleanup_dir, ignore_errors=True)
        finally:
            shutil.rmtree(tmp_dir, ignore_errors=True)

    def test_load_scenario_with_forced_seed_generates_seed_when_missing_or_boolean(self):
        tmp_dir = Path(tempfile.mkdtemp(prefix="test-scenario-"))
        try:
            for bad_seed in (None, True, False, "123"):
                with self.subTest(bad_seed=bad_seed):
                    scenario_path = tmp_dir / "scenario_missing.json"
                    content = {"name": "test"}
                    if bad_seed is not None:
                        content["random_seed"] = bad_seed
                    scenario_path.write_text(json.dumps(content), encoding="utf-8")
                    forced_path, seed, cleanup_dir = _load_scenario_with_forced_seed(scenario_path)
                    try:
                        self.assertIsInstance(seed, int)
                        self.assertNotIsInstance(seed, bool)
                        self.assertGreaterEqual(seed, 0)
                        self.assertLess(seed, 2 ** 31)
                        loaded = json.loads(forced_path.read_text(encoding="utf-8"))
                        self.assertEqual(loaded["random_seed"], seed)
                    finally:
                        shutil.rmtree(cleanup_dir, ignore_errors=True)
        finally:
            shutil.rmtree(tmp_dir, ignore_errors=True)

    def test_load_scenario_with_forced_seed_raises_when_not_dict(self):
        tmp_dir = Path(tempfile.mkdtemp(prefix="test-scenario-"))
        try:
            scenario_path = tmp_dir / "invalid.json"
            scenario_path.write_text(json.dumps(["not", "an", "object"]), encoding="utf-8")
            with self.assertRaises(SystemExit) as ctx:
                _load_scenario_with_forced_seed(scenario_path)
            self.assertIn("error: scenario must be a JSON object", str(ctx.exception))
        finally:
            shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
