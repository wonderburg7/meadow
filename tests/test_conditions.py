"""Contract tests for C1's pure GDScript conditions evaluator.

The evaluator is intentionally not wired into a running game yet. These tests
therefore exercise constructed condition dictionaries through the source's
public vocabulary, while source_checks.py covers its read-only boundary.
"""

from pathlib import Path
import unittest


SOURCE = (Path(__file__).parent.parent / "scripts" / "conditions.gd").read_text(encoding="utf-8")


class ConditionsVocabularyTest(unittest.TestCase):
    def test_every_supported_leaf_has_a_match_arm(self):
        cases = {
            "day_at_least": 2,
            "role_count": {"role": "nurse", "at_least": 1},
            "hive_total": {"resource": "nectar", "at_least": 1.0},
            "cell_count": {"content": "brood", "at_least": 1},
            "built_cells_at_least": 1,
            "brood_cells_at_least": 1,
            "queen_alive": True,
            "skill_owned": "skill.brood.nurses",
            "event_count": {"type": "brood_feed", "at_least": 1},
            "disease": {"at_most": 0.5},
            "all_of": [{"day_at_least": 1}],
            "any_of": [{"queen_alive": True}],
            "custom": "goal_check",
        }
        for key, value in cases.items():
            with self.subTest(spec={key: value}):
                self.assertIn('"%s":' % key, SOURCE)

    def test_progress_covers_every_numeric_condition(self):
        for key in (
            "day_at_least", "role_count", "hive_total", "cell_count",
            "built_cells_at_least", "brood_cells_at_least", "event_count", "disease",
        ):
            with self.subTest(key=key):
                self.assertIn('"%s":' % key, SOURCE.split("static func _progress_key", 1)[1])

    def test_evaluator_reads_cached_apis_instead_of_scene_groups(self):
        self.assertIn("main._role_counts()", SOURCE)
        self.assertIn("main.hive.total(", SOURCE)
        self.assertIn("main.hive.cells_holding(", SOURCE)
        self.assertNotIn("get_nodes_in_group", SOURCE)


if __name__ == "__main__":
    unittest.main()
