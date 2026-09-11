"""Drives tests/fixtures/hc16_tray_reselect*.json through a real Godot boot --
the headless proof behind HC-16 (plans/archive/HUD_CONTROLS_2026-09-11.md,
full delivery record at plans/archive/HC-16_2026-09-11.md): the command
tray's height matches its content on a *reselection* (forager -> queen and
the reverse), with `More…` open and without it, at two text scales.

HC-8's own diagnostic (10 Sep 2026) found the reapply loop settling on a
plausible but wrong value because a reselection's old rows stayed parented
-- and counted by every nested HFlowContainer's wrap/height computation --
until Godot's own idle pass actually freed them, arriving on no schedule a
bounded reapply count could wait out. HC-16 detaches each old row from its
container immediately (still freeing it only on the deferred pass, since
this can run mid-signal for a role-menu click) so the stale content stops
being measured before the new rows are ever added. These fixtures are the
one place that regression can be re-proven mechanically; a hand-reverted
run of hc16_tray_reselect_1x.json against the pre-fix hud.gd fails this
suite's assertion.

Requires a real Godot executable, unlike the rest of tests/ -- skips with a
clear message naming the missing path rather than failing, matching
test_hc8_tray_first_open.py's own resolution.

Run with: python3 tests/test_hc16_tray_reselect.py
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
from run_scenario import DEFAULT_GODOT_PATH, run_once  # noqa: E402

FIXTURES = [
    ROOT / "tests" / "fixtures" / "hc16_tray_reselect_1x.json",
    ROOT / "tests" / "fixtures" / "hc16_tray_reselect_2x.json",
    ROOT / "tests" / "fixtures" / "hc16_tray_reselect_more_1x.json",
    ROOT / "tests" / "fixtures" / "hc16_tray_reselect_more_2x.json",
]


def _resolve_godot_path() -> str | None:
    candidate = os.environ.get("GODOT_PATH")
    if candidate and Path(candidate).is_file():
        return candidate
    if Path(DEFAULT_GODOT_PATH).is_file():
        return DEFAULT_GODOT_PATH
    found = shutil.which("godot") or shutil.which("godot4")
    return found


class HC16TrayReselectTest(unittest.TestCase):
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
