"""In-memory contracts for the HO10 and Challenge2 Godot wrappers."""

from __future__ import annotations

import subprocess
import unittest
from unittest.mock import patch

import test_challenge2_checks as c2_module
import test_ho10_queen_starvation_ends_run as ho10_module


class TestGodotHelperContracts(unittest.TestCase):
    def _cases(self):
        return (
            (ho10_module.HO10QueenStarvationEndsRunTest(), "restore_queen", "HO10"),
            (c2_module.Challenge2ChecksTest(), "nurse_gating", "C2CHECKS"),
        )

    def test_output_and_exit_contracts(self):
        for case, mode, tag in self._cases():
            outcomes = (
                ("pass", f"{tag} PASS\n", "", 0, False),
                ("missing pass", "ordinary output\n", "", 0, True),
                ("script error", f"{tag} PASS\n", "SCRIPT ERROR: parse error\n", 0, True),
                ("explicit fail", f"{tag} PASS\n{tag} FAIL assertion failed\n", "", 0, True),
                ("nonzero exit", f"{tag} PASS\n", "", 7, True),
            )
            for label, stdout, stderr, code, fails in outcomes:
                with self.subTest(wrapper=tag, outcome=label), \
                     patch("godot_compile_check.find_godot", return_value="mock-godot"), \
                     patch("godot_compile_check.ensure_writable_user_dir"), \
                     patch("godot_compile_check.engine_can_boot", return_value=True), \
                     patch("godot_compile_check.prepare_cache", return_value=True), \
                     patch("subprocess.run", return_value=subprocess.CompletedProcess(
                         ["mock-godot"], code, stdout, stderr)) as run:
                    if fails:
                        with self.assertRaises(AssertionError):
                            case._boot_and_run(mode)
                    else:
                        self.assertIsNone(case._boot_and_run(mode))
                    run.assert_called_once()
                    self.assertEqual(run.call_args.args[0][0], "mock-godot")
                    self.assertEqual(run.call_args.args[0][-1], mode)

    def test_skip_and_cache_failure_contracts(self):
        for case, mode, tag in self._cases():
            for label, executable, boots, cache_ok, error in (
                ("no executable", None, True, True, unittest.SkipTest),
                ("cannot boot", "mock-godot", False, True, unittest.SkipTest),
                ("cache failure", "mock-godot", True, False, AssertionError),
            ):
                with self.subTest(wrapper=tag, outcome=label), \
                     patch("godot_compile_check.find_godot", return_value=executable), \
                     patch("godot_compile_check.ensure_writable_user_dir") as writable, \
                     patch("godot_compile_check.engine_can_boot", return_value=boots) as boot, \
                     patch("godot_compile_check.prepare_cache", return_value=cache_ok) as cache, \
                     patch("subprocess.run") as run:
                    with self.assertRaises(error):
                        case._boot_and_run(mode)
                    run.assert_not_called()
                    if executable is None:
                        writable.assert_not_called()
                        boot.assert_not_called()
                    else:
                        writable.assert_called_once_with()
                        boot.assert_called_once_with(executable)
                    if executable is None or not boots:
                        cache.assert_not_called()
                    else:
                        cache.assert_called_once_with(executable)


if __name__ == "__main__":
    unittest.main()
