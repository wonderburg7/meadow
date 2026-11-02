"""check_queue_items_fit_one_worker: a queued slice is one worker's size, and
a `high` level names a CLAUDE.md rule 4 reason."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import check_docs  # noqa: E402


def queue_text(files: list[str]) -> str:
    listed = ", ".join(f"`{name}`" for name in files)
    return (
        "## Next up\n\n### Claude lane\n\n"
        "1. **[Claude] X-1 -- fixture**\n"
        "   - Plan: `plans/now/fixture.md` -- \"X-1 -- fixture\"\n"
        f"   - Files: {listed}\n"
        "   - Check: deterministic\n"
        "   - Proof: `absent: scripts/a.gd :: nothing`\n"
        "   - Next after: none -- the fixture plan is complete\n\n"
        "## Not in the queue, and why\n\n- Nothing.\n"
    )


class QueueSizingTest(unittest.TestCase):
    def run_check(self, files: list[str], section: str) -> list[str]:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "plans" / "now").mkdir(parents=True)
            (root / "plans" / "now" / "fixture.md").write_text(
                f"# Fixture\n\n## X-1 -- fixture\n\n{section}\n", encoding="utf-8"
            )
            warnings: list[str] = []
            check_docs.check_queue_items_fit_one_worker(warnings, queue_text(files), root)
            return warnings

    def test_a_small_medium_slice_is_quiet(self):
        self.assertEqual([], self.run_check(["scripts/a.gd", "tests/t.py"], "Level: medium"))

    def test_more_files_than_the_budget_warns(self):
        files = [f"scripts/f{i}.gd" for i in range(check_docs.QUEUE_ITEM_FILE_BUDGET + 1)]
        warnings = self.run_check(files, "Level: medium")
        self.assertEqual(1, len(warnings))
        self.assertIn("X-1", warnings[0])
        self.assertIn("Split it", warnings[0])

    def test_exactly_the_budget_is_quiet(self):
        files = [f"scripts/f{i}.gd" for i in range(check_docs.QUEUE_ITEM_FILE_BUDGET)]
        self.assertEqual([], self.run_check(files, "Level: medium"))

    def test_fixture_files_do_not_count(self):
        files = [f"tests/fixtures/saves/s{i}.json" for i in range(check_docs.QUEUE_ITEM_FILE_BUDGET + 3)]
        self.assertEqual([], self.run_check(["scripts/a.gd"] + files, "Level: medium"))

    def test_high_with_a_rule_four_reason_is_quiet(self):
        self.assertEqual([], self.run_check(["scripts/a.gd"], "Level: high (save field, per-bee hot path)"))

    def test_high_for_a_gameplay_outcome_alone_warns(self):
        warnings = self.run_check(
            ["scripts/a.gd"], "Reasoning level high: these tools set how the arc measures."
        )
        self.assertEqual(1, len(warnings))
        self.assertIn("rule 4", warnings[0])

    def test_a_reason_on_the_next_line_counts(self):
        self.assertEqual(
            [], self.run_check(["scripts/a.gd"], "Level: high\nBecause it moves an ownership boundary.")
        )


if __name__ == "__main__":
    unittest.main()
