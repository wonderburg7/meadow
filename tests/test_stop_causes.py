from datetime import date
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import stop_causes  # noqa: E402

TODAY = date(2026, 10, 23)
BASELINE = {"failures": [
    {"test": "tests.test_a.A.test_one", "disposition": "fixture lock timeout", "owner": "Dave", "expires": "2026-11-01"},
    {"test": "tests.test_a.A.test_old", "disposition": "old", "owner": "Dave", "expires": "2026-10-01"},
]}


def category(text):
    return stop_causes.classify(text, BASELINE, TODAY)[0]


class StopCauseTests(unittest.TestCase):
    def test_sandbox_job_denied(self):
        self.assertEqual(category("Receive-Job: Access is denied"), "sandbox")
        self.assertEqual(category("unit tests: PowerShell could not read this background job (x)"), "sandbox")

    def test_refused_push(self):
        self.assertEqual(category(" ! [remote rejected] claude/L-1 -> claude/L-1 (refusing to allow an OAuth App)"), "credentials")
        self.assertEqual(category("fatal: Authentication failed for 'https://x'"), "credentials")

    def test_import_cache(self):
        self.assertEqual(category("godot cache: FAILED (not a code fault) -- run the Fix command"), "import-cache")

    def test_lock_and_cwd_holder(self):
        self.assertEqual(category("slice lifecycle is busy: finish has held it"), "lock")
        self.assertEqual(category("error: failed to delete worktree: Directory not empty"), "cwd-holder")

    def test_approval_policy(self):
        self.assertEqual(category("The command requires approval and auto-approval is off"), "approval-policy")

    def test_baseline_vs_code(self):
        listed = "FAIL: test_one (tests.test_a.A.test_one)\n"
        self.assertEqual(category(listed), "baseline")
        self.assertEqual(category(listed + "ERROR: test_new (tests.test_a.A.test_new)\n"), "code")
        self.assertEqual(category("FAIL: test_old (tests.test_a.A.test_old)\n"), "code")
        self.assertEqual(category("AssertionError: nope"), "code")

    def test_every_category_has_a_remedy(self):
        for name, _pattern, remedy in stop_causes.CAUSES:
            self.assertTrue(remedy, name)

    def test_expired_entry_is_reported(self):
        problems = stop_causes.expired_entries(BASELINE, TODAY)
        self.assertEqual(len(problems), 1)
        self.assertIn("test_old", problems[0])
        self.assertEqual(stop_causes.expired_entries({"failures": [{"test": "x"}]}, TODAY)[0][:7], "entry 1")

    def test_shipped_baseline_has_no_expired_entry(self):
        self.assertEqual(stop_causes.expired_entries(), [])


if __name__ == "__main__":
    unittest.main()
