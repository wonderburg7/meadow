"""Unit tests for tools/overflow_discard_check.py.

Guards the 'A restriction that lives in the comment and not in the predicate'
pitfall from docs/known-pitfalls.md, verifying that Challenge 1 overflow discards
are restricted to designated stages in both definition and runner predicate.
"""

from io import StringIO
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools import overflow_discard_check

ROOT = Path(__file__).resolve().parent.parent


class TestOverflowDiscardCheck(unittest.TestCase):
    def test_repo_passes(self) -> None:
        """The master repo scripts/ must pass the overflow discard check cleanly."""
        problems = overflow_discard_check.check_repo()
        self.assertEqual(problems, [])

    def test_main_cli_success(self) -> None:
        """Invoking main() with default arguments prints OK and exits 0."""
        with patch("sys.stdout", new_callable=StringIO) as out, \
             patch("sys.stderr", new_callable=StringIO) as err:
            code = overflow_discard_check.main([])
            self.assertEqual(code, 0)
            self.assertIn("OK", out.getvalue())
            self.assertEqual(err.getvalue(), "")

    def test_mutation_missing_c1_discard_stages_constant(self) -> None:
        """Omitting C1_DISCARD_STAGES from challenge_stages.gd fails the check."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp = Path(tmp_dir)
            stages_file = tmp / "challenge_stages.gd"
            runner_file = tmp / "challenge_runner.gd"

            stages_file.write_text("extends RefCounted\n\nconst OTHER_CONST = 1\n", encoding="utf-8")
            runner_file.write_text(
                (ROOT / "scripts" / "challenge_runner.gd").read_text(encoding="utf-8"),
                encoding="utf-8",
            )

            problems = overflow_discard_check.check_repo(runner_path=runner_file, stages_path=stages_file)
            self.assertTrue(any("const C1_DISCARD_STAGES is not defined" in p for p in problems))

    def test_mutation_unauthorized_stages_in_constant(self) -> None:
        """Broadening C1_DISCARD_STAGES to other stages (e.g. ['1.12', '1.14']) fails."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp = Path(tmp_dir)
            stages_file = tmp / "challenge_stages.gd"
            runner_file = tmp / "challenge_runner.gd"

            stages_file.write_text('extends RefCounted\n\nconst C1_DISCARD_STAGES := ["1.12", "1.14"]\n', encoding="utf-8")
            runner_file.write_text(
                (ROOT / "scripts" / "challenge_runner.gd").read_text(encoding="utf-8"),
                encoding="utf-8",
            )

            problems = overflow_discard_check.check_repo(runner_path=runner_file, stages_path=stages_file)
            self.assertTrue(any("contains unauthorized stage '1.12'" in p for p in problems))

    def test_mutation_empty_stages_constant(self) -> None:
        """An empty C1_DISCARD_STAGES list fails the check."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp = Path(tmp_dir)
            stages_file = tmp / "challenge_stages.gd"
            runner_file = tmp / "challenge_runner.gd"

            stages_file.write_text('extends RefCounted\n\nconst C1_DISCARD_STAGES := []\n', encoding="utf-8")
            runner_file.write_text(
                (ROOT / "scripts" / "challenge_runner.gd").read_text(encoding="utf-8"),
                encoding="utf-8",
            )

            problems = overflow_discard_check.check_repo(runner_path=runner_file, stages_path=stages_file)
            self.assertTrue(any("C1_DISCARD_STAGES is empty" in p for p in problems))

    def test_mutation_missing_stage_in_discards_overflow_predicate(self) -> None:
        """The bug where discards_overflow checks bee and nectar but omits stage check."""
        buggy_runner = """
func discards_overflow(bee: Node2D) -> bool:
\treturn (
\t\tactive and Session.starting_level == 1
\t\tand is_instance_valid(main.queen) and bee == main.queen
\t\tand bee.current_load_type == "nectar"
\t)
"""
        problems = overflow_discard_check.check_discards_overflow_predicate(buggy_runner)
        self.assertTrue(any("must check C1_DISCARD_STAGES in predicate" in p for p in problems))

    def test_mutation_discards_overflow_missing_function(self) -> None:
        """If func discards_overflow is completely missing, report an error."""
        problems = overflow_discard_check.check_discards_overflow_predicate("extends Node2D\n")
        self.assertTrue(any("func discards_overflow(...) not found" in p for p in problems))

    def test_missing_files_reported(self) -> None:
        """Passing non-existent file paths to check_repo yields errors."""
        problems = overflow_discard_check.check_repo(
            runner_path=Path("nonexistent_runner.gd"),
            stages_path=Path("nonexistent_stages.gd"),
        )
        self.assertTrue(any("runner file not found" in p for p in problems))
        self.assertTrue(any("stages file not found" in p for p in problems))

    def test_main_cli_failure(self) -> None:
        """CLI returns exit code 1 when problems are detected."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp = Path(tmp_dir)
            runner_file = tmp / "challenge_runner.gd"
            stages_file = tmp / "challenge_stages.gd"
            runner_file.write_text("func discards_overflow(bee: Node2D) -> bool:\n\treturn true\n", encoding="utf-8")
            stages_file.write_text("const C1_DISCARD_STAGES := []\n", encoding="utf-8")

            with patch("sys.stderr", new_callable=StringIO) as err:
                code = overflow_discard_check.main(["--runner", str(runner_file), "--stages", str(stages_file)])
                self.assertEqual(code, 1)
                self.assertIn("FAILED", err.getvalue())


if __name__ == "__main__":
    unittest.main()
