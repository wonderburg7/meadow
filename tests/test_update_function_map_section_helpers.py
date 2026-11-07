"""Unit tests for tools/update_function_map.py's file discovery, formatting, and header warning helpers."""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools.update_function_map import (
    LINE_THRESHOLD,
    PREAMBLE,
    build_file,
    build_section,
    discover_files,
    header_warnings,
)


class TestUpdateFunctionMapSectionHelpers(unittest.TestCase):
    def test_discover_files_filters_and_sorts(self) -> None:
        """discover_files ignores files <= LINE_THRESHOLD and sorts by (-lines, name)."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir)
            (scripts_dir / "tiny.gd").write_text("\n".join(["# line"] * 10), encoding="utf-8")
            (scripts_dir / "boundary.gd").write_text(
                "\n".join(["# line"] * LINE_THRESHOLD), encoding="utf-8"
            )
            (scripts_dir / "b_large.gd").write_text(
                "\n".join(["# line"] * (LINE_THRESHOLD + 100)), encoding="utf-8"
            )
            (scripts_dir / "a_large.gd").write_text(
                "\n".join(["# line"] * (LINE_THRESHOLD + 100)), encoding="utf-8"
            )
            (scripts_dir / "huge.gd").write_text(
                "\n".join(["# line"] * (LINE_THRESHOLD + 500)), encoding="utf-8"
            )
            (scripts_dir / "not_gd.txt").write_text(
                "\n".join(["# line"] * (LINE_THRESHOLD + 1000)), encoding="utf-8"
            )

            discovered = discover_files(scripts_dir)
            expected = [
                ("huge.gd", LINE_THRESHOLD + 500),
                ("a_large.gd", LINE_THRESHOLD + 100),
                ("b_large.gd", LINE_THRESHOLD + 100),
            ]
            self.assertEqual(discovered, expected)

    def test_build_section_formats_markdown(self) -> None:
        """build_section formats section header, description, and indexed entries."""
        with tempfile.TemporaryDirectory() as tmpdir:
            scripts_dir = Path(tmpdir)
            script_path = scripts_dir / "example.gd"
            content = (
                "# --- Setup ---\n"
                "func _ready() -> void:\n"
                "    pass\n"
            )
            script_path.write_text(content, encoding="utf-8")

            section = build_section("example.gd", 1234, "Test description.", scripts=scripts_dir)
            expected_header = "## example.gd (1,234 lines)\n\nTest description.\n\n```\n"
            self.assertTrue(section.startswith(expected_header))
            self.assertIn("1    # --- Setup ---", section)
            self.assertIn("2    func _ready() -> void", section)
            self.assertTrue(section.endswith("```\n"))

    def test_build_file_assembles_preamble_and_sections(self) -> None:
        """build_file concatenates preamble with formatted sections for all discovered files."""
        discovered = [("bee.gd", 2400)]
        output = build_file(discovered)
        self.assertTrue(output.startswith(PREAMBLE))
        self.assertIn("## bee.gd (2,400 lines)", output)

    def test_header_warnings_flags_missing_and_delayed_headers(self) -> None:
        """header_warnings reports files lacking section headers or with delayed headers."""
        with tempfile.TemporaryDirectory() as tmpdir:
            fake_scripts = Path(tmpdir)
            (fake_scripts / "no_headers.gd").write_text(
                "\n".join(["var x = 1"] * 100), encoding="utf-8"
            )

            # 100 lines total, cutoff = max(1, 100 // 10) = 10.
            # Header placed at line 20 (> 10) should trigger delayed warning.
            delayed_lines = ["# padding"] * 19 + ["# --- delayed section ---"] + ["var y = 2"] * 80
            (fake_scripts / "delayed.gd").write_text("\n".join(delayed_lines), encoding="utf-8")

            # Early header at line 2 (<= 10) should trigger no warning.
            early_lines = ["# line 1", "# --- early section ---"] + ["var z = 3"] * 98
            (fake_scripts / "early.gd").write_text("\n".join(early_lines), encoding="utf-8")

            discovered = [
                ("no_headers.gd", 100),
                ("delayed.gd", 100),
                ("early.gd", 100),
            ]
            with patch("tools.update_function_map.SCRIPTS", fake_scripts):
                warnings = header_warnings(discovered)

            self.assertEqual(len(warnings), 2)
            self.assertIn("no_headers.gd (100 lines) has no `# --- section ---` header at all", warnings[0])
            self.assertIn("delayed.gd (100 lines) has no `# --- section ---` header until line 20", warnings[1])


if __name__ == "__main__":
    unittest.main()
