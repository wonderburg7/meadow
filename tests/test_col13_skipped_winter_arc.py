import sys, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import analyze_session  # noqa: E402

SETTINGS = {"seconds_per_day": 100, "winter_length_days": 10}


def snap(day, t, total=3, winter=False):
    return {"type": "snapshot", "day": day, "game_time": t,
            "population": {"total": total}, "environment": {"winter_here": winter}}


class SkippedWinterArcTest(unittest.TestCase):
    def run_log(self, snaps, settings=SETTINGS):
        return analyze_session.analyze([{"type": "config", "settings": settings}] + snaps)

    def test_clock_jump_dates_winter_either_side(self):
        a = self.run_log([snap(19, 1900), snap(20, 2000), snap(31, 3000)])
        self.assertEqual(20, a["milestones"]["winter_entered_day"])
        self.assertEqual(31, a["milestones"]["winter_survived_day"])
        self.assertEqual(20.0, a["milestone_times"]["winter_entered_day"])  # 3000 - 10 days
        self.assertEqual(30.0, a["milestone_times"]["winter_survived_day"])
        self.assertLess(a["milestones"]["winter_entered_day"], a["milestones"]["winter_survived_day"])

    def test_dead_colony_after_jump_did_not_survive(self):
        a = self.run_log([snap(20, 2000), snap(31, 3000, total=0)])
        self.assertIn("winter_entered_day", a["milestones"])
        self.assertNotIn("winter_survived_day", a["milestones"])

    def test_short_gap_is_not_winter(self):
        a = self.run_log([snap(1, 100), snap(5, 900)])
        self.assertNotIn("winter_entered_day", a["milestones"])

    def test_played_winter_reads_as_before(self):
        a = self.run_log([snap(1, 100), snap(5, 500, winter=True), snap(6, 600)])
        self.assertEqual(5, a["milestones"]["winter_entered_day"])
        self.assertEqual(6, a["milestones"]["winter_survived_day"])

    def test_fixture_unchanged(self):
        entries = analyze_session.load_entries(ROOT / "tests/fixtures/headless/success.jsonl")
        self.assertNotIn("winter_survived_day", analyze_session.analyze(entries)["milestones"])


if __name__ == "__main__":
    unittest.main()
