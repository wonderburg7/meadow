"""Offline evidence failures and arithmetic, without an engine launch."""
import copy
import json
import contextlib
import io
import tempfile
from unittest import mock
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import seed_set_evidence as evidence
from seed_set_evidence import specialist_report, aggregate_arm, aggregate_spring, spring_report, paired_report, readable, SPECIES


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


class SpringEvidenceTest(unittest.TestCase):
    event = EvidenceTest.event

    def setUp(self):
        EvidenceTest.setUp(self)
        self.scenario = json.loads((ROOT / "test_scenarios/ee2_seed_set_spring.json").read_text())
        self.entries = [{"type": "action", "do": a["do"], "result": "accepted", "game_time": t}
                        for a, t in zip(self.scenario["actions"], (0, 0, 0, 180, 480))]
        self.entries.insert(4, dict(self.event("pollination_spring", "21", {"spring_counts": {"Clover": 3}}), game_time=400))
        self.entries.insert(5, dict(self.event("pollination_replant", "seasonal", {
            "species_index": 0, "species": "Clover", "weights": [2, 1, 0, 0, 0, 0]}), game_time=400))
        self.entries.append({"type": "summary", "game_time": 480, "day": 25, "outcome": "actions_resolved"})
        bank = {"seed_counts": {"Clover": 3}, "spring_counts": {}}
        self.summer = dict(copy.deepcopy(self.save), seed_bank=bank)
        self.spring = {"clock": {"day": 25, "sim_time": 480}, "flowers": [{"species": 0}],
                       "seed_bank": {"seed_counts": {}, "spring_counts": {"Clover": 3}}}

    def aggregate(self):
        return aggregate_spring(self.entries, self.summer, self.spring, self.result, self.scenario)

    def test_phase_boundaries_and_missing_coverage(self):
        self.assertEqual(self.aggregate()["spring_replacements"]["Clover"], 1)
        self.entries[5]["game_time"] = 460
        with self.assertRaisesRegex(ValueError, "coverage"):
            self.aggregate()
        self.entries[5]["game_time"] = 400
        for day, t in ((11, 200), (9, 160)):
            self.summer["clock"] = {"day": day, "sim_time": t}
            with self.assertRaises(ValueError):
                self.aggregate()

    def test_incomplete_spring_and_reverse_timeline(self):
        self.entries[4]["game_time"] = 399
        with self.assertRaises(ValueError):
            self.aggregate()
        self.entries[4]["game_time"] = 400
        self.entries[-2]["game_time"] = 399
        with self.assertRaises(ValueError):
            self.aggregate()
        self.entries[-2]["game_time"] = 480
        self.scenario["config_overrides"]["spring_regrowth_days"] = 5
        with self.assertRaisesRegex(ValueError, "incomplete spring"):
            self.aggregate()

    def test_known_spring_pairs_and_absent_species(self):
        on = dict(self.aggregate(), seed=1, arm="on")
        self.spring["flowers"] = [{"species": 1}, {"species": 1}]
        off = dict(self.aggregate(), seed=1, arm="off")
        report = spring_report([on, off], (1,))
        self.assertIn("Observed spring replacements", readable(report))
        self.assertIn("spring minus summer", readable(report))
        diff = report["spring_on_minus_off"][0]["spring"]
        self.assertEqual(diff["live_by_species"], dict(zip(SPECIES, (1, -2, 0, 0, 0, 0))))
        self.assertEqual(diff["clover_share"], 1)
        self.assertEqual(report["spring_paired_summary"]["spring"]["live_by_species"]["Borage"]["median"], -2)
        self.assertEqual(on["summer_to_spring"]["live_by_species"]["Borage"], -1)

    def test_disabled_arm_has_no_rollover_and_zero_bank(self):
        self.scenario["seed_set"] = False
        self.entries.pop(4)
        self.summer["seed_bank"]["seed_counts"] = {}
        self.spring["seed_bank"]["spring_counts"] = {}
        row = self.aggregate()
        self.assertEqual(row["spring_rollover_counts"], dict.fromkeys(SPECIES, 0))
        self.assertEqual(row["spring_replacements"]["Clover"], 1)



