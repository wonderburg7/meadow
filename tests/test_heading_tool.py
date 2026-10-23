"""Unit tests for tools/heading.py.

Tests cover:
- Parsing ATX headings while skipping fenced blocks
- Section bounds ending at same-or-shallower level headings
- Case-insensitive substring matching
- Multiple heading matches (note on stderr)
- No heading matches (list of available headings on stderr, exit status 1)
- Missing file error handling
"""

import io
import tempfile
import unittest
from unittest.mock import patch

from tools import heading


class TestHeadingToolFunctions(unittest.TestCase):
    def test_headings_parsing_and_fenced_blocks(self) -> None:
        lines = [
            "# Title",
            "Intro paragraph",
            "## Subtitle A",
            "```gdscript",
            "## GDScript comment inside code block",
            "```",
            "### Subtitle B",
        ]
        parsed = heading.headings(lines)
        self.assertEqual(len(parsed), 3)
        self.assertEqual(parsed[0], (0, 1, "Title"))
        self.assertEqual(parsed[1], (2, 2, "Subtitle A"))
        self.assertEqual(parsed[2], (6, 3, "Subtitle B"))

    def test_section_bounds(self) -> None:
        lines = [
            "# Title",
            "## Subtitle A",
            "Content A",
            "### Subtitle A.1",
            "Content A.1",
            "## Subtitle B",
            "Content B",
        ]
        parsed = heading.headings(lines)
        # Extract section for Subtitle A (index 1, level 2)
        sec = heading.section(lines, 1, 2, parsed)
        self.assertEqual(sec, [
            "## Subtitle A",
            "Content A",
            "### Subtitle A.1",
            "Content A.1",
        ])


class TestHeadingToolCLI(unittest.TestCase):
    def test_main_case_insensitive_match(self) -> None:
        content = (
            "# Main Heading\n"
            "\n"
            "## Section One\n"
            "Details about section one.\n"
            "\n"
            "## Section Two\n"
            "Details about section two.\n"
        )
        with tempfile.NamedTemporaryFile("w+", suffix=".md", delete=False, encoding="utf-8") as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        try:
            with patch("sys.argv", ["tools/heading.py", tmp_path, "section one"]):
                with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout, \
                     patch("sys.stderr", new_callable=io.StringIO) as mock_stderr:
                    mock_stdout.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    mock_stderr.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    exit_code = heading.main()
                    self.assertEqual(exit_code, 0)
                    output = mock_stdout.getvalue()
                    self.assertIn("## Section One", output)
                    self.assertIn("Details about section one.", output)
                    self.assertNotIn("## Section Two", output)
        finally:
            import os
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def test_main_multiple_matches(self) -> None:
        content = (
            "# Main Heading\n"
            "## Alpha Section\n"
            "Content A\n"
            "## Alpha Sub-section\n"
            "Content B\n"
        )
        with tempfile.NamedTemporaryFile("w+", suffix=".md", delete=False, encoding="utf-8") as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        try:
            with patch("sys.argv", ["tools/heading.py", tmp_path, "Alpha"]):
                with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout, \
                     patch("sys.stderr", new_callable=io.StringIO) as mock_stderr:
                    mock_stdout.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    mock_stderr.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    exit_code = heading.main()
                    self.assertEqual(exit_code, 0)
                    err_output = mock_stderr.getvalue()
                    self.assertIn("Note: 2 headings matched", err_output)
                    self.assertIn("'Alpha Sub-section'", err_output)
        finally:
            import os
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def test_main_no_match(self) -> None:
        content = (
            "# Main Heading\n"
            "## Section A\n"
        )
        with tempfile.NamedTemporaryFile("w+", suffix=".md", delete=False, encoding="utf-8") as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        try:
            with patch("sys.argv", ["tools/heading.py", tmp_path, "Nonexistent"]):
                with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout, \
                     patch("sys.stderr", new_callable=io.StringIO) as mock_stderr:
                    mock_stdout.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    mock_stderr.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    exit_code = heading.main()
                    self.assertEqual(exit_code, 1)
                    err_output = mock_stderr.getvalue()
                    self.assertIn("no heading matches 'Nonexistent'", err_output)
                    self.assertIn("Headings are:", err_output)
                    self.assertIn("# Main Heading", err_output)
                    self.assertIn("## Section A", err_output)
        finally:
            import os
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def test_main_missing_file(self) -> None:
        with patch("sys.argv", ["tools/heading.py", "nonexistent_file_999.md", "Title"]):
            with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout, \
                 patch("sys.stderr", new_callable=io.StringIO) as mock_stderr:
                mock_stdout.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                mock_stderr.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                exit_code = heading.main()
                self.assertEqual(exit_code, 1)
                err_output = mock_stderr.getvalue()
                self.assertIn("nonexistent_file_999.md:", err_output)


if __name__ == "__main__":
    unittest.main()
