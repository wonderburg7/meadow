"""Unit tests for pure helper functions in tools/skirt_commitment_check.py."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.skirt_commitment_check import (
    is_multi_frame_condition,
    is_single_frame_condition,
    strip_code,
    tracked_gd_files,
)


class TestSkirtCommitmentCheckHelpers(unittest.TestCase):
    def test_strip_code_removes_comments(self) -> None:
        self.assertEqual(strip_code("var x = 1 # comment"), "var x = 1 ")
        self.assertEqual(strip_code("# whole line comment"), "")
        self.assertEqual(strip_code("func test():\n"), "func test():\n")

    def test_strip_code_replaces_strings(self) -> None:
        self.assertEqual(strip_code('var s = "hello world"'), 'var s = ""')
        self.assertEqual(strip_code("var s = 'single quotes'"), 'var s = ""')
        self.assertEqual(strip_code(r'var s = "escaped \" quotes"'), 'var s = ""')
        self.assertEqual(strip_code('var s = "hash # inside string" # actual comment'), 'var s = "" ')

    def test_is_single_frame_condition(self) -> None:
        self.assertTrue(is_single_frame_condition("frames >= 1"))
        self.assertTrue(is_single_frame_condition("frames > 0"))
        self.assertTrue(is_single_frame_condition("frames == 1"))
        self.assertFalse(is_single_frame_condition("frames >= 2"))
        self.assertFalse(is_single_frame_condition("frames > 1"))
        self.assertFalse(is_single_frame_condition("frames == 2"))
        self.assertFalse(is_single_frame_condition("skirt_clear_frames >= SKIRT_FORGET_FRAMES"))

    def test_is_multi_frame_condition_literal_thresholds(self) -> None:
        self.assertTrue(is_multi_frame_condition("skirt_clear_frames >= 2"))
        self.assertTrue(is_multi_frame_condition("bee.skirt_clear_frames >= 2"))
        self.assertTrue(is_multi_frame_condition("skirt_clear_frames > 1"))
        self.assertTrue(is_multi_frame_condition("bee.skirt_clear_frames > 1"))
        self.assertTrue(is_multi_frame_condition("skirt_clear_frames == 2"))

        # Rejects single-frame thresholds even if expression shape matches
        self.assertFalse(is_multi_frame_condition("skirt_clear_frames >= 1"))
        self.assertFalse(is_multi_frame_condition("skirt_clear_frames > 0"))
        self.assertFalse(is_multi_frame_condition("skirt_clear_frames == 1"))

        # Rejects non-matching expressions
        self.assertFalse(is_multi_frame_condition("other_frames >= 2"))
        self.assertFalse(is_multi_frame_condition("skirt_clear_frames <= 2"))

    def test_is_multi_frame_condition_named_constants(self) -> None:
        constants = {"SKIRT_FORGET_FRAMES": 3, "ZERO_FRAME": 0, "ONE_FRAME": 1}
        self.assertTrue(is_multi_frame_condition("skirt_clear_frames >= SKIRT_FORGET_FRAMES", constants))
        self.assertTrue(is_multi_frame_condition("skirt_clear_frames > ONE_FRAME", constants))
        self.assertFalse(is_multi_frame_condition("skirt_clear_frames >= ONE_FRAME", constants))
        self.assertFalse(is_multi_frame_condition("skirt_clear_frames > ZERO_FRAME", constants))
        self.assertFalse(is_multi_frame_condition("skirt_clear_frames >= UNKNOWN_CONST", constants))

    def test_tracked_gd_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmproot = Path(tmpdir)
            self.assertEqual(tracked_gd_files(tmproot), [])

            scripts_dir = tmproot / "scripts"
            scripts_dir.mkdir()
            f1 = scripts_dir / "b.gd"
            f2 = scripts_dir / "a.gd"
            sub = scripts_dir / "sub"
            sub.mkdir()
            f3 = sub / "c.gd"
            other = scripts_dir / "notes.txt"

            f1.touch()
            f2.touch()
            f3.touch()
            other.touch()

            found = tracked_gd_files(tmproot)
            self.assertEqual(found, [f2, f1, f3])


if __name__ == "__main__":
    unittest.main()
