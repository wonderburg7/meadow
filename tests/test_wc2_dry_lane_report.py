"""WC-2: a dry lane identifies its missing deferral and possible borrowed work."""

import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import backlog  # noqa: E402
import check_docs  # noqa: E402
import refill_lane  # noqa: E402


class DryLaneReportTest(unittest.TestCase):
    def test_successor_and_borrowable_blocks(self):
        with tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parents[1]) as directory:
            root = Path(directory)
            (root / "plans").mkdir()
            queue = (
                "## Next up\n\n### Claude lane\n\n"
                "1. **[Claude] C-1 -- queued.**\n"
                "   - Files: `queued.py`\n"
                "   - Next after: none -- complete\n\n"
                "### Codex lane\n\n"
                "1. **[Codex] X-1 -- closing.**\n"
                "   - Files: `closing.py`\n"
                "   - Next after: X-2 -- next slice\n\n"
                "2. **[Codex] X-3 -- retained.**\n"
                "   - Files: `owned.py`\n"
                "   - Next after: none -- complete\n\n"
                "## Not in the queue, and why\n\n"
                "- **D-1** -- waits for review.\n"
            )
            specs = [
                ("B-1", "medium", "borrow.py", "absent", False),
                ("H-1", "high", "high.py", "absent", False),
                ("G-1", "low", "gated.py", "absent", True),
                ("O-1", "low", "owned.py", "absent", False),
                ("D-1", "low", "deferred.py", "absent", False),
                ("P-1", "low", "present.py", "absent", False),
                ("C-1", "low", "queued.py", "absent", False),
            ]
            plans = []
            for slice_id, level, path, proof, gated in specs:
                plan = root / "plans" / f"{slice_id}.md"
                plan.write_text(
                    f"## {slice_id} -- example\n\n"
                    f"{'**Level:**' if slice_id == 'B-1' else 'Level:'} {level}\n\n"
                    f"```queue{'-gated' if gated else ''}\n"
                    f"**[Claude] {slice_id} -- example**\n"
                    f"- Plan: `plans/{slice_id}.md` -- example\n"
                    f"- Files: `{path}`\n- Check: example\n"
                    f"- Proof: `{proof}: {path} :: marker`\n"
                    "- Next after: none -- complete\n```\n",
                    encoding="utf-8",
                )
                plans.append(plan)
            for _, _, path, _, _ in specs:
                (root / path).write_text("marker\n" if path == "present.py" else "",
                                         encoding="utf-8")
            entries, errors = backlog.collect(plans, root)
            self.assertEqual([], errors)
            report = refill_lane.dry_after_report(queue, "Codex", "X-1", root, entries)
            self.assertEqual("X-2", report["successor"])
            self.assertFalse(report["successor_deferred"])
            self.assertEqual([{"id": "B-1", "plan": "plans/B-1.md", "level": "medium"}],
                             report["borrowable"])
            self.assertTrue(report["dry_after"])
            self.assertEqual([], report["would_add"])
            self.assertEqual([], report["gated"])
            self.assertEqual(1, report["lane_after"])
            self.assertEqual(2, report["queue_after"])
            warnings = []
            check_docs.check_queue_lookahead(warnings, queue, root, entries)
            self.assertTrue(any("X-2 is neither queued nor deferred" in warning and
                                "B-1 (medium" in warning and
                                "Dave reassigns it" in warning for warning in warnings))
            log = []
            refill_lane.top_up(refill_lane.delete_item(queue, "X-1"), "Codex", root,
                               ["X-2"], entries, log, closed={"X-1"})
            self.assertTrue(any("X-2 is neither queued nor deferred" in line for line in log))
            self.assertTrue(any("B-1 (medium" in line and "Dave reassigns it" in line
                                for line in log))
            deferred_queue = queue.replace(
                "- **D-1** -- waits for review.\n",
                "- **D-1** -- waits for review.\n- **X-2** -- waits for review.\n",
            )
            deferred = refill_lane.dry_after_report(
                deferred_queue, "Codex", "X-1", root, entries)
            self.assertTrue(deferred["successor_deferred"])

    def test_malformed_block_proof_is_named_not_called_built(self):
        # FR-1b's `contains:` proof was refused as "may already be built" and
        # passed check_docs, so AR-5's finish found the Codex lane dry.
        with tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parents[1]) as directory:
            root = Path(directory)
            (root / "plans").mkdir()
            (root / "target.py").write_text("marker\n", encoding="utf-8")
            plan = root / "plans" / "M-1.md"
            plan.write_text(
                "## M-1 -- example\n\n```queue\n"
                "**[Codex] M-1 -- example**\n"
                "- Plan: `plans/M-1.md` -- example\n"
                "- Files: `target.py`\n- Check: example\n"
                "- Proof: `contains: target.py :: marker`\n"
                "- Next after: none -- complete\n```\n",
                encoding="utf-8",
            )
            entries, problems = backlog.collect([plan], root)
            self.assertEqual([], problems)
            queue = "## Next up\n\n### Claude lane\n\n### Codex lane\n\n"
            reason = refill_lane.rejection(entries[0], queue, root)
            self.assertIn("must start with 'present:' or 'absent:'", reason)
            self.assertNotIn("already be built", reason)
            errors, warnings = [], []
            check_docs.check_plan_queue_blocks(errors, warnings, queue, root, entries)
            self.assertTrue(any("M-1's queue block" in error and "contains:" in error
                                for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
