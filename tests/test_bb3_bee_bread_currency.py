"""BB-3: Bee Bread is spendable on a tier-3 recipe, from ripe cells only.

Runs test_scenarios/bb3_bee_bread_currency.json once. The fixture seals one
cell of 60 bee bread (ripe after one game hour), stocks nectar, pollen and
ripe honey, buys the colony branch's prerequisites for Restocking (a tier-3
skill priced 12 bee bread, 40 honey, 150 nectar), and tries Restocking while
the only bee bread is unripe (refused), then again after it ripens (bought).

From the run: the refused attempt leaves the unripe cell untouched; the
bought one leaves the cell holding exactly the recipe's bee bread less.

The run gets a user:// of its own (APPDATA pointed at a temporary folder),
for the reason test_bb1_bee_bread.py gives.
"""

from __future__ import annotations

import json
import os
import re
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import log_dir, run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "bb3_bee_bread_currency.json"
SKILLS = ROOT / "scripts" / "skills.gd"
SKILL = "skill.colony.restocking"
STOCK = 60.0


def _recipe_bee_bread() -> float:
    text = SKILLS.read_text(encoding="utf-8")
    block = text[text.index('"id": RESTOCKING'):]
    match = re.search(r"BEE_BREAD: ([0-9.]+)", block)
    if match is None:
        raise AssertionError("skills.gd prices Restocking with no bee bread")
    return float(match.group(1))


def _bread(save: dict) -> float:
    return sum(float(c["amount"]) for c in save["cells"] if c["content"] == "bee_bread")


class BeeBreadCurrencyRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        godot_path = find_godot()
        if not godot_path:
            raise unittest.SkipTest("no Godot executable found -- this test needs a real headless boot")
        old_appdata = os.environ.get("APPDATA")
        with tempfile.TemporaryDirectory(prefix="meadow-bb3-") as appdata:
            os.environ["APPDATA"] = appdata
            try:
                session_file = run_once(FIXTURE, godot_path, timeout=600, fixed_fps=30)
                if session_file is None:
                    raise AssertionError("scenario run produced no session log")
                entries = load_entries(session_file)
                scratch = log_dir().parent / "scenario_saves"
                cls.saves = {}
                for name in ("unripe", "bought"):
                    path = scratch / ("bb3-%s.json" % name)
                    if path.exists():
                        cls.saves[name] = json.loads(path.read_text(encoding="utf-8"))
            finally:
                if old_appdata is None:
                    os.environ.pop("APPDATA", None)
                else:
                    os.environ["APPDATA"] = old_appdata
        cls.actions = [e for e in entries if e.get("type") == "action"]

    def setUp(self):
        self.assertEqual([a for a in self.actions if a.get("result") == "rejected"], [],
                         "a scenario action was rejected")
        self.assertEqual(sorted(self.saves), ["bought", "unripe"], "the run did not write both saves")

    def test_a_recipe_is_refused_while_the_only_bee_bread_is_unripe(self):
        refused = [a for a in self.actions if a.get("do") == "buy_skill" and a.get("reason") == "refused as expected"]
        self.assertEqual(len(refused), 1, "the unripe attempt was not refused")
        self.assertNotIn(SKILL, json.dumps(self.saves["unripe"].get("skills", {})))
        self.assertAlmostEqual(_bread(self.saves["unripe"]), STOCK, places=3)

    def test_the_recipe_is_bought_once_it_ripens_and_spends_exactly_its_bee_bread(self):
        self.assertIn(SKILL, json.dumps(self.saves["bought"].get("skills", {})))
        self.assertAlmostEqual(_bread(self.saves["bought"]), STOCK - _recipe_bee_bread(), places=3)


if __name__ == "__main__":
    unittest.main()
