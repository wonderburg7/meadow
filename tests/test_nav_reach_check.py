"""Tests for tools/nav_reach_check.py."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import nav_reach_check  # noqa: E402


class TestNavReachCheck(unittest.TestCase):
    def test_repo_passes(self) -> None:
        """The repository tree on origin/master passes nav_reach_check."""
        problems = nav_reach_check.check_repo(ROOT)
        self.assertEqual(problems, [], f"Unexpected problems on repo: {problems}")

    def test_main_cli_success(self) -> None:
        """CLI invocation succeeds with code 0."""
        code = nav_reach_check.main([str(ROOT)])
        self.assertEqual(code, 0)

    def test_main_cli_failure(self) -> None:
        """CLI invocation exits with code 1 when errors exist."""
        # Non-existent root directory produces missing file errors
        code = nav_reach_check.main(["/nonexistent_path_nav_reach"])
        self.assertEqual(code, 1)

    def test_detects_inclusive_loop_mutation(self) -> None:
        """A loop running to reach + 1 or range(0, reach + 1) is flagged."""
        mutated_hive = (
            "func build_navigation() -> void:\n"
            "    var reach := int(GameConfig.hive_interior_rings + GameConfig.hive_soil_depth + GameConfig.hive_rock_rings)\n"
            "    for ring: int in range(0, reach + 1):\n"
            "        pass\n"
        )
        problems = nav_reach_check.check_hive_navigation(mutated_hive)
        self.assertTrue(
            any("ring loop stop bound must be exactly 'reach'" in p for p in problems),
            f"Expected error about reach bound, got {problems}",
        )

    def test_detects_reach_plus_one_mutation(self) -> None:
        """Adding + 1 to reach expression in hive.gd is flagged."""
        mutated_hive = (
            "func build_navigation() -> void:\n"
            "    var reach := int(GameConfig.hive_interior_rings + GameConfig.hive_soil_depth + GameConfig.hive_rock_rings + 1)\n"
            "    for ring: int in range(0, reach):\n"
            "        pass\n"
        )
        problems = nav_reach_check.check_hive_navigation(mutated_hive)
        self.assertTrue(
            any("reach definition must evaluate to the sum of" in p for p in problems),
            f"Expected reach arithmetic failure, got {problems}",
        )

    def test_detects_reach_subtraction_mutation(self) -> None:
        """Subtracting rock rings from reach calculation is flagged."""
        mutated_hive = (
            "func build_navigation() -> void:\n"
            "    var reach := int(GameConfig.hive_interior_rings + GameConfig.hive_soil_depth - GameConfig.hive_rock_rings)\n"
            "    for ring: int in range(0, reach):\n"
            "        pass\n"
        )
        problems = nav_reach_check.check_hive_navigation(mutated_hive)
        self.assertTrue(
            any("is not a valid sum expression" in p for p in problems),
            f"Expected reach subtraction failure, got {problems}",
        )

    def test_detects_missing_reach_term(self) -> None:
        """A reach calculation omitting rock rings is flagged."""
        mutated_hive = (
            "func build_navigation() -> void:\n"
            "    var reach := int(GameConfig.hive_interior_rings + GameConfig.hive_soil_depth)\n"
            "    for ring: int in range(0, reach):\n"
            "        pass\n"
        )
        problems = nav_reach_check.check_hive_navigation(mutated_hive)
        self.assertTrue(
            any("reach definition must evaluate to the sum of" in p for p in problems),
            f"Expected error about missing terms, got {problems}",
        )

    def test_formatting_variations_pass(self) -> None:
        """Ordinary formatting differences (whitespace, term order, without int wrap) pass."""
        varied_hive = (
            "func build_navigation() -> void:\n"
            "    var reach := ( GameConfig.hive_rock_rings  +\n"
            "                   GameConfig.hive_interior_rings +\n"
            "                   GameConfig.hive_soil_depth )\n"
            "    for ring: int in range( 0 , reach ):\n"
            "        pass\n"
        )
        problems = nav_reach_check.check_hive_navigation(varied_hive)
        self.assertEqual(problems, [], f"Expected formatted hive to pass, got {problems}")

    def test_detects_outer_chamber_bound_drift(self) -> None:
        """A mismatch in world_building rock ring bounds is flagged."""
        mutated_wb = (
            "func _dig_out_chamber(centre_local: Vector2, interior_rings: int, soil_depth: int, spacing: float) -> void:\n"
            "    for ring: int in range(0, interior_rings + soil_depth):\n"
            "        pass\n"
            "    for ring: int in range(interior_rings + soil_depth, interior_rings + soil_depth + rock_rings + 1):\n"
            "        pass\n"
        )
        problems = nav_reach_check.check_world_building_chamber(mutated_wb)
        self.assertTrue(
            any("outer rock ring bound must evaluate to" in p for p in problems),
            f"Expected error about outer rock ring bound, got {problems}",
        )

    def test_actual_source_reach_mutations(self):
        source = (ROOT / "scripts/hive.gd").read_text(encoding="utf-8")
        old = "GameConfig.hive_interior_rings + GameConfig.hive_soil_depth + GameConfig.hive_rock_rings"
        self.assertIn(old, source)
        for replacement in [old + " + 1", old.replace("+ GameConfig.hive_rock_rings", "- GameConfig.hive_rock_rings"),
                            old.replace(" + GameConfig.hive_rock_rings", "")]:
            with self.subTest(replacement=replacement):
                self.assertTrue(nav_reach_check.check_hive_navigation(source.replace(old, replacement)))
        self.assertIn("range(0, reach)", source)
        self.assertTrue(nav_reach_check.check_hive_navigation(source.replace("range(0, reach)", "range(0, reach + 1)")))


if __name__ == "__main__":
    unittest.main()
