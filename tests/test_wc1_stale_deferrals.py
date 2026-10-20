"""WC-1: archived gates in deferral reasons are reported as warnings."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import check_docs  # noqa: E402


def nextsteps(reason: str) -> str:
    return (
        "## Not in the queue, and why\n\n"
        f"- **NF-2 -- deferred fermentation** {reason}\n"
    )


class StaleDeferralsTest(unittest.TestCase):
    def run_check(self, reason: str, archives: tuple[str, ...]) -> list[str]:
        with tempfile.TemporaryDirectory(dir=ROOT) as directory:
            root = Path(directory)
            archive_dir = root / "plans" / "archive"
            archive_dir.mkdir(parents=True)
            for archive in archives:
                (archive_dir / archive).write_text("record\n", encoding="utf-8")
            warnings: list[str] = []
            check_docs.check_stale_deferrals(warnings, nextsteps(reason), root)
            return warnings

    def test_archived_gate_in_reason_warns_with_its_context(self) -> None:
        warnings = self.run_check("waits for COL-4 to land.", ("COL-4_2026-10-08.md",))
        self.assertEqual(len(warnings), 1)
        self.assertIn("waits for a shipped slice COL-4", warnings[0])
        self.assertIn("plans/archive/COL-4_2026-10-08.md", warnings[0])
        self.assertIn("NF-2 -- deferred fermentation", warnings[0])

    def test_unshipped_gate_does_not_warn(self) -> None:
        self.assertEqual(self.run_check("waits for COL-4 to land.", ()), [])

    def test_landed_clause_is_an_explicit_exemption(self) -> None:
        self.assertEqual(
            self.run_check("T2-2 landed 7 Oct 2026; waits for COL-4.",
                           ("T2-2_2026-10-07.md",)),
            [],
        )

    def test_bold_lead_id_is_not_its_own_gate(self) -> None:
        self.assertEqual(self.run_check("awaits a decision.", ("NF-2_2026-10-08.md",)), [])


def blocked_md(blocked_by: str) -> str:
    return (
        "### C-84 -- a check waiting on a slice\n\n"
        "Some action to take.\n\n"
        "PASS: it passes.\n\n"
        f"Blocked by: {blocked_by}\n\n"
        "Owner: none\n"
    )


class ReleasedBlockedChecksTest(unittest.TestCase):
    def run_check(self, blocked_by: str, archives: tuple[str, ...]) -> list[str]:
        with tempfile.TemporaryDirectory(dir=ROOT) as directory:
            root = Path(directory)
            archive_dir = root / "plans" / "archive"
            archive_dir.mkdir(parents=True)
            for archive in archives:
                (archive_dir / archive).write_text("record\n", encoding="utf-8")
            warnings: list[str] = []
            check_docs.check_released_blocked_checks(warnings, blocked_md(blocked_by), root)
            return warnings

    def test_entry_blocked_by_one_archived_id_warns(self) -> None:
        warnings = self.run_check(
            "RR-1 (`plans/now/run-repairs.md`) -- a lone queen cannot build.",
            ("RR-1_2026-10-13.md",),
        )
        self.assertEqual(len(warnings), 1)
        self.assertIn("C-84 waits only for shipped slices RR-1", warnings[0])
        self.assertIn("checks/ready/", warnings[0])

    def test_entry_also_naming_an_unarchived_id_does_not_warn(self) -> None:
        self.assertEqual(
            self.run_check(
                "RR-1 (`plans/now/run-repairs.md`) and T2-9 (`plans/now/tier-two.md`) "
                "-- two things must land.",
                ("RR-1_2026-10-13.md",),
            ),
            [],
        )

    def test_entry_with_prose_besides_the_ids_does_not_warn(self) -> None:
        self.assertEqual(
            self.run_check(
                "T2-12 (`plans/now/tier-two.md`), which waits for `scripts/hud.gd`.",
                ("T2-12_2026-10-14.md",),
            ),
            [],
        )

    def test_id_that_prefixes_another_id_still_warns(self) -> None:
        warnings = self.run_check(
            "RR-1, RR-11 (`plans/now/run-repairs.md`) -- both must land.",
            ("RR-1_2026-10-13.md", "RR-11_2026-10-15.md"),
        )
        self.assertEqual(len(warnings), 1)
        self.assertIn("RR-1, RR-11", warnings[0])

    def test_entry_with_no_ids_does_not_warn(self) -> None:
        self.assertEqual(
            self.run_check("an asset/licensing commit, not more UI code.", ()),
            [],
        )


if __name__ == "__main__":
    unittest.main()
