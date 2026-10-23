"""Unit tests for tools/presentation_gate_check.py."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.presentation_gate_check import (
    check_paths,
    find_is_on_screen_calls,
)


class TestPresentationGateCheck(unittest.TestCase):
    def test_real_tree_passes(self) -> None:
        """Verify that all is_on_screen calls in scripts/ are allowlisted and presentation-only."""
        repo_root = Path(__file__).resolve().parent.parent
        scripts_dir = repo_root / "scripts"
        allowlisted, unallowlisted = check_paths([scripts_dir], root_dir=repo_root)

        self.assertGreater(len(allowlisted), 0, "Expected to find allowlisted calls in scripts/")
        self.assertEqual(
            unallowlisted,
            [],
            f"Found unallowlisted is_on_screen call(s) in real tree: {unallowlisted}",
        )

    def test_sample_gdscript_parsing(self) -> None:
        """Test is_on_screen detection on inline GDScript snippets."""
        sample_code = """
extends Node2D

# Comment with is_on_screen(self) inside it
var msg = "String with is_on_screen(self) inside it"

func _update_label():
    if not world.is_on_screen(self):
        return
    label.text = "hi"

func _sim_logic():
    if world.is_on_screen(self):
        energy -= 1.0

func is_on_screen(node: Node2D) -> bool:
    return true
"""

        calls = find_is_on_screen_calls(sample_code, file_path="scripts/bee.gd")

        # Must find exactly 2 calls: inside _update_label and inside _sim_logic
        # It must NOT flag the comment, the string, or the func definition.
        self.assertEqual(len(calls), 2)

        self.assertEqual(calls[0]["function_name"], "_update_label")
        self.assertEqual(calls[0]["line_number"], 8)

        self.assertEqual(calls[1]["function_name"], "_sim_logic")
        self.assertEqual(calls[1]["line_number"], 13)


if __name__ == "__main__":
    unittest.main()
