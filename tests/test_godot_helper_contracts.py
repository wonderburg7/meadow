"""Contract tests for Godot wrapper test helpers (HO10 and Challenge2).

Proves that _boot_and_run in test_ho10_queen_starvation_ends_run and
test_challenge2_checks:
 - Succeeds on valid exit code 0 and PASS line
 - Raises AssertionError on missing PASS line, script error, explicit FAIL line,
   or non-zero returncode
 - Raises unittest.SkipTest when Godot is not found or engine cannot boot
   without invoking subprocess.run.
"""

from __future__ import annotations

import subprocess
import unittest
from unittest.mock import MagicMock, patch

import tests.test_challenge2_checks as c2_module
import tests.test_ho10_queen_starvation_ends_run as ho10_module


class TestGodotHelperContracts(unittest.TestCase):
    def setUp(self):
        self.ho10_case = ho10_module.HO10QueenStarvationEndsRunTest()
        self.c2_case = c2_module.Challenge2ChecksTest()

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_ho10_boot_and_run_pass(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=0, stdout="HO10 PASS\n", stderr=""
        )
        self.ho10_case._boot_and_run("restore_queen")
        mock_run.assert_called_once()

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_c2_boot_and_run_pass(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=0, stdout="C2CHECKS PASS\n", stderr=""
        )
        self.c2_case._boot_and_run("nurse_gating")
        mock_run.assert_called_once()

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_ho10_missing_pass_raises_assertion_error(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=0, stdout="Some output without pass tag\n", stderr=""
        )
        with self.assertRaises(AssertionError):
            self.ho10_case._boot_and_run("restore_queen")

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_c2_missing_pass_raises_assertion_error(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=0, stdout="Some output without pass tag\n", stderr=""
        )
        with self.assertRaises(AssertionError):
            self.c2_case._boot_and_run("nurse_gating")

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_ho10_script_error_raises_assertion_error(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=0, stdout="HO10 PASS\nSCRIPT ERROR: parse error\n", stderr=""
        )
        with self.assertRaises(AssertionError):
            self.ho10_case._boot_and_run("restore_queen")

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_c2_script_error_raises_assertion_error(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=0, stdout="C2CHECKS PASS\nSCRIPT ERROR: parse error\n", stderr=""
        )
        with self.assertRaises(AssertionError):
            self.c2_case._boot_and_run("nurse_gating")

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_ho10_fail_line_raises_assertion_error(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=0, stdout="HO10 PASS\nHO10 FAIL assertion failed\n", stderr=""
        )
        with self.assertRaises(AssertionError):
            self.ho10_case._boot_and_run("restore_queen")

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_c2_fail_line_raises_assertion_error(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=0, stdout="C2CHECKS PASS\nC2CHECKS FAIL assertion failed\n", stderr=""
        )
        with self.assertRaises(AssertionError):
            self.c2_case._boot_and_run("nurse_gating")

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_ho10_nonzero_exit_raises_assertion_error(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=1, stdout="HO10 PASS\n", stderr=""
        )
        with self.assertRaises(AssertionError):
            self.ho10_case._boot_and_run("restore_queen")

    @patch("subprocess.run")
    @patch("godot_compile_check.prepare_cache", return_value=True)
    @patch("godot_compile_check.engine_can_boot", return_value=True)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_c2_nonzero_exit_raises_assertion_error(self, mock_find, mock_boot, mock_cache, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=["godot"], returncode=1, stdout="C2CHECKS PASS\n", stderr=""
        )
        with self.assertRaises(AssertionError):
            self.c2_case._boot_and_run("nurse_gating")

    @patch("subprocess.run")
    @patch("godot_compile_check.find_godot", return_value=None)
    def test_skips_when_godot_not_found(self, mock_find, mock_run):
        with self.assertRaises(unittest.SkipTest):
            self.ho10_case._boot_and_run("restore_queen")
        mock_run.assert_not_called()

        with self.assertRaises(unittest.SkipTest):
            self.c2_case._boot_and_run("nurse_gating")
        mock_run.assert_not_called()

    @patch("subprocess.run")
    @patch("godot_compile_check.engine_can_boot", return_value=False)
    @patch("godot_compile_check.find_godot", return_value="/usr/bin/godot")
    def test_skips_when_godot_cannot_boot(self, mock_find, mock_boot, mock_run):
        with self.assertRaises(unittest.SkipTest):
            self.ho10_case._boot_and_run("restore_queen")
        mock_run.assert_not_called()

        with self.assertRaises(unittest.SkipTest):
            self.c2_case._boot_and_run("nurse_gating")
        mock_run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
