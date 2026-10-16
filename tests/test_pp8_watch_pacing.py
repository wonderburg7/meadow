"""PP-8: the C-129 watch run plays at real time.

scenario boot sets Engine.time_scale from the scenario's "time_scale" (default
30), so the watch scenario must say 1 to be watchable. It must also stay
purchase-free and stop on days.
"""

from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCENARIO = ROOT / "test_scenarios" / "pp2_points_watch.json"


class WatchPacingTest(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(SCENARIO.read_text(encoding="utf-8"))

    def test_runs_at_real_time(self):
        self.assertEqual(self.data.get("time_scale"), 1)

    def test_still_has_no_purchase(self):
        dos = [a.get("do") for a in self.data.get("actions", [])]
        self.assertNotIn("buy_skill", dos)
        self.assertFalse(any("buy" in d or "purchase" in d for d in dos))

    def test_still_stops_on_days(self):
        self.assertIn("max_days", self.data["stop"])


if __name__ == "__main__":
    unittest.main()
