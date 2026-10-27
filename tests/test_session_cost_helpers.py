"""Unit tests for tools/session_cost.py's outcome and row helpers."""

import unittest
from tools.session_cost import (
    _edit_paths,
    _is_finish_call,
    _is_worker_dispatch,
    _level_allows,
    classify_outcome,
)


class TestSessionCostHelpers(unittest.TestCase):
    """Test pure helper functions in tools/session_cost.py."""

    def test_classify_outcome_all_seven_classes(self) -> None:
        """Verify classify_outcome returns each of its seven outcome classes correctly."""
        # 1. expected_no_match
        self.assertEqual(
            classify_outcome(command="git status", result="", is_error=True),
            "expected_no_match",
        )
        self.assertEqual(
            classify_outcome(
                command="git ls-remote origin --exit-code",
                result="exit code 2",
                is_error=True,
            ),
            "expected_no_match",
        )

        # 2. partially_denied
        self.assertEqual(
            classify_outcome(
                command="cd foo && git status",
                result="Permission to use Bash has been denied",
                is_error=True,
            ),
            "partially_denied",
        )

        # 3. diagnostic_in_success
        self.assertEqual(
            classify_outcome(
                command="python tools/check_docs.py",
                result="doc checks: FAILED for 1 file",
                is_error=False,
            ),
            "diagnostic_in_success",
        )

        # 4. test_failure
        self.assertEqual(
            classify_outcome(
                command="python -m unittest",
                result="AssertionError: 1 != 2",
                is_error=True,
            ),
            "test_failure",
        )

        # 5. environment_failure
        self.assertEqual(
            classify_outcome(
                command="godot --headless",
                result="godot: command not found",
                is_error=True,
            ),
            "environment_failure",
        )

        # 6. lifecycle_failure
        self.assertEqual(
            classify_outcome(
                command="tools/slice.ps1 start",
                result="slice failed to start",
                is_error=True,
            ),
            "lifecycle_failure",
        )

        # 7. agent_mistake
        self.assertEqual(
            classify_outcome(
                command="cat non_existent_file.txt",
                result="No such file or directory",
                is_error=True,
            ),
            "agent_mistake",
        )

    def test_classify_outcome_failing_slice_with_failed_is_lifecycle_failure(self) -> None:
        """Verify a failing slice.ps1 run with FAILED in the result returns lifecycle_failure."""
        self.assertEqual(
            classify_outcome(
                command="tools/slice.ps1 finish",
                result="FAILED: unit tests failed",
                is_error=True,
            ),
            "lifecycle_failure",
        )

    def test_is_finish_call(self) -> None:
        """Verify _is_finish_call identifies finish commands across shell types."""
        bash_finish = {
            "name": "Bash",
            "input": {"command": "powershell -File tools/slice.ps1 finish"},
        }
        ps_finish = {
            "name": "PowerShell",
            "input": {"command": "tools/slice.ps1 finish"},
        }
        bash_start = {
            "name": "Bash",
            "input": {"command": "tools/slice.ps1 start -Lane Codex"},
        }
        read_block = {
            "name": "Read",
            "input": {"file_path": "tools/slice.ps1"},
        }

        self.assertTrue(_is_finish_call(bash_finish))
        self.assertTrue(_is_finish_call(ps_finish))
        self.assertFalse(_is_finish_call(bash_start))
        self.assertFalse(_is_finish_call(read_block))

    def test_is_worker_dispatch(self) -> None:
        """Verify _is_worker_dispatch recognises slice-worker subagents."""
        worker_block = {
            "name": "Agent",
            "input": {"subagent_type": "slice-worker-low"},
        }
        explore_block = {
            "name": "Agent",
            "input": {"subagent_type": "Explore"},
        }

        self.assertTrue(_is_worker_dispatch(worker_block))
        self.assertFalse(_is_worker_dispatch(explore_block))

    def test_edit_paths(self) -> None:
        """Verify _edit_paths extracts edited paths with slashes normalised and root stripped."""
        rows = [
            {
                "type": "assistant",
                "message": {
                    "content": [
                        {
                            "type": "tool_use",
                            "name": "Edit",
                            "input": {"file_path": "C:\\Repo\\Root\\scripts\\main.gd"},
                        }
                    ]
                },
            },
            {
                "type": "assistant",
                "message": {
                    "content": [
                        {
                            "type": "tool_use",
                            "name": "Write",
                            "input": {"file_path": "C:/repo/root/tests/test_foo.py"},
                        }
                    ]
                },
            },
            {
                "type": "assistant",
                "message": {
                    "content": [
                        {
                            "type": "tool_use",
                            "name": "NotebookEdit",
                            "input": {"notebook_path": "c:\\repo\\root\\tools\\notebook.ipynb"},
                        }
                    ]
                },
            },
            {
                "type": "assistant",
                "message": {
                    "content": [
                        {
                            "type": "tool_use",
                            "name": "Read",
                            "input": {"file_path": "C:\\repo\\root\\README.md"},
                        }
                    ]
                },
            },
            {
                "type": "user",
                "message": {
                    "content": [
                        {
                            "type": "tool_result",
                            "content": "Updated file",
                        }
                    ]
                },
            },
        ]

        paths = _edit_paths(rows, repo_root="C:\\Repo\\Root")
        self.assertEqual(
            paths,
            ["scripts/main.gd", "tests/test_foo.py", "tools/notebook.ipynb"],
        )

    def test_level_allows(self) -> None:
        """Verify _level_allows enforces model prefix rules per level."""
        # low accepts sonnet and haiku-5-5, rejects opus
        self.assertTrue(_level_allows("low", "claude-sonnet-5-20260401"))
        self.assertTrue(_level_allows("low", "claude-haiku-5-5-20260401"))
        self.assertFalse(_level_allows("low", "claude-opus-5-20260401"))

        # medium accepts sonnet, rejects haiku and opus
        self.assertTrue(_level_allows("medium", "claude-sonnet-5-20260401"))
        self.assertFalse(_level_allows("medium", "claude-haiku-5-5-20260401"))
        self.assertFalse(_level_allows("medium", "claude-opus-5-20260401"))

        # high accepts opus, rejects sonnet
        self.assertTrue(_level_allows("high", "claude-opus-5-20260401"))
        self.assertFalse(_level_allows("high", "claude-sonnet-5-20260401"))


if __name__ == "__main__":
    unittest.main()
