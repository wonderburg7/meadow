"""tools/check_docs.py check_rule_globs: every path-scoped rule must load (AC-1)."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "tools"))

import check_docs  # noqa: E402


def rule_text(globs: list[str], body_lines: int = 3) -> str:
    front = ["---", "paths:"] + [f'  - "{glob}"' for glob in globs] + ["---"]
    body = [f"Rule body line {n}." for n in range(body_lines)]
    return "\n".join(front + body) + "\n"


class RuleGlobsTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)
        (self.root / "scripts").mkdir()
        (self.root / "scripts" / "bee.gd").write_text("", encoding="utf-8")
        (self.root / ".claude" / "rules").mkdir(parents=True)
        self._saved_root = check_docs.ROOT
        check_docs.ROOT = self.root
        self.addCleanup(self._restore_root)

    def _restore_root(self) -> None:
        check_docs.ROOT = self._saved_root

    def write_rule(self, name: str, text: str) -> None:
        (self.root / ".claude" / "rules" / name).write_text(text, encoding="utf-8")

    def run_check(self) -> tuple[list[str], list[str]]:
        errors: list[str] = []
        warnings: list[str] = []
        check_docs.check_rule_globs(errors, warnings)
        return errors, warnings

    def test_rule_whose_glob_matches_a_file_passes(self) -> None:
        self.write_rule("bees.md", rule_text(["scripts/bee*.gd"]))
        errors, warnings = self.run_check()
        self.assertEqual(errors, [])
        self.assertEqual(warnings, [])

    def test_dead_glob_is_an_error_naming_the_rule_and_glob(self) -> None:
        self.write_rule("hives.md", rule_text(["scripts/hive*.gd"]))
        errors, _ = self.run_check()
        self.assertEqual(len(errors), 1)
        self.assertIn("hives.md", errors[0])
        self.assertIn("scripts/hive*.gd", errors[0])

    def test_missing_front_matter_is_an_error(self) -> None:
        self.write_rule("bare.md", "# No front matter here\n\nBody.\n")
        errors, _ = self.run_check()
        self.assertEqual(len(errors), 1)
        self.assertIn("bare.md", errors[0])
        self.assertIn("front matter", errors[0])

    def test_front_matter_without_paths_is_an_error(self) -> None:
        self.write_rule("nopaths.md", "---\ndescription: x\n---\nBody.\n")
        errors, _ = self.run_check()
        self.assertEqual(len(errors), 1)
        self.assertIn("paths:", errors[0])

    def test_rule_over_100_lines_warns(self) -> None:
        text = rule_text(["scripts/bee*.gd"])
        long_text = text + "".join(f"Line {n}.\n" for n in range(101 - len(text.splitlines())))
        self.assertEqual(len(long_text.splitlines()), 101)
        self.write_rule("long.md", long_text)
        errors, warnings = self.run_check()
        self.assertEqual(errors, [])
        self.assertEqual(len(warnings), 1)
        self.assertIn("long.md", warnings[0])
        self.assertIn("101", warnings[0])

    def test_real_repository_rules_are_clean(self) -> None:
        check_docs.ROOT = REPO_ROOT
        errors, _ = self.run_check()
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