class SpecialistEvidenceTest(unittest.TestCase):
    def setUp(self):
        fixture = SpringEvidenceTest()
        fixture.setUp()
        self.row = fixture.aggregate()
        self.provenance = dict(baseline_commit="baseline", reporter_sha256="reporter",
                               fixture_sha256="fixture", engine_version="Godot 4.7",
                               fixed_fps=30, controls=fixture.scenario)
        self.rows = []
        for seed in (1, 2):
            for specialist in evidence.SPECIALISTS:
                for arm in ("off", "on"):
                    row = copy.deepcopy(self.row)
                    # Distinct effects for all six species, not just Clover.
                    effect = 3 if specialist == "Borage" else 1
                    counts = {s: (i + 1) * (effect if arm == "on" else 1)
                              for i, s in enumerate(SPECIES)}
                    row["spring"] = {"live_by_species": counts, "clover_share": 99,
                                     "seed_counts": counts, "spring_counts": counts}
                    row["spring_replacements"] = counts
                    row.update(seed=seed, arm=arm, specialist=specialist,
                               treatment={"specialist": specialist, "seed_set": arm == "on"},
                               scenario=dict(fixture.scenario, random_seed=seed,
                                             forager_species=specialist, seed_set=arm == "on"),
                               provenance=copy.deepcopy(self.provenance),
                               seed_events_by_species=dict.fromkeys(SPECIES, 0))
                    self.rows.append(row)

    def report(self):
        return specialist_report(self.rows, self.provenance, (1, 2))

    def test_four_treatment_arithmetic_and_all_species(self):
        report = self.report()
        contrast = report["borage_minus_clover_effect"][0]
        for i, species in enumerate(SPECIES):
            for metric in ("live_by_species", "seed_counts", "spring_counts"):
                self.assertEqual(contrast["spring"][metric][species], 2 * (i + 1))
            self.assertEqual(contrast["spring_replacements"][species], 2 * (i + 1))
            self.assertEqual(report["contrast_summary"]["spring"]["live_by_species"][species],
                             {"n": 2, "median": 2 * (i + 1), "min": 2 * (i + 1), "max": 2 * (i + 1)})
            self.assertAlmostEqual(contrast["spring"]["shares"][species], 0)
        self.assertIn("No Borage seed events observed.", report["limitations"])
        rendered = readable(report)
        for phrase in ("Raw arm data", "draw-weight ranges", "Within-arm", "n, median, min, max",
                       "not confidence intervals"):
            self.assertIn(phrase, rendered)

    def test_share_contrast_uses_every_live_species_and_actual_pair_ranges(self):
        # Clover on/off: Borage share 1/2 - 1/4. Borage on/off: 3/4 - 1/4.
        counts = ({"Borage": 1, "Poppy": 3}, {"Borage": 2, "Foxglove": 2},
                  {"Borage": 1, "Poppy": 3}, {"Borage": 3, "Dandelion": 1})
        for row, flowers in zip(self.rows[:4], counts):
            row["spring"]["live_by_species"] = flowers
        report = self.report()
        self.assertEqual(report["borage_minus_clover_effect"][0]["spring"]["shares"]["Borage"], .25)
        summary = report["contrast_summary"]["spring"]["shares"]["Borage"]
        self.assertEqual(summary, {"n": 2, "median": .125, "min": 0, "max": .25})
        # Other species enter the denominator and have their own contrasts.
        self.assertEqual(report["borage_minus_clover_effect"][0]["spring"]["shares"]["Dandelion"], .25)
        self.assertEqual(report["rows"][0]["spring"]["shares"]["Clover"], 0)

    def test_missing_duplicate_unexpected_and_mislabeled_arms(self):
        original = self.rows
        bad = [original[:-1], original + [original[0]], [original[0], original[0], *original[2:]]]
        for field, value in (("seed", 99), ("specialist", "Poppy"), ("arm", "enabled"),
                             ("treatment", {"specialist": "Clover", "seed_set": False})):
            rows = copy.deepcopy(original)
            rows[1][field] = value
            bad.append(rows)
        for rows in bad:
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                specialist_report(rows, self.provenance, (1, 2))

    def test_controls_and_provenance_must_match(self):
        for field, value in (("weather", True), ("forager_species", "Borage"),
                             ("random_seed", 99), ("seed_set", 1)):
            rows = copy.deepcopy(self.rows)
            rows[0]["scenario"][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                specialist_report(rows, self.provenance, (1, 2))
        for field in evidence.PROVENANCE_KEYS:
            rows = copy.deepcopy(self.rows)
            rows[0]["provenance"][field] = "different"
            with self.subTest(field=field), self.assertRaises(ValueError):
                specialist_report(rows, self.provenance, (1, 2))
        provenance = dict(self.provenance, fixed_fps=60)
        with self.assertRaises(ValueError):
            specialist_report(self.rows, provenance, (1, 2))

    def test_empty_meadows_absent_species_and_defined_denominators(self):
        self.rows[3]["spring"]["live_by_species"] = {}
        report = self.report()
        self.assertIsNone(report["borage_minus_clover_effect"][0]["spring"]["shares"]["Borage"])
        self.assertEqual(report["contrast_summary"]["spring"]["shares"]["Borage"]["n"], 1)
        for row in self.rows:
            row["spring"]["live_by_species"] = {}
        report = self.report()
        self.assertEqual(report["contrast_summary"]["spring"]["shares"]["Poppy"],
                         {"n": 0, "median": None, "min": None, "max": None})
        for row in self.rows:
            row["spring"]["live_by_species"] = {"Clover": 1}
        report = self.report()
        self.assertEqual(report["borage_minus_clover_effect"][0]["spring"]["shares"]["Borage"], 0)
        self.assertEqual(report["contrast_summary"]["spring"]["shares"]["Borage"]["n"], 2)

    def test_command_runs_twenty_unique_serial_arms_and_retains_scenarios(self):
        with tempfile.TemporaryDirectory(prefix="meadow-specialist-test-") as temporary:
            root = Path(temporary)
            calls = []
            def run(case, godot, timeout, fps, case_dir):
                scenario = json.loads(case.read_text())
                calls.append((scenario["random_seed"], scenario["forager_species"], scenario["seed_set"]))
                self.assertEqual(fps, 30)
                run_dir = case_dir / "run-test"
                run_dir.mkdir()
                run_id = str(len(calls))
                (run_dir / "result.json").write_text(json.dumps({"run_id": run_id}))
                private = root / "private" / run_id
                private.mkdir(parents=True)
                for name in ("ee2-summer.json", "ee2-spring.json"):
                    (private / name).write_text("{}")
                return 0
            output = root / "output"
            fixture = ROOT / "test_scenarios/ee2_seed_set_spring.json"
            with mock.patch.object(sys, "argv", ["seed_set_evidence.py", "specialists",
                                                "--fixture", str(fixture), "--output", str(output)]), \
                 mock.patch.object(evidence, "find_godot", return_value="godot"), \
                 mock.patch.object(evidence.runner, "prepare_launch", return_value=None), \
                 mock.patch.object(evidence.runner, "run_verdict_scenario", side_effect=run), \
                 mock.patch.object(evidence.runner, "PRIVATE_USER_ROOT", root / "private"), \
                 mock.patch.object(evidence.subprocess, "check_output", return_value="baseline"), \
                 mock.patch.object(evidence, "load_entries", return_value=[]), \
                 mock.patch.object(evidence, "aggregate_spring", side_effect=lambda *args: copy.deepcopy(self.row)), \
                 contextlib.redirect_stdout(io.StringIO()):
                evidence.main()
            self.assertEqual(len(calls), 20)
            self.assertEqual(len(set(calls)), 20)
            self.assertEqual(calls[:4], [(12345, "Clover", False), (12345, "Clover", True),
                                        (12345, "Borage", False), (12345, "Borage", True)])
            report = json.loads((output / "report.json").read_text())
            self.assertEqual(len(report["rows"]), 20)
            self.assertEqual(report["provenance"]["fixture"], str(fixture.resolve()))
            self.assertTrue((output / "report.md").exists())
            for row in report["rows"]:
                self.assertEqual(row["scenario"]["forager_species"], row["specialist"])
                self.assertEqual(row["scenario"]["seed_set"], row["arm"] == "on")
                self.assertIn("spring_weights", row)
                case = output / f'{row["seed"]}-{row["specialist"]}-{row["arm"]}' / "scenario.json"
                self.assertEqual(json.loads(case.read_text()), row["scenario"])


if __name__ == "__main__":
    unittest.main()
