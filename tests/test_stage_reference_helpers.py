"""Tests for helper functions in tools/stage_reference.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest.mock import patch

from tools import stage_reference


class TestStageReferenceHelpers(unittest.TestCase):
    def test_array_body_extracts_content(self) -> None:
        text = 'const STAGES_1 := [\n  {"id": "1.1"}\n]'
        extracted = stage_reference._array_body(text, "STAGES_1")
        self.assertIn('"id": "1.1"', extracted)

    def test_array_body_unbalanced_brackets_raises(self) -> None:
        text = 'const STAGES_1 := [\n  {"id": "1.1"}'
        with self.assertRaises(ValueError):
            stage_reference._array_body(text, "STAGES_1")

    def test_table_formats_stages(self) -> None:
        stages = [
            {
                "id": "1.1",
                "goal_text": "Goal: Collect nectar",
                "goal": "nectar >= 10",
                "instruction": "Fly to flower",
            }
        ]
        table_lines = stage_reference._table(stages)
        self.assertEqual(len(table_lines), 3)
        self.assertIn("| `1.1` | Collect nectar | `nectar >= 10` | Fly to flower |", table_lines[2])

    def test_main_check_mode(self) -> None:
        with patch.object(stage_reference, "render", return_value="content"):
            with patch.object(Path, "exists", return_value=True):
                with patch.object(Path, "read_text", return_value="content"):
                    with patch.object(sys, "argv", ["stage_reference.py", "--check"]):
                        code = stage_reference.main()
                        self.assertEqual(code, 0)

            with patch.object(Path, "exists", return_value=True):
                with patch.object(Path, "read_text", return_value="stale"):
                    with patch.object(sys, "argv", ["stage_reference.py", "--check"]):
                        code = stage_reference.main()
                        self.assertEqual(code, 1)


if __name__ == "__main__":
    unittest.main()
