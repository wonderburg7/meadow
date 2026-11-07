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

    # --- real-source mutations (jules-review-2026-11-07 F1) ---

    STAGE_LINE = "\t\tand _stages()[_stage_index].id in Stages.C1_DISCARD_STAGES\n"

    def _real(self, name: str) -> str:
        return (ROOT / "scripts" / name).read_text(encoding="utf-8")

    def _mutated_runner(self, old: str, new: str) -> list[str]:
        source = self._real("challenge_runner.gd")
        self.assertIn(old, source, "mutation target missing from the real runner")
        return overflow_discard_check.check_discards_overflow_predicate(source.replace(old, new, 1))

    def _mutated_stages(self, old: str, new: str) -> list[str]:
        source = self._real("challenge_stages.gd")
        self.assertIn(old, source, "mutation target missing from the real stages file")
        _, problems = overflow_discard_check.parse_stages_constant(source.replace(old, new, 1))
        return problems

    def test_real_runner_not_in_fails(self) -> None:
        problems = self._mutated_runner(
            ".id in Stages.C1_DISCARD_STAGES", ".id not in Stages.C1_DISCARD_STAGES"
        )
        self.assertTrue(any("as a conjunct" in p for p in problems), problems)

    def test_real_runner_or_true_fails(self) -> None:
        problems = self._mutated_runner(
            "Stages.C1_DISCARD_STAGES\n", "Stages.C1_DISCARD_STAGES or true\n"
        )
        self.assertTrue(any("top-level `or`" in p for p in problems), problems)

    def test_real_runner_nested_or_true_fails(self) -> None:
        problems = self._mutated_runner(
            "and _stages()[_stage_index].id in Stages.C1_DISCARD_STAGES\n",
            "and (_stages()[_stage_index].id in Stages.C1_DISCARD_STAGES or true)\n",
        )
        self.assertTrue(any("as a conjunct" in p for p in problems), problems)

    def test_real_runner_membership_in_unused_local_fails(self) -> None:
        source = self._real("challenge_runner.gd")
        mutated = source.replace(self.STAGE_LINE, "", 1).replace(
            "func discards_overflow(bee: Node2D) -> bool:\n",
            "func discards_overflow(bee: Node2D) -> bool:\n"
            "\tvar in_stage: bool = _stages()[_stage_index].id in Stages.C1_DISCARD_STAGES\n",
            1,
        )
        self.assertNotEqual(source, mutated)
        problems = overflow_discard_check.check_discards_overflow_predicate(mutated)
        self.assertTrue(any("single `return" in p for p in problems), problems)

    def test_real_runner_negated_predicate_fails(self) -> None:
        problems = self._mutated_runner("\treturn (\n\t\tactive", "\treturn not (\n\t\tactive")
        self.assertTrue(any("negates" in p for p in problems), problems)

    def test_real_runner_column_zero_comment_keeps_body(self) -> None:
        """A column-zero comment inside the function neither ends the body nor hides a mutation."""
        passing = self._mutated_runner(self.STAGE_LINE, "# note\n" + self.STAGE_LINE)
        self.assertEqual(passing, [])
        failing = self._mutated_runner(
            self.STAGE_LINE, "# note\n" + self.STAGE_LINE.replace(" in ", " not in ")
        )
        self.assertTrue(any("as a conjunct" in p for p in failing), failing)

    def test_real_stages_commented_constant_fails(self) -> None:
        problems = self._mutated_stages(
            'const C1_DISCARD_STAGES := ["1.14"]', '# const C1_DISCARD_STAGES := ["1.14"]'
        )
        self.assertTrue(any("is not defined" in p for p in problems), problems)

    def test_real_stages_duplicate_constant_fails(self) -> None:
        problems = self._mutated_stages(
            'const C1_DISCARD_STAGES := ["1.14"]',
            'const C1_DISCARD_STAGES := ["1.14"]\nconst C1_DISCARD_STAGES := ["1.12"]',
        )
        self.assertTrue(any("more than once" in p for p in problems), problems)

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
