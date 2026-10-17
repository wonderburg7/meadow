"""FC-2: the Colony Run's first crisis, traced on two pinned-seed runs.

FC-1's accepted option A (plans/archive/FC-1_2026-10-09.md): one announced
heavy-rain episode in a bounded window around the 20-minute experience gate.
A colony with the early automation milestone, a working forager and food
cover for the episode is warned as soon as the window opens; one without is
warned at the cutoff and rained on at window close. main.gd's
`_advance_first_crisis` owns it and writes one DiagnosticLog "recorded"
action line ("first_crisis") at each fixed checkpoint -- warning, onset,
peak, end, recovery -- and at every restore.

The two fixtures start from the same colony and seed:
test_scenarios/fc2_first_crisis_prepared.json grants automation and puts
two workers on foraging; test_scenarios/fc2_first_crisis_unprepared.json
withholds both and, at the warning, sends one worker out, whose trip must
come home before the rain. Both save at the warning and restore that save
once the rain has begun, then save during the rain and restore it once the
rain is over, so the crisis record is proved to round-trip across the
trigger: a restore that dropped it would leave the later state live. At the
very end the prepared run reloads the crisis checkpoint itself, which must
warn again without writing a second checkpoint (once a run). While
the rain falls, the trace shows Dr Gallerin's "Why is this happening?" list
holding the crisis entry (guidance_catalogue.gd's first_crisis_rain) and its
text. The window, lead and readiness tick are GameConfig's (Dave, 17 Oct 2026).

What the traces show is that the cause and a response are available to a
player in time; whether a player understands them is the played check filed
in checks/ready.md. Requires a real Godot for the run tests.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402
from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

PREPARED = ROOT / "test_scenarios" / "fc2_first_crisis_prepared.json"
UNPREPARED = ROOT / "test_scenarios" / "fc2_first_crisis_unprepared.json"
MAIN = ROOT / "scripts" / "main.gd"
SAVE_GAME = ROOT / "scripts" / "save_game.gd"
SAVING = ROOT / "scripts" / "saving.gd"
GAME_CONFIG = ROOT / "scripts" / "game_config.gd"
# GameConfig's defaults, which neither fixture overrides.
RAIN_FORAGE_LIMIT = 0.5
RAIN_MAX_SECONDS = 130.0
# The 20-minute experience gate, in seconds of run time.
EXPERIENCE_GATE = 1200.0
# One frame at the fixtures' time_scale under the runner's --fixed-fps 30.
FRAME = 4.0 / 30.0 + 1e-6


def function_body(source: str, name: str) -> str:
    """One GDScript function's text, up to the next top-level line."""
    body = source.replace("\r\n", "\n").split("\nfunc %s(" % name, 1)[1]
    lines = body.split("\n")
    kept = [lines[0]]
    for line in lines[1:]:
        if line and not line[0].isspace():
            break
        kept.append(line)
    return "\n".join(kept)


_RUNS: dict[Path, list[dict]] = {}


def _run(fixture: Path, test: unittest.TestCase) -> list[dict]:
    """The fixture's crisis trace, oldest first; each fixture runs once."""
    if fixture not in _RUNS:
        godot_path = find_godot()
        if not godot_path:
            test.skipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(fixture, godot_path, timeout=900, fixed_fps=30)
        test.assertIsNotNone(session_file, "scenario run produced no session log")
        entries = load_entries(session_file)
        actions = [e for e in entries if e.get("type") == "action"]
        problems = [e for e in actions if e.get("result") not in ("accepted", "recorded")]
        test.assertEqual(problems, [], "actions not accepted: %s" % problems)
        _RUNS[fixture] = [json.loads(e["reason"]) for e in actions if e.get("do") == "first_crisis"]
    return _RUNS[fixture]


def _phase(trace: list[dict], phase: str) -> list[dict]:
    return [line for line in trace if line["phase"] == phase]


def _last(trace: list[dict], phase: str) -> dict:
    lines = _phase(trace, phase)
    if not lines:
        raise AssertionError("no %s line in the crisis trace" % phase)
    return lines[-1]


