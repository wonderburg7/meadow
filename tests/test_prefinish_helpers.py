"""Unit tests for tools/prefinish.py's git_lines, module_name, and tests_naming helpers."""

import subprocess
import unittest
from unittest.mock import MagicMock, patch

from tools import prefinish


class GitLinesTest(unittest.TestCase):
    @patch("subprocess.run")
    def test_git_lines_returns_stripped_non_empty_lines(self, mock_run: MagicMock) -> None:
        mock_run.return_value = MagicMock(
            stdout="  line1  \n\n  line2\n   \nline3\n",
            returncode=0,
        )
        result = prefinish.git_lines("status", "--short")
        self.assertEqual(["line1", "line2", "line3"], result)
        mock_run.assert_called_once_with(
            ["git", "status", "--short"],
            cwd=prefinish.ROOT,
            capture_output=True,
            text=True,
            check=True,
        )

    @patch("subprocess.run")
    def test_git_lines_returns_empty_list_on_called_process_error(self, mock_run: MagicMock) -> None:
        mock_run.side_effect = subprocess.CalledProcessError(1, ["git", "status"])
        result = prefinish.git_lines("status")
        self.assertEqual([], result)

    @patch("subprocess.run")
    def test_git_lines_returns_empty_list_on_os_error(self, mock_run: MagicMock) -> None:
        mock_run.side_effect = OSError("git not found")
        result = prefinish.git_lines("status")
        self.assertEqual([], result)


class ModuleNameTest(unittest.TestCase):
    def test_valid_test_module_path_returns_python_module_string(self) -> None:
        self.assertEqual("tests.test_prefinish", prefinish.module_name("tests/test_prefinish.py"))
        self.assertEqual("tests.test_foo_bar", prefinish.module_name("tests/test_foo_bar.py"))

    def test_non_test_module_path_returns_none(self) -> None:
        self.assertIsNone(prefinish.module_name("scripts/main.gd"))
        self.assertIsNone(prefinish.module_name("tests/prefinish.py"))
        self.assertIsNone(prefinish.module_name("tests/test_foo/bar.py"))
        self.assertIsNone(prefinish.module_name("tools/test_prefinish.py"))


class TestsNamingTest(unittest.TestCase):
    @patch("tools.prefinish.git_lines")
    def test_tests_naming_passes_correct_grep_arguments(self, mock_git_lines: MagicMock) -> None:
        mock_git_lines.return_value = ["tests/test_a.py", "tests/test_b.py"]
        result = prefinish.tests_naming("my_term")
        self.assertEqual(["tests/test_a.py", "tests/test_b.py"], result)
        mock_git_lines.assert_called_once_with(
            "grep", "-l", "--untracked", "-w", "-F", "-e", "my_term", "--", "tests/test_*.py"
        )


if __name__ == "__main__":
    unittest.main()
