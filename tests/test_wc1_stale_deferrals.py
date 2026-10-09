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


if __name__ == "__main__":
    unittest.main()