class CrisisRunChecks:
    """Shared by both paths: one announced crisis inside the window, the
    rain's effect on forage and stores, and save/restore across it."""

    fixture: Path
    path: str

    def trace(self) -> list[dict]:
        """The crisis up to any reload of its own checkpoint (prepared only),
        which replays it from before the warning and is checked apart."""
        trace = _run(self.fixture, self)
        for index, line in enumerate(trace):
            if line["phase"] == "restored" and line["state"] == "pending":
                return trace[:index]
        return trace

    def test_exactly_one_announced_crisis_inside_the_window(self):
        trace = self.trace()
        warnings = _phase(trace, "warning")
        self.assertEqual(len(warnings), 1, "the warning was posted %d times" % len(warnings))
        warning = warnings[0]
        self.assertEqual(warning["path"], self.path)
        self.assertLessEqual(warning["window_open"], EXPERIENCE_GATE)
        self.assertGreaterEqual(warning["window_close"], EXPERIENCE_GATE)
        self.assertGreaterEqual(warning["t"], warning["window_open"])
        self.assertLessEqual(warning["t"], warning["cutoff"] + FRAME)
        self.assertTrue(warning["checkpoint_written"], "no checkpoint before the crisis")
        self.assertTrue(warning["checkpointed"])
        # The lead is dry: no ordinary shower runs into the warning.
        self.assertEqual(warning["rain_target"], 0.0)
        self.assertLessEqual(warning["rain_seconds_left"], 0.0)
        self.assertIn("Heavy rain is coming", warning["text"])
        self.assertIn("Your stores feed the colony for about", warning["text"])
        self.assertTrue(warning["note"].startswith("Heavy rain due in"), warning["note"])
        # Every onset, the first and the one replayed after the restore, is
        # the one the warning scheduled: nothing moved or repeated it.
        onsets = _phase(trace, "onset")
        self.assertTrue(onsets, "the rain never started")
        for onset in onsets:
            # A restored record has been through the save's JSON.
            self.assertAlmostEqual(onset["starts_at"], warning["starts_at"], delta=1e-3)
            self.assertAlmostEqual(onset["warned_at"], warning["t"], delta=1e-3)
            self.assertGreaterEqual(onset["t"], onset["starts_at"])
            self.assertLess(onset["t"] - onset["starts_at"], FRAME)
            # At window close, give or take the frame the cutoff fell in.
            self.assertLessEqual(onset["t"], warning["window_close"] + 2 * FRAME)
            self.assertEqual(onset["note"], "Heavy rain: foragers kept in")

    def test_warning_gives_a_usable_lead(self):
        trace = self.trace()
        warning = _last(trace, "warning")
        onset = _phase(trace, "onset")[0]
        lead = onset["t"] - warning["t"]
        # Never the same tick, and within a frame of the full lead.
        self.assertGreater(lead, 0.0)
        self.assertGreaterEqual(lead, warning["warning_lead"] - FRAME)

    def test_rain_stops_forage_income_and_the_colony_lives_on_its_stores(self):
        trace = self.trace()
        peak, end = _last(trace, "peak"), _last(trace, "end")
        onset = _phase(trace, "onset")[-1]
        self.assertEqual(onset["rain_target"], 1.0)
        self.assertGreater(peak["rain_intensity"], RAIN_FORAGE_LIMIT, "the rain never grounded foragers")
        self.assertAlmostEqual(end["t"] - onset["t"], RAIN_MAX_SECONDS, delta=1.0)
        # Grounded: nothing came in through the heart of the rain ...
        self.assertAlmostEqual(end["nectar_collected"], peak["nectar_collected"], delta=1e-6)
        # ... while the colony went on eating: its whole food, the comb's
        # stores and what the bees carry, fell through the rain.
        def food(line: dict) -> float:
            return line["readiness"]["food_stores"] + line["readiness"]["bee_energy"]
        self.assertLess(food(end), food(onset))
        recovery = _last(trace, "recovery")
        self.assertGreaterEqual(recovery["t"] - end["t"], 120.0 - 1e-6)
        self.assertEqual(recovery["rain_target"], 0.0)

    def test_why_explains_the_rain_while_it_falls(self):
        trace = self.trace()
        peak, recovery = _last(trace, "peak"), _last(trace, "recovery")
        # The "Why is this happening?" list holds the crisis entry while the
        # rain falls, and drops it from "Now" once the rain has passed.
        self.assertIn("first_crisis_rain", peak["why_now"])
        self.assertNotIn("first_crisis_rain", recovery["why_now"])
        text = peak["why_text"]
        self.assertIn("Rain at 100% intensity.", text)
        self.assertIn("Foragers kept in by it: %d." % peak["readiness"]["able_foragers"], text)
        self.assertIn("Too low on energy to fly at all: %d." % peak["readiness"]["unable_foragers"], text)
        for cause in ("waters down the nectar", "soaks the bees' wings", "foragers stay at the hive",
                      "cannot fly for that reason", "the colony eats from its stores"):
            self.assertIn(cause, text)

    def test_the_crisis_record_survives_save_and_restore(self):
        trace = self.trace()
        warning = _last(trace, "warning")
        restored = _phase(trace, "restored")
        self.assertEqual([line["state"] for line in restored], ["warned", "active"])
        warned, active = restored
        # The warned save, restored after the rain began, put the schedule
        # back rather than leaving the live, raining state.
        self.assertAlmostEqual(warned["starts_at"], warning["starts_at"], delta=1e-3)
        self.assertAlmostEqual(warned["warned_at"], warning["t"], delta=1e-3)
        self.assertLess(warned["t"], warned["starts_at"])
        self.assertTrue(warned["note"].startswith("Heavy rain due in"), warned["note"])
        # The active save, restored after the rain ended, put the rain back.
        onsets = _phase(trace, "onset")
        self.assertEqual(len(onsets), 2, "the warned restore did not replay the onset once")
        self.assertAlmostEqual(active["started_at"], onsets[-1]["t"], delta=1e-3)
        self.assertEqual(active["rain_target"], 1.0)
        self.assertGreater(active["rain_seconds_left"], 0.0)
        self.assertEqual(active["note"], "Heavy rain: foragers kept in")
        # And it ended once more, without a second warning.
        self.assertEqual(len(_phase(trace, "end")), 2)
        self.assertEqual(len(_phase(trace, "warning")), 1)


