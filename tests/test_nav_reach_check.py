"""Tests for tools/nav_reach_check.py."""

import sys
import tempfile
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

    def test_detects_inclusive_loop_mutation(self) -> None:
        """A loop running to reach + 1 is flagged."""
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
            any("hive_rock_rings" in p for p in problems),
            f"Expected error about missing hive_rock_rings, got {problems}",
        )

    def test_detects_outer_chamber_bound_drift(self) -> None:
        """A mismatch in world_building rock ring bounds is flagged."""
        mutated_wb = (
            "func _dig_out_chamber(centre_local: Vector2, interior_rings: int, soil_depth: int, spacing: float) -> void:\n"
            "    for ring: int in range(interior_rings + soil_depth, interior_rings + soil_depth + rock_rings + 1):\n"
            "        pass\n"
        )
        problems = nav_reach_check.check_world_building_chamber(mutated_wb)
        self.assertTrue(
            any("outer rock ring bound" in p for p in problems),
            f"Expected error about outer rock ring bound, got {problems}",
        )


if __name__ == "__main__":
    unittest.main()
