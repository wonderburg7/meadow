"""WC-4: queue IDs cannot contain whitespace."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import backlog  # noqa: E402
import check_docs  # noqa: E402


def item(slice_id: str) -> str:
    return (
        f"**[Codex] {slice_id} -- validates queue IDs**\n"
        "- Plan: `plans/now/workflow-checks.md`\n"
        "- Files: `tools/check_docs.py`\n"
        "- Check: `python -m unittest`\n"
        "- Proof: `absent: tools/check_docs.py :: impossible`\n"
        "- Next after: none -- plan is complete\n"
    )


class SpacedQueueIdTests(unittest.TestCase):
    def test_nextsteps_item_with_spaced_id_is_rejected(self) -> None:
        text = "## Next up\n\n### Codex lane\n\n1. " + item("WC 4")
        errors: list[str] = []

        check_docs.check_next_steps(errors, [], text)

        self.assertTrue(any("id contains whitespace" in error for error in errors), errors)
        self.assertTrue(any("WC 4" in error for error in errors), errors)

    def test_plan_queue_blocks_with_spaced_id_are_rejected(self) -> None:
        for fence in ("queue", "queue-gated"):
            with self.subTest(fence=fence):
                _, problems = backlog.parse_blocks(
                    f"```{fence}\n" + item("WC 4") + "```\n", "plans/now/test.md"
                )

                self.assertEqual(1, len(problems))
                self.assertIn("id contains whitespace", problems[0])
                self.assertIn("plans/now/test.md", problems[0])

    def test_hyphenated_id_is_accepted_in_both_places(self) -> None:
        _, problems = backlog.parse_blocks("```queue\n" + item("WC-4") + "```\n", "plans/now/test.md")
        errors: list[str] = []

        check_docs.check_next_steps(errors, [], "## Next up\n\n### Codex lane\n\n1. " + item("WC-4"))

        self.assertEqual([], problems)
        self.assertFalse(any("id contains whitespace" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
