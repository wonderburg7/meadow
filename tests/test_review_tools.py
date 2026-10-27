"""Review-library tooling: new_check.py's --confirm mode, check_docs.py's
review-record rule (plans/reference/review-contract.md rules 5 and 8) and
review_due.py (rule 2)."""

from datetime import date
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_test_support import *  # noqa: E402,F401,F403


NEW_CHECK_SPEC = importlib.util.spec_from_file_location(
    "new_check", CHECK_DOCS_PATH.with_name("new_check.py")
)
new_check = importlib.util.module_from_spec(NEW_CHECK_SPEC)
NEW_CHECK_SPEC.loader.exec_module(new_check)

ARCHIVE = (
    "# Hands-on check archive\n"
    "\n"
    "Completed entries. Newest first.\n"
    "\n"
    "## 19 Sep 2026 -- Dave's hands-on pass\n"
    "\n"
    "### C-18 -- an older check\n"
    "\n"
    "PASS: it worked then.\n"
)


def ready_record(check_id: int) -> str:
    return (
        f"# C-{check_id} -- check {check_id}\n\nDo the thing.\n\n"
        "PASS: the thing happens.\n\nOwner: `plans/now/sample.md`\n"
    )


class ConfirmCheckTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root, ignore_errors=True)
        (self.root / "checks" / "ready").mkdir(parents=True)
        (self.root / "docs" / "archive").mkdir(parents=True)
        self.archive = self.root / new_check.ARCHIVE_REL
        self.archive.write_text(ARCHIVE, encoding="utf-8")
        for check_id in (42, 57):
            self.record(check_id).write_text(ready_record(check_id), encoding="utf-8")

    def record(self, check_id: int) -> Path:
        return self.root / "checks" / "ready" / f"C-{check_id}.md"

    def test_a_pass_moves_under_a_new_heading_above_older_passes(self):
        removed = new_check.confirm_checks(self.root, [42], date(2026, 9, 28), "fine at 800x600")

        text = self.archive.read_text(encoding="utf-8")
        self.assertEqual([path.name for path in removed], ["C-42.md"])
        self.assertFalse(self.record(42).exists())
        self.assertTrue(self.record(57).exists())
        heading = text.index("## 28 Sep 2026 -- Dave's hands-on pass")
        self.assertLess(text.index("Newest first."), heading)
        self.assertLess(heading, text.index("### C-42 -- check 42"))
        self.assertLess(text.index("### C-42 -- check 42"), text.index("## 19 Sep 2026"))
        self.assertIn("Confirmed 28 Sep 2026: fine at 800x600", text)
        self.assertNotIn("\n\n\n", text)

    def test_a_second_batch_the_same_day_joins_that_days_section(self):
        new_check.confirm_checks(self.root, [42], date(2026, 9, 28))
        new_check.confirm_checks(self.root, [57], date(2026, 9, 28))

        text = self.archive.read_text(encoding="utf-8")
        self.assertEqual(text.count("## 28 Sep 2026"), 1)
        self.assertLess(text.index("### C-42"), text.index("### C-57"))
        self.assertLess(text.index("### C-57"), text.index("## 19 Sep 2026"))

    def test_an_unknown_id_changes_nothing(self):
        with self.assertRaises(ValueError):
            new_check.confirm_checks(self.root, [42, 99], date(2026, 9, 28))

        self.assertEqual(self.archive.read_text(encoding="utf-8"), ARCHIVE)
        self.assertTrue(self.record(42).exists())

    def test_ids_parse_with_or_without_the_prefix(self):
        self.assertEqual(
            [new_check.parse_check_id(raw) for raw in ("C-42", "c-7", "13,")], [42, 7, 13]
        )
        with self.assertRaises(ValueError):
            new_check.parse_check_id("X-1")

    def test_lines_still_naming_the_id_are_listed(self):
        (self.root / "NEXTSTEPS.md").write_text(
            "- waits for C-42 to pass\n- C-420 is a different check\n", encoding="utf-8"
        )

        self.assertEqual(
            new_check.still_mentioned(self.root, [42]),
            ["NEXTSTEPS.md:1: - waits for C-42 to pass"],
        )