class PreparedCrisisTest(CrisisRunChecks, unittest.TestCase):
    fixture = PREPARED
    path = "prepared"

    def test_a_ready_colony_is_warned_when_the_window_opens(self):
        warning = _last(self.trace(), "warning")
        readiness = warning["readiness"]
        self.assertTrue(readiness["automation"])
        self.assertGreaterEqual(readiness["able_foragers"], 1)
        self.assertTrue(readiness["food_ready"])
        self.assertGreaterEqual(readiness["food_cover_seconds"], RAIN_MAX_SECONDS)
        self.assertLess(warning["t"] - warning["window_open"], 1.0 + FRAME)
        self.assertAlmostEqual(warning["starts_at"] - warning["t"], warning["warning_lead"], delta=1e-6)
        self.assertGreater(warning["nectar_collected"], 0.0, "the foragers brought nothing in")

    def test_reloading_the_crisis_checkpoint_warns_again_without_another_checkpoint(self):
        full = _run(self.fixture, self)
        first = _last(self.trace(), "warning")
        cut = len(self.trace())
        self.assertLess(cut, len(full), "the crisis checkpoint was never reloaded")
        reloaded, tail = full[cut], full[cut + 1:]
        # The checkpoint was written on the warning's tick, still pending,
        # and carries the flag that says it has been written.
        self.assertEqual(reloaded["state"], "pending")
        self.assertTrue(reloaded["checkpointed"])
        self.assertAlmostEqual(reloaded["t"], first["t"], delta=1e-3)
        warnings = _phase(tail, "warning")
        self.assertEqual(len(warnings), 1)
        self.assertFalse(warnings[0]["checkpoint_written"], "a reload wrote another crisis checkpoint")
        self.assertTrue(_phase(tail, "onset"), "the replayed crisis never rained")

    def test_foragers_fly_again_after_the_rain(self):
        trace = self.trace()
        end, recovery = _last(trace, "end"), _last(trace, "recovery")
        self.assertGreater(recovery["nectar_collected"], end["nectar_collected"])


