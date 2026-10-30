"""tools/jules_preflight.py's review rota and ledger, and review_due.py's `Jules:` line,
run against a throwaway repository with its own `origin`."""

from __future__ import annotations

import datetime
import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


TOOLS = Path(__file__).resolve().parent.parent / "tools"
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location("jules_preflight", TOOLS / "jules_preflight.py")
preflight = importlib.util.module_from_spec(SPEC)
sys.modules["jules_preflight"] = preflight  # dataclasses look the module up while building their classes
SPEC.loader.exec_module(preflight)
review_due = preflight.review_due

TASKS = (
    "# Jules\n\n## Tasks\n\n"
    "### J-1 -- first\n\n- Files: `tools/one.py`\n\n"
    "### J-2 -- second\n\n- Files: `tools/two.py`\n\n"
    "## Standing tasks\n"
)
LEDGER_HEAD = "# Ledger\n\n| Item | Branch | State | Date | By | Outcome |\n| --- | --- | --- | --- | --- | --- |\n"


def review_file(title: str, key: str, jules: str) -> str:
    return (
        f"# {title}\n\n<!-- CONTEXT: review-prompt -->\nRecord key: {key}\nReasoning: high\n"
        f"Watches: scripts\nJules: {jules}\n\n**Owns:** things.\n"
    )


class ParsingTest(unittest.TestCase):
    def test_jules_line_reads_the_rota_entry(self):
        rota, note = review_due.parse_jules(" R-gameplay | priority 1 | every 7 days | min 20 commits ")
        self.assertEqual((rota.id, rota.priority, rota.every_days, rota.min_commits), ("R-gameplay", 1, 7, 20))
        self.assertEqual(note, "")

    def test_jules_no_keeps_its_reason_and_garbage_is_flagged(self):
        self.assertEqual(review_due.parse_jules("no -- needs Dave"), (None, "no -- needs Dave"))
        rota, note = review_due.parse_jules("R-x every week")
        self.assertIsNone(rota)
        self.assertTrue(note.startswith("unreadable Jules line"))

    def test_prompt_header_carries_the_jules_line(self):
        prompt = review_due.parse_prompt(Path("r.md"), review_file("Alpha", "alpha-review", "R-alpha | priority 2 | every 3 days | min 1 commit"))
        self.assertEqual(prompt.key, "alpha-review")
        self.assertEqual(prompt.jules.id, "R-alpha")
        self.assertEqual(review_due.parse_prompt(Path("r.md"), "# T\nRecord key: x\n").jules_note, "no Jules line")

    def test_ledger_rows_by_branch_and_the_last_row_wins(self):
        text = LEDGER_HEAD + (
            "| J-1 | jules/j-1-a | returned | 2026-10-30 | Claude | fix the test |\n"
            "| J-2 | `origin/jules/j-2-b` | closed | 2026-10-30 | Codex | superseded by R-alpha |\n"
            "| J-1 | jules/j-1-a | merged | 2026-10-31 | Claude | taken by checkout, a | b |\n"
            "| J-3 | jules/j-3-c | pending | 2026-10-31 | Claude | not a state |\n"
        )
        rows = preflight.parse_ledger(text)
        self.assertEqual(sorted(rows), ["jules/j-1-a", "jules/j-2-b"])
        self.assertEqual(rows["jules/j-1-a"].state, "merged")
        self.assertEqual(rows["jules/j-1-a"].outcome, "taken by checkout, a | b")
        self.assertEqual(rows["jules/j-2-b"].item, "J-2")
        self.assertEqual(preflight.closed_items(rows), {"J-2"})

    def test_ledger_notes_name_only_returned_rows_of_the_item(self):
        rows = preflight.parse_ledger(
            LEDGER_HEAD
            + "| J-1 | jules/j-1-a | returned | 2026-10-30 | Claude | fix the test |\n"
            + "| J-1 | jules/j-1-b | closed | 2026-10-30 | Claude | gone |\n"
        )
        self.assertEqual(preflight.ledger_notes(rows, "j-1"), ["returned 2026-10-30 by Claude (jules/j-1-a): fix the test"])
        self.assertEqual(preflight.ledger_notes(rows, "J-2"), [])

    def test_branch_names_carry_review_ids(self):
        self.assertEqual(preflight.task_for_ref(Path("."), "origin/jules/r-save-1234"), "R-SAVE")
        self.assertEqual(preflight.task_for_ref(Path("."), "jules/r-gameplay"), "R-GAMEPLAY")
        self.assertEqual(preflight.task_for_ref(Path("."), "origin/jules/j-12-x"), "J-12")
        self.assertTrue(preflight.review_branch("R-save", "origin/jules/r-save-99"))
        self.assertFalse(preflight.review_branch("R-save", "origin/jules/r-saves-99"))


class RepositoryTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        base = Path(self.temp.name)
        self.origin = base / "origin.git"
        self.root = base / "work"
        subprocess.run(["git", "init", "-q", "--bare", "-b", "master", str(self.origin)], check=True)
        subprocess.run(["git", "clone", "-q", str(self.origin), str(self.root)], check=True, capture_output=True)
        self.git("config", "user.email", "test@example.com")
        self.git("config", "user.name", "Test")
        self.git("checkout", "-q", "-b", "master")
        self.write("plans/reference/jules.md", TASKS)
        self.write("plans/reference/reviews/README.md", "# Index\n")
        self.write("plans/reference/reviews/alpha.md", review_file("Alpha review", "alpha-review", "R-alpha | priority 2 | every 7 days | min 2 commits"))
        self.write("plans/reference/reviews/beta.md", review_file("Beta review", "beta-review", "R-beta | priority 1 | every 14 days | min 2 commits"))
        self.write("plans/reference/reviews/gamma.md", review_file("Gamma review", "gamma-review", "no -- needs Dave"))
        self.write("scripts/a.gd", "# a\n")
        for name in ("one", "two"):
            self.write(f"tools/{name}.py", "# placeholder\n")
        self.commit("seed")
        self.seed = self.git("rev-parse", "HEAD").strip()
        self.write("docs/alpha-review-2026-10-01.md", f"# Alpha\n\nReviewed: {self.seed} | Since: first run\n")
        self.write("docs/beta-review-2026-10-20.md", f"# Beta\n\nReviewed: {self.seed} | Since: first run\n")
        self.commit("records")
        self.git("push", "-q", "origin", "master")
        self.git("fetch", "-q", "origin")
        self.today = datetime.date(2026, 10, 30)

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args: str) -> str:
        return preflight.git(self.root, *args)

    def write(self, path: str, text: str) -> None:
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")

    def commit(self, message: str) -> None:
        self.git("add", "-A")
        self.git("commit", "-q", "-m", message)

    def push_master(self) -> None:
        self.git("push", "-q", "origin", "master")
        self.git("fetch", "-q", "origin")

    def push_branch(self, name: str, path: str, text: str | None = None) -> None:
        self.git("checkout", "-q", "-b", name, "master")
        self.write(path, text or f"# {name}\n")
        self.commit("edit")
        self.git("push", "-q", "origin", name)
        self.git("checkout", "-q", "master")
        self.git("fetch", "-q", "origin")

    def touch_scripts(self, count: int) -> None:
        for number in range(count):
            self.write("scripts/a.gd", f"# a {number}\n")
            self.commit(f"script {number}")
        self.push_master()

    def ledger(self, rows: str) -> None:
        self.write("plans/reference/jules-ledger.md", LEDGER_HEAD + rows)
        self.commit("ledger")
        self.push_master()

    def states(self) -> dict[str, tuple[str, str]]:
        return {
            review.id: preflight.review_state(self.root, review, "origin/master", self.today)
            for review in preflight.parse_reviews(self.root, "origin/master")
        }

    def test_rota_holds_only_jules_reviews_by_priority(self):
        reviews = preflight.parse_reviews(self.root, "origin/master")
        self.assertEqual([(review.id, review.key, review.title) for review in reviews],
                         [("R-beta", "beta-review", "Beta review"), ("R-alpha", "alpha-review", "Alpha review")])
        self.assertEqual(reviews[0].watches, ["scripts"])
        self.assertEqual(reviews[0].report_pattern, "docs/jules-reviews/beta-review-*.md")

    def test_a_review_rests_inside_its_interval_and_is_quiet_without_commits(self):
        states = self.states()
        self.assertEqual(states["R-beta"], ("rests", "last reviewed 2026-10-20; due again 2026-11-03"))
        self.assertEqual(states["R-alpha"][0], "quiet")
        self.assertIn("0 commits on its watched paths", states["R-alpha"][1])
        self.touch_scripts(2)
        self.assertEqual(self.states()["R-alpha"][0], "due")

    def test_next_review_takes_the_highest_priority_due_one(self):
        self.touch_scripts(2)
        review, reason, skipped = preflight.next_review(self.root, "origin/master", self.today)
        self.assertEqual(review.id, "R-alpha")
        self.assertIn("2 commits on its watched paths", reason)
        self.assertEqual(skipped, ["R-beta: rests -- last reviewed 2026-10-20; due again 2026-11-03"])
        review, _, _ = preflight.next_review(self.root, "origin/master", datetime.date(2026, 11, 5))
        self.assertEqual(review.id, "R-beta")

    def test_an_open_report_takes_its_review_until_the_ledger_processes_it(self):
        self.touch_scripts(2)
        self.push_branch("jules/r-alpha-111", "docs/jules-reviews/alpha-review-2026-10-30.md")
        self.assertEqual(self.states()["R-alpha"][0], "taken")
        self.assertEqual(preflight.waiting_reports(self.root, "origin/master"), {"R-alpha": "jules/r-alpha-111"})
        self.ledger("| R-alpha | jules/r-alpha-111 | closed | 2026-10-29 | Claude | findings routed |\n")
        self.assertEqual(preflight.waiting_reports(self.root, "origin/master"), {})
        self.assertEqual(self.states()["R-alpha"], ("rests", "last reviewed 2026-10-29; due again 2026-11-05"))

    def test_a_report_already_on_master_is_not_waiting(self):
        self.push_branch("jules/r-alpha-222", "docs/jules-reviews/alpha-review-2026-10-30.md", "# report\n")
        self.git("checkout", "-q", "origin/jules/r-alpha-222", "--", "docs/jules-reviews/alpha-review-2026-10-30.md")
        self.commit("take the report")
        self.push_master()
        self.assertEqual(preflight.waiting_reports(self.root, "origin/master"), {})

    def test_review_due_marks_a_review_with_a_waiting_report(self):
        self.push_branch("jules/r-beta-333", "docs/jules-reviews/beta-review-2026-10-30.md")
        self.assertEqual(review_due.waiting_jules_reports(self.root), {"R-beta": "jules/r-beta-333"})

    def test_returned_branch_frees_its_task_and_closed_closes_it(self):
        self.push_branch("jules/j-1-first-5", "tools/one.py")
        self.push_branch("jules/j-2-second-6", "tools/two.py")
        tasks = preflight.parse_tasks(TASKS)
        states = [(task.id, state) for task, state, _ in preflight.classify(self.root, tasks, "origin/master")]
        self.assertEqual(states, [("J-1", "taken"), ("J-2", "taken")])
        self.ledger(
            "| J-1 | jules/j-1-first-5 | returned | 2026-10-30 | Claude | assert the value |\n"
            "| J-2 | jules/j-2-second-6 | closed | 2026-10-30 | Claude | superseded |\n"
        )
        states = [(task.id, state) for task, state, _ in preflight.classify(self.root, tasks, "origin/master")]
        self.assertEqual(states, [("J-1", "free"), ("J-2", "closed")])
        task, _ = preflight.next_task(self.root, tasks, "origin/master")
        self.assertEqual(task.id, "J-1")

    def test_jules_branches_sorts_unreviewed_from_merged(self):
        self.push_branch("jules/j-1-first-5", "tools/one.py")
        self.push_branch("jules/s-1-helpers-7", "tests/test_helpers.py", "# helpers\n")
        self.push_branch("jules/idea-8", "docs/idea.md")
        self.git("checkout", "-q", "origin/jules/s-1-helpers-7", "--", "tests/test_helpers.py")
        self.commit("take helpers by checkout")
        self.push_master()
        self.ledger("| idea | jules/idea-8 | closed | 2026-10-30 | Claude | routed to a plan |\n")
        found = {name: state for name, state, _ in preflight.jules_branches(self.root, preflight.load_ledger(self.root, "origin/master"), "origin/master")}
        self.assertEqual(found, {"jules/j-1-first-5": "unreviewed", "jules/s-1-helpers-7": "merged", "jules/idea-8": "closed"})
        report = preflight.ledger_report(self.root, "origin/master")
        self.assertTrue(report[0].startswith("unreviewed jules/j-1-first-5 -- "))
        self.assertIn("total      1 unreviewed, 1 merged, 0 returned, 1 closed", report)

    def test_review_scope_allows_only_its_report(self):
        task = preflight.scope_task(self.root, "R-ALPHA", "origin/master")
        self.assertEqual(task.files, ["docs/jules-reviews/alpha-review-*.md"])
        self.assertIsNone(preflight.scope_task(self.root, "R-NOPE", "origin/master"))
        self.git("checkout", "-q", "-b", "jules/r-alpha-9", "master")
        self.write("docs/jules-reviews/alpha-review-2026-10-30.md", "# report\n")
        self.write("scripts/a.gd", "# edited\n")
        self.commit("R-alpha: report")
        report = preflight.scope_report(self.root, task, "HEAD", base="master")
        self.assertIn("ok    A docs/jules-reviews/alpha-review-2026-10-30.md", report)
        self.assertTrue(any(line.startswith("off   M scripts/a.gd") for line in report))
        self.assertFalse(any(line.startswith("note") for line in report))
        self.git("checkout", "-q", "master")


if __name__ == "__main__":
    unittest.main()