RECORD = """# Plan review -- 28 Sep 2026

<!-- CONTEXT: review-record | LOAD: on-demand -->
Reviewed: abc123 | Since: first run

## Follow-through

None -- first run.

## Findings

| Id | Finding | Disposition |
| --- | --- | --- |
| F1 | a stale restriction | Queued -- PERF-3 in plans/now/hot-path-queries.md |
| F2 | a small scan | **Rejected**: costs more than it saves |
| F3 | a dead pointer | Fixed in `plans/README.md` |

## Hand-offs
"""


class RenumberClashesTest(unittest.TestCase):
    """finish moves a branch's new check off an id master spent since the fork."""

    def test_only_clashing_ids_move_past_every_id_in_use(self):
        self.assertEqual(new_check.plan_renumbers({150, 151}, {149, 150, 153}), {150: 154})
        self.assertEqual(new_check.plan_renumbers({160}, {150}), {})

    def test_rewrite_leaves_longer_ids_alone(self):
        self.assertEqual(
            new_check.rewrite_ids("C-150 and C-1500, C-15", {150: 154}), "C-154 and C-1500, C-15"
        )

    def git(self, *args):
        subprocess.run(["git", "-C", str(self.root), *args], check=True, capture_output=True)

    def write(self, rel, text):
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def test_a_branch_check_clashing_with_master_is_renamed_and_its_plan_follows(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root, ignore_errors=True)
        self.git("init", "-q", "-b", "master")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "t")
        self.write("checks/ready/C-4.md", ready_record(4))
        self.write("plans/now/sample.md", "Status: active\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "base")
        self.git("checkout", "-q", "-b", "work")
        self.write("checks/ready/C-5.md", ready_record(5))
        self.write("plans/now/sample.md", "Status: active | C-5 filed\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "branch check")
        self.git("checkout", "-q", "master")
        self.write("checks/ready/C-5.md", "# C-5 -- master's own\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "master check")
        self.git("checkout", "-q", "work")

        self.assertEqual(new_check.renumber_clashes(self.root, "master"), {5: 6})
        self.assertTrue((self.root / "checks/ready/C-6.md").read_text().startswith("# C-6 --"))
        self.assertIn("C-6 filed", (self.root / "plans/now/sample.md").read_text())
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "renumber")
        self.git("merge", "-q", "master", "-m", "merge")  # raises on an add/add conflict
        self.assertEqual(new_check.renumber_clashes(self.root, "master"), {})


class ReviewRecordTest(unittest.TestCase):
    def errors(self, text: str) -> list[str]:
        return check_docs.review_record_errors("docs/plan-review-2026-09-28.md", text)

    def test_a_record_with_every_finding_disposed_of_passes(self):
        self.assertEqual(self.errors(RECORD), [])

    def test_a_finding_left_as_prose_fails(self):
        errors = self.errors(
            RECORD.replace("Queued -- PERF-3 in plans/now/hot-path-queries.md", "worth a look")
        )

        self.assertTrue(any("row 'F1' has no disposition" in e for e in errors), errors)

    def test_queued_must_name_the_slice_that_holds_it(self):
        errors = self.errors(
            RECORD.replace("Queued -- PERF-3 in plans/now/hot-path-queries.md", "Queued -- later")
        )

        self.assertTrue(any("without naming the slice id" in e for e in errors), errors)

    def test_a_bare_disposition_word_fails(self):
        errors = self.errors(RECORD.replace("**Rejected**: costs more than it saves", "Rejected"))

        self.assertTrue(any("says Rejected but not how" in e for e in errors), errors)

    def test_only_the_follow_through_may_say_shipped(self):
        follow_through = "| Previous finding | Disposition |\n| --- | --- |\n| F9 | Shipped -- IDLE-1 |"
        self.assertEqual(self.errors(RECORD.replace("None -- first run.", follow_through)), [])

        errors = self.errors(RECORD.replace("Fixed in `plans/README.md`", "Shipped in IDLE-1"))
        self.assertTrue(any("row 'F3' has no disposition" in e for e in errors), errors)

    def test_a_table_without_a_disposition_column_fails(self):
        errors = self.errors(RECORD.replace("| Disposition |", "| Outcome |"))

        self.assertTrue(any("no Disposition column" in e for e in errors), errors)

    def test_both_sections_are_required(self):
        errors = self.errors(RECORD.split("## Follow-through")[0])

        self.assertEqual(len(errors), 2, errors)

    def test_older_free_form_reviews_are_not_held_to_it(self):
        self.assertIsNone(
            check_docs.REVIEW_RECORD_MARKER.search("<!-- CONTEXT: review | LAYER: on-demand -->")
        )
        self.assertIsNotNone(
            check_docs.REVIEW_RECORD_MARKER.search("<!-- CONTEXT: review-record | LOAD: on-demand -->")
        )


REVIEW_DUE_SPEC = importlib.util.spec_from_file_location(
    "review_due", CHECK_DOCS_PATH.with_name("review_due.py")
)
review_due = importlib.util.module_from_spec(REVIEW_DUE_SPEC)
sys.modules["review_due"] = review_due  # its dataclasses look their module up
REVIEW_DUE_SPEC.loader.exec_module(review_due)


class ReviewDueTest(unittest.TestCase):
    def test_a_prompt_header_gives_its_key_and_watches(self):
        prompt = review_due.parse_prompt(
            Path("x.md"),
            "# X\n\n<!-- CONTEXT: review-prompt -->\nRecord key: save-review\n"
            "Watches: scripts/saving.gd tests\n",
        )
        self.assertEqual(prompt.key, "save-review")
        self.assertEqual(prompt.watches, ["scripts/saving.gd", "tests"])

    def test_a_prompt_without_a_record_has_no_key(self):
        prompt = review_due.parse_prompt(Path("x.md"), "# X\nRecord key: none (stage 2 writes it)\n")
        self.assertIsNone(prompt.key)
        self.assertEqual(prompt.watches, [])

    def test_the_newest_record_wins_and_other_keys_are_ignored(self):
        tracked = [
            "docs/save-review-2026-09-30.md",
            "docs/save-review-2026-10-07.md",
            "docs/agent-workflow-review-2026-10-09.md",
            "plans/archive/save-review_2026-09-01.md",
        ]
        self.assertEqual(
            review_due.latest_record("save-review", tracked),
            ("docs/save-review-2026-10-07.md", "2026-10-07"),
        )
        self.assertIsNone(review_due.latest_record("ui-review", tracked))

    def test_an_archived_record_counts(self):
        tracked = ["plans/archive/architecture-review_2026-09-24.md"]
        self.assertEqual(
            review_due.latest_record("architecture-review", tracked)[0],
            "plans/archive/architecture-review_2026-09-24.md",
        )

    def test_the_reviewed_commit_comes_from_the_header(self):
        text = "# R\n\nReviewed: b9854e5 | Since: first run | Scope: all\n"
        self.assertEqual(review_due.reviewed_commit(text), "b9854e5")
        self.assertIsNone(review_due.reviewed_commit("# R\nno header\n"))

    def test_every_review_in_the_repo_watches_paths_that_exist(self):
        prompts = review_due.load_prompts()
        self.assertTrue(any(prompt.watches for prompt in prompts))
        self.assertEqual(review_due.missing_watches(prompts), [])

    def test_every_review_in_the_repo_states_a_level_a_runner_exists_for(self):
        # /run-reviews dispatches review-runner-<level>; only these two exist.
        for prompt in review_due.load_prompts():
            self.assertIn(prompt.reasoning, ("medium", "high"), prompt.path)


if __name__ == "__main__":
    unittest.main()
