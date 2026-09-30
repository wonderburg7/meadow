"""Drives tests/fixtures/hc8_tray_first_open_1x.json and _2x.json through a
real Godot boot -- the headless proof behind HC-8
(plans/archive/HUD_CONTROLS_2026-09-11.md):
the command tray's height matches its content on the very first build after a
selection, at both text scales. Reuses panel_rect's "matches_content"
assertion (scripts/scenario_actions.gd) rather than adding a second height
helper; two files rather than one scenario because a genuine "first open"
needs no prior selection in the same run, and HC-8's own measurement found a
*re*selection still lands the tray short of its content -- that residual was
tracked separately and shipped as HC-16 (see test_hc16_tray_reselect.py), not
asserted on here.

Requires a real Godot executable, unlike the rest of tests/ -- skips with a
clear message naming the missing path rather than failing, matching
test_layout_regression.py's own resolution.

Run with: python3 tests/test_hc8_tray_first_open.py
"""

from __future__ import annotations

import os
import shutil
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from analyze_session import load_entries  # noqa: E402
from godot_compile_check import find_godot  # noqa: E402
from run_scenario import DEFAULT_GODOT_PATH, run_once  # noqa: E402

FIXTURES = [
    ROOT / "tests" / "fixtures" / "hc8_tray_first_open_1x.json",
    ROOT / "tests" / "fixtures" / "hc8_tray_first_open_2x.json",
]


def _resolve_godot_path() -> str | None:
    return find_godot()


class HC8TrayFirstOpenTest(unittest.TestCase):
    def test_fixtures_pass(self):
        godot_path = _resolve_godot_path()
        if not godot_path:
            self.skipTest(
                "no Godot executable found (checked $GODOT_PATH, %r, and PATH) "
                "-- this test needs a real boot, unlike the rest of tests/"
                % DEFAULT_GODOT_PATH
            )

        for fixture in FIXTURES:
            with self.subTest(fixture=fixture.name):
                session_file = run_once(fixture, godot_path, timeout=120)
                self.assertIsNotNone(
                    session_file,
                    "%s produced no session_*.jsonl -- see stderr above for the launch failure" % fixture.name,
                )

                entries = load_entries(session_file)
                rejected = [
                    e for e in entries
                    if e.get("type") == "action" and e.get("do") == "assert" and e.get("result") != "accepted"
                ]
                if rejected:
                    detail = "\n".join(
                        "  %s: %s" % (e.get("target", ""), e.get("reason", "")) for e in rejected
                    )
                    self.fail("%s had %d failing/unresolved assertion(s):\n%s" % (fixture.name, len(rejected), detail))


if __name__ == "__main__":
    unittest.main()
