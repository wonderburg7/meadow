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
                      mock.patch.object(run_scenario, "PRIVATE_USER_ROOT", Path(folder.name) / "users"),
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
        # Each launch gets a user:// of its own (private_user_env).
        homes = [kwargs["env"]["APPDATA" if run_scenario.os.name == "nt" else "XDG_DATA_HOME"]
                 for _args, kwargs in calls.launch.call_args_list]
        self.assertEqual(2, len(set(homes)))

    def test_a_refused_seed_fails_at_once_without_launching(self):
        refusal = ("godot cache: FAILED -- the primary checkout C:\\meadow does not boot "
                   "(Parse Error); not copying its cache. Fix master first")
        results, calls, stderr = self._run_twice((False, refusal))

        self.assertEqual([None, None], results)
        calls.launch.assert_not_called()
        # Remembered: the second run does not boot the primary again.
        calls.ensure_cache.assert_called_once()
        self.assertEqual(2, stderr.count("error: not launching Godot -- " + refusal))


class PrivateUserDirTest(unittest.TestCase):
    """Every scenario run empties user://scenario_saves/ as it starts, so
    runs side by side (verify.ps1's parallel modules) each need their own
    user:// or one wipes another's saves between save_slot and restore_slot
    (9 Oct 2026)."""

    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.root = Path(folder.name) / "users"
        patch = mock.patch.object(run_scenario, "PRIVATE_USER_ROOT", self.root)
        patch.start()
        self.addCleanup(patch.stop)

    def test_two_runs_get_separate_user_dirs_and_saves(self):
        first, second = (run_scenario.private_user_env(run_id) for run_id in ("aaa", "bbb"))
        self.assertNotEqual(run_scenario.user_dir(first), run_scenario.user_dir(second))
        self.assertTrue(run_scenario.user_dir(first).is_relative_to(self.root / "aaa"))
        session = run_scenario.log_dir(first) / "session_x_aaa.jsonl"
        self.assertEqual(run_scenario.user_dir(first) / "scenario_saves",
                         run_scenario.scenario_saves_dir(session))
        self.assertTrue((self.root / ".gdignore").is_file())

    def test_a_new_run_clears_only_stale_user_dirs(self):
        run_scenario.private_user_env("old")
        run_scenario.private_user_env("recent")
        stale = run_scenario.time.time() - run_scenario.PRIVATE_USER_KEEP_SECONDS - 60
        run_scenario.os.utime(self.root / "old", (stale, stale))
        run_scenario.private_user_env("new")
        self.assertFalse((self.root / "old").exists())
        self.assertTrue((self.root / "recent").is_dir())
        self.assertTrue((self.root / "new").is_dir())

    def test_no_test_reads_saves_from_its_own_user_dir(self):
        # log_dir().parent is this process's user://, not the run's: saves
        # read from there are missing, or another run's (10 Oct 2026, NF-3).
        tests = Path(__file__).resolve().parent
        readers = sorted(p.name for p in tests.glob("test_*.py")
                         if "log_dir().parent" in p.read_text(encoding="utf-8")
                         and p.name != Path(__file__).name)
        self.assertEqual([], readers, "read saves with run_scenario.scenario_saves_dir(session_file)")


