"""RR-4: the window cannot be made smaller than 800x600.

Reads the source: ui_layout.gd must hold both floor constants, and main.gd's
_ready must assign the window's min_size from them before the menu_pending
return. A static read is enough here: the assignment is one line of boot code
with no behaviour beyond the value it sets.

Run with: python -m unittest tests.test_rr4_min_window
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UI_LAYOUT = ROOT / "scripts" / "ui_layout.gd"
MAIN = ROOT / "scripts" / "main.gd"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


class RR4MinWindowTest(unittest.TestCase):
    def test_ui_layout_holds_both_floor_constants(self):
        source = _read(UI_LAYOUT)
        self.assertRegex(source, r"(?m)^const MIN_SUPPORTED_WIDTH := 800\.0\s*$")
        self.assertRegex(source, r"(?m)^const MIN_SUPPORTED_HEIGHT := 600\.0\s*$")

    def test_main_assigns_min_size_from_both_constants(self):
        source = _read(MAIN)
        assignment = re.search(
            r'(?m)^\s*get_tree\(\)\.root\.set_deferred\(\s*"min_size",\s*Vector2i\(\s*'
            r"int\(UiLayout\.MIN_SUPPORTED_WIDTH\)\s*,\s*"
            r"int\(UiLayout\.MIN_SUPPORTED_HEIGHT\)\s*\)\s*\)\s*$",
            source,
        )
        self.assertIsNotNone(assignment, "main.gd does not set the window's min_size from the floor constants")

    def test_min_size_is_set_before_the_menu_pending_return(self):
        source = _read(MAIN)
        assignment = source.find("get_tree().root.set_deferred(")
        self.assertNotEqual(assignment, -1)
        ready_start = source.index("func _ready() -> void:")
        early_return = source.index("if Session.menu_pending:", ready_start)
        self.assertLess(
            assignment,
            early_return,
            "min_size is assigned after the menu_pending return, so the pre-run menu is unbounded",
        )
        self.assertGreater(assignment, ready_start)

    def test_main_preloads_ui_layout(self):
        self.assertRegex(
            _read(MAIN),
            r'(?m)^const UiLayout = preload\("res://scripts/ui_layout\.gd"\)\s*$',
        )


if __name__ == "__main__":
    unittest.main()
