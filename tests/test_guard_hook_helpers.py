"""Unit tests for helper functions in tools/guard_hook.py."""

from __future__ import annotations

import io
import json
import unittest
from unittest.mock import patch

from tools import guard_hook


class TestGuardHookHelpers(unittest.TestCase):
    def test_is_worktree(self) -> None:
        self.assertTrue(guard_hook._is_worktree(r"C:\repo\.worktrees\L-34"))
        self.assertTrue(guard_hook._is_worktree("/home/user/meadow/.worktrees/slice-1"))
        self.assertTrue(guard_hook._is_worktree(".worktrees/my-tree"))
        self.assertFalse(guard_hook._is_worktree(r"C:\repo\Meadow"))
        self.assertFalse(guard_hook._is_worktree("/home/user/meadow"))
        self.assertFalse(guard_hook._is_worktree("."))

    def test_reads_tree_denied_paths(self) -> None:
        self.assertTrue(guard_hook._reads_tree("cat .godot/global_script_class_cache.cfg"))
        self.assertTrue(guard_hook._reads_tree("head _backups/backup.json"))
        self.assertTrue(guard_hook._reads_tree("tail docs/archive/old.md"))
        self.assertTrue(guard_hook._reads_tree("sed -n '1p' plans/archive/slice.md"))
        self.assertTrue(guard_hook._reads_tree("grep error .godot/app_userdata"))
        self.assertTrue(guard_hook._reads_tree("rg pattern _backups"))
        self.assertTrue(guard_hook._reads_tree("Select-String pattern docs/archive/notes.md"))
        self.assertTrue(guard_hook._reads_tree("Get-Content plans/archive/item.md"))
        self.assertTrue(guard_hook._reads_tree("type docs/archive/record.txt"))
        self.assertTrue(guard_hook._reads_tree("ls .godot"))
        self.assertTrue(guard_hook._reads_tree("dir _backups"))
        self.assertTrue(guard_hook._reads_tree("Get-ChildItem plans/archive"))

    def test_reads_tree_compound_and_multiline_commands(self) -> None:
        self.assertTrue(guard_hook._reads_tree("cd scripts && cat ../.godot/cache"))
        self.assertTrue(guard_hook._reads_tree("echo start || cat docs/archive/x.md"))
        self.assertTrue(guard_hook._reads_tree("git status; ls plans/archive"))
        self.assertTrue(guard_hook._reads_tree("echo 'line 1'\ncat _backups/x.txt"))

    def test_reads_tree_allowed_paths_and_commands(self) -> None:
        self.assertFalse(guard_hook._reads_tree("cat scripts/main.gd"))
        self.assertFalse(guard_hook._reads_tree("git grep -n pattern -- plans/archive"))
        self.assertFalse(guard_hook._reads_tree("echo plans/archive/x.md"))
        self.assertFalse(guard_hook._reads_tree("python tools/heading.py plans/now/example.md heading"))
        self.assertFalse(guard_hook._reads_tree(""))

    def test_reads_tree_exclusions_and_filters(self) -> None:
        self.assertFalse(guard_hook._reads_tree("git ls-files | grep -v _backups"))
        self.assertFalse(guard_hook._reads_tree("git ls-files | rg --invert-match _backups"))
        self.assertFalse(guard_hook._reads_tree("Get-ChildItem | Select-String -NotMatch _backups"))
        self.assertFalse(guard_hook._reads_tree("grep -rn pattern --exclude-dir=_backups ."))
        self.assertFalse(guard_hook._reads_tree("grep -rn pattern --exclude-dir _backups ."))
        self.assertFalse(guard_hook._reads_tree("rg pattern -g '!_backups' ."))
        self.assertFalse(guard_hook._reads_tree("rg pattern --glob=!plans/archive/** ."))

    def test_reason_stop_process(self) -> None:
        reason = guard_hook._reason("Stop-Process -Name godot", "/repo")
        self.assertEqual(reason, "Do not stop Godot or Python; use slice.ps1 stop-verify or slice.ps1 status.")
        reason_py = guard_hook._reason("stop-process -name python3", "/repo")
        self.assertEqual(reason_py, "Do not stop Godot or Python; use slice.ps1 stop-verify or slice.ps1 status.")
        reason_pid = guard_hook._reason("Stop-Process -Id 999", "/repo")
        self.assertEqual(reason_pid, "Do not stop Godot or Python; use slice.ps1 stop-verify or slice.ps1 status.")

    def test_reason_pipe_finish(self) -> None:
        cmd = "powershell -File tools/slice.ps1 finish 2>&1 | Tee-Object out.log"
        self.assertEqual(
            guard_hook._reason(cmd, "/repo"),
            "Do not pipe slice.ps1 finish; run it directly so closeout can complete.",
        )

    def test_reason_worktree_finish(self) -> None:
        cmd = "powershell -File tools/slice.ps1 finish"
        self.assertEqual(
            guard_hook._reason(cmd, "/repo/.worktrees/slice-1"),
            "Run slice.ps1 finish from the primary checkout, not this worktree.",
        )

    def test_reason_worktree_relative_tools(self) -> None:
        cmd = "python ../../tools/verify.py"
        self.assertEqual(
            guard_hook._reason(cmd, "/repo/.worktrees/slice-1"),
            "Run tools/… from inside the worktree, not ../../tools/… .",
        )

    def test_reason_reads_denied_tree(self) -> None:
        cmd = "cat .godot/state.txt"
        self.assertEqual(guard_hook._reason(cmd, "/repo"), "Do not read this denied path.")

    def test_reason_safe_command(self) -> None:
        self.assertEqual(guard_hook._reason("git status", "/repo"), "")
        self.assertEqual(guard_hook._reason("python tools/check_docs.py", "/repo"), "")

    def test_deny(self) -> None:
        stdout_capture = io.StringIO()
        with patch("sys.stdout", stdout_capture):
            guard_hook._deny("Custom refusal reason")
        payload = json.loads(stdout_capture.getvalue())
        self.assertEqual(
            payload,
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": "Custom refusal reason",
                }
            },
        )


if __name__ == "__main__":
    unittest.main()
