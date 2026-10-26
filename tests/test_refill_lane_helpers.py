"""Unit tests for the pure queue-text helper functions in tools/refill_lane.py."""

from __future__ import annotations

import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import backlog
import refill_lane

SAMPLE_QUEUE = """# Next steps

## Next up

### Claude lane

1. **[Claude] CL-1 -- first claude item**
   - Plan: `plans/now/test.md` -- "CL-1"
   - Files: `scripts/claude_one.gd`, `scripts/shared.gd`
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
   - Plan: `plans/now/test_codex.md` -- "CX-1"
   - Files: `scripts/codex_one.gd`
   - Check: `python -m unittest tests.test_codex` passes
   - Proof: `present: scripts/codex_one.gd :: func test`
   - Next after: none -- complete

## Not in the queue, and why

- **DEF-1** (`plans/now/test.md`) -- the Claude lane is full.
- **DEF-2** (`plans/now/test.md`) -- startable, but the Codex lane is full; extra note
- **DEF-3** (`plans/now/test.md`) -- waits for Dave to review
- **GAT-1** (`plans/now/gated.md`) -- waits for CL-1 to finish first.
"""


class TestRefillLaneHelpers(unittest.TestCase):
    def test_queued_ids(self) -> None:
        ids = refill_lane.queued_ids(SAMPLE_QUEUE)
        expected = [
            ("Claude", "CL-1"),
            ("Claude", "CL-2"),
            ("Codex", "CX-1"),
        ]
        self.assertEqual(ids, expected)

    def test_deferred_ids(self) -> None:
        deferred = refill_lane.deferred_ids(SAMPLE_QUEUE)
        self.assertEqual(deferred, {"DEF-1", "DEF-2", "DEF-3", "GAT-1"})

    def test_capacity_deferrals(self) -> None:
        only_claude, mixed_claude = refill_lane.capacity_deferrals(SAMPLE_QUEUE, "Claude")
        self.assertEqual(only_claude, {"DEF-1"})
        self.assertEqual(mixed_claude, set())

        only_codex, mixed_codex = refill_lane.capacity_deferrals(SAMPLE_QUEUE, "Codex")
        self.assertEqual(only_codex, set())
        self.assertEqual(mixed_codex, {"DEF-2"})

    def test_capacity_deferrals_skips_multi_id_bullets(self) -> None:
        text = SAMPLE_QUEUE.replace(
            "- **DEF-1** (`plans/now/test.md`)",
            "- **DEF-1, DEF-4** (`plans/now/test.md`)",
        )
        only, mixed = refill_lane.capacity_deferrals(text, "Claude")
        self.assertEqual((only, mixed), (set(), set()))

    def test_clear_deferral(self) -> None:
        line = "- **DEF-1** (`plans/now/test.md`) -- the Claude lane is full.\n"
        cleared = refill_lane.clear_deferral(SAMPLE_QUEUE, "DEF-1")
        self.assertEqual(cleared, SAMPLE_QUEUE.replace(line, ""))
        self.assertEqual(refill_lane.deferred_ids(cleared), {"DEF-2", "DEF-3", "GAT-1"})
        self.assertEqual(refill_lane.clear_deferral(SAMPLE_QUEUE, "MISSING-1"), SAMPLE_QUEUE)

    def test_lane_files(self) -> None:
        claude_files = refill_lane.lane_files(SAMPLE_QUEUE, "Claude")
        self.assertEqual(
            claude_files,
            {"scripts/claude_one.gd", "scripts/shared.gd", "scripts/claude_two.gd"},
        )
        codex_files = refill_lane.lane_files(SAMPLE_QUEUE, "Codex")
        self.assertEqual(codex_files, {"scripts/codex_one.gd"})

    def test_gated_reason(self) -> None:
        reason = refill_lane.gated_reason(SAMPLE_QUEUE, "GAT-1")
        self.assertEqual(reason, "waits for CL-1 to finish first.")

        missing_reason = refill_lane.gated_reason(SAMPLE_QUEUE, "MISSING-1")
        self.assertEqual(
            missing_reason,
            "no bullet under '## Not in the queue, and why' says what it waits for",
        )

    def test_append_item(self) -> None:
        entry_body = (
            "**[Claude] CL-3 -- third claude item**\n"
            "- Plan: `plans/now/test.md` -- \"CL-3\"\n"
            "- Files: `scripts/claude_three.gd`\n"
            "- Check: `python -m unittest tests.test_claude_three` passes\n"
            "- Proof: `present: scripts/claude_three.gd :: func test`\n"
            "- Next after: none -- complete"
        )
        entry = backlog.Entry(
            plan="plans/now/test.md",
            line=10,
            lane="Claude",
            slice_id="CL-3",
            title="third claude item",
            body=entry_body,
            gated=False,
        )

        appended = refill_lane.append_item(SAMPLE_QUEUE, entry)
        self.assertIn("3. **[Claude] CL-3 -- third claude item**", appended)
        self.assertEqual(
            refill_lane.queued_ids(appended),
            [
                ("Claude", "CL-1"),
                ("Claude", "CL-2"),
                ("Claude", "CL-3"),
                ("Codex", "CX-1"),
            ],
        )


if __name__ == "__main__":
    unittest.main()
