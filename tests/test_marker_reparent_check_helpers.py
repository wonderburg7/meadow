"""Unit tests for pure helper functions in tools/marker_reparent_check.py."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from marker_reparent_check import strip_comments  # noqa: E402


class TestMarkerReparentCheckHelpers(unittest.TestCase):
    def test_strip_single_line_comment(self) -> None:
        source = "var x = 1 # this is a comment\nvar y = 2\n"
        result = strip_comments(source)
        self.assertEqual(len(result), len(source))
        lines = result.splitlines()
        self.assertEqual(lines[0].rstrip(), "var x = 1")
        self.assertEqual(lines[1], "var y = 2")

    def test_strip_non_stage_string_literals(self) -> None:
        source = 'var s = "hello world"\nvar c = \'single quoted\''
        result = strip_comments(source)
        self.assertEqual(len(result), len(source))
        self.assertEqual(result.splitlines(), ['var s =              ', 'var c =                '])

    def test_preserve_stage_id_literals(self) -> None:
        source = 'if stage_id in ["1.2", "1.5", "1.10"]:\n\tmarker_parent = main.hive_root'
        result = strip_comments(source)
        self.assertEqual(len(result), len(source))
        self.assertIn('"1.2"', result)
        self.assertIn('"1.5"', result)
        self.assertIn('"1.10"', result)

    def test_strip_triple_quoted_multiline_string(self) -> None:
        source = 'var doc = """first line\nsecond line\nthird line"""\nvar z = 3'
        result = strip_comments(source)
        self.assertEqual(len(result), len(source))
        self.assertEqual(result.count("\n"), source.count("\n"))
        lines = result.splitlines()
        self.assertEqual(len(lines), 4)
        self.assertEqual(lines[3], "var z = 3")
        self.assertTrue(lines[1].isspace())
        self.assertTrue(lines[2].isspace())

    def test_hash_inside_string_not_comment(self) -> None:
        source = 'var tag = "#not_a_comment"\n# actual comment'
        result = strip_comments(source)
        self.assertEqual(len(result), len(source))
        lines = result.splitlines()
        self.assertEqual(len(lines), 2)
        self.assertEqual(lines[0], 'var tag =                 ')
        self.assertEqual(lines[1], '                ')


if __name__ == "__main__":
    unittest.main()
