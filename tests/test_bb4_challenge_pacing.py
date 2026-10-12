"""BB-4: Challenges 1 and 2 are still completable with 15-day unfed workers.

Plays each Challenge through once on its fixture's pinned seed, under BB-2's
rule (a worker raised on pollen alone lives pollen_raised_lifespan_factor of
the usual days at pollen_raised_stat_factor of speed and load), with no
advance_challenge_stage after the start:

- test_scenarios/bb4_challenge1_route.json starts Challenge 1 at 1.16 (where
  the queen lays the colony's first egg), the stage the Challenge's setup
  builds the world for, and plays 1.16 to 1.20: laying, the first worker, its
  selection and its first trip out. Challenge 1 has no later stage to start
  from, so its one advance_challenge_stage is the start.
- test_scenarios/bb4_challenge2_route.json starts Challenge 2 at 2.1 and plays
  it to 2.9, hatching roles, buying Nurses, designating cells, building and
  mining through the actions scripts/scenario_actions.gd already has.

A Challenge's last goal opens the completion screen, which pauses the run and
with it the scenario driver, so each route ends on a `challenge_goal_met`
assertion in the frames before that, and the stage assertions before it stamp
the game time each stage was reached.

The completion targets are read from scripts/challenge_stages.gd, never
restated here: the run's snapshots at that moment must hold them.
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

STAGES = ROOT / "scripts" / "challenge_stages.gd"
SCENARIOS = ROOT / "test_scenarios"
SECONDS_PER_DAY = 200.0
C1_STAGES = ["1.16", "1.17", "1.18", "1.19", "1.20"]
C2_STAGES = ["2.%d" % n for n in range(1, 10)]
# Snapshots land every 10 game seconds; the completion check takes the best of
# the snapshots within this many seconds of the goal being met.
SNAPSHOT_SECONDS = 30.0


def _constant(name: str) -> float:
    match = re.search(r"^const %s(?::\s*\w+)?\s*:?=\s*([0-9.]+)" % name, STAGES.read_text(encoding="utf-8"), re.M)
    if match is None:
        raise AssertionError("challenge_stages.gd has no numeric const %s" % name)
    return float(match.group(1))


def _stage_marks(actions: list[dict]) -> dict[str, float]:
    """Game time of each accepted `challenge_stage_id` assertion that has no other condition."""
    marks: dict[str, float] = {}
    for entry in actions:
        if entry["do"] != "assert" or entry["result"] != "accepted":
            continue
        target = json.loads(entry["target"])
        if list(target) == ["challenge_stage_id"]:
            marks[target["challenge_stage_id"]] = float(entry["game_time"])
    return marks


class _RouteChecks:
    """The checks both routes share; a mixin so unittest does not run it bare."""

    fixture = ""
    stages: list[str] = []
    start_moves: list = []

    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(SCENARIOS / cls.fixture, godot_path, timeout=900, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        entries = load_entries(session_file)
        cls.actions = [e for e in entries if e.get("type") == "action"]
        cls.snapshots = [e for e in entries if e.get("type") == "snapshot"]
        cls.marks = _stage_marks(cls.actions)

    def _completion_time(self) -> float:
        done = [a for a in self.actions
                if a["do"] == "assert" and a["result"] == "accepted" and "challenge_goal_met" in a["target"]]
        self.assertEqual(len(done), 1, "the route never met the Challenge's last goal")
        return float(done[0]["game_time"])

    def _near(self, when: float) -> list[dict]:
        near = [s for s in self.snapshots if abs(float(s["game_time"]) - when) <= SNAPSHOT_SECONDS]
        self.assertTrue(near, "no snapshot near game time %.1f" % when)
        return near

    def _held(self, when: float, read) -> float:
        """The best value `read` gives from the snapshots around `when`."""
        return max(read(s) for s in self._near(when))

    def test_no_action_was_rejected(self):
        rejected = [a for a in self.actions if a["result"] in ("rejected", "never_fired")]
        self.assertEqual(rejected, [], "an action was rejected or never fired")

    def test_every_stage_is_reached_in_order(self):
        self.assertEqual([s for s in self.stages if s not in self.marks], [], "stages never reached")
        times = [self.marks[s] for s in self.stages]
        self.assertEqual(times, sorted(times))
        self.assertGreaterEqual(self._completion_time(), times[-1])

    def test_the_route_jumps_no_stage_after_its_start(self):
        moves = [a for a in self.actions if a["do"] in ("advance_challenge_stage", "retreat_challenge_stage")]
        self.assertEqual([(m["do"], m["target"]) for m in moves], self.start_moves)


class ChallengeOneRouteTest(_RouteChecks, unittest.TestCase):
    fixture = "bb4_challenge1_route.json"
    stages = C1_STAGES
    start_moves = [("advance_challenge_stage", "1.16")]

    def test_the_first_worker_hatched_before_completion(self):
        # 1.17 asks for a hatched nectar forager and 1.18 for her selection, so
        # the stage marks alone say it; the log's own count backs them.
        done = self._completion_time()
        self.assertGreaterEqual(self._held(done, lambda s: s["role_outcomes"]["brood_hatches_total"]), 1)


class ChallengeTwoRouteTest(_RouteChecks, unittest.TestCase):
    fixture = "bb4_challenge2_route.json"
    stages = C2_STAGES
    start_moves: list = []

    def test_the_full_colony_goal_holds_at_completion(self):
        done = self._completion_time()

        def held(read) -> float:
            return self._held(done, read)

        self.assertGreaterEqual(held(lambda s: s["resources"]["stored_nectar"]), _constant("C2_COMPLETE_NECTAR"))
        # The goal itself read the full pollen target (the assertion above it
        # passed). The run ends in the frames before the completion screen, so
        # no snapshot follows the moment it was met, and a forager's load
        # lands between snapshots: the last one stands within a fifth of it.
        self.assertGreaterEqual(held(lambda s: s["resources"]["stored_pollen"]), 0.8 * _constant("C2_COMPLETE_POLLEN"))
        foragers = _constant("C2_COMPLETE_NECTAR_FORAGERS") + _constant("C2_COMPLETE_POLLEN_FORAGERS")
        self.assertGreaterEqual(held(lambda s: s["population"]["by_role"]["forager"]), foragers)
        self.assertGreaterEqual(held(lambda s: s["population"]["by_role"]["nursery"]), _constant("C2_COMPLETE_NURSES"))
        self.assertGreaterEqual(held(lambda s: s["population"]["by_role"]["builder"]), _constant("C2_COMPLETE_BUILDERS"))
        self.assertGreaterEqual(held(lambda s: s["population"]["by_role"]["miner"]), _constant("C2_COMPLETE_MINERS"))


if __name__ == "__main__":
    unittest.main()
