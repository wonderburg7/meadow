"""PP-2: Pollinator Points are spendable on a tier-4 skill.

Runs test_scenarios/pp2_points_spendable.json once. The fixture stocks the
comb with nectar and a cell of bee bread (ripe after one game hour), grants
both Foraging tier-3 nodes (Weighted flower choice, so tier 4 is open, and
Pollinator points, so foragers earn), and tries Auto-recruitment -- a tier-4
skill priced in points -- 15 seconds in, when too few points have been
earned (refused). After seven minutes of foraging it tries again (bought).

The fixture sets "pollination_log": true, so pollination.gd writes a line per
finished visit carrying the ledger's points, and a "pollination_spent" line
when a purchase spends them. From those lines and the two saves:

- the refused attempt came with fewer points than the recipe asks, and
  spent none;
- the bought attempt came with at least the recipe's points, spent exactly
  the recipe's points once, and left the ledger that much lower;
- the bought save holds the ledger as the log last showed it.

Static checks pin who reads and spends the ledger, and that the "+1" is
presentation only.
"""

from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once, scenario_saves_dir  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "pp2_points_spendable.json"
SKILL = "skill.foraging.auto_recruitment"
SAVES = ("refused", "bought")


def _recipe() -> dict:
    """Auto-recruitment's cost from skills.gd, by skills.gd's key names."""
    text = (SCRIPTS / "skills.gd").read_text(encoding="utf-8")
    start = text.index('"id": AUTO_RECRUITMENT')
    block = text[start:text.index("\n\t},", start)]
    match = re.search(r'"cost": \{([^}]*)\}', block)
    cost = {key: int(value) for key, value in re.findall(r"([A-Z_]+): ([0-9]+)", match.group(1))} if match else {}
    if "POLLINATOR_POINTS" not in cost:
        raise AssertionError("skills.gd prices Auto-recruitment with no pollinator points")
    return cost


class PointsSpendableSourceTest(unittest.TestCase):
    def test_panel_reads_and_spends_the_ledger(self):
        text = (SCRIPTS / "skill_tree_panel.gd").read_text(encoding="utf-8")
        self.assertIn("stores[Skills.POLLINATOR_POINTS] = float(main.pollination.points)", text)
        self.assertIn("main.pollination.spend(", text)

    def test_pop_is_presentation_only(self):
        text = (SCRIPTS / "pollination_pop.gd").read_text(encoding="utf-8")
        for reach in ("main", "Session.", "GameConfig", "pollination."):
            self.assertNotIn(reach, re.sub(r"##.*", "", text), "pollination_pop.gd reaches %r" % reach)
        hud = (SCRIPTS / "hud.gd").read_text(encoding="utf-8")
        self.assertIn("main.pollination.points_earned.connect(pollination_pop.show_at)", hud)


class PointsSpendableRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        session_file = run_once(FIXTURE, godot_path, timeout=900, fixed_fps=30)
        if session_file is None:
            raise AssertionError("scenario run produced no session log")
        entries = load_entries(session_file)
        godot_log = session_file.parent / "godot.log"
        log_text = godot_log.read_text(encoding="utf-8", errors="replace") if godot_log.exists() else ""
        cls.script_errors = [line for line in log_text.splitlines() if "SCRIPT ERROR" in line]
        actions = [e for e in entries if e.get("type") == "action"]
        cls.rejected = [e for e in actions if e.get("result") == "rejected"]
        scratch = scenario_saves_dir(session_file)
        cls.saves = {}
        for name in SAVES:
            path = scratch / ("pp2-%s.json" % name)
            if path.exists():
                cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))
        # Walk the log in order, keeping the ledger's points as last shown.
        cls.points_at_buy = []
        cls.spends = []
        cls.points_at_save = {}
        cls.awarded = 0
        points = 0
        for e in actions:
            kind = e.get("do")
            if kind == "pollination_visit":
                visit = json.loads(e["reason"])
                points = int(visit["points"])
                cls.awarded += 1 if visit["awarded"] else 0
            elif kind == "pollination_spent":
                spend = json.loads(e["reason"])
                cls.spends.append(dict(spend, points_logged=points, buys_before=len(cls.points_at_buy)))
                points = int(spend["after"])
            elif kind == "buy_skill":
                cls.points_at_buy.append(points)
            elif kind == "save_run":
                match = re.search(r'"name": "PP2 ([^"]+)"', str(e.get("target", "")))
                if match:
                    cls.points_at_save[match.group(1)] = points
        cls.cost = _recipe()
        cls.recipe = cls.cost["POLLINATOR_POINTS"]

    def test_run_raises_no_script_error(self):
        self.assertEqual(self.script_errors, [], self.script_errors[:5])

    def test_run_resolves_every_action(self):
        self.assertEqual(self.rejected, [], self.rejected)
        self.assertEqual(sorted(self.saves), sorted(SAVES), "missing saves: %s" % sorted(self.saves))
        self.assertEqual(len(self.points_at_buy), 2, self.points_at_buy)

    def test_refused_with_too_few_points(self):
        self.assertLess(self.points_at_buy[0], self.recipe)
        self.assertFalse(any(s["buys_before"] == 0 for s in self.spends), self.spends)
        # The comb held the rest of the recipe, so points were what fell short.
        cells = self.saves["refused"]["cells"]
        stock = {kind: sum(float(c["amount"]) for c in cells if c["content"] == kind)
                 for kind in ("bee_bread", "nectar")}
        self.assertGreaterEqual(stock["bee_bread"], self.cost["BEE_BREAD"], stock)
        self.assertGreaterEqual(stock["nectar"], self.cost["NECTAR"], stock)

    def test_bought_once_enough_are_earned(self):
        self.assertGreater(self.awarded, 0, "no point was ever earned")
        self.assertGreaterEqual(self.points_at_buy[1], self.recipe)

    def test_ledger_loses_exactly_the_recipe(self):
        self.assertEqual(len(self.spends), 1, self.spends)
        spend = self.spends[0]
        self.assertEqual(spend["before"], spend["points_logged"], "the ledger moved without a log line")
        self.assertEqual(spend["spent"], self.recipe)
        self.assertEqual(spend["after"], spend["before"] - self.recipe)

    def test_saves_hold_the_ledger(self):
        for name in SAVES:
            saved = int(self.saves[name].get("pollination", {}).get("points", -1))
            self.assertEqual(saved, self.points_at_save[name], name)


if __name__ == "__main__":
    unittest.main()
