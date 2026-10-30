"""L-34: the closeout guard refuses only the five known unsafe patterns."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HOOK = ROOT / "tools" / "guard_hook.py"


class GuardHookTest(unittest.TestCase):
    def test_both_hook_configs_register_guard_for_shell_tools(self) -> None:
        for config_path in (ROOT / ".claude" / "settings.json", ROOT / ".codex" / "hooks.json"):
            with self.subTest(config=config_path):
                config = json.loads(config_path.read_text(encoding="utf-8"))
                entries = config["hooks"]["PreToolUse"]
                self.assertTrue(any(
                    entry.get("matcher") == "Bash|PowerShell"
                    and any("guard_hook.py" in hook["command"] for hook in entry["hooks"])
                    for entry in entries
                ))

    def run_hook(self, command: str, cwd: str | None = None) -> tuple[int, dict]:
        payload = {"cwd": cwd or str(ROOT), "session_id": "guard-test", "tool_input": {"command": command}}
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [sys.executable, str(HOOK)],
                input=json.dumps(payload),
                capture_output=True,
                text=True,
                cwd=directory,
                timeout=10,
            )
        output = json.loads(result.stdout) if result.stdout else {}
        return result.returncode, output

    def assert_denied(self, command: str, expected: str, cwd: str | None = None) -> None:
        returncode, output = self.run_hook(command, cwd)
        self.assertEqual(returncode, 0)
        refusal = output["hookSpecificOutput"]
        self.assertEqual(refusal["permissionDecision"], "deny")
        self.assertIn(expected, refusal["permissionDecisionReason"])

    def test_denies_stopping_godot_or_an_unowned_pid(self) -> None:
        self.assert_denied("Stop-Process -Name godot", "stop-verify")
        self.assert_denied("Stop-Process -Id 1234", "stop-verify")

    def test_denies_piping_finish(self) -> None:
        self.assert_denied("powershell -File tools/slice.ps1 finish 2>&1 | Tee-Object output.txt", "pipe")

    def test_denies_finishing_from_a_worktree(self) -> None:
        self.assert_denied("powershell -File tools/slice.ps1 finish", "primary checkout", r"C:\repo\.worktrees\L-34")

    def test_denies_relative_tool_paths_from_a_worktree(self) -> None:
        self.assert_denied("python ../../tools/verify.py", "tools/…", r"C:\repo\.worktrees\L-34")

    def test_denies_reading_the_four_denied_paths(self) -> None:
        for denied_path in (".godot", "_backups", "docs/archive", "plans/archive"):
            with self.subTest(denied_path=denied_path):
                self.assert_denied(f"Get-Content {denied_path}/state.txt", "denied path")

    def test_denies_tree_readers_on_denied_paths(self) -> None:
        for command in (
            "Get-Content plans/archive/x.md",
            "cat docs/archive/x.md",
            "rg foo _backups",
            "ls .godot",
        ):
            with self.subTest(command=command):
                self.assert_denied(command, "denied path")

    def test_allows_history_and_path_mentions(self) -> None:
        for command in (
            "git show HEAD:plans/archive/x.md",
            "git grep -n L-31 HEAD -- plans/archive",
            'git commit -m "see plans/archive/x"',
            "git log -- plans/archive",
            "echo plans/archive/x.md",
        ):
            with self.subTest(command=command):
                returncode, output = self.run_hook(command)
                self.assertEqual(returncode, 0)
                self.assertEqual(output, {})

    def test_allows_ordinary_commands_and_cd_setup(self) -> None:
        for command in ("git status", "python tools/heading.py plans/now/example.md heading", "cd .worktrees/L-34 && git status"):
            with self.subTest(command=command):
                returncode, output = self.run_hook(command, r"C:\repo\.worktrees\L-34")
                self.assertEqual(returncode, 0)
                self.assertEqual(output, {})

    def test_allows_filters_that_exclude_denied_paths(self) -> None:
        for command in (
            'git grep -n x -- "*.md" | grep -v "^plans/archive"',
            "git ls-files | grep -iv _backups",
            "rg foo -g '!_backups'",
            "rg foo --glob=!plans/archive/**",
            "grep -rn foo --exclude-dir=_backups .",
            "grep -rn foo --exclude-dir _backups .",
            "Get-ChildItem -Recurse | Select-String -NotMatch _backups",
        ):
            with self.subTest(command=command):
                returncode, output = self.run_hook(command)
                self.assertEqual(returncode, 0)
                self.assertEqual(output, {})

    def test_still_denies_reads_beside_an_exclusion(self) -> None:
        for command in (
            "grep -v foo _backups/x.txt",
            "rg foo _backups -g '!x'",
            "grep -rn foo --exclude-dir=x _backups",
            "cat _backups/x | grep -v y",
        ):
            with self.subTest(command=command):
                self.assert_denied(command, "denied path")


if __name__ == "__main__":
    unittest.main()
