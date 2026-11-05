"""A new run starts with the Problems star on and the Goals list shown.

Both are persisted display preferences, so an earlier untick or collapse
would otherwise carry into every later run. Source-level: the reset lives in
Session.reset_run_state(), which only the new-run handlers call (a load goes
through saving.gd, not here).

Run with: python -m unittest tests.test_new_run_display_defaults
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SESSION = (ROOT / "scripts" / "session.gd").read_text(encoding="utf-8")


def _reset_body() -> str:
    match = re.search(r"^func reset_run_state\(\) -> void:\n(.*?)(?=^func |\Z)", SESSION, re.S | re.M)
    assert match, "reset_run_state not found"
    return match.group(1)


class NewRunDisplayDefaults(unittest.TestCase):
    def test_problems_star_is_put_back_on(self) -> None:
        body = _reset_body()
        self.assertIn('pinned_stats.has("signals")', body)
        self.assertIn('pinned_stats.append("signals")', body)

    def test_goals_list_is_shown(self) -> None:
        self.assertIn("goals_collapsed = false", _reset_body())

    def test_load_path_does_not_call_the_reset(self) -> None:
        saving = (ROOT / "scripts" / "saving.gd").read_text(encoding="utf-8")
        self.assertNotIn("reset_run_state", saving)


if __name__ == "__main__":
    unittest.main()
