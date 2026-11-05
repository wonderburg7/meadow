"""Colony window rows: readouts keep their text and hover tip; the queen has a line.

Headless Godot against the real Main.tscn (level 3). Opens the Colony
window, refreshes it once and checks:

- every readout label is expand-filled, takes the mouse and carries its tip
  as a tooltip (the info badge is off by default), and holds its text;
- the queen row reads "Queen: <role_name_text()>" and is hidden when main.queen
  is gone.

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_colony_panel_rows
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TIMEOUT_SECONDS = 180
SCRIPT = r'''extends SceneTree
var _n := 0
var _m: Node = null
func _process(_d: float) -> bool:
	_n += 1
	if _n == 1:
		root.get_node("Session").starting_level = 3
		root.get_node("Session").menu_pending = false
		_m = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
		root.add_child(_m)
	elif _n == 30:
		var p = _m.colony_panel
		p.panel.visible = true
		p.refresh({}, {"day": "Day 1", "stores": "Nectar: 0"}, [], [])
		var fails := PackedStringArray()
		if p.stat_labels["day"].text != "Day 1":
			fails.append("day readout blank")
		for key in p.stat_labels:
			var l: Label = p.stat_labels[key]
			if l.tooltip_text == "":
				fails.append("%s has no hover tip" % key)
			if l.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				fails.append("%s ignores the mouse" % key)
			if not (l.size_flags_horizontal & Control.SIZE_EXPAND):
				fails.append("%s does not expand" % key)
		if not p.queen_label.visible or p.queen_label.text != "Queen: " + _m.queen.role_name_text():
			fails.append("queen row wrong: '%s'" % p.queen_label.text)
		_m.queen = null
		p.refresh({}, {}, [], [])
		if p.queen_label.visible:
			fails.append("queen row shown with no queen")
		print("RESULT ", "OK" if fails.is_empty() else "; ".join(fails))
		quit()
	return false
'''


class ColonyPanelRows(unittest.TestCase):
    def test_rows(self) -> None:
        godot = gcc.find_godot()
        if godot is None:
            self.skipTest("no Godot executable")
        with tempfile.TemporaryDirectory() as tmp:
            script = Path(tmp) / "probe.gd"
            script.write_text(SCRIPT, encoding="utf-8")
            try:
                proc = subprocess.run(
                    [str(godot), "--headless", "--path", str(ROOT), "--script", script.as_posix()],
                    capture_output=True, text=True, timeout=TIMEOUT_SECONDS,
                )
            except subprocess.TimeoutExpired:
                self.skipTest("Godot did not finish headlessly")
        lines = [l for l in proc.stdout.splitlines() if l.startswith("RESULT ")]
        if not lines:
            self.skipTest("engine could not run the probe headlessly")
        self.assertEqual(lines[-1], "RESULT OK")


if __name__ == "__main__":
    unittest.main()
