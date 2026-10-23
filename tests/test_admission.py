"""tools/admission.py: one admission test for check_docs, start and closeout (L-33)."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import admission  # noqa: E402
import check_docs  # noqa: E402


def item(number: int, lane: str, slice_id: str, files: str, plan: str = "plans/now/x.md") -> str:
    return (
        f"{number}. **[{lane}] {slice_id} -- title**\n"
        f"   - Plan: `{plan}` -- \"{slice_id} section\"\n"
        f"   - Files: {files}\n"
        "   - Check: `true`\n"
        "   - Proof: `absent: tools/a.py :: zzz`\n"
        "   - Next after: none -- x is complete\n"
    )


def nextsteps(claude: str, codex: str, not_queued: str = "") -> str:
    return (
        "## Next up\n\n### Claude lane\n\n" + claude
        + "\n### Codex lane\n\n" + codex
        + "\n## Not in the queue, and why\n\n" + not_queued + "\n## Later\n"
    )


class AdmissionTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)
        for folder in ("plans/now", "plans/archive", "tools", "tests"):
            (self.root / folder).mkdir(parents=True)
        (self.root / "tools/a.py").write_text("", encoding="utf-8")
        (self.root / "tools/b.py").write_text("", encoding="utf-8")
        (self.root / "FUNCTION_MAP.md").write_text("", encoding="utf-8")
        check_docs.ROOT = self.root

    def plan(self, section_extra: str = "", name: str = "x.md") -> None:
        (self.root / "plans/now" / name).write_text(
            "# Plan\n\n## L-1 section\n\n" + section_extra + "\n## Other\n", encoding="utf-8")

    def verdict(self, text: str, slice_id: str) -> admission.Verdict:
        found = next(i for i in admission.queue_items(text) if i.slice_id == slice_id)
        return admission.check_item(text, self.root, found)

    def test_clean_item_is_admissible(self) -> None:
        self.plan("**Open decisions:** none.\n")
        text = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`").replace("L-1 section", "L-1 section"),
                         item(1, "Codex", "C-1", "`tools/b.py`"))
        verdict = self.verdict(text, "L-1")
        self.assertTrue(verdict.admissible, verdict.line())
        self.assertEqual(verdict.line(), "admissible")

    def test_missing_open_decisions_line_only_warns(self) -> None:
        self.plan("Prose only.\n")
        text = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`"), item(1, "Codex", "C-1", "`tools/b.py`"))
        verdict = self.verdict(text, "L-1")
        self.assertTrue(verdict.admissible)
        self.assertTrue(verdict.warnings)

    def test_open_decision_blocks(self) -> None:
        self.plan("**Open decisions:** which save format?\n")
        text = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`"), item(1, "Codex", "C-1", "`tools/b.py`"))
        self.assertIn("open decision: which save format?", self.verdict(text, "L-1").line())

    def test_file_in_other_lane_blocks_with_reason(self) -> None:
        self.plan("**Open decisions:** none.\n")
        text = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`"), item(1, "Codex", "C-1", "`tools/a.py`"))
        verdict = self.verdict(text, "L-1")
        self.assertFalse(verdict.admissible)
        self.assertIn("Codex lane's C-1 owns tools/a.py", verdict.line())

    def test_unmerged_branch_blocks(self) -> None:
        self.plan("**Open decisions:** none.\n")
        text = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`"), item(1, "Codex", "C-1", "`tools/b.py`"))
        found = admission.queue_items(text)[0]
        verdict = admission.check_item(text, self.root, found,
                                       branches={"origin/jules/x": {"tools/a.py"}})
        self.assertIn("unmerged branch origin/jules/x changes tools/a.py", verdict.line())

    def test_landed_dependency_is_ignored_and_open_one_blocks(self) -> None:
        self.plan("**Open decisions:** none.\n\n**Gate.** L-0 must land first; L-9 too.\n")
        (self.root / "plans/archive/L-0_2026-10-01.md").write_text("", encoding="utf-8")
        text = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`"), item(1, "Codex", "C-1", "`tools/b.py`"))
        line = self.verdict(text, "L-1").line()
        self.assertIn("waits for L-9", line)
        self.assertNotIn("L-0", line)

    def test_merged_branch_counts_as_landed(self) -> None:
        self.plan("**Open decisions:** none.\n\n**Gate.** L-9 must land first.\n")
        text = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`"), item(1, "Codex", "C-1", "`tools/b.py`"))
        found = admission.queue_items(text)[0]
        verdict = admission.check_item(text, self.root, found, merged={"L-9"})
        self.assertTrue(verdict.admissible, verdict.line())

    def test_missing_plan_and_missing_folder_block(self) -> None:
        text = nextsteps(item(1, "Claude", "L-1", "`nowhere/new.py`", plan="plans/now/gone.md"),
                         item(1, "Codex", "C-1", "`tools/b.py`"))
        verdict = self.verdict(text, "L-1")
        self.assertIn("plan plans/now/gone.md does not exist", verdict.warnings)
        self.assertIn("nowhere/new.py does not exist and neither does its folder", verdict.line())

    def test_new_file_in_existing_folder_is_admissible(self) -> None:
        self.plan("**Open decisions:** none.\n")
        text = nextsteps(item(1, "Claude", "L-1", "`tools/new.py`"), item(1, "Codex", "C-1", "`tools/b.py`"))
        self.assertTrue(self.verdict(text, "L-1").admissible)

    def test_function_map_is_unowned_but_indexed_scripts_still_clash(self) -> None:
        self.plan("**Open decisions:** none.\n")
        text = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`, `FUNCTION_MAP.md`"),
                         item(1, "Codex", "C-1", "`tools/b.py`, `FUNCTION_MAP.md`"))
        self.assertTrue(self.verdict(text, "L-1").admissible)
        clash = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`"), item(1, "Codex", "C-1", "`tools/a.py`"))
        self.assertFalse(self.verdict(clash, "L-1").admissible)
        self.assertEqual(admission.lane_conflicts(text, "Claude", {"FUNCTION_MAP.md"}), [])
        self.assertEqual(admission.lane_conflicts(clash, "Claude", {"tools/a.py"}), ["tools/a.py"])

    def test_clear_landed_drops_id_from_gate_lists(self) -> None:
        text = nextsteps(
            item(1, "Claude", "L-1", "`tools/a.py`"), item(1, "Codex", "C-1", "`tools/b.py`"),
            "- **CQ-X** (`plans/now/x.md`) -- waits for L-1, SG-2 and ED-1.\n"
            "- **CQ-Y** (`plans/now/x.md`) -- waits for L-1 only.\n"
            "- **L-1** (`plans/now/x.md`) -- its own bullet keeps its lead.\n")
        updated, notes = admission.clear_landed(text, "L-1")
        self.assertIn("waits for SG-2 and ED-1.", updated)
        self.assertIn("waits for L-1 only.", updated)  # sole gate: left for the gates job
        self.assertTrue(any("CQ-Y" in note for note in notes))

    def test_clear_landed_rewrites_archived_plan_references(self) -> None:
        (self.root / "plans/archive/X_2026-10-23.md").write_text("", encoding="utf-8")
        queue = self.root / "NEXTSTEPS.md"
        queue.write_text("see `plans/now/x.md` and `plans/now/y.md`\n", encoding="utf-8")
        (self.root / "plans/now/y.md").write_text("# Y\n", encoding="utf-8")
        self.assertEqual(admission.rewrite_archived_refs(self.root), ["NEXTSTEPS.md"])
        self.assertEqual(queue.read_text(encoding="utf-8"),
                         "see `plans/archive/X_2026-10-23.md` and `plans/now/y.md`\n")

    def test_clear_landed_command_edits_the_queue_file(self) -> None:
        text = nextsteps(item(1, "Claude", "L-1", "`tools/a.py`"), item(1, "Codex", "C-1", "`tools/b.py`"),
                         "- **CQ-X** (`plans/now/x.md`) -- waits for L-1, SG-2.\n")
        (self.root / "NEXTSTEPS.md").write_text(text, encoding="utf-8")
        self.assertEqual(admission.main(["--clear-landed", "L-1", "--root", str(self.root)]), 0)
        self.assertIn("waits for SG-2.", (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