class UnpreparedCrisisTest(CrisisRunChecks, unittest.TestCase):
    fixture = UNPREPARED
    path = "fallback"

    def test_an_unready_colony_is_warned_at_the_cutoff_and_rained_on_at_close(self):
        warning = _last(self.trace(), "warning")
        readiness = warning["readiness"]
        self.assertFalse(readiness["ready"])
        self.assertFalse(readiness["automation"])
        self.assertEqual(readiness["able_foragers"], 0)
        self.assertAlmostEqual(warning["t"], warning["cutoff"], delta=FRAME)
        # Rain at window close, never with less than the full lead.
        self.assertAlmostEqual(warning["starts_at"],
                               max(warning["window_close"], warning["t"] + warning["warning_lead"]), delta=1e-6)
        self.assertIn("You have no worker able to forage.", warning["text"])
        self.assertEqual(warning["nectar_collected"], 0.0)

    def test_a_worker_sent_out_at_the_warning_brings_a_trip_home_before_the_rain(self):
        trace = self.trace()
        warning = _last(trace, "warning")
        onset = _phase(trace, "onset")[0]
        self.assertGreaterEqual(onset["readiness"]["able_foragers"], 1)
        # No other forager exists, so any income is that worker's trip.
        self.assertGreater(onset["nectar_collected"], warning["nectar_collected"],
                           "the response's forage trip did not come home before the rain")
        self.assertLess(onset["t"], warning["starts_at"] + FRAME)


# The four crisis settings through the real save code (Dave, 17 Oct 2026:
# persist "run", FORMAT_VERSION 7): a version 6 save, which has none of them,
# comes out of save_migrations.gd with GameConfig's defaults, and a run saved
# with changed values (save_game.gd's own settings writer, through JSON) puts
# them back when the save's settings are applied on load.
SETTINGS_SCRIPT = """extends SceneTree
var _frame := 0

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	var config: Node = root.get_node("GameConfig")
	var save_game = load("res://scripts/save_game.gd")
	var migrations = load("res://scripts/save_migrations.gd")
	var keys := ["first_crisis_window_open", "first_crisis_window_close",
		"first_crisis_warning_lead", "first_crisis_check_seconds"]
	var defaults := {}
	for key in keys:
		defaults[key] = config.get(key)
		print("FC2 SAVED %s %s" % [key, save_game.saved_settings().has(key)])
	var old: Dictionary = migrations.upgrade({"version": 6, "settings": {}}, save_game.FORMAT_VERSION)
	print("FC2 OLD version %d" % int(old["version"]))
	for key in keys:
		print("FC2 OLD %s %s" % [key, old["settings"][key]])
	config.first_crisis_window_open = 900.0
	config.first_crisis_window_close = 1320.0
	config.first_crisis_warning_lead = 90.0
	config.first_crisis_check_seconds = 2.0
	var written: Dictionary = JSON.parse_string(JSON.stringify({"settings": save_game._settings_dict()}))
	for key in keys:
		config.set(key, defaults[key])
	save_game.apply_settings(written)
	for key in keys:
		print("FC2 LOADED %s %s" % [key, config.get(key)])
	# Inconsistent settings are made consistent where main.gd reads them.
	config.first_crisis_window_open = 1080.0
	config.first_crisis_window_close = 1100.0
	config.first_crisis_warning_lead = 120.0
	var main_script = load("res://scripts/main.gd")
	var bounds: Dictionary = main_script.first_crisis_bounds()
	print("FC2 BOUNDS close %s" % bounds.close)
	print("FC2 BOUNDS cutoff %s" % main_script.first_crisis_cutoff())
	config.first_crisis_warning_lead = 2.0
	print("FC2 BOUNDS lead %s" % main_script.first_crisis_bounds().lead)
	for key in keys:
		config.set(key, defaults[key])
	return true
"""


