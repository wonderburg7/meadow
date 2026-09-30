"""Drives tests/fixtures/layout_panels.json through a real Godot boot and
checks every scenario assertion accepted -- the actual headless proof
behind LAY-5/LAY-6 (plans/now/layout-regression.md): a persistent panel
losing its viewport bounds or its 16px gap (LAY-5), or a control inside one
collapsing to an unusable size (LAY-6), fails this test without a human
looking at a screenshot.

Requires a real Godot executable, unlike the rest of tests/ -- skips with
a clear message naming the missing path rather than failing, the same
shape as the fixture's own godot-path resolution
(tools/run_scenario.py's --godot-path / GODOT_PATH).

Run with: python3 tests/test_layout_regression.py
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

FIXTURE = ROOT / "tests" / "fixtures" / "layout_panels.json"
# The settings window during a Challenge: its stage row once drew a wrapping
# label one letter per line between stretched arrows (C-49, UI-W-1).
SETTINGS_FIXTURE = ROOT / "tests" / "fixtures" / "settings_stage_row.json"


def _resolve_godot_path() -> str | None:
    return find_godot()


class LayoutRegressionTest(unittest.TestCase):
    def test_layout_panels_fixture_passes(self):
        self._assert_fixture_passes(FIXTURE)

    def test_settings_stage_row_fixture_passes(self):
        self._assert_fixture_passes(SETTINGS_FIXTURE)

    def _assert_fixture_passes(self, fixture: Path):
        godot_path = _resolve_godot_path()
        if not godot_path:
            self.skipTest(
                "no Godot executable found (checked $GODOT_PATH, %r, and PATH) "
                "-- this test needs a real boot, unlike the rest of tests/"
                % DEFAULT_GODOT_PATH
            )

        session_file = run_once(fixture, godot_path, timeout=120)
        self.assertIsNotNone(
            session_file,
            "scenario run produced no session_*.jsonl -- see stderr above for the launch failure",
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
            self.fail("layout_panels.json had %d failing/unresolved assertion(s):\n%s" % (len(rejected), detail))


if __name__ == "__main__":
    unittest.main()
