"""NF-1: headless runs report how long raw nectar sits in the comb.

Runs test_scenarios/nf1_nectar_age.json (an ordinary colony with foragers and
honey makers) and checks the run summary carries `nectar_age`. A second run
with honey makers removed is printed for the plan's Evidence paragraph.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import run_once  # noqa: E402

FIXTURE = ROOT / "test_scenarios" / "nf1_nectar_age.json"


def _summary_for(scenario: Path, godot_path: str) -> dict:
    session_file = run_once(scenario, godot_path, timeout=300, fixed_fps=30)
    if session_file is None:
        raise AssertionError("scenario run produced no session log")
    entries = load_entries(session_file)
    return next(e for e in reversed(entries) if e.get("type") == "summary")


class NectarAgeTest(unittest.TestCase):
    def test_summary_reports_nectar_age(self):
        godot_path = find_godot()
        if not godot_path:
            self.skipTest("no Godot executable found -- this test needs a real headless boot")
        summary = _summary_for(FIXTURE, godot_path)
        age = summary.get("nectar_age")
        self.assertIsNotNone(age, "summary has no nectar_age")
        print("NF1 with honey makers:", json.dumps({k: v for k, v in age.items() if k != "daily"}), json.dumps([[d["day"], d["cells"], d["p50"], d["p95"], d["max"], d["share_older_than_a_day"]] for d in age["daily"]]))
        self.assertGreaterEqual(age["p95"], age["p50"])
        self.assertGreater(age["max"], 0)

    def test_run_without_honey_makers_for_the_evidence(self):
        godot_path = find_godot()
        if not godot_path:
            self.skipTest("no Godot executable found -- this test needs a real headless boot")
        scenario = json.loads(FIXTURE.read_text(encoding="utf-8"))
        scenario["honey_makers"] = 0
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "nf1_no_honey_makers.json"
            path.write_text(json.dumps(scenario), encoding="utf-8")
            summary = _summary_for(path, godot_path)
        age = summary.get("nectar_age")
        self.assertIsNotNone(age, "summary has no nectar_age")
        print("NF1 without honey makers:", json.dumps({k: v for k, v in age.items() if k != "daily"}), json.dumps([[d["day"], d["cells"], d["p50"], d["p95"], d["max"], d["share_older_than_a_day"]] for d in age["daily"]]))
        self.assertGreaterEqual(age["p95"], age["p50"])


if __name__ == "__main__":
    unittest.main()
