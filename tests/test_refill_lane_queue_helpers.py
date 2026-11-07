"""Unit tests for queue parsing, rebuilding, and review formatting helpers in tools/refill_lane.py."""

from __future__ import annotations

import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import admission
import backlog
import refill_lane

ROOT = Path(__file__).resolve().parent.parent

SAMPLE_QUEUE = """# Next steps

## Next up

### Claude lane

1. **[Claude] CL-1 -- first claude item**
   - Plan: `plans/now/test.md` -- "CL-1"
   - Files: `scripts/claude_one.gd`
   - Check: `python -m unittest tests.test_claude` passes
   - Proof: `present: scripts/claude_one.gd :: func test`
   - Next after: CL-2 -- second claude item

2. **[Claude] CL-2 -- second claude item**
   - Plan: `plans/now/test.md` -- "CL-2"
   - Files: `scripts/claude_two.gd`
   - Check: `python -m unittest tests.test_claude_two` passes
   - Proof: `present: scripts/claude_two.gd :: func test`
   - Next after: none -- complete

### Codex lane

1. **[Codex] CX-1 -- first codex item**
   - Plan: `plans/now/test.md` -- "CX-1"
   - Files: `scripts/codex_one.gd`
   - Check: `python -m unittest tests.test_codex` passes
   - Proof: `present: scripts/codex_one.gd :: func test`
   - Next after: none -- complete

## Not in the queue, and why

- **GAT-1** (`plans/now/test.md`) -- waits for CL-1 to finish first.
- **GAT-HUMAN** (`plans/now/test.md`) -- waiting on Dave to review the design pass.
"""


class TestRefillLaneQueueHelpers(unittest.TestCase):
    def test_sections(self) -> None:
        before, lanes, after = refill_lane._sections(SAMPLE_QUEUE)
        self.assertEqual(before, "# Next steps\n\n## Next up\n")
        self.assertEqual(len(lanes), 3)
        self.assertEqual(lanes[0], "\n")
        self.assertTrue(lanes[1].startswith("### Claude lane\n\n"))
        self.assertTrue(lanes[2].startswith("### Codex lane\n\n"))
        self.assertTrue(after.startswith("## Not in the queue, and why"))

    def test_sections_missing_heading_raises(self) -> None:
        with self.assertRaises(SystemExit) as ctx:
            refill_lane._sections("# Next steps\n\nNo next up section here.")
        self.assertIn("missing a '## Next up' section", str(ctx.exception))

    def test_lane_of(self) -> None:
        self.assertEqual(refill_lane._lane_of("### Claude lane\n\n1. item"), "Claude")
        self.assertEqual(refill_lane._lane_of("### Codex lane\n\n1. item"), "Codex")
        self.assertIsNone(refill_lane._lane_of("\n"))
        self.assertIsNone(refill_lane._lane_of("## Next up\n"))

    def test_items(self) -> None:
        _, lanes, _ = refill_lane._sections(SAMPLE_QUEUE)
        preamble, items = refill_lane._items(lanes[1])
        self.assertEqual(preamble, "### Claude lane\n\n")
        self.assertEqual(len(items), 2)
        self.assertTrue(items[0].startswith("1. **[Claude] CL-1 -- first claude item**"))
        self.assertTrue(items[1].startswith("2. **[Claude] CL-2 -- second claude item**"))

    def test_rebuild(self) -> None:
        preamble = "### Claude lane\n\n"
        items = [
            "5. **[Claude] CL-1 -- first**\n   - Plan: p\n",
            "9. **[Claude] CL-2 -- second**\n   - Plan: p\n",
        ]
        rebuilt = refill_lane._rebuild(preamble, items)
        self.assertEqual(
            rebuilt,
            "### Claude lane\n\n"
            "1. **[Claude] CL-1 -- first**\n   - Plan: p\n\n"
            "2. **[Claude] CL-2 -- second**\n   - Plan: p\n\n",
        )

    def test_dry_lane_advice(self) -> None:
        report = {
            "successor": "CL-3",
            "successor_deferred": False,
            "lane": "Claude",
            "borrowable": [
                {"id": "CX-2", "level": "low", "plan": "plans/now/borrow.md"}
            ],
        }
        advice = refill_lane.dry_lane_advice(report, queued={"CL-1"})
        self.assertEqual(len(advice), 2)
        self.assertIn("CL-3 is neither queued nor deferred", advice[0])
        self.assertIn("the Codex backlog holds CX-2", advice[1])

        # If successor is already queued, advice on successor is omitted
        advice_already_queued = refill_lane.dry_lane_advice(report, queued={"CL-1", "CL-3"})
        self.assertEqual(len(advice_already_queued), 1)
        self.assertIn("the Codex backlog holds CX-2", advice_already_queued[0])

    def test_gate_review_lines(self) -> None:
        entry_blocked = backlog.Entry(
            "plans/now/test.md", 1, "Claude", "GAT-1", "title", "body", True
        )
        entry_admissible = backlog.Entry(
            "plans/now/test.md", 2, "Claude", "GAT-2", "title", "body", True
        )
        entry_other_admissible = backlog.Entry(
            "plans/now/test.md", 3, "Codex", "GAT-3", "title", "body", True
        )
        entry_human = backlog.Entry(
            "plans/now/test.md", 4, "Claude", "GAT-HUMAN", "title", "body", True
        )

        review = [
            (entry_blocked, admission.Verdict("GAT-1", reasons=["file owned elsewhere"])),
            (entry_admissible, admission.Verdict("GAT-2", reasons=[])),
            (entry_other_admissible, admission.Verdict("GAT-3", reasons=[])),
            (entry_human, admission.Verdict("GAT-HUMAN", reasons=[])),
        ]

        lines = refill_lane.gate_review_lines(SAMPLE_QUEUE, "Claude", review)
        self.assertIn("gated: GAT-1 (plans/now/test.md) -- waits for CL-1 to finish first.", lines)
        self.assertIn("  now: still blocked: file owned elsewhere", lines)
        self.assertIn("gated: GAT-2 (plans/now/test.md) -- no bullet under '## Not in the queue, and why' says what it waits for", lines)
        self.assertTrue(any("open its fence" in line for line in lines))
        self.assertIn("the Codex backlog's gated GAT-3 (plans/now/test.md) -- no bullet under '## Not in the queue, and why' says what it waits for", lines)
        self.assertTrue(any("retag [Codex] -> [Claude]" in line for line in lines))
        self.assertTrue(any("waits on Dave, a check or a design pass" in line for line in lines))

    def test_dry_lane_warnings(self) -> None:
        short_queue = """# Next steps

## Next up

### Claude lane

1. **[Claude] CL-1 -- first**
   - Plan: `plans/now/test.md` -- "CL-1"
   - Files: `scripts/bee.gd`
   - Check: `python -m unittest tests.test_bee` passes
   - Proof: `present: scripts/bee.gd :: func test`
   - Next after: none -- complete

### Codex lane

## Not in the queue, and why
"""
        warnings = refill_lane.dry_lane_warnings(short_queue, ROOT)
        self.assertTrue(any("under the floor" in w for w in warnings))
        self.assertTrue(any("no [Codex] item" in w for w in warnings))


if __name__ == "__main__":
    unittest.main()
