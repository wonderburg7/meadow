"""Pure-Python unit tests covering helper functions in tools/run_scenario.py."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))

from run_scenario import (  # noqa: E402
    _background_command,
    _compile_failure_details,
    _exit_code_detail,
    _experiment_terminal_line,
    _failure_capsule,
    _scenario_declares_seed,
    _scenario_metadata,
    _terminal_line,
)


class TestRunScenarioHelpers(unittest.TestCase):
    def test_scenario_declares_seed(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            with_seed = temp_path / "with_seed.json"
            with_seed.write_text(json.dumps({"random_seed": 42}), encoding="utf-8")
            without_seed = temp_path / "without_seed.json"
            without_seed.write_text(json.dumps({"other": "value"}), encoding="utf-8")
            invalid_json = temp_path / "invalid.json"
            invalid_json.write_text("{bad json", encoding="utf-8")
            non_dict = temp_path / "list.json"
            non_dict.write_text("[1, 2, 3]", encoding="utf-8")
            non_existent = temp_path / "missing.json"

            self.assertTrue(_scenario_declares_seed(with_seed))
            self.assertFalse(_scenario_declares_seed(without_seed))
            self.assertFalse(_scenario_declares_seed(invalid_json))
            self.assertFalse(_scenario_declares_seed(non_dict))
            self.assertFalse(_scenario_declares_seed(non_existent))

    def test_exit_code_detail(self) -> None:
        self.assertEqual(_exit_code_detail(0), {"exit_code": 0})
        self.assertEqual(_exit_code_detail(1), {"exit_code": 1})
        self.assertEqual(_exit_code_detail(None), {"exit_code": None})

        # Negative returncode: signed Windows crash or POSIX signal
        negative_detail = _exit_code_detail(-1073741819)
        self.assertEqual(negative_detail["exit_code"], -1073741819)
        self.assertEqual(negative_detail["windows_exception"], "0xC0000005")

        sigkill_detail = _exit_code_detail(-9)
        self.assertEqual(sigkill_detail["exit_code"], -9)
        self.assertEqual(sigkill_detail["windows_exception"], "0xFFFFFFF7")

    def test_failure_capsule_structure_and_bounded_entries(self) -> None:
        entries = [
            {"type": "config", "data": "c"},
            {"type": "action", "id": 1},
            {"type": "action", "id": 2},
            {"type": "action", "id": 3},
            {"type": "action", "id": 4},
            {"type": "action", "id": 5},
            {"type": "action", "id": 6},
            {"type": "custom_event", "val": 10},
            {"type": "snapshot", "day": 1},
            {"type": "snapshot", "day": 2},
        ]
        artefacts = {"log": "process.log"}
        reason = {"kind": "contract", "message": "broken"}
        capsule = _failure_capsule(
            status="failed",
            run_id="run123",
            reason=reason,
            entries=entries,
            artefacts=artefacts,
        )

        self.assertEqual(capsule["status"], "failed")
        self.assertEqual(capsule["run_id"], "run123")
        self.assertEqual(capsule["reason"], reason)
        self.assertEqual(capsule["artefacts"], artefacts)
        self.assertFalse(capsule["truncated"])
        # Actions bounded to last 5
        self.assertEqual(len(capsule["actions"]), 5)
        self.assertEqual([a["id"] for a in capsule["actions"]], [2, 3, 4, 5, 6])
        # Events bounded to last 5 non-(config/snapshot/summary/action)
        self.assertEqual(capsule["events"], [{"type": "custom_event", "val": 10}])
        # Snapshot is the latest snapshot entry
        self.assertEqual(capsule["snapshot"], {"type": "snapshot", "day": 2})

    def test_failure_capsule_truncation_on_large_payload(self) -> None:
        large_entries = [
            {"type": "action", "data": "x" * 1000} for _ in range(6)
        ]
        capsule = _failure_capsule(
            status="failed",
            run_id="run_large",
            reason={"kind": "crash"},
            entries=large_entries,
            artefacts={"log": "p.log"},
        )
        self.assertTrue(capsule["truncated"])
        self.assertEqual(capsule["actions"], [])
        self.assertEqual(capsule["events"], [])
        self.assertIsNone(capsule["snapshot"])

    def test_terminal_line(self) -> None:
        result_path = Path("/tmp/result.json")
        line1 = _terminal_line("passed", "abc", result_path)
        self.assertEqual(line1, f"status=passed run_id=abc result={result_path}")

        line2 = _terminal_line("failed", "abc", result_path, outcome="victory", reason="timeout")
        self.assertEqual(
            line2,
            f"status=failed run_id=abc outcome=victory reason=timeout result={result_path}",
        )

    def test_experiment_terminal_line(self) -> None:
        result_path = Path("/tmp/exp/result.json")
        line1 = _experiment_terminal_line("passed", "smoke", result_path)
        self.assertEqual(line1, f"status=passed experiment=smoke result={result_path}")

        line2 = _experiment_terminal_line("failed", "smoke", result_path, reason="expectation")
        self.assertEqual(
            line2,
            f"status=failed experiment=smoke reason=expectation result={result_path}",
        )

    def test_compile_failure_details(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)

            clean_log = temp_path / "clean.log"
            clean_log.write_text("Engine boot ok\nEverything running cleanly\n", encoding="utf-8")
            self.assertIsNone(_compile_failure_details(clean_log))

            error_log = temp_path / "error.log"
            error_log.write_text(
                "Godot Engine v4.7\n"
                "SCRIPT ERROR: Parse Error: Identifier not found: foo\n"
                "   at: GDScript::reload (res://scripts/bee.gd:42)\n",
                encoding="utf-8",
            )
            details = _compile_failure_details(error_log)
            self.assertIsNotNone(details)
            assert details is not None
            error_line, script = details
            self.assertEqual(error_line, "SCRIPT ERROR: Parse Error: Identifier not found: foo")
            self.assertEqual(script, "res://scripts/bee.gd")

    def test_background_command(self) -> None:
        argv = [
            "run_scenario.py",
            "scenario.json",
            "--background",
            "--job-root",
            "/tmp/jobs",
            "--timeout",
            "60",
            "--job-root=/tmp/jobs2",
            "--repeat",
            "3",
        ]
        cmd = _background_command(argv)
        self.assertEqual(cmd[0], sys.executable)
        self.assertTrue(cmd[1].endswith("run_scenario.py"))
        self.assertNotIn("--background", cmd)
        self.assertNotIn("--job-root", cmd)
        self.assertNotIn("/tmp/jobs", cmd)
        self.assertNotIn("--job-root=/tmp/jobs2", cmd)
        self.assertIn("scenario.json", cmd)
        self.assertIn("--timeout", cmd)
        self.assertIn("60", cmd)
        self.assertIn("--repeat", cmd)
        self.assertIn("3", cmd)

    def test_scenario_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            scenario_path = Path(temp_dir) / "test.json"
            content = b'{"name": "test_scenario"}'
            scenario_path.write_bytes(content)

            meta = _scenario_metadata(scenario_path, seed=12345)
            self.assertEqual(meta["path"], str(scenario_path))
            self.assertEqual(meta["seed"], 12345)
            self.assertEqual(meta["sha256"], hashlib.sha256(content).hexdigest())


if __name__ == "__main__":
    unittest.main()
