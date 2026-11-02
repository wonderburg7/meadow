"""Contract tests for Godot test wrapper helpers in HO10 and Challenge2.

Proves that HO10QueenStarvationEndsRunTest._boot_and_run and
Challenge2ChecksTest._boot_and_run propagate process failure, script error lines,
FAIL reports and non-zero exit codes as AssertionError, and skip cleanly without
launching subprocesses when Godot or engine boot is missing.
"""

from __future__ import annotations

import unittest
from unittest.mock import MagicMock, patch

import tests.test_challenge2_checks as c2
import tests.test_ho10_queen_starvation_ends_run as ho10


class TestGodotHelperContracts(unittest.TestCase):
    def setUp(self):
        self.ho10_case = ho10.HO10QueenStarvationEndsRunTest(methodName="runTest")
        self.c2_case = c2.Challenge2ChecksTest(methodName="runTest")
        self.cases_and_pass_tokens = [
            (self.ho10_case, ho10, "HO10 PASS"),
            (self.c2_case, c2, "C2CHECKS PASS"),
        ]

    def _mock_completed_process(self, stdout: str, returncode: int = 0):
        mock_proc = MagicMock()
        mock_proc.returncode = returncode
        mock_proc.stdout = stdout
        mock_proc.stderr = ""
        return mock_proc

    def test_pass_payload_and_exit_zero_succeeds(self):
        for case, mod, pass_token in self.cases_and_pass_tokens:
            with self.subTest(module=mod.__name__):
                mock_proc = self._mock_completed_process(f"Some log output...\n{pass_token}\nDone.")
                with patch.object(mod.gcc, "find_godot", return_value="/usr/bin/godot"), \
                     patch.object(mod.gcc, "ensure_writable_user_dir"), \
                     patch.object(mod.gcc, "engine_can_boot", return_value=True), \
                     patch.object(mod.gcc, "prepare_cache", return_value=True), \
                     patch.object(mod.subprocess, "run", return_value=mock_proc) as mock_run:
                    case._boot_and_run("test_mode")
                    mock_run.assert_called_once()

    def test_missing_pass_raises_assertion_error(self):
        for case, mod, _ in self.cases_and_pass_tokens:
            with self.subTest(module=mod.__name__):
                mock_proc = self._mock_completed_process("Some log output without pass token.\nDone.")
                with patch.object(mod.gcc, "find_godot", return_value="/usr/bin/godot"), \
                     patch.object(mod.gcc, "ensure_writable_user_dir"), \
                     patch.object(mod.gcc, "engine_can_boot", return_value=True), \
                     patch.object(mod.gcc, "prepare_cache", return_value=True), \
                     patch.object(mod.subprocess, "run", return_value=mock_proc):
                    with self.assertRaises(AssertionError):
                        case._boot_and_run("test_mode")

    def test_script_error_raises_assertion_error(self):
        for case, mod, pass_token in self.cases_and_pass_tokens:
            with self.subTest(module=mod.__name__):
                mock_proc = self._mock_completed_process(
                    f"SCRIPT ERROR: Parse Error\n{pass_token}\nDone."
                )
                with patch.object(mod.gcc, "find_godot", return_value="/usr/bin/godot"), \
                     patch.object(mod.gcc, "ensure_writable_user_dir"), \
                     patch.object(mod.gcc, "engine_can_boot", return_value=True), \
                     patch.object(mod.gcc, "prepare_cache", return_value=True), \
                     patch.object(mod.subprocess, "run", return_value=mock_proc):
                    with self.assertRaises(AssertionError):
                        case._boot_and_run("test_mode")

    def test_fail_line_raises_assertion_error(self):
        for case, mod, pass_token in self.cases_and_pass_tokens:
            prefix = "HO10" if case is self.ho10_case else "C2CHECKS"
            with self.subTest(module=mod.__name__):
                mock_proc = self._mock_completed_process(
                    f"{prefix} FAIL assertion failed\n{pass_token}\nDone."
                )
                with patch.object(mod.gcc, "find_godot", return_value="/usr/bin/godot"), \
                     patch.object(mod.gcc, "ensure_writable_user_dir"), \
                     patch.object(mod.gcc, "engine_can_boot", return_value=True), \
                     patch.object(mod.gcc, "prepare_cache", return_value=True), \
                     patch.object(mod.subprocess, "run", return_value=mock_proc):
                    with self.assertRaises(AssertionError):
                        case._boot_and_run("test_mode")

    def test_non_zero_exit_code_raises_assertion_error(self):
        for case, mod, pass_token in self.cases_and_pass_tokens:
            with self.subTest(module=mod.__name__):
                mock_proc = self._mock_completed_process(
                    f"{pass_token}\nDone.", returncode=1
                )
                with patch.object(mod.gcc, "find_godot", return_value="/usr/bin/godot"), \
                     patch.object(mod.gcc, "ensure_writable_user_dir"), \
                     patch.object(mod.gcc, "engine_can_boot", return_value=True), \
                     patch.object(mod.gcc, "prepare_cache", return_value=True), \
                     patch.object(mod.subprocess, "run", return_value=mock_proc):
                    with self.assertRaises(AssertionError):
                        case._boot_and_run("test_mode")

    def test_no_executable_skips_without_subprocess(self):
        for case, mod, _ in self.cases_and_pass_tokens:
            with self.subTest(module=mod.__name__):
                with patch.object(mod.gcc, "find_godot", return_value=None), \
                     patch.object(mod.subprocess, "run") as mock_run:
                    with self.assertRaises(unittest.SkipTest):
                        case._boot_and_run("test_mode")
                    mock_run.assert_not_called()

    def test_engine_cannot_boot_skips_without_subprocess(self):
        for case, mod, _ in self.cases_and_pass_tokens:
            with self.subTest(module=mod.__name__):
                with patch.object(mod.gcc, "find_godot", return_value="/usr/bin/godot"), \
                     patch.object(mod.gcc, "ensure_writable_user_dir"), \
                     patch.object(mod.gcc, "engine_can_boot", return_value=False), \
                     patch.object(mod.subprocess, "run") as mock_run:
                    with self.assertRaises(unittest.SkipTest):
                        case._boot_and_run("test_mode")
                    mock_run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
