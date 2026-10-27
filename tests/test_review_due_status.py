"""Unit tests for tools/review_due.py status_of and check_backlog."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

# Add tools directory to path so review_due can be imported.
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from review_due import Prompt, check_backlog, status_of  # noqa: E402


def _run_git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args], cwd=root, capture_output=True, text=True, encoding="utf-8"
    )
    if result.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout.strip()


class TestReviewDueStatus(unittest.TestCase):
    """Tests for status_of and check_backlog using a temporary git repo."""

    def test_status_of_success_and_problems(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir).resolve()

            # Initialize git repository and set up git config for commits
            _run_git(root, "init")
            _run_git(root, "config", "user.name", "Test User")
            _run_git(root, "config", "user.email", "test@example.com")

            # 1. Problem case: no record yet
            prompt = Prompt(Path("plans/reference/reviews/demo.md"), "demo", ["watched.txt"])
            status1 = status_of(prompt, [], root=root)
            self.assertEqual(status1.problem, "no record yet -- first run")

            # Commit watched file
            watched = root / "watched.txt"
            watched.write_text("initial watched\n", encoding="utf-8")
            _run_git(root, "add", "watched.txt")
            _run_git(root, "commit", "-m", "Initial watched")
            commit1 = _run_git(root, "rev-parse", "HEAD")

            # Commit record docs/demo-2026-10-01.md with Reviewed line
            docs_dir = root / "docs"
            docs_dir.mkdir(parents=True, exist_ok=True)
            record1 = docs_dir / "demo-2026-10-01.md"
            record1.write_text(f"Record\nReviewed: {commit1}\n", encoding="utf-8")
            _run_git(root, "add", "docs/demo-2026-10-01.md")
            _run_git(root, "commit", "-m", "Record 1")

            # Two commits changing watched file
            watched.write_text("change 1\n", encoding="utf-8")
            _run_git(root, "commit", "-am", "Change 1")
            watched.write_text("change 2\n", encoding="utf-8")
            _run_git(root, "commit", "-am", "Change 2")

            # One commit changing unwatched file
            unwatched = root / "unwatched.txt"
            unwatched.write_text("unwatched\n", encoding="utf-8")
            _run_git(root, "add", "unwatched.txt")
            _run_git(root, "commit", "-m", "Unwatched change")

            # Check status_of success path
            tracked = ["docs/demo-2026-10-01.md"]
            status2 = status_of(prompt, tracked, root=root)
            self.assertIsNone(status2.problem)
            self.assertEqual(status2.record, "docs/demo-2026-10-01.md")
            self.assertEqual(status2.date, "2026-10-01")
            self.assertEqual(status2.since, commit1)
            self.assertEqual(status2.commits, 2)
            self.assertEqual(status2.changed, ["watched.txt"])

            # 2. Problem case: record with no Reviewed line
            record_no_rev = docs_dir / "demo-2026-10-02.md"
            record_no_rev.write_text("Record with no reviewed line\n", encoding="utf-8")
            _run_git(root, "add", "docs/demo-2026-10-02.md")
            _run_git(root, "commit", "-m", "Record without reviewed")

            tracked_no_rev = ["docs/demo-2026-10-02.md"]
            status3 = status_of(prompt, tracked_no_rev, root=root)
            self.assertEqual(
                status3.problem,
                "docs/demo-2026-10-02.md has no 'Reviewed: <commit>' line",
            )

            # 3. Problem case: Reviewed deadbeef line git cannot resolve
            record_deadbeef = docs_dir / "demo-2026-10-03.md"
            record_deadbeef.write_text("Record\nReviewed: deadbeef\n", encoding="utf-8")
            _run_git(root, "add", "docs/demo-2026-10-03.md")
            _run_git(root, "commit", "-m", "Record deadbeef")

            tracked_deadbeef = ["docs/demo-2026-10-03.md"]
            status4 = status_of(prompt, tracked_deadbeef, root=root)
            self.assertIsNotNone(status4.problem)
            self.assertTrue(status4.problem.startswith("cannot diff from deadbeef:"))

    def test_check_backlog(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir).resolve()

            # Empty folder case
            self.assertEqual(check_backlog(root=root), "hands-on checks waiting: 0")

            # Write three checks/ready/C-*.md files (two with Runner: haiku, one with no Runner line)
            ready_dir = root / "checks" / "ready"
            ready_dir.mkdir(parents=True, exist_ok=True)

            (ready_dir / "C-1.md").write_text("# C-1\nRunner: haiku\n", encoding="utf-8")
            (ready_dir / "C-2.md").write_text("# C-2\nRunner: haiku\n", encoding="utf-8")
            (ready_dir / "C-3.md").write_text("# C-3\nNo runner line here\n", encoding="utf-8")

            self.assertEqual(
                check_backlog(root=root),
                "hands-on checks waiting: 3 (2 haiku, 1 unset)",
            )


if __name__ == "__main__":
    unittest.main()
