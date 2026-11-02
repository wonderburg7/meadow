"""Unit tests for tools/nearest_standing_check.py."""

from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

from tools.nearest_standing_check import (
    DEFAULT_TARGET,
    check_file,
    check_foraging_nearest_exclusions,
    extract_function_body,
    main,
)


class TestNearestStandingCheck(unittest.TestCase):
    def test_extract_function_body(self) -> None:
        source = (
            "static func helper() -> void:\n"
            "\tpass\n"
            "\n"
            "static func nearest_flower(bee: Node2D) -> Node2D:\n"
            "\t# comment\n"
            "\tvar x = 1\n"
            "\treturn null\n"
            "\n"
            "static func other() -> void:\n"
            "\tpass\n"
        )
        body = extract_function_body(source, "nearest_flower")
        self.assertIsNotNone(body)
        assert body is not None
        self.assertIn("var x = 1", body)
        self.assertNotIn("static func other", body)

    def test_repo_passes(self) -> None:
        """The repository's scripts/bee_foraging.gd must pass nearest_standing_check."""
        diagnostics = check_file(DEFAULT_TARGET)
        self.assertEqual(diagnostics, [])

    def test_mutation_missing_flower_cooldowns_fails(self) -> None:
        """Simulate removing flower_cooldowns from nearest_flower body."""
        real_text = DEFAULT_TARGET.read_text(encoding="utf-8")
        mutated_text = real_text.replace("flower_cooldowns", "unrelated_cooldowns")
        diagnostics = check_foraging_nearest_exclusions(mutated_text, "scripts/bee_foraging.gd")
        self.assertEqual(len(diagnostics), 1)
        self.assertIn("missing candidate cooldown exclusion 'flower_cooldowns'", diagnostics[0])

    def test_cli_main_success(self) -> None:
        buf = io.StringIO()
        with redirect_stdout(buf):
            code = main([str(DEFAULT_TARGET)])
        self.assertEqual(code, 0)
        self.assertIn("no missing exclusions found", buf.getvalue())

    def test_cli_main_failure(self) -> None:
        bad_text = (
            "static func nearest_flower(bee: Node2D) -> Node2D:\n"
            "\treturn null\n"
        )
        with tempfile.TemporaryDirectory() as tmpdir:
            bad_file = Path(tmpdir) / "bee_foraging.gd"
            bad_file.write_text(bad_text, encoding="utf-8")
            buf = io.StringIO()
            with redirect_stderr(buf):
                code = main([str(bad_file)])
            self.assertEqual(code, 1)
            self.assertIn("missing candidate cooldown exclusion 'flower_cooldowns'", buf.getvalue())

    def test_cli_missing_file(self) -> None:
        buf = io.StringIO()
        with redirect_stderr(buf):
            code = main(["nonexistent_file.gd"])
        self.assertEqual(code, 1)
        self.assertIn("file not found", buf.getvalue())


if __name__ == "__main__":
    unittest.main()
