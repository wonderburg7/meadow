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

    def test_stale_rows_are_preparation_claims_left_on_master(self):
        rows = preflight.parse_ledger(
            LEDGER_HEAD
            + "| J-1 | jules/j-1-a | closed | 2026-11-05 | Codex | #1: prepared; pending review, not on master. |\n"
            + "| J-2 | jules/j-2-b | merged | 2026-11-05 | Claude | delivered to master in the batch merge |\n"
            + "| J-3 | jules/j-3-c | closed | 2026-11-05 | Codex | prepared, Not On Master |\n"
            + "| J-3 | jules/j-3-c | merged | 2026-11-06 | Claude | delivered |\n"
        )
        self.assertEqual([row.branch for row in preflight.stale_rows(rows)], ["jules/j-1-a"])

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

    def test_a_reverted_task_is_not_done_until_merged_again(self):
        task = preflight.parse_tasks(TASKS)[0]
        self.write("tools/one.py", "# j-1\n")
        self.commit("J-1: first")
        self.push_master()
        self.assertTrue(preflight.is_done(self.root, task, "origin/master"))
        self.git("revert", "--no-edit", "HEAD")
        self.push_master()
        self.assertFalse(preflight.is_done(self.root, task, "origin/master"))
        self.assertEqual(preflight.classify(self.root, [task], "origin/master")[0][1], "free")
        self.git("revert", "--no-edit", "HEAD")  # 'Reapply ...': a fresh merge carries the J-1 line again
        self.git("commit", "-q", "--amend", "-m", "J-1: first, corrected")
        self.push_master()
        self.assertTrue(preflight.is_done(self.root, task, "origin/master"))

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
        self.assertIn("total      1 unreviewed, 1 merged, 0 returned, 1 closed, 0 reviewed, 0 moved, 0 stale", report)
        self.assertFalse(any(line.startswith("stale") for line in report))
        self.ledger("| idea | jules/idea-8 | closed | 2026-11-05 | Codex | prepared on a batch branch, not on master |\n")
        report = preflight.ledger_report(self.root, "origin/master")
        self.assertIn("stale      jules/idea-8 -- says 'not on master' but is on origin/master: rewrite it to what landed", report)

    def test_a_reviewed_row_waits_at_its_tip_and_flags_a_moved_or_landed_branch(self):
        self.push_branch("jules/j-1-first-5", "tools/one.py", "# j-1 reviewed\n")
        tip = self.git("rev-parse", "origin/jules/j-1-first-5").strip()
        task = preflight.parse_tasks(TASKS)[0]

        def found() -> tuple[str, list[str]]:
            ledger = preflight.load_ledger(self.root, "origin/master")
            state = {name: state for name, state, _ in preflight.jules_branches(self.root, ledger, "origin/master")}
            return state["jules/j-1-first-5"], preflight.ledger_report(self.root, "origin/master")

        # Reviewed at its tip: not unreviewed, still takes its task and owns its file.
        self.ledger(f"| J-1 | jules/j-1-first-5 | reviewed | 2026-11-05 | Claude | #7 at {tip}: take tools/one.py |\n")
        state, report = found()
        self.assertEqual(state, "reviewed")
        self.assertIn("total      0 unreviewed, 0 merged, 0 returned, 0 closed, 1 reviewed, 0 moved, 0 stale", report)
        self.assertFalse(any(line.startswith(("stale", "moved")) for line in report))
        self.assertEqual(preflight.classify(self.root, [task], "origin/master")[0][1], "taken")
        self.assertEqual(preflight.owners(self.root, ["tools/one.py"], "origin/master")["tools/one.py"],
                         ["changed on unmerged origin/jules/j-1-first-5"])

        # The tip moves after review: it needs another look.
        self.git("checkout", "-q", "jules/j-1-first-5")
        self.write("tools/one.py", "# j-1 corrected\n")
        self.commit("J-1 correction")
        self.git("push", "-q", "origin", "jules/j-1-first-5")
        self.git("checkout", "-q", "master")
        self.git("fetch", "-q", "origin")
        state, report = found()
        self.assertEqual(state, "moved")
        self.assertTrue(any(line.startswith("moved      jules/j-1-first-5") and "tip is now" in line for line in report))

        # Re-reviewed at the new tip, then integrated without flipping the row: stale.
        tip = self.git("rev-parse", "origin/jules/j-1-first-5").strip()
        self.ledger(f"| J-1 | jules/j-1-first-5 | reviewed | 2026-11-06 | Claude | at {tip}: take tools/one.py |\n")
        self.assertEqual(found()[0], "reviewed")
        self.git("checkout", "-q", "origin/jules/j-1-first-5", "--", "tools/one.py")
        self.commit("take tools/one.py by checkout")
        self.push_master()
        state, report = found()
        self.assertEqual(state, "stale")
        self.assertTrue(any(line.startswith("stale      jules/j-1-first-5") and "flip the row to merged" in line for line in report))

        # A reviewed row without a recorded SHA cannot prove what was reviewed.
        self.ledger("| J-1 | jules/j-1-first-5 | reviewed | 2026-11-06 | Claude | looked fine |\n")
        self.assertEqual(found()[0], "moved")

    def jules_commit(self, branch: str, files: dict[str, str], message: str, when: str, start: str = "master") -> None:
        """Commit `files` on `branch` (created from `start` if new) at committer time `when`, and push it."""
        exists = subprocess.run(["git", "-C", str(self.root), "rev-parse", "--verify", "-q", branch],
                                capture_output=True).returncode == 0
        self.git("checkout", "-q", branch) if exists else self.git("checkout", "-q", "-b", branch, start)
        for path, text in files.items():
            self.write(path, text)
        self.git("add", "-A")
        env = {"GIT_COMMITTER_DATE": when, "GIT_AUTHOR_DATE": when}
        subprocess.run(["git", "-C", str(self.root), "commit", "-q", "-m", message], check=True,
                       env={**__import__("os").environ, **env})
        self.git("push", "-q", "origin", branch)
        self.git("checkout", "-q", "master")
        self.git("fetch", "-q", "origin")

    def test_sequence_fails_only_the_later_duplicate(self):
        trailer = "E-4: report\n\nJules-Sequence: 4 efficiency\n"
        self.jules_commit("jules/e-4-first", {"docs/jules-efficiency/e-4.md": "# first\n"}, trailer, "2026-11-05T10:00:00")
        self.jules_commit("jules/e-4-second", {"docs/jules-efficiency/e-4.md": "# second\n"}, trailer, "2026-11-05T10:01:12")
        self.jules_commit("jules/j-1-other", {"tools/one.py": "# j-1\n"}, "J-1\n\nJules-Sequence: 5 ordinary\n", "2026-11-05T09:00:00")

        def report(ref: str) -> list[str]:
            return preflight.sequence_report(self.root, f"origin/{ref}", "origin/master")

        self.assertEqual(report("jules/e-4-first"), ["ok    Jules-Sequence: 4 efficiency"])
        self.assertEqual(report("jules/e-4-second"),
                         ["dup   Jules-Sequence: 4 efficiency -- duplicate of jules/e-4-first (older): close this PR as a duplicate"])
        self.assertEqual(report("jules/j-1-other"), ["ok    Jules-Sequence: 5 ordinary"])

        # A correction on the first branch keeps its trailer and stays green.
        self.jules_commit("jules/e-4-first", {"docs/jules-efficiency/e-4.md": "# first, corrected\n"}, trailer, "2026-11-05T11:00:00")
        self.assertEqual(report("jules/e-4-first"), ["ok    Jules-Sequence: 4 efficiency"])

        # A correction of a returned submission may come on a fresh branch with the original trailer.
        self.ledger("| E-4 | jules/e-4-first | returned | 2026-11-05 | Claude | at " + "0" * 40 + ": correct it |\n")
        self.assertEqual(report("jules/e-4-second"), ["ok    Jules-Sequence: 4 efficiency"])

        self.jules_commit("jules/j-2-none", {"tools/two.py": "# j-2\n"}, "J-2 without a trailer", "2026-11-05T12:00:00")
        self.assertTrue(report("jules/j-2-none")[0].startswith("note  no Jules-Sequence trailer"))

    def test_standing_task_scopes_have_fixed_shapes(self):
        self.write("docs/audits/alpha.md", "# Alpha audit\n")
        self.write("docs/audits/beta.md", "# Beta audit\n")
        self.commit("audits")
        self.push_master()

        def scope(task: str, branch: str, files: dict[str, str]) -> list[str]:
            self.jules_commit(branch, files, f"{task}: change", "2026-11-05T10:00:00")
            return preflight.standing_scope_report(self.root, task, f"origin/{branch}", "origin/master")

        def fails(lines: list[str]) -> bool:
            return any(line.startswith(("off", "note")) for line in lines)

        cases = [
            ("S-1", {"tests/test_one_helpers.py": "# ok\n"}, False),
            ("S-1", {"tests/test_one_extra_helpers.py": "# suffix ok\n"}, False),
            ("S-1", {"tests/test_one_helpers.py": "# ok\n", "AGENTS.md": "# inherited\n"}, True),
            ("S-1", {"tests/test_missing_helpers.py": "# no such tool\n"}, True),
            ("S-1", {"tests/test_one_helpers.py": "# one\n", "tests/test_two_helpers.py": "# two tools\n"}, True),
            ("S-2", {"scripts/a.gd": "# trimmed\n"}, False),
            ("S-2", {"scripts/a.gd": "# trimmed\n", "tools/one.py": "# second file\n"}, True),
            ("S-2", {"scripts/new.gd": "# added, not existing\n"}, True),
            ("S-3", {"tools/foo_check.py": "# guard\n", "tests/test_foo_check.py": "# test\n"}, False),
            ("S-3", {"tools/foo_check.py": "# guard alone\n"}, True),
            ("S-3", {"tools/foo_check.py": "# guard\n", "tests/test_bar_check.py": "# other name\n"}, True),
            ("S-3", {"tools/foo_check.py": "# g\n", "tests/test_foo_check.py": "# t\n", "CHATGPT.md": "# x\n"}, True),
            ("S-4", {"docs/audits/alpha.md": "# Alpha audit, refreshed\n"}, False),
            ("S-4", {"docs/audits/alpha.md": "# a\n", "docs/audits/beta.md": "# b\n"}, True),
            ("S-4", {"docs/audits/gamma.md": "# new audit\n"}, True),
        ]
        for number, (task, files, should_fail) in enumerate(cases):
            with self.subTest(task=task, files=sorted(files)):
                lines = scope(task, f"jules/{task.lower()}-case-{number}", files)
                self.assertEqual(fails(lines), should_fail, lines)

    def test_branch_names_carry_standing_task_ids(self):
        self.assertEqual(preflight.task_for_ref(self.root, "origin/jules/s-3-indoor-flower-check-1"), "S-3")
        self.assertIsNone(preflight.task_for_ref(self.root, "origin/jules/s-9-unknown-1"))

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
