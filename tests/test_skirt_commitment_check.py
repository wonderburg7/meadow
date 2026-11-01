"""Unit tests for tools/skirt_commitment_check.py."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import skirt_commitment_check  # noqa: E402


class TestSkirtCommitmentCheck(unittest.TestCase):
    def test_real_tree_passes(self) -> None:
        """The real tree on origin/master has no premature skirt commitment drops."""
        files = skirt_commitment_check.tracked_gd_files(ROOT)
        self.assertGreater(len(files), 0, "Expected to find GDScript files in scripts/")
        problems: list[str] = []
        for path in files:
            problems.extend(skirt_commitment_check.check_file(path))
        self.assertEqual(problems, [], f"Unexpected skirt commitment problems on real tree: {problems}")

    def test_cli_main_passes_on_repo(self) -> None:
        """main() returns 0 when run on the repo."""
        code = skirt_commitment_check.main([])
        self.assertEqual(code, 0)

    def test_cli_files_argument(self) -> None:
        """main() accepts specific file paths."""
        code = skirt_commitment_check.main(["scripts/bee_movement.gd"])
        self.assertEqual(code, 0)

    def test_premature_clear_detected(self) -> None:
        """Directly setting skirt_obstacle = null on blocker == null without frame guard is detected."""
        code = (
            "extends Node\n"
            "func avoid_obstacles(bee: Node2D, target: Vector2) -> Vector2:\n"
            "    var blocker := first_blocker(bee, target)\n"
            "    if blocker == null:\n"
            "        bee.skirt_obstacle = null\n"
            "        return target\n"
            "    return tangent_past(bee, blocker, target)\n"
        )
        problems = skirt_commitment_check.check_file("scripts/dummy.gd", text=code)
        self.assertEqual(len(problems), 1)
        self.assertIn("skirt_obstacle cleared on a single null-blocker frame", problems[0])

    def test_debounced_clear_passes(self) -> None:
        """Clearing skirt_obstacle with frame counter guard passes."""
        code = (
            "extends Node\n"
            "func avoid_obstacles(bee: Node2D, target: Vector2) -> Vector2:\n"
            "    var blocker := first_blocker(bee, target)\n"
            "    if blocker == null:\n"
            "        bee.skirt_clear_frames += 1\n"
            "        if bee.skirt_clear_frames >= SKIRT_FORGET_FRAMES:\n"
            "            bee.skirt_obstacle = null\n"
            "            bee.skirt_clear_frames = 0\n"
            "        return target\n"
            "    return tangent_past(bee, blocker, target)\n"
        )
        problems = skirt_commitment_check.check_file("scripts/dummy.gd", text=code)
        self.assertEqual(problems, [])

    def test_reset_function_clear_passes(self) -> None:
        """Intentional reset functions clearing skirt_obstacle unconditionally (e.g. clear_navigation_state) pass."""
        code = (
            "extends Node\n"
            "func clear_navigation_state(bee: Node2D) -> void:\n"
            "    bee.skirt_obstacle = null\n"
            "    bee.skirt_clear_frames = 0\n"
        )
        problems = skirt_commitment_check.check_file("scripts/dummy.gd", text=code)
        self.assertEqual(problems, [])

    def test_comments_and_strings_ignored(self) -> None:
        """Comments mentioning bee.skirt_obstacle = null inside a null check are ignored."""
        code = (
            "extends Node\n"
            "func avoid_obstacles(bee: Node2D, target: Vector2) -> Vector2:\n"
            "    if blocker == null:\n"
            "        # bee.skirt_obstacle = null\n"
            "        var comment := 'bee.skirt_obstacle = null'\n"
            "        return target\n"
        )
        problems = skirt_commitment_check.check_file("scripts/dummy.gd", text=code)
        self.assertEqual(problems, [])


if __name__ == "__main__":
    unittest.main()
