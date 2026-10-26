"""L-21: session_cost's transcript scope, worker-level drift and skipped stages."""

import contextlib
import io
import json
import tempfile
import time
import unittest
from datetime import datetime, timezone
from pathlib import Path
from unittest import mock

from tools import session_cost

SLUG = session_cost.PROJECT_SLUG


def _ts():
    return datetime.fromtimestamp(time.time() - 60, timezone.utc).isoformat()


def _write(path, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(json.dumps(r) for r in rows) + "\n", encoding="utf-8")


def _assistant(model):
    return {
        "type": "assistant",
        "timestamp": _ts(),
        "message": {"model": model, "usage": {"input_tokens": 1, "output_tokens": 1}},
    }


def _user(text):
    return {"type": "user", "timestamp": _ts(), "message": {"content": text}}


class SessionCostScopeTest(unittest.TestCase):
    def test_worktree_directory_session_is_counted(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            _write(home / SLUG / "a.jsonl", [_user("hi"), _assistant("claude-opus-4")])
            _write(home / (SLUG + "--claude-worktrees-x") / "b.jsonl", [_user("hi")])
            files, primary, worktree = session_cost._transcript_files(7, home)
        self.assertEqual(len(files), 2)
        self.assertEqual((primary, worktree), (1, 1))

    def test_level_drift_judges_the_worker_not_the_coordinator(self):
        claim = {"kind": "slice_claimed", "id": "L-21", "session": "S1", "level": "medium", "ts": "2026-10-06"}
        dispatch = _user('start JSON {"id":"L-21","plan":"x"}')
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            _write(home / SLUG / "S1.jsonl", [_user("go"), _assistant("claude-opus-4-7")])
            _write(
                home / SLUG / "S1" / "subagents" / "agent-1.jsonl",
                [dispatch, _assistant("claude-sonnet-5")],
            )
            _write(
                home / SLUG / "S1" / "subagents" / "agent-2.jsonl",
                [_user('{"id": "OTHER"}'), _assistant("claude-opus-4-7")],
            )
            totals = session_cost._session_totals(home)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                session_cost._print_level_drift([claim], [claim], totals, home)
            models = session_cost._subagent_models("S1", "L-21", home)
        self.assertEqual(dict(models), {"claude-sonnet-5": 1})
        self.assertIn("level drift                  none", out.getvalue())

    def test_model_check_warns_a_session_opened_on_the_wrong_model(self):
        """COL-8 (high) was claimed in a Sonnet session and PP-2 (medium) in
        an Opus one (14 Oct 2026); `start` now says so at the claim."""
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            _write(home / (SLUG + "--claude-worktrees-x") / "S2.jsonl",
                   [_user("implement the next slice"), _assistant("claude-sonnet-5-5")])
            high = session_cost.model_check("S2", "high", home)
            medium = session_cost.model_check("S2", "medium", home)
            missing = session_cost.model_check("S3", "high", home)
            unstated = session_cost.model_check("S2", "unstated", home)
        self.assertIn("runs claude-sonnet-5-5, but the plan level is high", high)
        self.assertEqual("", medium)
        self.assertEqual("", missing)
        self.assertEqual("", unstated)

    def test_coordinator_claims_skip_the_model_check(self):
        """The /run-queue coordinator's own model is not the worker's, so its
        `start` passes -Dispatched and slice.ps1 skips the check for it."""
        root = Path(__file__).resolve().parents[1]
        skill = (root / ".claude" / "skills" / "run-queue" / "SKILL.md").read_text(encoding="utf-8")
        self.assertIn("start -Lane Claude -Dispatched", skill)
        source = (root / "tools" / "slice.ps1").read_text(encoding="utf-8")
        self.assertIn('-not $Dispatched -and $env:CLAUDE_CODE_SESSION_ID', source)

    def test_skipped_stage_is_a_skip_not_a_failure(self):
        events = [
            {"kind": "verify_stage", "stage": "lifecycle tests", "skipped": True, "ts": "2999-01-01T00:00:00Z"},
            {"kind": "verify_stage", "stage": "boot", "ok": False, "ts": "2999-01-01T00:00:00Z"},
            {"kind": "verify_stage", "stage": "docs", "ok": True, "ts": "2999-01-01T00:00:00Z"},
        ]
        out = io.StringIO()
        with mock.patch.object(session_cost, "read_events", return_value=events):
            with mock.patch.object(session_cost, "_session_totals", return_value={}):
                with contextlib.redirect_stdout(out):
                    session_cost.run_events(7)
        text = out.getvalue()
        self.assertIn("verify failures              boot=1", text)
        self.assertIn("verify skips                 lifecycle tests=1", text)


def _tool(name, **inp):
    return {"type": "tool_use", "name": name, "input": inp}


class ScriptedEditTest(unittest.TestCase):
    """L-29: subagent transcripts and scripted edits count."""

    def test_subagent_file_is_counted_and_worker_share_printed(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            top = home / SLUG / "S1.jsonl"
            rows = [_user("go")] + [_assistant("m")] * 3
            _write(top, rows)
            sub = home / SLUG / "S1" / "subagents" / "agent-1.jsonl"
            _write(sub, rows)
            sub.with_name("agent-1.meta.json").write_text('{"agentType": "slice-worker-medium"}', encoding="utf-8")
            files, _, _ = session_cost._transcript_files(7, home)
            subs = session_cost._subagent_transcripts(files)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                session_cost.run_phases(files, subs)
        self.assertEqual(subs, [sub])
        self.assertIn("slice workers (subagents named slice-worker-*): 3 = 50.0% of all context", out.getvalue())

    def test_scripted_forms_count_and_plain_script_does_not(self):
        wt = "C:/x/meadow/.worktrees/L-29/tools/session_cost.py"
        self.assertTrue(session_cost._product_edit(
            _tool("Write", file_path="/tmp/s/e.py", content=f"open('{wt}')"), None))
        self.assertTrue(session_cost._product_edit(
            _tool("Bash", command=f"sed -i 's/a/b/' {wt}"), None))
        self.assertTrue(session_cost._product_edit(
            _tool("Bash", command=f"cp /tmp/n.py {wt}"), None))
        self.assertFalse(session_cost._product_edit(
            _tool("Write", file_path="/tmp/s/e.py", content="print('hi')"), None))
        # A note that merely cites a worktree product path is not an edit.
        self.assertFalse(session_cost._product_edit(
            _tool("Write", file_path="/tmp/s/note.md", content=f"Please write up {wt}"), None))
        self.assertFalse(session_cost._product_edit(
            _tool("Write", file_path="/tmp/s/e.py", content=f"print('{wt}')"), None))
        self.assertFalse(session_cost._product_edit(
            _tool("Bash", command=f"cat {wt}"), None))

    def _phase_counts(self, command, cwd):
        """Run a miniature transcript, rather than testing a shell string alone."""
        rows = [_user("go")] + [_assistant("m") for _ in range(3)]
        rows[2]["cwd"] = cwd
        rows[2]["message"]["content"] = [_tool("Bash", command=command)]
        with tempfile.TemporaryDirectory() as temp:
            transcript = Path(temp) / "worker.jsonl"
            _write(transcript, rows)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                session_cost.run_phases([transcript])
        counts = {}
        for phase, label in session_cost.PHASE_LABELS.items():
            line = next(line for line in out.getvalue().splitlines() if line.startswith(label))
            counts[phase] = int(line[len(label):].split()[0])
        return counts

    def test_worktree_relative_shell_writes_count_in_transcripts(self):
        primary = "C:/x/meadow"
        cases = (
            "cd .worktrees/L-38; sed -i 's/a/b/' tools/session_cost.py",
            "cd .worktrees/L-38; cp /tmp/bee.gd scripts/bee.gd",
        )
        for command in cases:
            counts = self._phase_counts(command, primary)
            self.assertEqual(counts["implementing"], 1, command)
            self.assertEqual(counts["no_edit"], 0, command)

        counts = self._phase_counts(
            "sed -i 's/a/b/' tools/session_cost.py",
            "C:/x/meadow/.worktrees/L-38",
        )
        self.assertEqual(counts["implementing"], 1)
        self.assertEqual(counts["no_edit"], 0)

    def test_relative_read_only_and_non_product_writes_stay_uncounted(self):
        cwd = "C:/x/meadow/.worktrees/L-38"
        for command in (
            "cat tools/session_cost.py",
            "sed -i 's/a/b/' docs/note.md",
            "cp /tmp/bee.gd C:/tmp/bee.gd",
        ):
            counts = self._phase_counts(command, cwd)
            self.assertEqual(counts["implementing"], 0, command)
            self.assertEqual(counts["no_edit"], 3, command)


class WorkerAgentModelTest(unittest.TestCase):
    """Each slice-worker agent's pinned model is one its level allows, so the
    drift report never flags the routing it was built from (8 Oct 2026)."""

    def test_worker_models_match_level_models(self):
        agents = Path(__file__).resolve().parents[1] / ".claude" / "agents"
        for level, prefixes in session_cost.LEVEL_MODELS.items():
            text = (agents / f"slice-worker-{level}.md").read_text(encoding="utf-8")
            model = next(line.split(":", 1)[1].strip() for line in text.splitlines() if line.startswith("model:"))
            self.assertTrue(model.startswith(prefixes), f"{level}: {model} not in {prefixes}")


if __name__ == "__main__":
    unittest.main()
