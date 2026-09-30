"""Contract cases for C4's ordered problem-signal catalogue.

Godot's static catalogue is deliberately data-only. These cases construct the
same compact state that year_winter.gd supplies, then assert the exact strip
lines (including optional action/category elements) each distinct colony
condition is meant to produce.
"""

from pathlib import Path
import re
import unittest


SOURCE = (Path(__file__).parent.parent / "scripts" / "problem_messages.gd").read_text(encoding="utf-8")

ROW = re.compile(
    r'\{"id": "(\w+)", "condition": \{"custom": "(\w+)"\}, '
    r'"severity": (\d+), "action": (null|"[^"]*"), '
    r'"category": (null|"[^"]*"), "message": "(\w+)"\}'
)

MESSAGES = {
    "starving": "%d bees are about to starve",
    "hungry_brood": "%d larvae are going hungry",
    "dead_cells": "%d cells blocked by dead larvae",
    "low_pollen": "Almost no pollen — the queen cannot lay",
    "low_food": "Food is running out",
    "no_nurses": "No nurses — brood will not develop at all",
    "no_free_cells": "No free cells — nowhere to store food or lay eggs",
    "hungry": "%d bees are running low on energy",
    "no_foragers": "No foragers — nothing is coming in",
    "no_comb_workers": "No comb workers to clear the blocked cells",
    "hard_rain": "Raining hard — foragers are grounded",
    "rain": "Raining — nectar is watered down and flying costs more",
}


def catalogue():
    """Read the shipping GDScript rows, retaining their load-bearing order."""
    rows = []
    for signal_id, condition, severity, action, category, message in ROW.findall(SOURCE):
        rows.append((signal_id, condition, int(severity), None if action == "null" else action[1:-1],
                     None if category == "null" else category[1:-1], message))
    return rows


def matches(state, condition):
    return {
        "starving": state["starving"] > 0,
        "hungry_brood": state["hungry_brood"] > 0,
        "dead_cells": state["dead_cells"] > 0,
        "low_pollen": state["day"] >= 7 and state["pollen"] < 30,
        "low_food": state["nectar"] < 40 and state["honey"] < 10,
        "no_nurses": state["nurses"] == 0 and state["brood_cells"] > 0,
        "no_free_cells": state["free_cells"] == 0,
        "hungry": state["hungry"] > 0,
        "no_foragers": state["foragers"] == 0,
        "no_comb_workers": state["comb_workers"] == 0 and state["dead_cells"] > 0,
        "hard_rain": state["rain_intensity"] > 0.5,
        "rain": 0.05 < state["rain_intensity"] <= 0.5,
    }[condition]


def signal_lines(state):
    """The catalogue's custom predicates, evaluated over a constructed state."""
    lines = []
    for signal_id, condition, severity, action, category, message_name in catalogue():
        if not matches(state, condition):
            continue
        message = MESSAGES[signal_id]
        if "%d" in message:
            message %= state[signal_id]
        line = [message, severity]
        if action is not None:
            line.append(action)
        if category is not None:
            line.append(category)
        lines.append(tuple(line))
    return lines


def colony(**changes):
    state = {
        "day": 1, "starving": 0, "hungry_brood": 0, "dead_cells": 0,
        "pollen": 60, "nectar": 100, "honey": 100, "nurses": 1,
        "brood_cells": 0, "free_cells": 1, "hungry": 0, "foragers": 1,
        "comb_workers": 1, "rain_intensity": 0.0,
    }
    state.update(changes)
    return state


class SignalCatalogueTest(unittest.TestCase):
    def test_catalogue_rows_keep_the_signal_contract(self):
        rows = catalogue()
        self.assertEqual(12, len(rows))
        for signal_id, condition, _severity, _action, _category, message in rows:
            with self.subTest(signal=signal_id):
                self.assertEqual(signal_id, condition)
                self.assertEqual("signal_" + signal_id, message)
        # problem_messages.gd::_dispatch must route every catalogue message.
        for _signal_id, _condition, _severity, _action, _category, message in rows:
            self.assertIn(f'"{message}": return {message}(state)', SOURCE)

    def test_six_distinct_colony_states_have_exact_lines(self):
        cases = {
            "clear": (colony(), []),
            "urgent_brood": (colony(starving=2, hungry_brood=3, dead_cells=1, nurses=0, brood_cells=3, free_cells=0, foragers=0, comb_workers=0), [
                ("2 bees are about to starve", 2, "starving"),
                ("3 larvae are going hungry", 2, "hungry_brood", "brood"),
                ("1 cells blocked by dead larvae", 2, "dead_cells", "brood"),
                ("No nurses — brood will not develop at all", 2, "", "brood"),
                ("No free cells — nowhere to store food or lay eggs", 1),
                ("No foragers — nothing is coming in", 1, ""),
                ("No comb workers to clear the blocked cells", 1, "dead_cells", "brood"),
            ]),
            "low_stores": (colony(day=7, pollen=29, nectar=39, honey=9), [
                ("Almost no pollen — the queen cannot lay", 2, "", "brood"),
                ("Food is running out", 2),
            ]),
            "hungry_workers": (colony(hungry=4), [("4 bees are running low on energy", 1, "hungry")]),
            "hard_rain": (colony(rain_intensity=0.6), [("Raining hard — foragers are grounded", 1)]),
            "light_rain": (colony(rain_intensity=0.1), [("Raining — nectar is watered down and flying costs more", 0)]),
        }
        for name, (state, expected) in cases.items():
            with self.subTest(state=name):
                self.assertEqual(expected, signal_lines(state))


if __name__ == "__main__":
    unittest.main()
