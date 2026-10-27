"""Unit tests for tools/review_due.py's status_of and check_backlog."""

import importlib.util
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_test_support import CHECK_DOCS_PATH

REVIEW_DUE_SPEC = importlib.util.spec_from_file_location(
    "review_due", CHECK_DOCS_PATH.with_name("review_due.py")
)
review_due = importlib.util.module_from_spec(REVIEW_DUE_SPEC)
sys.modules["review_due"] = review_due
REVIEW_DUE_SPEC.loader.exec_module(review_due)


def git_cmd(repo_dir: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args], cwd=repo_dir, capture_output=True, text=True, encoding="utf-8"
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout.strip()


class ReviewDueStatusTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.temp_dir, ignore_errors=True)

    def test_status_of_normal_case(self):
        # In a temporary directory, git init a repository
        git_cmd(self.temp_dir, "init")
        git_cmd(self.temp_dir, "config", "user.name", "Test User")
        git_cmd(self.temp_dir, "config", "user.email", "test@example.com")

        # Commit a watched file
        watched_file = self.temp_dir / "watched.txt"
        watched_file.write_text("initial watched", encoding="utf-8")
        git_cmd(self.temp_dir, "add", "watched.txt")
        git_cmd(self.temp_dir, "commit", "-m", "Initial watched commit")

        # Commit a record docs/demo-2026-10-01.md with Reviewed: <hash>
        last_commit_hash = git_cmd(self.temp_dir, "rev-parse", "HEAD")
        docs_dir = self.temp_dir / "docs"
        docs_dir.mkdir(parents=True, exist_ok=True)
        record_file = docs_dir / "demo-2026-10-01.md"
        record_file.write_text(f"# Demo Record\n\nReviewed: {last_commit_hash}\n", encoding="utf-8")
        git_cmd(self.temp_dir, "add", "docs/demo-2026-10-01.md")
        git_cmd(self.temp_dir, "commit", "-m", "Add record")

        # Two more commits changing watched file
        watched_file.write_text("change 1", encoding="utf-8")
        git_cmd(self.temp_dir, "add", "watched.txt")
        git_cmd(self.temp_dir, "commit", "-m", "Watched change 1")

        watched_file.write_text("change 2", encoding="utf-8")
        git_cmd(self.temp_dir, "add", "watched.txt")
        git_cmd(self.temp_dir, "commit", "-m", "Watched change 2")

        # One commit changing an unwatched file
        unwatched_file = self.temp_dir / "unwatched.txt"
        unwatched_file.write_text("unwatched", encoding="utf-8")
        git_cmd(self.temp_dir, "add", "unwatched.txt")
        git_cmd(self.temp_dir, "commit", "-m", "Unwatched change")

        prompt = review_due.Prompt(
            path=Path("plans/reference/reviews/demo.md"),
            key="demo",
            watches=["watched.txt"],
        )
        tracked = ["docs/demo-2026-10-01.md"]

        status = review_due.status_of(prompt, tracked, root=self.temp_dir)
        self.assertEqual(status.record, "docs/demo-2026-10-01.md")
        self.assertEqual(status.date, "2026-10-01")
        self.assertEqual(status.since, last_commit_hash)
        self.assertEqual(status.commits, 2)
        self.assertEqual(status.changed, ["watched.txt"])
        self.assertIsNone(status.problem)

    def test_status_of_problem_cases(self):
        git_cmd(self.temp_dir, "init")
        git_cmd(self.temp_dir, "config", "user.name", "Test User")
        git_cmd(self.temp_dir, "config", "user.email", "test@example.com")

        prompt = review_due.Prompt(
            path=Path("plans/reference/reviews/demo.md"),
            key="demo",
            watches=["watched.txt"],
        )

        # Case 1: no record for the key
        status_no_record = review_due.status_of(prompt, [], root=self.temp_dir)
        self.assertEqual(status_no_record.problem, "no record yet -- first run")

        # Case 2: record with no Reviewed: line
        docs_dir = self.temp_dir / "docs"
        docs_dir.mkdir(parents=True, exist_ok=True)
        record1 = docs_dir / "demo-2026-10-01.md"
        record1.write_text("# Demo Record\nNo reviewed line here.\n", encoding="utf-8")
        status_no_reviewed = review_due.status_of(
            prompt, ["docs/demo-2026-10-01.md"], root=self.temp_dir
        )
        self.assertEqual(
            status_no_reviewed.problem,
            "docs/demo-2026-10-01.md has no 'Reviewed: <commit>' line",
        )

        # Case 3: Reviewed: deadbeef line git cannot resolve
        record2 = docs_dir / "demo-2026-10-02.md"
        record2.write_text("# Demo Record\nReviewed: deadbeef\n", encoding="utf-8")
        status_invalid_hash = review_due.status_of(
            prompt, ["docs/demo-2026-10-02.md"], root=self.temp_dir
        )
        self.assertIsNotNone(status_invalid_hash.problem)
        self.assertTrue(status_invalid_hash.problem.startswith("cannot diff from deadbeef:"))

    def test_check_backlog(self):
        # Empty checks/ready folder
        ready_dir = self.temp_dir / "checks" / "ready"
        ready_dir.mkdir(parents=True, exist_ok=True)
        self.assertEqual(
            review_due.check_backlog(root=self.temp_dir),
            "hands-on checks waiting: 0",
        )

        # Write three checks/ready/C-*.md files: two with Runner: haiku, one with no Runner line
        c1 = ready_dir / "C-1.md"
        c1.write_text("Runner: haiku\nCheck content\n", encoding="utf-8")
        c2 = ready_dir / "C-2.md"
        c2.write_text("Runner: haiku\nOther check\n", encoding="utf-8")
        c3 = ready_dir / "C-3.md"
        c3.write_text("No runner line here\n", encoding="utf-8")

        self.assertEqual(
            review_due.check_backlog(root=self.temp_dir),
            "hands-on checks waiting: 3 (2 haiku, 1 unset)",
        )


if __name__ == "__main__":
    unittest.main()
