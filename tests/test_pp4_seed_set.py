"""PP-4: seed set -- pollinated flowers replant nearby and the meadow
remembers through winter.

Runs test_scenarios/pp4_seed_set.json once: a level row with "seed_set": true
and winter on, at 20-second days and 10-day seasons, with thirty foragers
that all prefer Clover ("forager_species"), so the colony works one species.
It saves at the end of the first summer ("summer"), early in the second
spring while COL-8's regrowth is under way ("mid"), restores "mid" in place
twenty seconds later and saves again in the same tick ("restored"), then
saves once the regrowth is over ("spring").

The fixture sets "pollination_log": true, so pollination.gd writes one
session-log line per flower that dies of age ("pollination_withered", with
its pollen counts and whether it set seed), one per replacement
("pollination_replant": "seed" or "seasonal", with the weights a seasonal
draw used, the counts that weighted them, and on a replacement's first
flower the gap it filled and the empty gaps a bush took with it), and one
when the year's counts move to spring
("pollination_spring"). From those lines and the saves:

- a flower sets seed exactly when it had a compatible delivery and more
  compatible than incompatible ones;
- every flower that set seed is replaced by its own species close to where
  it stood, inside the field and clear of the hive, and no flower that did
  not set seed is;
- the gaps are filled in the order the flowers died: a seed of a species in
  flower comes up, an empty gap or an out-of-season seed takes the seasonal
  draw, and the gaps a save holds are exactly the ones still waiting;
- the year's counts move to spring at the first death or replacement after
  winter, and the seasonal draw is weighted only during the spring regrowth,
  by exactly the seed the year set; the weighting favours the seeded species, keeps
  every species at or above its seasonal weight, and the meadow comes back
  with more of the species the colony pollinated;
- the seed counts, the gaps waiting and each flower's lifespan survive save
  and restore.

A second, shorter run of the same fixture without "seed_set" stands for a
Challenge (whose level rows never set it): flowers still set seed by the
rule, but none replants its own species and no draw is weighted.
"""

from __future__ import annotations

import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(TOOLS))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once, scenario_saves_dir  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "pp4_seed_set.json"
SAVES = ("summer", "mid", "restored", "spring")
SPECIES = ["Clover", "Borage", "Foxglove", "Poppy", "Bramble", "Dandelion"]
# world_building.gd's SEED_DISTANCE: a seed comes up 20 to 60 px from its
# parent, unless an obstacle pushed it clear.
SEED_NEAR = 60.0
SEED_FAR = 150.0
MAIN = (SCRIPTS / "main.gd").read_text(encoding="utf-8")


def _vector(name: str) -> tuple:
    match = re.search(r"const %s := Vector2\(([-\d.]+), ([-\d.]+)\)" % name, MAIN)
    return float(match.group(1)), float(match.group(2))


HIVE = _vector("HIVE_MARKER_POSITION")
FIELD_HALF = _vector("FLOWER_FIELD_HALF_SIZE")
MIN_DISTANCE = float(re.search(r"const FLOWER_MIN_DISTANCE := ([\d.]+)", MAIN).group(1))
# Each species' flowering window, in SPECIES order (flower_species.gd).
WINDOWS = [(float(a), float(b)) for a, b in re.findall(
    r'"season_start": ([\d.]+), "season_end": ([\d.]+)',
    (SCRIPTS / "flower_species.gd").read_text(encoding="utf-8"))]


def _close(a, b, tolerance: float = 0.01) -> bool:
    return abs(float(a[0]) - float(b[0])) <= tolerance and abs(float(a[1]) - float(b[1])) <= tolerance


def _distance(a, b) -> float:
    return ((float(a[0]) - float(b[0])) ** 2 + (float(a[1]) - float(b[1])) ** 2) ** 0.5


def _seed_sets(compatible: int, incompatible: int) -> bool:
    return compatible >= 1 and compatible > incompatible


def _shares(save: dict) -> dict:
    counts = {}
    for f in save["flowers"]:
        name = SPECIES[int(f["species"])]
        counts[name] = counts.get(name, 0) + 1
    total = sum(counts.values())
    return {name: n / total for name, n in counts.items()}


