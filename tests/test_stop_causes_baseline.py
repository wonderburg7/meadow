from datetime import date
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import stop_causes  # noqa: E402


class StopCausesBaselineTests(unittest.TestCase):
    def test_failing_tests_parses_unittest_log(self):
        log = (
            "Some output line\n"
            "FAIL: test_x (module.Class)\n"
            "ERROR: test_y (module.Class)\n"
            "FAIL: test_z (module.Class.test_z)\n"
            "random trailing line\n"
        )
        parsed = stop_causes.failing_tests(log)
        self.assertEqual(parsed, [
            "module.Class.test_x",
            "module.Class.test_y",
            "module.Class.test_z",
        ])

    def test_live_ids_filters_by_date_and_validity(self):
        today = date(2026, 10, 26)
        baseline = {
            "failures": [
                {"test": "t_today", "expires": "2026-10-26"},
                {"test": "t_future", "expires": "2026-10-27"},
                {"test": "t_past", "expires": "2026-10-25"},
                {"test": "t_no_expires"},
                {"test": "t_bad_date", "expires": "invalid-date"},
            ]
        }
        live = stop_causes.live_ids(baseline, today)
        self.assertEqual(live, {"t_today", "t_future"})

    def test_unlisted_returns_non_live_failures_in_order(self):
        today = date(2026, 10, 26)
        baseline = {
            "failures": [
                {"test": "t1", "expires": "2026-10-27"},
                {"test": "t2", "expires": "2026-10-27"},
            ]
        }
        failing = ["t1", "t3", "t2", "t4"]
        unlisted_ids = stop_causes.unlisted(failing, baseline, today)
        self.assertEqual(unlisted_ids, ["t3", "t4"])

        all_live_failing = ["t1", "t2"]
        self.assertEqual(stop_causes.unlisted(all_live_failing, baseline, today), [])


if __name__ == "__main__":
    unittest.main()
