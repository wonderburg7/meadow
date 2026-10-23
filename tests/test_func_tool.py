"""Unit tests for tools/func.py.

Tests cover:
- Extracting a single function (with doc comments, static func, section headers)
- Extracting multiple functions in a single invocation
- Missing function name handling and exit status
- Missing file error handling and exit status
"""

import io
import tempfile
import unittest
from unittest.mock import patch

from tools import func


class TestFuncToolExtract(unittest.TestCase):
    def test_extract_basic_function(self) -> None:
        lines = [
            "extends Node",
            "",
            "func foo() -> void:",
            "\tpass",
            "",
            "func bar() -> void:",
            "\tpass",
        ]
        span = func.extract(lines, "foo")
        self.assertIsNotNone(span)
        start, end = span  # type: ignore[misc]
        self.assertEqual(lines[start:end], ["func foo() -> void:", "\tpass"])

    def test_extract_with_doc_comment(self) -> None:
        lines = [
            "## This is a doc comment for foo",
            "# Additional line comment",
            "func foo() -> void:",
            "\tpass",
        ]
        span = func.extract(lines, "foo")
        self.assertIsNotNone(span)
        start, end = span  # type: ignore[misc]
        self.assertEqual(start, 0)
        self.assertEqual(end, 4)

    def test_extract_static_func(self) -> None:
        lines = [
            "static func my_static_method(x: int) -> int:",
            "\treturn x * 2",
        ]
        span = func.extract(lines, "my_static_method")
        self.assertIsNotNone(span)
        start, end = span  # type: ignore[misc]
        self.assertEqual(start, 0)
        self.assertEqual(end, 2)

    def test_extract_stopped_by_section_header(self) -> None:
        lines = [
            "# --- SECTION ---",
            "## Comment for foo",
            "func foo() -> void:",
            "\tpass",
            "# --- NEXT SECTION ---",
            "func bar() -> void:",
            "\tpass",
        ]
        span = func.extract(lines, "foo")
        self.assertIsNotNone(span)
        start, end = span  # type: ignore[misc]
        self.assertEqual(lines[start:end], ["## Comment for foo", "func foo() -> void:", "\tpass"])

    def test_extract_nonexistent_function(self) -> None:
        lines = [
            "func foo() -> void:",
            "\tpass",
        ]
        self.assertIsNone(func.extract(lines, "missing_func"))


class TestFuncToolCLI(unittest.TestCase):
    def test_main_single_func(self) -> None:
        content = (
            "## Doc comment for foo\n"
            "func foo() -> void:\n"
            "    print('foo')\n"
            "\n"
            "func bar() -> void:\n"
            "    print('bar')\n"
        )
        with tempfile.NamedTemporaryFile("w+", suffix=".gd", delete=False, encoding="utf-8") as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        try:
            with patch("sys.argv", ["tools/func.py", tmp_path, "foo"]):
                with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout, \
                     patch("sys.stderr", new_callable=io.StringIO) as mock_stderr:
                    mock_stdout.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    mock_stderr.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    exit_code = func.main()
                    self.assertEqual(exit_code, 0)
                    output = mock_stdout.getvalue()
                    self.assertIn("## Doc comment for foo", output)
                    self.assertIn("func foo() -> void:", output)
                    self.assertNotIn("func bar() -> void:", output)
        finally:
            import os
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def test_main_multiple_funcs(self) -> None:
        content = (
            "func foo() -> void:\n"
            "    pass\n"
            "\n"
            "static func bar() -> void:\n"
            "    pass\n"
        )
        with tempfile.NamedTemporaryFile("w+", suffix=".gd", delete=False, encoding="utf-8") as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        try:
            with patch("sys.argv", ["tools/func.py", tmp_path, "foo", "bar"]):
                with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout, \
                     patch("sys.stderr", new_callable=io.StringIO) as mock_stderr:
                    mock_stdout.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    mock_stderr.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    exit_code = func.main()
                    self.assertEqual(exit_code, 0)
                    output = mock_stdout.getvalue()
                    self.assertIn("func foo() -> void:", output)
                    self.assertIn("static func bar() -> void:", output)
        finally:
            import os
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def test_main_missing_func(self) -> None:
        content = "func foo() -> void:\n    pass\n"
        with tempfile.NamedTemporaryFile("w+", suffix=".gd", delete=False, encoding="utf-8") as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        try:
            with patch("sys.argv", ["tools/func.py", tmp_path, "nonexistent"]):
                with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout, \
                     patch("sys.stderr", new_callable=io.StringIO) as mock_stderr:
                    mock_stdout.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    mock_stderr.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                    exit_code = func.main()
                    self.assertEqual(exit_code, 1)
                    err_output = mock_stderr.getvalue()
                    self.assertIn("has no function named 'nonexistent'", err_output)
        finally:
            import os
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def test_main_missing_file(self) -> None:
        with patch("sys.argv", ["tools/func.py", "nonexistent_file_12345.gd", "foo"]):
            with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout, \
                 patch("sys.stderr", new_callable=io.StringIO) as mock_stderr:
                mock_stdout.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                mock_stderr.reconfigure = lambda **kwargs: None  # type: ignore[attr-defined]
                exit_code = func.main()
                self.assertEqual(exit_code, 1)
                err_output = mock_stderr.getvalue()
                self.assertIn("error: no such file", err_output)


if __name__ == "__main__":
    unittest.main()
