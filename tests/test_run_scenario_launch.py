"""run_scenario.run_once prepares its own launch (1 Oct 2026).

The Godot-booting unit tests import run_once rather than going through
run_scenario.py's main(), and verify.ps1 runs them before its boot stage
seeds the worktree's .godot. In a fresh worktree every one of them failed to
resolve main.gd's scripts and waited out its 120 s timeout. These pin that
run_once redirects user:// and seeds the cache once per process before its
first launch, and that a refused seed fails at once without launching Godot.

BS-6 (plans/now/brood-spine.md) adds a source-reading test here: main.gd
passes the run definition through DeveloperOverrides.apply only outside a
scenario or headless run, so no fixture ever starts from a developer's
user:// edits.
"""

from __future__ import annotations

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

TOOLS = Path(__file__).resolve().parent.parent / "tools"
MAIN_GD = Path(__file__).resolve().parent.parent / "scripts" / "main.gd"
sys.path.insert(0, str(TOOLS))

import run_scenario  # noqa: E402

SESSION = Path("session.jsonl")


class RunOncePreparesLaunchTest(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        # prepare_launch seeds the cache only for a Godot path that exists.
        self.godot = str(Path(folder.name) / "Godot.exe")
        Path(self.godot).write_bytes(b"")
        for patch in (mock.patch.dict(run_scenario._prepared, clear=True),
                      mock.patch.object(run_scenario, "session_file_for_run_id",
                                        return_value=SESSION)):
            patch.start()
            self.addCleanup(patch.stop)

    def _run_twice(self, cache_result: tuple[bool, str]):
        """Two run_once calls; returns their results, the recorded calls
        (redirect, ensure_cache and launch, in order) and stderr."""
        calls = mock.Mock()
        calls.redirect.return_value = None
        calls.ensure_cache.return_value = cache_result
        calls.launch.return_value = mock.Mock(returncode=0, stdout="", stderr="")
        stderr = io.StringIO()
        with mock.patch.object(run_scenario, "ensure_writable_user_dir", calls.redirect), \
             mock.patch.object(run_scenario.godot_cache, "ensure_cache", calls.ensure_cache), \
             mock.patch.object(run_scenario.subprocess, "run", calls.launch), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(stderr):
            results = [run_scenario.run_once(Path("scenario.json"), self.godot, 1) for _ in range(2)]
        return results, calls, stderr.getvalue()

    def test_cache_is_seeded_once_before_the_first_launch(self):
        results, calls, stderr = self._run_twice((True, "godot cache: seeded from primary"))

        self.assertEqual([SESSION, SESSION], results)
        self.assertEqual(["redirect", "ensure_cache", "launch", "launch"],
                         [name for name, _args, _kwargs in calls.mock_calls])
        calls.ensure_cache.assert_called_once_with(run_scenario.ROOT, self.godot)
        self.assertEqual(1, stderr.count("godot cache: seeded from primary"))

    def test_a_refused_seed_fails_at_once_without_launching(self):
        refusal = ("godot cache: FAILED -- the primary checkout C:\\meadow does not boot "
                   "(Parse Error); not copying its cache. Fix master first")
        results, calls, stderr = self._run_twice((False, refusal))

        self.assertEqual([None, None], results)
        calls.launch.assert_not_called()
        # Remembered: the second run does not boot the primary again.
        calls.ensure_cache.assert_called_once()
        self.assertEqual(2, stderr.count("error: not launching Godot -- " + refusal))


class DeveloperOverridesOnlyOutsideScenariosTest(unittest.TestCase):
    """BS-6: the run start applies the developer table's edits, guarded."""

    def setUp(self):
        self.lines = MAIN_GD.read_text(encoding="utf-8").splitlines()

    def _code(self, line):
        return line.split("#", 1)[0].rstrip()

    def test_overrides_apply_once_between_the_level_and_its_sheet(self):
        calls = [i for i, line in enumerate(self.lines)
                 if "DeveloperOverrides.apply(" in self._code(line)]
        self.assertEqual(1, len(calls), "main.gd must call DeveloperOverrides.apply exactly once")
        call = calls[0]
        level_line = max(i for i, line in enumerate(self.lines[:call])
                         if "Levels.get_level(Session.starting_level)" in self._code(line))
        sheet_line = next(i for i, line in enumerate(self.lines[call:], call)
                          if "RunAvailability.sheet_for(level)" in self._code(line))
        self.assertLess(level_line, call)
        self.assertLess(call, sheet_line)
        self.assertIn("level = DeveloperOverrides.apply(Session.starting_level, level)",
                      self._code(self.lines[call]))

    def test_the_call_sits_under_a_scenario_and_headless_guard(self):
        call = next(i for i, line in enumerate(self.lines)
                    if "DeveloperOverrides.apply(" in self._code(line))
        indent = len(self.lines[call]) - len(self.lines[call].lstrip("\t"))
        guard_line = next(i for i in range(call - 1, -1, -1)
                          if self._code(self.lines[i]).strip()
                          and len(self.lines[i]) - len(self.lines[i].lstrip("\t")) < indent)
        guard = self._code(self.lines[guard_line]).strip()
        self.assertTrue(guard.startswith("if ") and guard.endswith(":"), guard)
        for condition in ("not scenario_active",
                          "Session.starting_level != Levels.SCENARIO_LEVEL_ID",
                          'DisplayServer.get_name() != "headless"'):
            self.assertIn(condition, guard)
        self.assertNotIn(" or ", guard, "every condition must hold, so the guard joins them with and")


if __name__ == "__main__":
    unittest.main()