class CrisisSettingsSaveTest(unittest.TestCase):
    def test_an_old_save_gets_the_defaults_and_a_saved_run_keeps_its_values(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        with tempfile.TemporaryDirectory() as folder:
            script = Path(folder) / "fc2_settings.gd"
            script.write_text(SETTINGS_SCRIPT, encoding="utf-8")
            finished = subprocess.run(
                [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
                 "--script", str(script)],
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
            )
        output = gcc.combined_output(finished)
        self.assertEqual(gcc.failing_lines(output), [], "script errors:\n" + output[-2000:])
        seen = {}
        for line in output.splitlines():
            if line.startswith("FC2 "):
                kind, rest = line[4:].split(" ", 1)
                key, value = rest.rsplit(" ", 1)
                seen[(kind, key)] = value
        defaults = {"first_crisis_window_open": 1080.0, "first_crisis_window_close": 1500.0,
                    "first_crisis_warning_lead": 120.0, "first_crisis_check_seconds": 1.0}
        changed = {"first_crisis_window_open": 900.0, "first_crisis_window_close": 1320.0,
                   "first_crisis_warning_lead": 90.0, "first_crisis_check_seconds": 2.0}
        self.assertEqual(seen.get(("OLD", "version")), "7", output[-2000:])
        for key in defaults:
            self.assertEqual(seen.get(("SAVED", key)), "true", "%s is not saved with the run" % key)
            self.assertEqual(float(seen[("OLD", key)]), defaults[key], "old save: %s" % key)
            self.assertEqual(float(seen[("LOADED", key)]), changed[key], "saved run: %s" % key)
        # open 1080, close 1100, lead 120: close moves to open + lead, so the
        # fallback still warns a full lead ahead; a 2 s lead becomes 10 s.
        self.assertEqual(float(seen[("BOUNDS", "close")]), 1200.0)
        self.assertEqual(float(seen[("BOUNDS", "cutoff")]), 1080.0)
        self.assertEqual(float(seen[("BOUNDS", "lead")]), 10.0)


class CrisisSourceTest(unittest.TestCase):
    def test_the_weather_owner_runs_the_crisis_and_the_save_keeps_it(self):
        main = MAIN.read_text(encoding="utf-8")
        self.assertIn("_advance_first_crisis(delta)", function_body(main, "_advance_weather"))
        self.assertIn("ColonyDiagnostics.crisis_readiness(", function_body(main, "_first_crisis_readiness"))
        warn = function_body(main, "_warn_first_crisis")
        self.assertIn("saving.crisis_checkpoint()", warn)
        # Once a run: the flag is set before the write, so the file carries it.
        self.assertLess(warn.index("first_crisis.checkpointed = true"), warn.index("saving.crisis_checkpoint()"))
        # A shower still falling ends at the warning.
        self.assertIn("rain_seconds_left = 0.0", warn)
        # The outcome is the ordinary rain rules: the crisis never writes the
        # stores, a bee's health or a death.
        crisis = "\n".join(function_body(main, name) for name in (
            "_advance_first_crisis", "_warn_first_crisis", "_start_first_crisis"))
        for forbidden in ("set_cell_contents", ".energy =", "die(", "colony_lost"):
            self.assertNotIn(forbidden, crisis)
        self.assertIn("first_crisis_check_timer = float(bounds.check)", function_body(main, "_advance_first_crisis"))
        self.assertIn("maxf(0.1, GameConfig.first_crisis_check_seconds)", main)
        # GameConfig owns the window, the lead and the readiness tick (Dave,
        # 17 Oct 2026); main.gd keeps no copy of them.
        config = GAME_CONFIG.read_text(encoding="utf-8")
        for name, value in (("first_crisis_window_open", "1080.0"), ("first_crisis_window_close", "1500.0"),
                            ("first_crisis_warning_lead", "120.0"), ("first_crisis_check_seconds", "1.0")):
            self.assertIn("var %s: float = %s" % (name, value), config)
        for stale in ("FIRST_CRISIS_WINDOW_OPEN", "FIRST_CRISIS_WINDOW_CLOSE",
                      "FIRST_CRISIS_WARNING_LEAD", "FIRST_CRISIS_CHECK_SECONDS"):
            self.assertNotIn(stale, main)
        self.assertIn('"first_crisis": world.first_crisis.duplicate(true)', SAVE_GAME.read_text(encoding="utf-8"))
        self.assertIn('main.restore_first_crisis(data.get("first_crisis"))',
                      function_body(SAVING.read_text(encoding="utf-8"), "_restore"))


if __name__ == "__main__":
    unittest.main()
