"""PP-1: bees earn Pollinator Points and Contribution.

Runs test_scenarios/pp1_pollination_ledger.json once: twelve foragers work
the meadow for 150 seconds without the Pollinator points skill, then the run
is granted it and forages on. It saves before the grant ("unowned") and 300
seconds after it ("owned"), forages another minute, restores "owned" in
place and saves again at once ("restored"), then forages a last minute.

pollination.gd writes one session-log line per finished flower visit in a
scenario run ("pollination_visit": first, compatible or incompatible), with
the bee, the flower and the flower it came from, the flower's counts and
award_ready_at after the visit, and the ledger's points and contribution.
From those lines and the three saves:

- a trip's first flower delivers nothing and earns nothing: every bee's
  first visit after she carried pollen into the hive (a
  "pollination_groomed" line) and after the restore (trip_last_flower is
  not saved) is a first flower;
- every delivery comes from the bee's previous visit on that trip, and is
  compatible exactly when the two flowers share a species;
- a compatible delivery adds one to the flower's compatible count and one to
  Contribution, with or without the skill; an incompatible one adds one to
  the flower's incompatible count and nothing else;
- before the grant no visit earns a point; after it a compatible delivery
  earns exactly one point when the flower's pollination window is open, and
  none when it is not, and an award closes the window until the flower's
  refill;
- the ledger and every flower's counts and window survive save and restore.

Static checks pin the skill entry, the ledger's single writer and the
helper's pattern.
"""

from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(TOOLS))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once, scenario_saves_dir  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "pp1_pollination_ledger.json"
SAVES = ("unowned", "owned", "restored")
SKILL = "skill.foraging.pollinator_points"
# A visit within this many game seconds of a flower's window opening is too
# close to call from the logged (rounded) times, so the window check skips it.
EDGE = 0.05


def _key(position) -> tuple:
    return (round(float(position[0]), 1), round(float(position[1]), 1))


def _flower_index(save: dict) -> dict:
    return {(_key((f["x"], f["y"])), int(f["species"])): f for f in save["flowers"]}


def _find_saved(save: dict, position, tolerance: float = 0.05):
    x, y = float(position[0]), float(position[1])
    for f in save["flowers"]:
        if abs(float(f["x"]) - x) <= tolerance and abs(float(f["y"]) - y) <= tolerance:
            return f
    return None


class PollinationSourceTest(unittest.TestCase):
    def test_skill_entry_enables_points(self):
        text = (SCRIPTS / "skills.gd").read_text(encoding="utf-8")
        start = text.index('"id": POLLINATOR_POINTS_SKILL')
        block = text[start:text.index("\n\t},", start)]
        self.assertIn('{"type": "enable_behaviour", "key": "pollinator_points_on"}', block)
        self.assertIn('"status": "existing"', block)

    def test_ledger_is_the_only_writer(self):
        for path in SCRIPTS.glob("*.gd"):
            if path.name == "pollination.gd":
                continue
            text = path.read_text(encoding="utf-8")
            self.assertIsNone(
                re.search(r"pollination\.(points|contribution)\s*[+\-]?=", text),
                "%s writes the pollination ledger" % path.name)

    def test_helper_follows_the_tarsal_pattern(self):
        text = (SCRIPTS / "pollination.gd").read_text(encoding="utf-8")
        self.assertIn("static func pollinator_points_on() -> bool:", text)
        self.assertIn('is_behaviour_enabled(BEHAVIOUR)', text)
        self.assertIn('const BEHAVIOUR := "pollinator_points_on"', text)


class PollinationRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=600, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        entries = load_entries(session_file)
        # The engine's own log sits beside the session log. A freed flower
        # assigned to a typed variable shows up only here, as a SCRIPT ERROR,
        # and the visit it broke is silently missing from the session log.
        godot_log = session_file.parent / "godot.log"
        log_text = godot_log.read_text(encoding="utf-8", errors="replace") if godot_log.exists() else ""
        cls.script_errors = [line for line in log_text.splitlines() if "SCRIPT ERROR" in line]
        actions = [e for e in entries if e.get("type") == "action"]
        cls.rejected = [e for e in actions if e.get("result") == "rejected"]
        scratch = scenario_saves_dir(session_file)
        cls.saves = {}
        for name in SAVES:
            path = scratch / ("pp1-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))
        # The visits, in the order they happened, split at the grant and the
        # restore (the restore winds game time back, so order is by log line).
        cls.before_grant, cls.after_grant, cls.after_restore = [], [], []
        # The ledger as the visit log last showed it when each save was
        # written, by the save's slot name.
        cls.ledger_at_save = {}
        ledger = {"points": 0, "contribution": 0}
        phase = cls.before_grant
        for e in actions:
            if e.get("do") == "save_run":
                match = re.search(r'"name": "([^"]+)"', str(e.get("target", "")))
                name = match.group(1) if match else ""
                cls.ledger_at_save[name] = dict(ledger)
            elif e.get("do") == "grant_skill":
                phase = cls.after_grant
            elif e.get("do") == "restore_slot":
                phase = cls.after_restore
            elif e.get("do") == "pollination_groomed":
                phase.append({"kind": "groomed", "bee": int(e["target"].split()[-1]),
                              "t": float(e["game_time"])})
            elif e.get("do") == "pollination_visit":
                visit = json.loads(e["reason"])
                visit["kind"] = e["target"]
                visit["t"] = float(e["game_time"])
                phase.append(visit)
                ledger = {"points": visit["points"], "contribution": visit["contribution"]}

    def test_run_raises_no_script_error(self):
        self.assertEqual(self.script_errors, [], self.script_errors[:5])

    def test_run_resolves_every_action(self):
        self.assertEqual(self.rejected, [], self.rejected)
        self.assertEqual(sorted(self.saves), sorted(SAVES), "missing saves: %s" % sorted(self.saves))

    def test_every_kind_of_visit_happens_in_each_phase(self):
        # "groomed" is a bee carrying pollen home into the hive.
        for name, visits in (("before the grant", self.before_grant),
                             ("after the grant", self.after_grant),
                             ("after the restore", self.after_restore)):
            kinds = {v["kind"] for v in visits}
            self.assertTrue({"first", "compatible", "groomed"} <= kinds, "%s: only %s" % (name, sorted(kinds)))
        self.assertTrue(any(v["kind"] == "incompatible" for v in self.before_grant + self.after_grant))

    def _replay(self, visits, start_points, start_contribution, saved=None):
        """Walks one unbroken stretch of visits, checking each against the
        state before it. `saved` seeds a flower's counts from a save when the
        stretch starts from a restore; otherwise every flower starts at zero."""
        points, contribution = start_points, start_contribution
        flowers = {}
        last_flower = {}
        awards_per_flower = {}
        refused_by_window = 0
        groomed = set()
        for v in visits:
            if v["kind"] == "groomed":
                # Home at the hive: the next flower starts a fresh trip.
                last_flower[v["bee"]] = None
                groomed.add(v["bee"])
                continue
            if v["bee"] in groomed:
                groomed.discard(v["bee"])
                self.assertEqual(v["kind"], "first", "bee %d's first flower after the hive" % v["bee"])
            fkey = (_key(v["flower"]), v["species"])
            if fkey not in flowers:
                seed = _find_saved(saved, v["flower"]) if saved is not None else None
                flowers[fkey] = {
                    "compatible": int(seed.get("compatible", 0)) if seed else 0,
                    "incompatible": int(seed.get("incompatible", 0)) if seed else 0,
                    "award_ready_at": float(seed.get("award_ready_at", 0.0)) if seed else 0.0,
                }
            before = flowers[fkey]
            what = "bee %d at t=%.2f (%s)" % (v["bee"], v["t"], v["kind"])
            previous = last_flower.get(v["bee"])
            if v["kind"] == "first":
                # Nothing delivered, nothing earned, nothing counted.
                self.assertFalse(v["awarded"], what)
                self.assertEqual((v["points"], v["contribution"]), (points, contribution), what)
                self.assertEqual(v["compatible_visits"], before["compatible"], what)
                self.assertEqual(v["incompatible_visits"], before["incompatible"], what)
            else:
                # A delivery comes from this bee's previous visit on the trip,
                # never the same flower.
                self.assertIsNotNone(previous, "%s: a delivery with no earlier visit" % what)
                self.assertEqual(_key(v["from"]), previous, what)
                self.assertNotEqual(_key(v["from"]), _key(v["flower"]), what)
                if v["kind"] == "incompatible":
                    self.assertNotEqual(v["from_species"], v["species"], what)
                    self.assertFalse(v["awarded"], what)
                    self.assertEqual((v["points"], v["contribution"]), (points, contribution), what)
                    self.assertEqual(v["compatible_visits"], before["compatible"], what)
                    self.assertEqual(v["incompatible_visits"], before["incompatible"] + 1, what)
                else:
                    self.assertEqual(v["kind"], "compatible", what)
                    self.assertEqual(v["from_species"], v["species"], what)
                    self.assertEqual(v["contribution"], contribution + 1, what)
                    self.assertEqual(v["compatible_visits"], before["compatible"] + 1, what)
                    self.assertEqual(v["incompatible_visits"], before["incompatible"], what)
                    if not v["owned"]:
                        self.assertFalse(v["awarded"], what)
                    elif abs(v["t"] - before["award_ready_at"]) > EDGE:
                        window_open = v["t"] >= before["award_ready_at"]
                        self.assertEqual(v["awarded"], window_open, "%s: window open from %.2f" % (what, before["award_ready_at"]))
                        if not window_open:
                            refused_by_window += 1
                    if v["awarded"]:
                        # The award closes the window until the refill.
                        self.assertGreaterEqual(v["award_ready_at"], v["t"] - EDGE, what)
                        awards_per_flower[fkey] = awards_per_flower.get(fkey, 0) + 1
                    else:
                        self.assertAlmostEqual(v["award_ready_at"], before["award_ready_at"], delta=EDGE, msg=what)
                    self.assertEqual(v["points"], points + (1 if v["awarded"] else 0), what)
            points, contribution = v["points"], v["contribution"]
            before.update(compatible=v["compatible_visits"], incompatible=v["incompatible_visits"],
                          award_ready_at=float(v["award_ready_at"]))
            last_flower[v["bee"]] = _key(v["flower"])
        return points, contribution, refused_by_window, awards_per_flower, last_flower

    def test_no_point_before_the_skill_but_contribution_rises(self):
        self.assertTrue(all(not v["owned"] for v in self.before_grant if v["kind"] != "groomed"))
        points, contribution, _, awards, _ = self._replay(self.before_grant, 0, 0)
        self.assertEqual(points, 0)
        self.assertEqual(awards, {})
        self.assertGreater(contribution, 0)
        unowned = self.saves["unowned"]["pollination"]
        self.assertEqual((unowned["points"], unowned["contribution"]), (0, contribution))

    def test_points_after_the_skill_respect_the_window(self):
        unowned = self.saves["unowned"]["pollination"]
        self.assertTrue(all(v["owned"] for v in self.after_grant if v["kind"] != "groomed"))
        # Each bee's trip carries over the grant, so replay the whole stretch.
        points, contribution, refused, awards, _ = self._replay(
            self.before_grant + self.after_grant, 0, 0)
        self.assertGreater(points, 0)
        self.assertGreater(contribution, unowned["contribution"])
        self.assertGreater(refused, 0, "no compatible delivery met a closed window")
        self.assertTrue(any(n > 1 for n in awards.values()), "no flower earned again after refilling")
        # Each save holds the ledger exactly as the visits had left it.
        for name in ("PP1 unowned", "PP1 owned"):
            self.assertIn(name, self.ledger_at_save)
        self.assertEqual(self.saves["owned"]["pollination"], self.ledger_at_save["PP1 owned"])
        self.assertEqual(self.saves["unowned"]["pollination"], self.ledger_at_save["PP1 unowned"])
        self.assertGreater(self.saves["owned"]["pollination"]["points"], 0)

    def test_restore_brings_back_ledger_and_flowers_and_starts_fresh_trips(self):
        owned, restored = self.saves["owned"], self.saves["restored"]
        self.assertEqual(restored["pollination"], owned["pollination"])
        owned_flowers = _flower_index(owned)
        matched = 0
        for key, flower in _flower_index(restored).items():
            before = owned_flowers.get(key)
            if before is None:
                continue
            matched += 1
            self.assertEqual(int(flower["compatible"]), int(before["compatible"]), key)
            self.assertEqual(int(flower["incompatible"]), int(before["incompatible"]), key)
            self.assertAlmostEqual(float(flower["award_ready_at"]), float(before["award_ready_at"]), places=3, msg=key)
        self.assertGreater(matched, 0)
        self.assertTrue(any(int(f["compatible"]) > 0 for f in restored["flowers"]))
        self.assertTrue(any(float(f["award_ready_at"]) > 0.0 for f in restored["flowers"]))
        # No bee carries a trip across the restore: each one's first visit
        # after it is a first flower, and the ledger carries on from the save.
        seen = set()
        for v in self.after_restore:
            if v["bee"] not in seen:
                seen.add(v["bee"])
                self.assertEqual(v["kind"], "first", "bee %d" % v["bee"])
        self._replay(self.after_restore, int(owned["pollination"]["points"]),
                     int(owned["pollination"]["contribution"]), saved=restored)


if __name__ == "__main__":
    unittest.main()