def _run(fixture: Path):
    godot_path = find_godot()
    if not godot_path:
        raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
    session_file = run_once(fixture, godot_path, timeout=900, fixed_fps=30)
    if session_file is None:
        raise AssertionError("scenario run produced no session log")
    godot_log = session_file.parent / "godot.log"
    log_text = godot_log.read_text(encoding="utf-8", errors="replace") if godot_log.exists() else ""
    errors = [line for line in log_text.splitlines() if "SCRIPT ERROR" in line]
    actions = [e for e in load_entries(session_file) if e.get("type") == "action"]
    return session_file, actions, errors


class SeedSetSourceTest(unittest.TestCase):
    def test_challenges_never_set_seed_and_every_other_row_does(self):
        text = (SCRIPTS / "levels.gd").read_text(encoding="utf-8")
        start = text.index("const LEVELS := {")
        rows = re.split(r"\n\t(\d+): \{", text[start:text.index("\n}\n", start)])
        bodies = {int(rows[i]): rows[i + 1] for i in range(1, len(rows), 2)}
        self.assertEqual(sorted(bodies), [1, 2, 3, 4, 5, 6, 7, 8])
        for level, body in bodies.items():
            has = '"seed_set": true' in body
            self.assertEqual(has, level >= 3, "level %d" % level)
        self.assertIn('return bool(get_level(id).get("seed_set", false))', text)

    def test_seed_rule(self):
        text = (SCRIPTS / "flower.gd").read_text(encoding="utf-8")
        self.assertIn("return compatible_visits >= 1 and compatible_visits > incompatible_visits", text)

    def test_ledger_is_the_only_writer_of_seed_state(self):
        for path in SCRIPTS.glob("*.gd"):
            if path.name == "pollination.gd":
                continue
            text = path.read_text(encoding="utf-8")
            self.assertIsNone(
                re.search(r"pollination\.(seed_counts|spring_counts|spring_of|gaps)\s*[+\-]?=", text),
                "%s writes the seed ledger" % path.name)


class SeedSetRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        session_file, actions, cls.script_errors = _run(FIXTURE)
        cls.config = json.loads(FIXTURE.read_text(encoding="utf-8"))["config_overrides"]
        cls.rejected = [e for e in actions if e.get("result") in ("rejected", "never_fired")]
        scratch = scenario_saves_dir(session_file)
        cls.saves = {}
        for name in SAVES:
            path = scratch / ("pp4-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))
        # Every seed-set line in log order, with the save and restore lines
        # that split it, each tagged with the game time it was logged at.
        cls.events = []
        for e in actions:
            do = e.get("do")
            if do == "save_run":
                match = re.search(r'"name": "PP4 ([^"]+)"', str(e.get("target", "")))
                cls.events.append({"kind": "save", "name": match.group(1) if match else ""})
            elif do == "restore_slot":
                cls.events.append({"kind": "restore"})
            elif do in ("pollination_withered", "pollination_replant", "pollination_spring"):
                detail = json.loads(e["reason"])
                detail["kind"] = do.split("_")[1]
                detail["target"] = e["target"]
                cls.events.append(detail)
            else:
                continue
            cls.events[-1]["t"] = float(e["game_time"])
        for e in cls.events:
            if e["kind"] == "replant" and e["target"] == "seed":
                e["parent"] = e["gap"][1:]
        cls.deaths = [e for e in cls.events if e["kind"] == "withered"]
        cls.replants = [e for e in cls.events if e["kind"] == "replant"]
        # COL-8's regrowth: winter ends on day season + 1 + winter, and the
        # meadow regrows over spring_regrowth_days from then (game seconds).
        day = float(cls.config["seconds_per_day"])
        winter_ends_day = float(cls.config["season_length_days"]) + 1.0 + float(cls.config["winter_length_days"])
        cls.regrowth_from = (winter_ends_day - 1.0) * day
        cls.regrowth_to = cls.regrowth_from + float(cls.config["spring_regrowth_days"]) * day

    def _in_season(self, species_index: int, t: float):
        """Whether the species flowers at game time `t` (flower_species.gd's
        in_season), or None within a hair of its window's edge."""
        day = 1.0 + t / float(self.config["seconds_per_day"])
        season = float(self.config["season_length_days"])
        year = season + float(self.config["winter_length_days"])
        fraction = min(1.0, max(0.0, (((day - 1.0) % year) + 1.0 - 1.0) / season))
        start, end = WINDOWS[species_index]
        if min(abs(fraction - start), abs(fraction - end)) < 0.02:
            return None
        return start <= fraction <= end

    def _index(self, kind: str, **match) -> int:
        for i, e in enumerate(self.events):
            if e["kind"] == kind and all(e.get(k) == v for k, v in match.items()):
                return i
        self.fail("no %s line matching %s" % (kind, match))

    def test_run_raises_no_script_error(self):
        self.assertEqual(self.script_errors, [], self.script_errors[:5])

    def test_run_resolves_every_action(self):
        self.assertEqual(self.rejected, [], self.rejected[:5])
        self.assertEqual(sorted(self.saves), sorted(SAVES), "missing saves: %s" % sorted(self.saves))

    def test_a_flower_sets_seed_by_the_rule(self):
        self.assertGreater(len(self.deaths), 500)
        for d in self.deaths:
            self.assertTrue(d["seed_set_on"], d)
            self.assertEqual(d["sets_seed"], _seed_sets(d["compatible_visits"], d["incompatible_visits"]), d)
        seeded = [d for d in self.deaths if d["sets_seed"]]
        self.assertGreater(len(seeded), 20, "too few flowers set seed to show anything")
        self.assertLess(len(seeded), len(self.deaths))

    def test_a_flower_that_set_seed_is_replaced_by_its_species_nearby(self):
        seeds = [r for r in self.replants if r["target"] == "seed"]
        self.assertGreater(len(seeds), 20)
        seeded_before = []
        near = 0
        for e in self.events:
            if e["kind"] == "withered" and e["sets_seed"]:
                seeded_before.append(e)
            elif e["kind"] == "replant" and e["target"] == "seed":
                parents = [d for d in seeded_before if _close(d["flower"], e["parent"])]
                self.assertTrue(parents, "seed at %s has no flower that set seed there" % e["parent"])
                self.assertEqual(e["species_index"], parents[-1]["species_index"], e)
                distance = _distance(e["flower"], e["parent"])
                self.assertLessEqual(distance, SEED_FAR, e)
                # Inside the field and off the hive, so a lineage cannot drift.
                x, y = e["flower"]
                self.assertLessEqual(abs(x - HIVE[0]), FIELD_HALF[0] + 1.0, e)
                self.assertLessEqual(abs(y - HIVE[1]), FIELD_HALF[1] + 1.0, e)
                self.assertGreaterEqual(_distance(e["flower"], HIVE), MIN_DISTANCE - 1.0, e)
                near += distance <= SEED_NEAR + 0.01
        self.assertGreaterEqual(near, 0.95 * len(seeds))
        # Up to the mid save, every flower that set seed has had its gap
        # filled (by its seed, or by the seasonal draw when out of season)
        # or is a seed still waiting in that save.
        mid = self._index("save", name="mid")
        waiting = [tuple(p[1:]) for p in self.saves["mid"]["seed_bank"]["gaps"] if p[0] >= 0]
        planted = [r["gap"][1:] for r in self.events[:mid]
                   if r["kind"] == "replant" and r.get("gap") and r["gap"][0] >= 0]
        for d in self.events[:mid]:
            if d["kind"] == "withered" and d["sets_seed"]:
                self.assertTrue(any(_close(d["flower"], p) for p in planted)
                                or any(_close(d["flower"], w) for w in waiting), d)

    def test_a_flower_that_did_not_set_seed_gets_the_seasonal_draw(self):
        unseeded = [d["flower"] for d in self.deaths if not d["sets_seed"]]
        seeded = [d["flower"] for d in self.deaths if d["sets_seed"]]
        for r in self.replants:
            if r["target"] != "seed":
                continue
            # Its parent set seed; no flower that did not set seed is a parent
            # unless a seeded one died on the very same spot.
            if any(_close(r["parent"], u) for u in unseeded):
                self.assertTrue(any(_close(r["parent"], s) for s in seeded), r)
        seasonal = [r for r in self.replants if r["target"] == "seasonal"]
        self.assertGreater(len(seasonal), len(self.deaths) // 2)
        # Outside the spring regrowth the draw is today's, unweighted.
        for r in seasonal:
            if r["t"] < self.regrowth_from - 1.0 or r["t"] > self.regrowth_to + 1.0:
                self.assertEqual(r["counts"], {}, r)

    def test_gaps_fill_in_the_order_the_flowers_died(self):
        mid_gaps = self.saves["mid"]["seed_bank"]["gaps"]
        queue = []
        filled = {"seed": 0, "empty": 0, "out_of_season": 0, "none_waiting": 0}
        checked_save = False
        for e in self.events:
            if e["kind"] == "save" and e["name"] == "mid":
                # The save holds exactly the gaps still waiting.
                self.assertEqual(len(mid_gaps), len(queue))
                for saved, waiting in zip(mid_gaps, queue):
                    self.assertEqual(int(saved[0]), waiting[0])
                    self.assertTrue(_close(saved[1:], waiting[1:]), (saved, waiting))
                checked_save = True
            elif e["kind"] == "restore":
                queue = [[int(g[0]), float(g[1]), float(g[2])] for g in mid_gaps]
            elif e["kind"] == "withered":
                queue.append([e["species_index"] if e["sets_seed"] else -1] + list(e["flower"]))
            elif e["kind"] == "replant" and "gap" in e:
                expected = queue.pop(0) if queue else []
                gap = e["gap"]
                self.assertEqual(len(gap), len(expected), e)
                if expected:
                    self.assertEqual(int(gap[0]), expected[0], e)
                    self.assertTrue(_close(gap[1:], expected[1:]), e)
                if e["target"] == "seed":
                    self.assertGreaterEqual(expected[0], 0, e)
                    self.assertEqual(e["species_index"], expected[0], e)
                    self.assertNotEqual(self._in_season(expected[0], e["t"]), False, e)
                    filled["seed"] += 1
                elif not expected:
                    filled["none_waiting"] += 1
                elif expected[0] < 0:
                    filled["empty"] += 1
                else:
                    # A seed out of season falls back to the seasonal draw.
                    self.assertNotEqual(self._in_season(expected[0], e["t"]), True, e)
                    filled["out_of_season"] += 1
                for _ in range(int(e["dropped"])):
                    self.assertTrue(queue and queue[0][0] == -1, "a bush took a gap that held a seed: %s" % e)
                    queue.pop(0)
        self.assertTrue(checked_save)
        self.assertGreater(filled["seed"], 20, filled)
        self.assertGreater(filled["empty"], 100, filled)
        self.assertGreater(filled["out_of_season"], 0, filled)

    def test_spring_regrowth_favours_the_species_that_set_seed_without_losing_any(self):
        spring = self._index("spring")
        # The swap happens at the first death or replacement after winter,
        # whatever is waiting, so no event after the winter precedes it.
        self.assertLessEqual(self.events[spring]["t"], self.regrowth_from + 2.0)
        self.assertTrue(all(e["t"] <= self.regrowth_from + 2.0 for e in self.events[:spring]))
        counted = {}
        for d in self.events[:spring]:
            if d["kind"] == "withered" and d["sets_seed"]:
                counted[d["target"]] = counted.get(d["target"], 0) + 1
        spring_counts = self.events[spring]["spring_counts"]
        self.assertEqual(spring_counts, counted)
        self.assertEqual(self.saves["summer"]["seed_bank"]["spring_counts"], {})
        self.assertTrue(self.saves["summer"]["seed_bank"]["seed_counts"])
        top = max(spring_counts, key=spring_counts.get)
        seed_total = sum(spring_counts.values())
        weighted = [r for r in self.replants if r["target"] == "seasonal" and r["counts"]]
        self.assertGreater(len(weighted), 100)
        expected_plain = 0.0
        expected_weighted = 0.0
        for r in weighted:
            self.assertGreaterEqual(r["t"], self.regrowth_from - 1.0, r)
            self.assertLessEqual(r["t"], self.regrowth_to + 1.0, r)
            self.assertEqual(r["counts"], spring_counts, r)
            weights = r["weights"]
            # Half the weighted draw is today's season, half the seed: the
            # weights total twice the seasonal ones, and taking each species'
            # share of the seed back off leaves its seasonal weight.
            seasonal_total = sum(weights) / 2.0
            for i, name in enumerate(SPECIES):
                seasonal = weights[i] - seasonal_total * spring_counts.get(name, 0) / seed_total
                self.assertGreater(seasonal, 0.0, "%s vanished from %s" % (name, r))
                self.assertGreaterEqual(weights[i], seasonal, r)
            top_index = SPECIES.index(top)
            seasonal_top = weights[top_index] - seasonal_total * spring_counts[top] / seed_total
            expected_plain += seasonal_top / seasonal_total
            expected_weighted += weights[top_index] / sum(weights)
        drawn = sum(1 for r in weighted if r["species"] == top) / len(weighted)
        expected_plain /= len(weighted)
        expected_weighted /= len(weighted)
        self.assertGreater(drawn, expected_plain + 0.1,
                           "%s drawn %.2f, seasonal alone %.2f" % (top, drawn, expected_plain))
        self.assertAlmostEqual(drawn, expected_weighted, delta=0.08)
        # The meadow comes back with more of the species the colony worked.
        summer = _shares(self.saves["summer"])
        spring_shares = _shares(self.saves["spring"])
        self.assertGreater(spring_shares.get(top, 0.0), summer.get(top, 0.0) + 0.1,
                           "summer %s, spring %s" % (summer, spring_shares))
        # The counts restart once spring has them.
        self.assertEqual(self.saves["spring"]["seed_bank"]["spring_counts"], spring_counts)
        self.assertLess(sum(self.saves["spring"]["seed_bank"]["seed_counts"].values()), seed_total)

    def test_seed_counts_and_lifespans_survive_save_and_restore(self):
        mid, restored = self.saves["mid"], self.saves["restored"]
        self.assertTrue(mid["seed_bank"]["spring_counts"])
        self.assertEqual(restored["seed_bank"], mid["seed_bank"])
        # The summer save holds exactly the seed the log counted by then.
        summer = self._index("save", name="summer")
        counted = {}
        for d in self.events[:summer]:
            if d["kind"] == "withered" and d["sets_seed"]:
                counted[d["target"]] = counted.get(d["target"], 0) + 1
        self.assertEqual(self.saves["summer"]["seed_bank"]["seed_counts"], counted)
        before = {(round(f["x"], 1), round(f["y"], 1), f["species"]): f for f in mid["flowers"]}
        matched = 0
        for f in restored["flowers"]:
            was = before.get((round(f["x"], 1), round(f["y"], 1), f["species"]))
            if was is None:
                continue
            matched += 1
            self.assertAlmostEqual(f["lifespan"], was["lifespan"], places=3)
            self.assertAlmostEqual(f["age"], was["age"], places=3)
            self.assertEqual((f["compatible"], f["incompatible"]), (was["compatible"], was["incompatible"]))
        self.assertEqual(matched, len(mid["flowers"]))
        # With lifespans restored, no flower is suddenly past its own and
        # dies at once: the first two seconds after the restore lose
        # flowers at the meadow's ordinary rate.
        restore = self._index("restore")
        t0 = self.events[restore]["t"]
        burst = [d for d in self.events[restore:] if d["kind"] == "withered" and d["t"] <= t0 + 2.0]
        self.assertLess(len(burst), 50, len(burst))


class ChallengeReplantsAsTodayTest(unittest.TestCase):
    """The fixture without "seed_set", as every Challenge row is."""

    @classmethod
    def setUpClass(cls):
        fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
        fixture.pop("seed_set")
        fixture["actions"] = [a for a in fixture["actions"] if a["do"] == "set_cell_contents"]
        fixture["stop"] = {"max_days": 8}
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "pp4_seed_set_off.json"
            path.write_text(json.dumps(fixture), encoding="utf-8")
            _, actions, cls.script_errors = _run(path)
        cls.deaths = [json.loads(e["reason"]) for e in actions if e.get("do") == "pollination_withered"]
        cls.replants = [(e["target"], json.loads(e["reason"])) for e in actions if e.get("do") == "pollination_replant"]

    def test_run_raises_no_script_error(self):
        self.assertEqual(self.script_errors, [], self.script_errors[:5])

    def test_no_flower_replants_its_own_species(self):
        self.assertGreater(len(self.deaths), 200)
        self.assertTrue(all(not d["seed_set_on"] for d in self.deaths))
        self.assertTrue(any(d["sets_seed"] for d in self.deaths), "no flower was pollinated enough to matter")
        self.assertTrue(all(d["seed_counts"] == {} and d["gaps"] == 0 for d in self.deaths))
        self.assertGreater(len(self.replants), 200)
        self.assertTrue(all(kind == "seasonal" and r["counts"] == {} for kind, r in self.replants))


if __name__ == "__main__":
    unittest.main()
