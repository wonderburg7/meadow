"""check_queue_lookahead warns when closing a lane's first item strands it (L-24)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import backlog  # noqa: E402
import check_docs  # noqa: E402


def item(number: int, lane: str, slice_id: str, files: str) -> str:
    return (
        f"{number}. **[{lane}] {slice_id} -- title**\n"
        "   - Plan: `plans/now/x.md` -- \"t\"\n"
        f"   - Files: `{files}`\n"
        "   - Check: `true`\n"
        "   - Proof: `absent: tools/check_docs.py :: def zzz_never_defined`\n"
        "   - Next after: none -- x is complete\n"
    )


def nextsteps() -> str:
    return (
        "## Next up\n\n### Claude lane\n\n"
        + item(1, "Claude", "AA-1", "tools/a.py")
        + "\n### Codex lane\n\n"
        + item(2, "Codex", "BB-1", "tools/b.py")
        + item(3, "Codex", "BB-2", "tools/c.py")
        + item(4, "Codex", "BB-3", "tools/d.py")
        + "\n## Not in the queue, and why\n\n- none\n"
    )


def entry(slice_id: str, files: str) -> backlog.Entry:
    body = item(1, "Claude", slice_id, files).split(". ", 1)[1].rstrip("\n")
    return backlog.Entry("plans/now/x.md", 1, "Claude", slice_id, "title", body, False)


class QueueLookaheadTest(unittest.TestCase):
    def run_check(self, entries: list[backlog.Entry]) -> list[str]:
        warnings: list[str] = []
        check_docs.check_queue_lookahead(warnings, text=nextsteps(), root=ROOT, entries=entries)
        return warnings

    def test_one_item_lane_over_dry_backlog_warns(self) -> None:
        warnings = self.run_check([])
        self.assertEqual(len(warnings), 1)
        self.assertIn("closing AA-1 would leave the Claude lane short", warnings[0])

    def test_admissible_block_behind_it_does_not_warn(self) -> None:
        self.assertEqual(self.run_check([entry("AA-2", "tools/e.py")]), [])


if __name__ == "__main__":
    unittest.main()
