"""Unit tests for pure helper functions in tools/seed_set_evidence.py."""

import math
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import seed_set_evidence as sse  # noqa: E402


class SeedSetEvidenceHelpersTests(unittest.TestCase):
    def test_number_valid(self) -> None:
        self.assertEqual(sse.number(0), 0)
        self.assertEqual(sse.number(42), 42)
        self.assertEqual(sse.number(-15.5), -15.5)
        self.assertEqual(sse.number(3.14159), 3.14159)

    def test_number_invalid(self) -> None:
        for invalid in (True, False, None, "123", [], {}, (1,), float("nan"), float("inf"), float("-inf")):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                sse.number(invalid)

    def test_species_index_valid(self) -> None:
        for idx in range(len(sse.SPECIES)):
            self.assertEqual(sse.species_index(idx), idx)
            self.assertEqual(sse.species_index(float(idx)), idx)

    def test_species_index_invalid(self) -> None:
        for invalid in (-1, len(sse.SPECIES), len(sse.SPECIES) + 5, 1.5, True, False, "0", None):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                sse.species_index(invalid)

    def test_count_map_valid(self) -> None:
        # Empty dict should initialise all species to 0
        expected_all_zero = {s: 0 for s in sse.SPECIES}
        self.assertEqual(sse.count_map({}), expected_all_zero)

        # Partial dict
        result = sse.count_map({"Clover": 5, "Poppy": 2.0})
        expected_partial = dict(expected_all_zero, Clover=5, Poppy=2)
        self.assertEqual(result, expected_partial)

        # Full dict
        full_input = {s: i for i, s in enumerate(sse.SPECIES)}
        self.assertEqual(sse.count_map(full_input), full_input)

    def test_count_map_invalid(self) -> None:
        # Not a dict
        for invalid_type in (None, [], [("Clover", 1)], "Clover: 1", 123):
            with self.subTest(invalid_type=invalid_type), self.assertRaises(ValueError):
                sse.count_map(invalid_type)

        # Extra / unknown species keys
        with self.assertRaises(ValueError):
            sse.count_map({"UnknownFlower": 1})
        with self.assertRaises(ValueError):
            sse.count_map({"Clover": 1, "Rose": 2})

        # Negative count or non-integer count or invalid types
        for bad_count in (-1, -0.5, 1.5, True, False, "5", None, math.nan, math.inf):
            with self.subTest(bad_count=bad_count), self.assertRaises(ValueError):
                sse.count_map({"Clover": bad_count})

    def test_snapshot_valid(self) -> None:
        # Flower array with valid species indices
        save = {
            "flowers": [{"species": 0}, {"species": 0}, {"species": 1}],
            "seed_bank": {
                "seed_counts": {"Clover": 10},
                "spring_counts": {"Borage": 4},
            },
        }
        res = sse.snapshot(save)
        self.assertEqual(res["live_by_species"]["Clover"], 2)
        self.assertEqual(res["live_by_species"]["Borage"], 1)
        self.assertEqual(res["live_by_species"]["Foxglove"], 0)
        self.assertAlmostEqual(res["clover_share"], 2.0 / 3.0)
        self.assertEqual(res["seed_counts"]["Clover"], 10)
        self.assertEqual(res["seed_counts"]["Borage"], 0)
        self.assertEqual(res["spring_counts"]["Borage"], 4)
        self.assertEqual(res["spring_counts"]["Clover"], 0)

    def test_snapshot_empty_meadow(self) -> None:
        save = {
            "flowers": [],
            "seed_bank": {
                "seed_counts": {},
                "spring_counts": {},
            },
        }
        res = sse.snapshot(save)
        self.assertIsNone(res["clover_share"])
        self.assertEqual(sum(res["live_by_species"].values()), 0)
        self.assertEqual(sum(res["seed_counts"].values()), 0)
        self.assertEqual(sum(res["spring_counts"].values()), 0)

    def test_snapshot_missing_seed_bank_raises(self) -> None:
        save = {"flowers": []}
        with self.assertRaises(ValueError):
            sse.snapshot(save)

    def test_difference_scalar_and_dict(self) -> None:
        before = {
            "clover_share": 0.25,
            "seed_replacements": 4,
            "live_by_species": {s: 1 for s in sse.SPECIES},
        }
        after = {
            "clover_share": 0.50,
            "seed_replacements": 7,
            "live_by_species": {s: (2 if s == "Clover" else 1) for s in sse.SPECIES},
        }
        diff = sse.difference(after, before)
        self.assertAlmostEqual(diff["clover_share"], 0.25)
        self.assertEqual(diff["seed_replacements"], 3)
        self.assertEqual(diff["live_by_species"]["Clover"], 1)
        self.assertEqual(diff["live_by_species"]["Borage"], 0)

    def test_difference_null_values(self) -> None:
        before = {"clover_share": None}
        after = {"clover_share": 0.5}
        diff = sse.difference(after, before)
        self.assertIsNone(diff["clover_share"])

        before2 = {"clover_share": 0.5}
        after2 = {"clover_share": None}
        diff2 = sse.difference(after2, before2)
        self.assertIsNone(diff2["clover_share"])


if __name__ == "__main__":
    unittest.main()
