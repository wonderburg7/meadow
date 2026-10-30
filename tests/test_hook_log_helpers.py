"""Unit tests for tools/hook_log.py pure helper functions."""

import unittest
from tools import hook_log


class TestHookLogHelpers(unittest.TestCase):
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


    def test_bash_command_token_skips_empty_and_setup_segments(self):
        self.assertEqual(hook_log._bash_command_token("; cd foo | VAR=1 ; git status"), "git")
        self.assertEqual(hook_log._bash_command_token("cd foo; VAR=1"), "")

    def test_bash_command_token_interpreter_without_script(self):
        for command, expected in (("python -V", "python"), ("pwsh -Version", "pwsh")):
            with self.subTest(command=command):
                self.assertEqual(hook_log._bash_command_token(command), expected)

    def test_bash_command_token_preserves_first_working_program(self):
        self.assertEqual(hook_log._bash_command_token("git status && python later.py"), "git")
        self.assertEqual(hook_log._bash_command_token("&"), "&")
        self.assertEqual(hook_log._bash_command_token("./tools/CHECK.PY"), "CHECK.PY")


if __name__ == "__main__":
    unittest.main()
