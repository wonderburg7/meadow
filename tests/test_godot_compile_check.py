"""Unit tests for the Godot boot verifier's host/project boundary."""

from contextlib import redirect_stdout
from io import StringIO
import subprocess
import unittest
from unittest.mock import patch

from tools import godot_compile_check


def completed(returncode: int, stdout: str = "", stderr: str = ""):
    return subprocess.CompletedProcess(["Godot"], returncode, stdout, stderr)


class GodotCompileCheckTest(unittest.TestCase):
    def run_main(self, responses):
        output = StringIO()
        with patch.object(godot_compile_check, "find_godot", return_value="Godot"), \
             patch.object(godot_compile_check.subprocess, "run", side_effect=responses), \
             redirect_stdout(output):
            result = godot_compile_check.main()
        return result, output.getvalue()

    def test_skips_when_the_engine_crashes_before_a_project_is_opened(self):
        result, output = self.run_main([completed(-1073741819)])

        self.assertEqual(result, 0)
        self.assertIn("skipped", output)
        self.assertIn("before opening the project", output)

    def test_checks_project_after_a_usable_engine_preflight(self):
        result, output = self.run_main([
            completed(0),
            completed(0, "SCRIPT ERROR: Parse Error: bad script"),
        ])

        self.assertEqual(result, 1)
        self.assertIn("project does not boot cleanly", output)


if __name__ == "__main__":
    unittest.main()
