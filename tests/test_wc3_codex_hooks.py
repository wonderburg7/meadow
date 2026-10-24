"""WC-3: Codex session hooks work without Claude's project variable."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class CodexHooksTest(unittest.TestCase):
    def test_session_hooks_log_from_checkout_without_claude_variable(self) -> None:
        config = json.loads((ROOT / ".codex" / "hooks.json").read_text(encoding="utf-8"))
        commands = [
            hook["command"]
            for entries in config["hooks"].values()
            for entry in entries
            for hook in entry["hooks"]
        ]
        self.assertTrue(commands)
        for command in commands:
            self.assertNotIn("CLAUDE_PROJECT_DIR", command)

        with tempfile.TemporaryDirectory() as directory:
            checkout = Path(directory)
            tools = checkout / "tools"
            tools.mkdir()
            for name in ("hook_log.py", "diagnostics.py"):
                shutil.copyfile(ROOT / "tools" / name, tools / name)
            subprocess.run(
                ["git", "init", "-q", "-b", "master", str(checkout)],
                check=True,
                capture_output=True,
                text=True,
            )
            env = os.environ.copy()
            env.pop("CLAUDE_PROJECT_DIR", None)
            subdirectory = checkout / "nested"
            subdirectory.mkdir()
            for cwd in (checkout, subdirectory):
                for event_name in ("SessionStart", "Stop"):
                    for entry in config["hooks"][event_name]:
                        for hook in entry["hooks"]:
                            result = subprocess.run(
                                hook["command"],
                                shell=True,
                                cwd=cwd,
                                env=env,
                                input=json.dumps({"cwd": str(cwd), "session_id": "wc3-test"}),
                                capture_output=True,
                                text=True,
                                timeout=15,
                            )
                            self.assertEqual(result.returncode, 0, result.stderr)
            log = checkout / ".git" / "meadow-diagnostics.jsonl"
            events = [json.loads(line) for line in log.read_text(encoding="utf-8").splitlines()]
            self.assertEqual(
                [event["kind"] for event in events],
                ["session_start", "session_end", "session_start", "session_end"],
            )
            self.assertTrue(all(event["session"] == "wc3-test" for event in events))


if __name__ == "__main__":
    unittest.main()
