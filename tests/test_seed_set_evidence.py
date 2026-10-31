"""Offline evidence failures and arithmetic, without an engine launch."""
import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from seed_set_evidence import aggregate_arm, paired_report, readable, SPECIES


class EvidenceTest(unittest.TestCase):
    def setUp(self):
        self.scenario = json.loads((ROOT / "test_scenarios/ee1_seed_set_summer.json").read_text())
        self.result = {"status": "passed", "process": {"exit_code": 0},
                       "actions": {"rejected": 0, "failed": 0, "unresolved": 0}}
        self.entries = [{"type": "action", "do": a["do"], "result": "accepted"}
                        for a in self.scenario["actions"]]
        for eligible in (True, False):
            self.entries.append(self.event("pollination_withered", "Clover", {
                "species_index": 0, "sets_seed": eligible, "seed_set_on": True,
                "compatible_visits": int(eligible), "incompatible_visits": 0}))
        for kind in ("seed", "seasonal"):
            self.entries.append(self.event("pollination_replant", kind, {"species_index": 0, "species": "Clover"}))
        self.entries.append({"type": "summary", "game_time": 180.0, "day": 10, "outcome": "actions_resolved"})
        self.save = {"clock": {"day": 10, "sim_time": 180.0}, "flowers": [{"species": 0}, {"species": 1}]}

    def event(self, do, target, detail):
        return {"type": "action", "do": do, "target": target, "result": "recorded",
                "game_time": 100, "reason": json.dumps(detail)}

    def aggregate(self):
        return aggregate_arm(self.entries, self.save, self.result, self.scenario)

    def test_counts_actual_events_and_all_species(self):
        row = self.aggregate()
        self.assertEqual((row["eligible_deaths"], row["all_deaths"]), (1, 2))
        self.assertEqual((row["seed_replacements"], row["seasonal_replacements"]), (1, 1))
        self.assertEqual(row["clover_share"], .5)
        self.assertEqual(row["live_by_species"], dict(zip(SPECIES, (1, 1, 0, 0, 0, 0))))

    def test_empty_meadow_has_undefined_share(self):
        self.save["flowers"] = []
        row = self.aggregate()
        self.assertEqual(row["live_total"], 0)
        self.assertIsNone(row["clover_share"])

    def test_failed_and_missing_arms_are_errors(self):
        for result in ({}, dict(self.result, status="failed"), dict(self.result, process={"exit_code": 1}),
                       dict(self.result, actions={"rejected": 0, "failed": 0, "unresolved": 1})):
            with self.subTest(result=result), self.assertRaises(ValueError):
                aggregate_arm(self.entries, self.save, result, self.scenario)

    def test_incomplete_logs_actions_and_save_fail(self):
        for entries in ([], self.entries[:-1], self.entries[1:], self.entries + [self.entries[0]],
                        self.entries[:-1] + [{"type": "summary", "game_time": 20, "day": 2}]):
            with self.subTest(entries=entries), self.assertRaises(ValueError):
                aggregate_arm(entries, self.save, self.result, self.scenario)
        with self.assertRaises(ValueError):
            aggregate_arm(self.entries, {}, self.result, self.scenario)
        self.save["clock"]["sim_time"] = 100
        with self.assertRaises(ValueError):
            self.aggregate()

    def test_malformed_event_payloads_fail(self):
        original = copy.deepcopy(self.entries)
        for payload in ("not json", "[]", "{}", json.dumps({"species_index": 99}),
                        json.dumps({"species_index": True}), json.dumps({"species_index": float("nan")})):
            self.entries = copy.deepcopy(original)
            self.entries[4]["reason"] = payload
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                self.aggregate()
        self.entries = original
        self.entries[4]["result"] = "failed"
        with self.assertRaises(ValueError):
            self.aggregate()

    def test_known_paired_differences_and_null_denominators(self):
        rows = []
        for seed, on, off in ((1, (8, .6), (2, .2)), (2, (4, .1), (1, .3))):
            for arm, values in (("on", on), ("off", off)):
                rows.append(dict(self.aggregate(), seed=seed, arm=arm,
                                 seed_replacements=values[0], clover_share=values[1]))
        report = paired_report(rows, (1, 2))
        self.assertEqual(report["paired_summary"]["seed_replacements"], {"n": 2, "median": 4.5, "min": 3, "max": 6})
        self.assertAlmostEqual(report["paired_summary"]["clover_share"]["median"], .1)
        self.assertIn("1/1/0/0/0/0", readable(report))
        for bad in (rows[:-1], rows + [rows[0]], [rows[0], rows[0], *rows[2:]]):
            with self.assertRaises(ValueError):
                paired_report(bad, (1, 2))
        rows[0]["clover_share"] = None
        report = paired_report(rows, (1, 2))
        self.assertIsNone(report["on_minus_off"][0]["clover_share"])
        self.assertEqual(report["paired_summary"]["clover_share"]["n"], 1)


if __name__ == "__main__":
    unittest.main()