class WindowedLaunchTest(unittest.TestCase):
    """SPR-1: --windowed swaps --headless for --disable-vsync, nothing else."""

    def test_default_prefix_is_unchanged(self):
        self.assertEqual(["g", "--headless", "--disable-crash-handler"],
                         run_scenario.launch_prefix("g"))

    def test_windowed_drops_headless_and_adds_disable_vsync(self):
        cmd = run_scenario.launch_prefix("g", windowed=True)
        self.assertNotIn("--headless", cmd)
        self.assertIn("--disable-vsync", cmd)
        self.assertIn("--disable-crash-handler", cmd)

    def test_run_once_passes_the_flag_through_with_fixed_fps_kept(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        godot = str(Path(folder.name) / "Godot.exe")
        Path(godot).write_bytes(b"")
        launch = mock.Mock(return_value=mock.Mock(returncode=0, stdout="", stderr=""))
        commands = {}
        for windowed in (False, True):
            with mock.patch.dict(run_scenario._prepared, clear=True), \
                 mock.patch.object(run_scenario, "PRIVATE_USER_ROOT", Path(folder.name) / "users"), \
                 mock.patch.object(run_scenario, "ensure_writable_user_dir"), \
                 mock.patch.object(run_scenario.godot_cache, "ensure_cache", return_value=(True, "")), \
                 mock.patch.object(run_scenario, "session_file_for_run_id", return_value=SESSION), \
                 mock.patch.object(run_scenario.subprocess, "run", launch), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                run_scenario.run_once(Path("s.json"), godot, 1, fixed_fps=60, windowed=windowed)
            commands[windowed] = launch.call_args[0][0]
        self.assertEqual("--headless", commands[False][1])
        self.assertNotIn("--disable-vsync", commands[False])
        self.assertNotIn("--headless", commands[True])
        self.assertIn("--disable-vsync", commands[True])
        self.assertIn("--fixed-fps", commands[True])


class DeveloperOverridesOnlyOutsideScenariosTest(unittest.TestCase):
    """BS-6: the run start applies the developer table's edits, guarded.

    BS-14 moved the call into main.gd's static run_definition, so a loaded
    save's own policy can win over the file: _ready works out whether
    developer edits are allowed and passes that in, and run_definition
    applies them under `if developer_edits_allowed:`."""

    def setUp(self):
        self.lines = MAIN_GD.read_text(encoding="utf-8").splitlines()

    def _code(self, line):
        return line.split("#", 1)[0].rstrip()

    def _line(self, text, start=0):
        return next(i for i, line in enumerate(self.lines[start:], start)
                    if text in self._code(line))

    def test_overrides_apply_once_between_the_level_and_its_sheet(self):
        calls = [i for i, line in enumerate(self.lines)
                 if "DeveloperOverrides.apply(" in self._code(line)]
        self.assertEqual(1, len(calls), "main.gd must call DeveloperOverrides.apply exactly once")
        call = calls[0]
        definition = self._line("static func run_definition(")
        level_line = self._line("Levels.get_level(level_id)", definition)
        self.assertLess(definition, level_line)
        self.assertLess(level_line, call)
        self.assertIn("edited = DeveloperOverrides.apply(level_id, level, overrides_path)",
                      self._code(self.lines[call]))
        # run_definition is the run start's only source of its level, and
        # the sheet is built straight from what it returns.
        ready = self._line("func _ready() -> void:")
        start = self._line("run_definition(Session.starting_level, developer_edits_allowed)", ready)
        self.assertIn("var level: Dictionary = run_definition(", self._code(self.lines[start]))
        sheet_line = self._line("RunAvailability.sheet_for(level)", start)
        self.assertEqual(start + 1, sheet_line)
        self.assertEqual(1, sum("run_definition(" in self._code(line) for line in self.lines[ready:]))

    def test_the_call_sits_under_a_scenario_and_headless_guard(self):
        call = next(i for i, line in enumerate(self.lines)
                    if "DeveloperOverrides.apply(" in self._code(line))
        indent = len(self.lines[call]) - len(self.lines[call].lstrip("\t"))
        guard_line = next(i for i in range(call - 1, -1, -1)
                          if self._code(self.lines[i]).strip()
                          and len(self.lines[i]) - len(self.lines[i].lstrip("\t")) < indent)
        self.assertEqual("if developer_edits_allowed:", self._code(self.lines[guard_line]).strip())
        ready = self._line("func _ready() -> void:")
        allowed = self._code(self.lines[self._line("var developer_edits_allowed", ready)]).strip()
        for condition in ("not scenario_active",
                          "Session.starting_level != Levels.SCENARIO_LEVEL_ID",
                          'DisplayServer.get_name() != "headless"'):
            self.assertIn(condition, allowed)
        self.assertNotIn(" or ", allowed, "every condition must hold, so they are joined with and")


if __name__ == "__main__":
    unittest.main()
