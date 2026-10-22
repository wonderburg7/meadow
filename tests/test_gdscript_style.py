"""Tests for tools/gdscript_style.py: the gdlint stage of verify.ps1."""

import io
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import gdscript_style  # noqa: E402


class GdscriptStyleTest(unittest.TestCase):
    def test_missing_gdtoolkit_skips_with_one_line(self):
        out = io.StringIO()
        with mock.patch.object(gdscript_style, "gdtoolkit_installed", return_value=False), \
                redirect_stdout(out):
            code = gdscript_style.main()
        self.assertEqual(code, 0)
        self.assertEqual(len(out.getvalue().strip().splitlines()), 1)
        self.assertIn("skipped", out.getvalue())
        self.assertIn(gdscript_style.PINNED, out.getvalue())

    def test_addons_are_left_out(self):
        listing = "scripts/a.gd\naddons/x/plugin.gd\ntools/addons/y.gd\ntests/b.gd\n"
        done = subprocess.CompletedProcess([], 0, stdout=listing, stderr="")
        with mock.patch.object(gdscript_style.subprocess, "run", return_value=done):
            self.assertEqual(gdscript_style.tracked_gd_files(ROOT), ["scripts/a.gd", "tests/b.gd"])

    def test_a_problem_fails_and_a_clean_file_passes(self):
        if not gdscript_style.gdtoolkit_installed():
            self.skipTest("gdtoolkit is not installed")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "gdlintrc").write_text((ROOT / "gdlintrc").read_text(encoding="utf-8"), encoding="utf-8")
            (root / "clean.gd").write_text("extends Node\n\n\nfunc f() -> int:\n\treturn 1\n", encoding="utf-8")
            (root / "bad.gd").write_text(
                "extends Node\n\n\nfunc f(x: int) -> int:\n\tif x:\n\t\treturn 1\n\telse:\n\t\treturn 2\n",
                encoding="utf-8",
            )
            self.assertEqual(gdscript_style.lint(root, ["clean.gd"])[0], 0)
            code, output = gdscript_style.lint(root, ["bad.gd"])
            self.assertNotEqual(code, 0)
            self.assertIn("no-else-return", output)

    def test_repo_gdlintrc_has_daves_thresholds(self):
        text = (ROOT / "gdlintrc").read_text(encoding="utf-8")
        for needle in ("function-arguments-number: 7", "max-public-methods: 80", "max-returns: 12",
                       "- class-definitions-order", "- max-file-lines", "- max-line-length"):
            self.assertIn(needle, text)


if __name__ == "__main__":
    unittest.main()
