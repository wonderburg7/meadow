"""Unit tests for pure and filesystem helper functions in tools/admission.py."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import admission  # noqa: E402
import check_docs  # noqa: E402


class AdmissionHelpersTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.addCleanup(setattr, check_docs, "ROOT", check_docs.ROOT)
        self.root = Path(self._tmp.name)
        for folder in ("plans/now", "plans/archive", "tools"):
            (self.root / folder).mkdir(parents=True)
        check_docs.ROOT = self.root

    def test_is_unowned(self) -> None:
        self.assertTrue(admission.is_unowned("FUNCTION_MAP.md"))
        self.assertTrue(admission.is_unowned("checks/ready.md"))
        self.assertTrue(admission.is_unowned("plans/workstreams.md"))
        self.assertFalse(admission.is_unowned("scripts/main.gd"))

    def test_shared_paths(self) -> None:
        mine = {"scripts/a.gd", "FUNCTION_MAP.md"}
        theirs = {"scripts/a.gd", "scripts/b.gd"}
        self.assertEqual(admission.shared_paths(mine, theirs), ["scripts/a.gd"])

        unowned_mine = {"FUNCTION_MAP.md"}
        unowned_theirs = {"FUNCTION_MAP.md"}
        self.assertEqual(admission.shared_paths(unowned_mine, unowned_theirs), [])

    def test_find_item(self) -> None:
        text = (
            "## Next up\n\n"
            "### Claude lane\n\n"
            "1. **[Claude] L-1 -- title**\n"
            "   - Plan: `plans/now/x.md` -- \"L-1 section\"\n"
            "   - Files: `tools/a.py`\n"
        )
        item = admission.find_item(text, self.root, "L-1")
        self.assertIsNotNone(item)
        assert item is not None
        self.assertEqual(item.slice_id, "L-1")
        self.assertEqual(item.lane, "Claude")

        missing_item = admission.find_item(text, self.root, "NONEXISTENT-99")
        self.assertIsNone(missing_item)

    def test_deferral_reason(self) -> None:
        text = (
            "## Not in the queue, and why\n\n"
            "- **L-1** (`plans/now/x.md`) -- waits for L-0.\n"
            "- **L-2** (`plans/now/y.md`) -- blocked on decision.\n"
        )
        self.assertEqual(admission.deferral_reason(text, "L-1"), " (`plans/now/x.md`) -- waits for L-0.")
        self.assertEqual(admission.deferral_reason(text, "L-99"), "")

    def test_plan_section(self) -> None:
        plan_file = self.root / "plans/now/x.md"
        plan_file.write_text("## Section A\n\nContent A\n\n## Section B\n\nContent B\n", encoding="utf-8")

        section_a = admission.plan_section(self.root, "plans/now/x.md", "Section A")
        self.assertIn("Content A", section_a)
        self.assertNotIn("Content B", section_a)

        missing_section = admission.plan_section(self.root, "plans/now/x.md", "Section Nonexistent")
        self.assertEqual(missing_section, "")

        missing_file = admission.plan_section(self.root, "plans/now/missing.md", "Section A")
        self.assertEqual(missing_file, "")

    def test_dependency_ids(self) -> None:
        item = admission.Item("L-1", "Claude", "", True)
        section = "**Gate.** L-2 must land first; L-3 landed.\n"
        deps = admission.dependency_ids("", item, section)
        self.assertEqual(deps, ["L-2"])

        section_all_landed = "**Gate.** L-3 landed.\n"
        deps_landed = admission.dependency_ids("", item, section_all_landed)
        self.assertEqual(deps_landed, [])

    def test_is_landed(self) -> None:
        self.assertTrue(admission.is_landed(self.root, "L-1", {"L-1"}))

        (self.root / "plans/archive/L-2_2026-10-01.md").write_text("", encoding="utf-8")
        self.assertTrue(admission.is_landed(self.root, "L-2", set()))

        self.assertFalse(admission.is_landed(self.root, "L-3", set()))

    def test_archived_plan_for(self) -> None:
        (self.root / "plans/archive/FEATURE_X_2026-10-01.md").write_text("", encoding="utf-8")
        archived = admission.archived_plan_for(self.root, "plans/now/feature-x.md")
        self.assertEqual(archived, "plans/archive/FEATURE_X_2026-10-01.md")

        missing = admission.archived_plan_for(self.root, "plans/now/nonexistent.md")
        self.assertIsNone(missing)


if __name__ == "__main__":
    unittest.main()
