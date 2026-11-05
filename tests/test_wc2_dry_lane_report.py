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
                # Shares a file with the Claude lane's queue: moving it to
                # Codex would put one file in both lanes.
                ("S-1", "low", "queued.py", "absent", False),
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
                                "may take: retag its block [Claude] -> [Codex]" in warning
                                for warning in warnings))
            log = []
            refill_lane.top_up(refill_lane.delete_item(queue, "X-1"), "Codex", root,
                               ["X-2"], entries, log, closed={"X-1"})
            self.assertTrue(any("X-2 is neither queued nor deferred" in line for line in log))
            self.assertTrue(any("B-1 (medium" in line and "retag its block" in line
                                for line in log))
            deferred_queue = queue.replace(
                "- **D-1** -- waits for review.\n",
                "- **D-1** -- waits for review.\n- **X-2** -- waits for review.\n",
            )
            deferred = refill_lane.dry_after_report(
                deferred_queue, "Codex", "X-1", root, entries)
            self.assertTrue(deferred["successor_deferred"])

    def write_block(self, root, slice_id, lane, path, *, gated=False, level_row="",
                    next_after="none -- complete"):
        plan = root / "plans" / f"{slice_id}.md"
        plan.write_text(
            f"## {slice_id} -- example\n\n{level_row}\n\n**Open decisions:** none.\n\n"
            f"```queue{'-gated' if gated else ''}\n"
            f"**[{lane}] {slice_id} -- example**\n"
            f"- Plan: `plans/{slice_id}.md` -- \"{slice_id} -- example\"\n"
            f"- Files: `{path}`\n- Check: example\n"
            f"- Proof: `absent: {path} :: marker`\n"
            f"- Next after: {next_after}\n```\n",
            encoding="utf-8",
        )
        (root / path).write_text("", encoding="utf-8")
        return plan

    def test_a_model_in_the_level_cell_and_the_other_lanes_successor(self):
        # 5 Nov 2026: "low / haiku" hid every play-notes slice from borrowing,
        # and nothing stopped a lane borrowing the slice the other lane names next.
        with tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parents[1]) as directory:
            root = Path(directory)
            (root / "plans").mkdir()
            queue = (
                "## Next up\n\n### Claude lane\n\n"
                "1. **[Claude] C-1 -- queued.**\n"
                "   - Files: `queued.py`\n"
                "   - Next after: N-1 -- planned next\n\n"
                "### Codex lane\n\n"
                "## Not in the queue, and why\n\n"
            )
            plans = [
                self.write_block(root, "B-2", "Claude", "free.py",
                                 level_row="| B-2 | outcome | `free.py` | yes | low / haiku |"),
                self.write_block(root, "N-1", "Claude", "next.py", level_row="Level: low"),
                self.write_block(root, "S-2", "Claude", "next.py", level_row="Level: low"),
            ]
            entries, errors = backlog.collect(plans, root)
            self.assertEqual([], errors)
            self.assertEqual("low", refill_lane._entry_level(entries[0], root))
            # check_docs reads the same cell for a queued item's advice.
            (root / "NEXTSTEPS.md").write_text(
                "## Next up\n\n### Claude lane\n\n1. " + entries[0].body.replace("\n", "\n   ")
                + "\n\n### Codex lane\n\n## Not in the queue, and why\n", encoding="utf-8")
            (root / "plans" / "B-2.md").write_text(
                (root / "plans" / "B-2.md").read_text(encoding="utf-8").replace(
                    "## B-2 -- example", "## B-2 -- example\n"), encoding="utf-8")
            saved_root, check_docs.ROOT = check_docs.ROOT, root
            try:
                level_warnings = []
                check_docs.check_queue_items_state_a_level(level_warnings)
            finally:
                check_docs.ROOT = saved_root
            self.assertEqual([], level_warnings)
            self.assertEqual({"N-1"}, refill_lane.successor_ids(queue, "Claude"))
            self.assertEqual(["B-2"], [b["id"] for b in
                                       refill_lane.borrowable_blocks(queue, "Codex", root, entries)])

    def test_the_gate_review_rereads_every_recorded_gate(self):
        # 5 Nov 2026: the Codex lane sat empty behind gates naming Jules
        # branches that had closed or changed none of the gated files; the
        # refill printed each recorded reason as if it still held.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "plans").mkdir()
            queue = (
                "## Next up\n\n### Claude lane\n\n"
                "1. **[Claude] C-1 -- queued.**\n"
                "   - Plan: `plans/C-1.md` -- \"C-1 -- example\"\n"
                "   - Files: `queued.py`\n"
                "   - Check: example\n"
                "   - Proof: `absent: queued.py :: marker`\n"
                "   - Next after: none -- complete\n\n"
                "### Codex lane\n\n"
                "## Not in the queue, and why\n\n"
                "- **G-1** (`plans/G-1.md`) -- waits for the unmerged Jules S-3 branch.\n"
                "- **G-2** (`plans/G-2.md`) -- waits for the Claude lane to release queued.py.\n"
                "- **H-1** (`plans/H-1.md`) -- waits for Dave to redraw the art.\n"
                "- **K-1** (`plans/K-1.md`) -- waits for the Jules E-14 branch.\n"
            )
            (root / "queued.py").write_text("", encoding="utf-8")
            plans = [
                self.write_block(root, "G-1", "Codex", "g1.py", gated=True),
                self.write_block(root, "G-2", "Codex", "queued.py", gated=True),
                self.write_block(root, "H-1", "Claude", "h1.py", gated=True, level_row="Level: low"),
                self.write_block(root, "K-1", "Claude", "k1.py", gated=True, level_row="Level: medium"),
                self.write_block(root, "X-1", "Claude", "x1.py", gated=True, level_row="Level: high"),
            ]
            entries, errors = backlog.collect(plans, root)
            self.assertEqual([], errors)
            log = []
            refill_lane.top_up(queue, "Codex", root, [], entries, log, review_gates=True)
            text = "\n".join(log)
            g1 = text.split("gated: G-1", 1)[1].split("\n", 2)[1]
            self.assertIn("now: no blocker found", g1)
            g2 = text.split("gated: G-2", 1)[1].split("\n", 2)[1]
            self.assertIn("now: still blocked: the Claude lane's C-1 owns queued.py", g2)
            h1 = text.split("gated H-1", 1)[1].split("\n", 2)[1]
            self.assertIn("waits on Dave", h1)
            k1 = text.split("gated K-1", 1)[1].split("\n", 2)[1]
            self.assertIn("retag [Claude] -> [Codex]", k1)
            self.assertNotIn("X-1", text)  # high level: never offered across lanes

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
