"""Unit tests for untested specialist and tree summary helpers in tools/seed_set_evidence.py."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import seed_set_evidence as sse  # noqa: E402


class SeedSetEvidenceSpecialistHelpersTests(unittest.TestCase):
    def test_specialist_snapshot_valid(self) -> None:
        raw_snapshot = {
            "live_by_species": {"Clover": 3, "Borage": 1},
            "seed_counts": {"Clover": 10},
            "spring_counts": {"Borage": 2},
        }
        snap = sse.specialist_snapshot(raw_snapshot)
        self.assertEqual(snap["live_by_species"]["Clover"], 3)
        self.assertEqual(snap["live_by_species"]["Borage"], 1)
        self.assertEqual(snap["live_by_species"]["Foxglove"], 0)
        self.assertAlmostEqual(snap["shares"]["Clover"], 0.75)
        self.assertAlmostEqual(snap["shares"]["Borage"], 0.25)
        self.assertEqual(snap["shares"]["Foxglove"], 0.0)
        self.assertEqual(snap["seed_counts"]["Clover"], 10)
        self.assertEqual(snap["seed_counts"]["Borage"], 0)
        self.assertEqual(snap["spring_counts"]["Borage"], 2)
        self.assertEqual(snap["spring_counts"]["Clover"], 0)

    def test_specialist_snapshot_empty_meadow(self) -> None:
        raw_snapshot = {
            "live_by_species": {},
            "seed_counts": {},
            "spring_counts": {},
        }
        snap = sse.specialist_snapshot(raw_snapshot)
        for s in sse.SPECIES:
            self.assertEqual(snap["live_by_species"][s], 0)
            self.assertIsNone(snap["shares"][s])
            self.assertEqual(snap["seed_counts"][s], 0)
            self.assertEqual(snap["spring_counts"][s], 0)

    def test_specialist_difference_scalar_and_dict(self) -> None:
        before = {
            "shares": {"Clover": 0.2, "Borage": 0.8},
            "seed_counts": {"Clover": 5, "Borage": 10},
        }
        after = {
            "shares": {"Clover": 0.5, "Borage": 0.5},
            "seed_counts": {"Clover": 8, "Borage": 7},
        }
        diff = sse.specialist_difference(after, before)
        self.assertAlmostEqual(diff["shares"]["Clover"], 0.3)
        self.assertAlmostEqual(diff["shares"]["Borage"], -0.3)
        self.assertEqual(diff["seed_counts"]["Clover"], 3)
        self.assertEqual(diff["seed_counts"]["Borage"], -3)

    def test_specialist_difference_null_values(self) -> None:
        self.assertIsNone(sse.specialist_difference(None, 5))
        self.assertIsNone(sse.specialist_difference(5, None))
        self.assertIsNone(sse.specialist_difference(None, None))
        dict_with_none = sse.specialist_difference({"val": None}, {"val": 10})
        self.assertIsNone(dict_with_none["val"])

    def test_summarise_tree_scalars_and_nested(self) -> None:
        records = [
            {"seed": 101, "metric_a": 10, "metric_b": 2.0},
            {"seed": 102, "metric_a": 20, "metric_b": 4.0},
            {"seed": 103, "metric_a": 30, "metric_b": 6.0},
        ]
        summary = sse.summarise_tree(records)
        self.assertNotIn("seed", summary)
        self.assertEqual(summary["metric_a"], {"n": 3, "median": 20, "min": 10, "max": 30})
        self.assertEqual(summary["metric_b"], {"n": 3, "median": 4.0, "min": 2.0, "max": 6.0})

    def test_summarise_tree_with_none_values(self) -> None:
        records = [
            {"val": None},
            {"val": 5},
            {"val": 15},
        ]
        summary = sse.summarise_tree(records)
        self.assertEqual(summary["val"], {"n": 2, "median": 10.0, "min": 5, "max": 15})

    def test_summarise_tree_all_none(self) -> None:
        records = [
            {"val": None},
            {"val": None},
        ]
        summary = sse.summarise_tree(records)
        self.assertEqual(summary["val"], {"n": 0, "median": None, "min": None, "max": None})

    def test_specialist_readable_format(self) -> None:
        report = {
            "limitations": ["Test limitation 1."],
            "specialist_paired_summary": {
                "Clover": {
                    "share": {"n": 2, "median": 0.1, "min": 0.05, "max": 0.15},
                },
                "Borage": {
                    "share": {"n": 2, "median": None, "min": None, "max": None},
                },
            },
            "contrast_summary": {
                "contrast": {"n": 1, "median": 0.25, "min": 0.25, "max": 0.25},
            },
            "within_arm_summary": {
                "Clover": {
                    "off": {"metric": {"n": 1, "median": 1.0, "min": 1.0, "max": 1.0}},
                    "on": {"metric": {"n": 1, "median": 2.0, "min": 2.0, "max": 2.0}},
                },
                "Borage": {
                    "off": {"metric": {"n": 0, "median": None, "min": None, "max": None}},
                    "on": {"metric": {"n": 0, "median": None, "min": None, "max": None}},
                },
            },
            "provenance": {"tool": "seed_set_evidence"},
            "rows": [],
            "specialist_on_minus_off": {"Clover": [], "Borage": []},
            "borage_minus_clover_effect": [],
            "seed_event_coverage": {"Clover": True, "Borage": False},
        }
        text = sse.specialist_readable(report)
        self.assertTrue(text.startswith("# Specialist spring comparison\n"))
        self.assertIn("Test limitation 1.", text)
        self.assertIn("| Clover on minus off | share | 2 | 0.1 | 0.05 | 0.15 |", text)
        self.assertIn("| Borage on minus off | share | 2 | undefined | undefined | undefined |", text)
        self.assertIn("| Borage effect minus Clover effect | contrast | 1 | 0.25 | 0.25 | 0.25 |", text)
        self.assertIn("## Provenance and controls", text)
        self.assertIn("## Seed-event coverage", text)


if __name__ == "__main__":
    unittest.main()
