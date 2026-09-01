"""Focused regression tests for the headless GDScript source checker."""

import importlib.util
from pathlib import Path
import unittest


SOURCE_CHECKS_PATH = Path(__file__).with_name("source_checks.py")
PREREQUISITES_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "prerequisites.gd"
DEBUG_PANEL_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "debug_panel.gd"
SPEC = importlib.util.spec_from_file_location("source_checks", SOURCE_CHECKS_PATH)
source_checks = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(source_checks)


class BracketChecksTest(unittest.TestCase):
    def test_premature_closer_cannot_cancel_with_later_opener(self):
        problems = []

        source_checks.check_brackets("sample.gd", ["var value = )("], problems)

        self.assertTrue(
            any("unexpected closing )" in problem for problem in problems), problems
        )
        self.assertTrue(any("unclosed (" in problem for problem in problems), problems)

    def test_nested_brackets_must_close_in_order(self):
        problems = []

        source_checks.check_brackets("sample.gd", ["var value = ([)]"], problems)

        self.assertTrue(any("does not match" in problem for problem in problems), problems)

    def test_balanced_brackets_ignore_strings_and_comments(self):
        problems = []

        source_checks.check_brackets(
            "sample.gd",
            ['var text = "]" # )', "var value = ({[]})"],
            problems,
        )

        self.assertEqual([], problems)


class ForagingPrerequisiteContractTest(unittest.TestCase):
    def test_orientation_flight_and_scouting_are_symmetric_alternatives(self):
        source = PREREQUISITES_PATH.read_text(encoding="utf-8")
        prerequisite_map = source.split("const TOGGLE_PREREQUISITE := {", 1)[1].split("}", 1)[0]
        mutual_exclusion_map = source.split("const MUTUALLY_EXCLUSIVE := {", 1)[1].split("}", 1)[0]

        self.assertNotIn('"scouting_on": "orientation_flight_on"', prerequisite_map)
        self.assertIn('"orientation_flight_on": "scouting_on"', mutual_exclusion_map)
        self.assertIn('"scouting_on": "orientation_flight_on"', mutual_exclusion_map)
        self.assertIn("MUTUALLY_EXCLUSIVE.has(key)", source)

        debug_panel_source = DEBUG_PANEL_PATH.read_text(encoding="utf-8")
        prerequisite_cascade = debug_panel_source.split("static func _cascade_prerequisites_on_static", 1)[1].split(
            "static func _cascade_dependents_off_static", 1
        )[0]
        self.assertIn("_cascade_mutual_exclusion_static(parent)", prerequisite_cascade)


if __name__ == "__main__":
    unittest.main()
