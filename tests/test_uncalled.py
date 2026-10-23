"""Unit tests for tools/uncalled.py.

Real tree baseline: currently reports 21 uncalled GDScript functions.
"""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.uncalled import find_uncalled_functions


class TestUncalled(unittest.TestCase):
    def test_fixture_tree(self) -> None:
        """Test uncalled function detection on a temporary directory structure."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            scripts_dir = root / "scripts"
            tests_dir = root / "tests"
            scenes_dir = root / "scenes"
            scripts_dir.mkdir()
            tests_dir.mkdir()
            scenes_dir.mkdir()

            (scripts_dir / "foo.gd").write_text(
                "func called_func():\n"
                "    pass\n\n"
                "func _engine_callback():\n"
                "    pass\n\n"
                "func dead_func():\n"
                "    pass\n",
                encoding="utf-8",
            )

            (scripts_dir / "bar.gd").write_text(
                "func _process(delta):\n"
                "    called_func()\n",
                encoding="utf-8",
            )

            uncalled = find_uncalled_functions(root)
            uncalled_names = [name for _, name, _ in uncalled]

            self.assertIn("dead_func", uncalled_names)
            self.assertNotIn("called_func", uncalled_names)
            self.assertNotIn("_engine_callback", uncalled_names)
            self.assertNotIn("_process", uncalled_names)

    def test_real_tree_total(self) -> None:
        """Verify the uncalled function count on the real codebase repository tree."""
        repo_root = Path(__file__).resolve().parent.parent
        uncalled = find_uncalled_functions(repo_root)
        self.assertEqual(
            len(uncalled),
            21,
            f"Expected exactly 21 uncalled functions on real tree, found {len(uncalled)}: {uncalled}",
        )


if __name__ == "__main__":
    unittest.main()
