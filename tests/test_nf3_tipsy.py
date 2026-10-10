"""NF-3: a bee that eats fermented nectar goes tipsy.

Runs test_scenarios/nf3_tipsy.json once, at time_scale 1 so a save half a
second apart records real movement. Four pollen foragers work a colony whose
only food is one nectar cell, stocked at the start and fermented within the
fixture's one-hour threshold. Hunger starts at 5%, so nobody eats, while
proximity recruitment puts every forager that scores a trip on a dance list;
thirty saves half a second apart record them sober. Hunger is then raised to
98%, so each forager eats the fermented nectar on its next visit home, and
thirty more saves record them tipsy. Hunger goes back down, and a save after
the fixture's tipsy_seconds shows them sober again. Finally the first tipsy
save is restored and saved once more.

From the saves and the session log's per-second snapshots the tests show,
from the run itself, that a forager that ate there went tipsy, that a tipsy
forager never covers more than tipsy_speed_factor of its own speed while a
sober one does, that no forager is dance-eligible while all of them are
tipsy (though they were before), that the tipsiness counts down and wears
off, and that its remaining time survives save and restore.
"""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once, scenario_saves_dir  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "nf3_tipsy.json"
SOBER = ["sober-%d" % i for i in range(30)]
TIPSY = ["tipsy-%d" % i for i in range(30)]
SAVES = SOBER + TIPSY + ["recovered", "restored"]
FORAGER = 0   # bee_enums.gd Role.FORAGER
CONFIG = json.loads(FIXTURE.read_text(encoding="utf-8"))["config_overrides"]
BEE_SPEED = float(CONFIG["bee_speed"])
TIPSY_SPEED_FACTOR = float(CONFIG["tipsy_speed_factor"])


def _foragers(save: dict) -> dict:
    return {int(b["id"]): b for b in save["bees"] if int(b.get("role", -1)) == FORAGER}


def _time(save: dict) -> float:
    return float(save["clock"]["sim_time"])


def _own_speed(bee: dict) -> float:
    """The bee's full speed: bee_speed with its rolled speed trait, if any
    (bee.gd::_apply_stats)."""
    if bee.get("trait_stat") == "speed":
        return BEE_SPEED * (1.0 + float(bee.get("trait_pct", 0.0)))
    return BEE_SPEED


def _paces(names: list, saves: dict, want_tipsy: bool) -> list:
    """Each forager's distance between consecutive saves, as a fraction of
    its own full speed over that interval. Skipped when the bee crossed the
    entrance (hive and meadow positions are in different spaces) or was not
    in the wanted state at both ends."""
    out = []
    for a, b in zip(names, names[1:]):
        dt = _time(saves[b]) - _time(saves[a])
        before, after = _foragers(saves[a]), _foragers(saves[b])
        for bee_id, x in before.items():
            y = after.get(bee_id)
            if y is None or bool(x["indoors"]) != bool(y["indoors"]):
                continue
            tipsy = float(x.get("tipsy", 0.0)) > 0.0 and float(y.get("tipsy", 0.0)) > 0.0
            sober = float(x.get("tipsy", 0.0)) <= 0.0 and float(y.get("tipsy", 0.0)) <= 0.0
            if (want_tipsy and not tipsy) or (not want_tipsy and not sober):
                continue
            moved = ((float(y["x"]) - float(x["x"])) ** 2 + (float(y["y"]) - float(x["y"])) ** 2) ** 0.5
            out.append(moved / (_own_speed(x) * dt))
    return out


class TipsyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        cls.tipsy_seconds = float(CONFIG["tipsy_seconds"])
        session_file = run_once(FIXTURE, godot_path, timeout=600, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        entries = load_entries(session_file)
        cls.rejected = [e for e in entries if e.get("type") == "action" and e.get("result") == "rejected"]
        cls.snapshots = [e for e in entries if e.get("type") == "snapshot"]
        scratch = scenario_saves_dir(session_file)
        cls.saves = {}
        for name in SAVES:
            path = scratch / ("nf3-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))

    def setUp(self):
        self.assertEqual(self.rejected, [], "a scenario action was rejected")
        missing = [n for n in SAVES if n not in self.saves]
        self.assertEqual(missing, [], "the run did not write every save")

    def test_a_forager_that_eats_fermented_nectar_goes_tipsy(self):
        for name in SOBER:
            for bee in _foragers(self.saves[name]).values():
                self.assertEqual(float(bee.get("tipsy", 0.0)), 0.0, "a forager was tipsy before any food was stocked")
        for name in TIPSY:
            foragers = _foragers(self.saves[name])
            self.assertEqual(len(foragers), 4)
            for bee in foragers.values():
                left = float(bee.get("tipsy", 0.0))
                self.assertGreater(left, 0.0, "forager %s never ate the fermented nectar" % bee["id"])
                # Restarted by each mouthful, never stacked past the set time.
                self.assertLessEqual(left, self.tipsy_seconds)

    def test_a_tipsy_forager_moves_slower(self):
        sober = _paces(SOBER, self.saves, want_tipsy=False)
        tipsy = _paces(TIPSY, self.saves, want_tipsy=True)
        self.assertTrue(sober and tipsy, "no comparable intervals")
        self.assertGreater(max(sober), TIPSY_SPEED_FACTOR + 0.15, "no sober forager was seen flying at full speed")
        self.assertGreater(max(tipsy), 0.1, "no tipsy forager was seen moving")
        self.assertLessEqual(max(tipsy), TIPSY_SPEED_FACTOR + 0.03, "a tipsy forager moved at more than its tipsy speed")

    def test_a_tipsy_forager_is_never_dance_eligible(self):
        def eligible(snapshot):
            behaviour = snapshot["foraging_behaviour"]
            return int(behaviour["dance_eligible_mentors"]) + int(behaviour["dance_eligible_seekers"])

        def during(first, last):
            start, end = _time(self.saves[first]), _time(self.saves[last])
            return [s for s in self.snapshots if start <= float(s["game_time"]) <= end]

        sober = during(SOBER[0], SOBER[-1])
        tipsy = during(TIPSY[0], TIPSY[-1])
        self.assertTrue(sober and tipsy, "no snapshots in the measured windows")
        self.assertGreater(max(eligible(s) for s in sober), 0, "no sober forager was ever dance-eligible")
        # Every forager is tipsy throughout this window (the first test).
        self.assertEqual([eligible(s) for s in tipsy], [0] * len(tipsy))
        self.assertEqual([int(s["population"]["by_state"]["DANCING"]) for s in tipsy], [0] * len(tipsy))

    def test_tipsiness_counts_down_and_wears_off(self):
        first, last = self.saves[TIPSY[0]], self.saves[TIPSY[-1]]
        elapsed = _time(last) - _time(first)
        later = _foragers(last)
        for bee_id, bee in _foragers(first).items():
            before, after = float(bee["tipsy"]), float(later[bee_id]["tipsy"])
            if after < before:   # not topped up by another mouthful in between
                self.assertAlmostEqual(before - after, elapsed, delta=0.2)
        recovered = self.saves["recovered"]
        self.assertGreater(_time(recovered) - _time(last), self.tipsy_seconds)
        for bee in _foragers(recovered).values():
            self.assertEqual(float(bee.get("tipsy", 0.0)), 0.0, "forager %s is still tipsy" % bee["id"])

    def test_tipsiness_survives_save_and_restore(self):
        saved = _foragers(self.saves[TIPSY[0]])
        restored = _foragers(self.saves["restored"])
        self.assertEqual(sorted(restored), sorted(saved))
        for bee_id, bee in saved.items():
            self.assertAlmostEqual(float(restored[bee_id]["tipsy"]), float(bee["tipsy"]), delta=0.5)


if __name__ == "__main__":
    unittest.main()
