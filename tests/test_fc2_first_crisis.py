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
trigger: a restore that dropped it would leave the later state live.

What the traces show is that the cause and a response are available to a
player in time; whether a player understands them is the played check filed
in checks/ready.md. Requires a real Godot for the run tests.
"""

from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

PREPARED = ROOT / "test_scenarios" / "fc2_first_crisis_prepared.json"
UNPREPARED = ROOT / "test_scenarios" / "fc2_first_crisis_unprepared.json"
MAIN = ROOT / "scripts" / "main.gd"
SAVE_GAME = ROOT / "scripts" / "save_game.gd"
SAVING = ROOT / "scripts" / "saving.gd"
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
        return _run(self.fixture, self)

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
            self.assertLessEqual(onset["t"], warning["window_close"] + FRAME)
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
        self.assertEqual(warning["starts_at"], warning["window_close"])
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


class CrisisSourceTest(unittest.TestCase):
    def test_the_weather_owner_runs_the_crisis_and_the_save_keeps_it(self):
        main = MAIN.read_text(encoding="utf-8")
        self.assertIn("_advance_first_crisis(delta)", function_body(main, "_advance_weather"))
        self.assertIn("ColonyDiagnostics.crisis_readiness(", function_body(main, "_first_crisis_readiness"))
        self.assertIn("saving.crisis_checkpoint()", function_body(main, "_warn_first_crisis"))
        # The outcome is the ordinary rain rules: the crisis never writes the
        # stores, a bee's health or a death.
        crisis = "\n".join(function_body(main, name) for name in (
            "_advance_first_crisis", "_warn_first_crisis", "_start_first_crisis"))
        for forbidden in ("set_cell_contents", ".energy =", "die(", "colony_lost"):
            self.assertNotIn(forbidden, crisis)
        self.assertRegex(function_body(main, "_advance_first_crisis"), re.compile(r"FIRST_CRISIS_CHECK_SECONDS"))
        self.assertIn('"first_crisis": world.first_crisis.duplicate(true)', SAVE_GAME.read_text(encoding="utf-8"))
        self.assertIn('main.restore_first_crisis(data.get("first_crisis"))',
                      function_body(SAVING.read_text(encoding="utf-8"), "_restore"))


if __name__ == "__main__":
    unittest.main()
