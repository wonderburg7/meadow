"""Unit tests for tools/hook_log.py pure helper functions."""

import os
import unittest
from unittest.mock import patch, MagicMock
from tools import hook_log


class TestHookLogHelpers(unittest.TestCase):
    def test_branch_returns_current_branch(self):
        branch_name = hook_log._branch(os.getcwd())
        self.assertIsInstance(branch_name, str)
        self.assertGreater(len(branch_name), 0)

    @patch("subprocess.run")
    def test_branch_subprocess_success(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0, stdout="main\n")
        self.assertEqual(hook_log._branch("/some/path"), "main")

    @patch("subprocess.run")
    def test_branch_subprocess_failure_fallback(self, mock_run):
        # Return error on candidate cwd, fallback succeeds
        mock_run.side_effect = [
            MagicMock(returncode=1, stdout=""),
            MagicMock(returncode=0, stdout="fallback-branch\n"),
        ]
        self.assertEqual(hook_log._branch("/invalid/path"), "fallback-branch")

    @patch("subprocess.run")
    def test_branch_exception_returns_empty(self, mock_run):
        mock_run.side_effect = Exception("git failed")
        self.assertEqual(hook_log._branch("/invalid/path"), "")

    def test_bash_command_token_empty(self):
        self.assertEqual(hook_log._bash_command_token(""), "")
        self.assertEqual(hook_log._bash_command_token("   "), "")

    def test_bash_command_token_simple_cmd(self):
        self.assertEqual(hook_log._bash_command_token("git status"), "git")
        self.assertEqual(hook_log._bash_command_token("ls -la /tmp"), "ls")

    def test_bash_command_token_cd_prefix(self):
        self.assertEqual(hook_log._bash_command_token("cd foo && git status"), "git")
        self.assertEqual(hook_log._bash_command_token("cd bar; ls"), "ls")
        self.assertEqual(hook_log._bash_command_token("cd baz"), "")

    def test_bash_command_token_env_vars(self):
        self.assertEqual(hook_log._bash_command_token("VAR=1 OTHER=2 pytest"), "pytest")
        self.assertEqual(hook_log._bash_command_token("VAR=1"), "")

    def test_bash_command_token_call_operator(self):
        self.assertEqual(hook_log._bash_command_token("& git status"), "git")

    def test_bash_command_token_scripts(self):
        self.assertEqual(hook_log._bash_command_token("./tools/script.ps1 arg"), "script.ps1")
        self.assertEqual(hook_log._bash_command_token(".\\tools\\script.py arg"), "script.py")

    def test_bash_command_token_python_and_powershell_interpreters(self):
        self.assertEqual(
            hook_log._bash_command_token("python tools/heading.py arg"),
            "python heading.py",
        )
        self.assertEqual(
            hook_log._bash_command_token("python3 tools/heading.py arg"),
            "python3 heading.py",
        )
        self.assertEqual(
            hook_log._bash_command_token("pwsh -File tools/script.ps1"),
            "pwsh script.ps1",
        )
        self.assertEqual(
            hook_log._bash_command_token("powershell .\\tools\\script.ps1"),
            "powershell script.ps1",
        )

    def test_bash_command_token_quoted_program(self):
        self.assertEqual(hook_log._bash_command_token('"python" tools/heading.py'), "python heading.py")
        self.assertEqual(hook_log._bash_command_token("'git' status"), "git")


if __name__ == "__main__":
    unittest.main()
