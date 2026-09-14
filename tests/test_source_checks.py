"""Focused regression tests for Meadow's source and workflow checks."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import tomllib
import unittest


SOURCE_CHECKS_PATH = Path(__file__).with_name("source_checks.py")
CHECK_DOCS_PATH = SOURCE_CHECKS_PATH.parent.parent / "tools" / "check_docs.py"
SLICE_PATH = SOURCE_CHECKS_PATH.parent.parent / "tools" / "slice.ps1"
VERIFY_PATH = SOURCE_CHECKS_PATH.parent.parent / "tools" / "verify.ps1"
CODEX_CONFIG_PATH = SOURCE_CHECKS_PATH.parent.parent / ".codex" / "config.toml"
CODEX_RULES_PATH = (
    SOURCE_CHECKS_PATH.parent.parent / ".codex" / "rules" / "meadow.rules"
)
ENVIRONMENT_CONFIG_PATH = (
    SOURCE_CHECKS_PATH.parent.parent / ".codex" / "environment.toml"
)
PREREQUISITES_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "prerequisites.gd"
SETTINGS_CATALOGUE_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "settings_catalogue.gd"
CHALLENGE_RUNNER_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "challenge_runner.gd"
CHALLENGE_STAGES_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "challenge_stages.gd"
BEE_FORAGING_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "bee_foraging.gd"
SPEC = importlib.util.spec_from_file_location("source_checks", SOURCE_CHECKS_PATH)
source_checks = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(source_checks)
CHECK_DOCS_SPEC = importlib.util.spec_from_file_location("check_docs", CHECK_DOCS_PATH)
check_docs = importlib.util.module_from_spec(CHECK_DOCS_SPEC)
CHECK_DOCS_SPEC.loader.exec_module(check_docs)


class BracketChecksTest(unittest.TestCase):
    def test_premature_closer_cannot_cancel_with_later_opener(self):
        problems = []

        source_checks.check_brackets("sample.gd", ["var value = )("], problems)

        self.assertTrue(
            any("unexpected closing )" in problem for problem in problems), problems
        )
        self.assertTrue(any("unclosed (" in problem for problem in problems), problems)

    def test_nested_brackets_must_close_in_order(self):
        problems = []

        source_checks.check_brackets("sample.gd", ["var value = ([)]"], problems)

        self.assertTrue(any("does not match" in problem for problem in problems), problems)

    def test_balanced_brackets_ignore_strings_and_comments(self):
        problems = []

        source_checks.check_brackets(
            "sample.gd",
            ['var text = "]" # )', "var value = ({[]})"],
            problems,
        )

        self.assertEqual([], problems)


class ForagingPrerequisiteContractTest(unittest.TestCase):
    def test_orientation_flight_and_scouting_are_symmetric_alternatives(self):
        source = PREREQUISITES_PATH.read_text(encoding="utf-8")
        prerequisite_map = source.split("const TOGGLE_PREREQUISITE := {", 1)[1].split("}", 1)[0]
        mutual_exclusion_map = source.split("const MUTUALLY_EXCLUSIVE := {", 1)[1].split("}", 1)[0]

        self.assertNotIn('"scouting_on": "orientation_flight_on"', prerequisite_map)
        self.assertIn('"orientation_flight_on": "scouting_on"', mutual_exclusion_map)
        self.assertIn('"scouting_on": "orientation_flight_on"', mutual_exclusion_map)
        self.assertIn("MUTUALLY_EXCLUSIVE.has(key)", source)

        settings_catalogue_source = SETTINGS_CATALOGUE_PATH.read_text(encoding="utf-8")
        prerequisite_cascade = settings_catalogue_source.split("static func _cascade_prerequisites_on_static", 1)[1].split(
            "static func _cascade_dependents_off_static", 1
        )[0]
        self.assertIn("_cascade_mutual_exclusion_static(parent)", prerequisite_cascade)


class ChallengeOneOverflowContractTest(unittest.TestCase):
    def test_only_the_pollen_automation_stage_can_discard_queen_nectar(self):
        stages = CHALLENGE_STAGES_PATH.read_text(encoding="utf-8")
        runner = CHALLENGE_RUNNER_PATH.read_text(encoding="utf-8")
        foraging = BEE_FORAGING_PATH.read_text(encoding="utf-8")

        self.assertIn('const C1_DISCARD_STAGES := ["1.14"]', stages)
        self.assertNotIn('"1.12"', stages.split("const C1_DISCARD_STAGES", 1)[1].splitlines()[0])
        predicate = runner.split("func discards_overflow", 1)[1].split(
            "func announce_overflow_discard", 1
        )[0]
        self.assertIn(
            "_stages()[_stage_index].id in Stages.C1_DISCARD_STAGES", predicate
        )
        self.assertIn("active and Session.starting_level == 1", predicate)
        self.assertIn("bee == main.queen", predicate)
        self.assertIn('bee.current_load_type == "nectar"', predicate)

        discard_branch = foraging.split("discards_overflow(bee):", 1)[1].split(
            "# Keep the load until a cell changes.", 1
        )[0]
        self.assertLess(
            discard_branch.index("announce_overflow_discard()"),
            discard_branch.index("bee.current_load = 0.0"),
        )
        retained_load = foraging.split("# Keep the load until a cell changes.", 1)[1].split(
            "var approach", 1
        )[0]
        self.assertIn("bee.deposit_blocked_epoch = bee.hive.index_epoch", retained_load)
        self.assertNotIn("bee.current_load = 0.0", retained_load)

    def test_each_real_discard_replaces_the_hint_with_an_explanation(self):
        runner = CHALLENGE_RUNNER_PATH.read_text(encoding="utf-8")
        prompt = runner.split("func announce_overflow_discard", 1)[1].split(
            "## Slice 18:", 1
        )[0]

        self.assertIn("_c1_overflow_discard_count += 1", prompt)
        self.assertIn("main.gallerin_panel.clear_queue()", prompt)
        self.assertIn("main.gallerin_panel.show_now({", prompt)
        self.assertIn("comb has no room for nectar", prompt)

        stage_entry = runner.split("func _enter_stage", 1)[1].split(
            "func _built_cell_count", 1
        )[0]
        self.assertIn("_c1_overflow_discard_count = 0", stage_entry)


class QueueSchemaChecksTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        (self.root / "scripts").mkdir()
        (self.root / "scripts" / "sample.gd").write_text(
            "func already_built():\n\tpass\n", encoding="utf-8"
        )

    def tearDown(self):
        self.temp_dir.cleanup()

    def proof_errors(self, line: str) -> list[str]:
        errors = []
        check_docs.validate_queue_proof(line, 1, self.root, errors)
        return errors

    def test_missing_proof_is_rejected(self):
        errors = self.proof_errors("- Files: `scripts/sample.gd`")

        self.assertEqual(1, len(errors), errors)
        self.assertIn("Proof: missing", errors[0])

    def test_unbackticked_proof_is_rejected(self):
        errors = self.proof_errors(
            "- Proof: absent: scripts/sample.gd :: new_function"
        )

        self.assertEqual(1, len(errors), errors)
        self.assertIn("must be backticked", errors[0])

    def test_malformed_proof_is_rejected(self):
        errors = self.proof_errors(
            "- Proof: `sometimes: scripts/sample.gd :: new_function`"
        )

        self.assertEqual(1, len(errors), errors)
        self.assertIn("must start with 'present:' or 'absent:'", errors[0])

    def test_false_proof_is_rejected(self):
        errors = self.proof_errors(
            "- Proof: `present: scripts/sample.gd :: not_in_the_file`"
        )

        self.assertEqual(1, len(errors), errors)
        self.assertIn("proof no longer holds", errors[0])

    def test_valid_proof_passes(self):
        errors = self.proof_errors(
            "- Proof: `absent: scripts/sample.gd :: new_function`"
        )

        self.assertEqual([], errors)

    def test_placeholder_files_value_is_rejected(self):
        errors = []
        check_docs.validate_queue_files(
            "- Files: see the named plan heading", 1, errors
        )

        self.assertEqual(1, len(errors), errors)
        self.assertIn("placeholder prose is not allowed", errors[0])

    def test_exact_repository_relative_files_pass(self):
        errors = []
        check_docs.validate_queue_files(
            "- Files: `scripts/sample.gd`, `tools/check_docs.py`", 1, errors
        )

        self.assertEqual([], errors)

    def test_an_id_in_both_queue_sections_is_rejected(self):
        text = (
            "## Next up\n\n"
            "1. **[Claude] X-1 -- does a thing.**\n"
            "   - Plan: `plans/now/x.md`\n"
            "   - Files: `scripts/x.gd`\n"
            "   - Check: something\n"
            "   - Proof: `absent: scripts/x.gd :: thing`\n"
            "   - Next after: X-2.\n\n"
            "## Not in the queue, and why\n\n"
            "- **X-1** -- waiting on Dave.\n"
        )
        errors = []

        check_docs.check_queue_section_agreement(errors, text)

        self.assertEqual(1, len(errors), errors)
        self.assertIn("X-1", errors[0])

    def test_a_prose_mention_of_a_ready_id_is_not_rejected(self):
        text = (
            "## Next up\n\n"
            "1. **[Claude] X-1 -- does a thing.**\n"
            "   - Plan: `plans/now/x.md`\n"
            "   - Files: `scripts/x.gd`\n"
            "   - Check: something\n"
            "   - Proof: `absent: scripts/x.gd :: thing`\n"
            "   - Next after: X-2.\n\n"
            "## Not in the queue, and why\n\n"
            "- **X-3** -- waits for X-1 to ship first.\n"
        )
        errors = []

        check_docs.check_queue_section_agreement(errors, text)

        self.assertEqual([], errors)


class SliceDoctorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.powershell = shutil.which("pwsh") or shutil.which("powershell")
        if not cls.powershell:
            raise unittest.SkipTest("PowerShell is required for slice.ps1 doctor tests")

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.remote_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.remote = Path(self.remote_dir.name) / "origin.git"
        (self.root / "tools").mkdir()
        (self.root / "plans").mkdir()
        (self.root / "scripts").mkdir()
        (self.root / ".codex").mkdir()
        (self.root / "checks" / "ready").mkdir(parents=True)
        shutil.copy2(SLICE_PATH, self.root / "tools" / "slice.ps1")
        shutil.copy2(VERIFY_PATH, self.root / "tools" / "verify.ps1")
        shutil.copy2(CHECK_DOCS_PATH, self.root / "tools" / "check_docs.py")
        (self.root / "plans" / "workstreams.md").write_text(
            "| Worktree path (branch) | Lane |\n| --- | --- |\n", encoding="utf-8"
        )
        (self.root / "checks" / "ready.md").write_text(
            "# Ready hands-on checks\n"
            "\n"
            "<!-- CONTEXT: player-checks | LAYER: on-demand -->\n"
            "\n"
            "Shipped behaviours that static checks cannot prove. Each ready check has its own\n"
            "record, so parallel feature slices do not edit a shared page. Reply by id, for\n"
            'example: "C-1 pass" or "C-1 fails: <what I saw>".\n'
            "\n"
            "This index is generated during slice closeout. Move a confirmed or superseded\n"
            "entry to `docs/archive/HANDS_ON_CHECKS_ARCHIVE.md`; move an on-demand check\n"
            "that cannot run to `checks/blocked.md`, naming its unblocker.\n"
            "\n"
            "## Ready to run\n"
            "\n",
            encoding="utf-8",
        )
        (self.root / "scripts" / "sample.gd").write_text(
            "func existing():\n\tpass\n", encoding="utf-8"
        )
        subprocess.run(
            ["git", "init", "-b", "master"],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=True,
        )
        subprocess.run(
            ["git", "init", "--bare", str(self.remote)],
            capture_output=True,
            text=True,
            check=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "Meadow Test"],
            cwd=self.root,
            check=True,
        )
        subprocess.run(
            ["git", "config", "user.email", "meadow@example.invalid"],
            cwd=self.root,
            check=True,
        )
        (self.root / ".codex" / "config.toml").write_text(
            "[mcp_servers.godot.env]\n"
            f"GODOT_PATH = '{Path(self.powershell).as_posix()}'\n",
            encoding="utf-8",
        )
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)
        subprocess.run(
            ["git", "commit", "-m", "fixture"],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=True,
        )
        subprocess.run(
            ["git", "remote", "add", "origin", str(self.remote)],
            cwd=self.root,
            check=True,
        )
        subprocess.run(
            ["git", "push", "-u", "origin", "master"],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=True,
        )

    def tearDown(self):
        self.temp_dir.cleanup()
        self.remote_dir.cleanup()

    def write_queue(self, proof: str) -> None:
        (self.root / "NEXTSTEPS.md").write_text(
            "## Next up\n\n"
            "1. **[Codex] T-1 -- fixture.**\n"
            "   - Plan: `plans/fixture.md` -- fixture\n"
            "   - Files: `scripts/sample.gd`\n"
            "   - Check: deterministic\n"
            f"   - Proof: {proof}\n"
            "   - Next after: none -- fixture plan is complete\n",
            encoding="utf-8",
        )

    def write_refill(self, worktree: Path, delivered_id: str = "T-1") -> None:
        """Simulate the session's own archive-and-refill edit on the branch.

        L-5 makes `finish` gate on this (and commit it inside the merge)
        rather than perform it: the archived write-up and a successor's own
        Plan/Files/Check/Proof/Next after lines are still authored by hand,
        same as today. This fixture's `Next after:` is always "none -- ...
        is complete", so the refill is just removal; promotion is exercised
        separately in test_refill_promotes_the_named_successor.
        """
        archive_dir = worktree / "plans" / "archive"
        archive_dir.mkdir(parents=True, exist_ok=True)
        (archive_dir / f"{delivered_id}_2026-01-01.md").write_text(
            f"# {delivered_id} (archived)\n\nShipped in this fixture.\n",
            encoding="utf-8",
        )
        (worktree / "NEXTSTEPS.md").write_text("## Next up\n\n", encoding="utf-8")
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(
            ["git", "commit", "-m", "archive and refill the queue"],
            cwd=worktree,
            check=True,
        )

    def run_doctor(self, *extra_args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                self.powershell,
                "-NoProfile",
                "-File",
                str(self.root / "tools" / "slice.ps1"),
                "doctor",
                "-Lane",
                "Codex",
                *extra_args,
            ],
            cwd=self.root,
            capture_output=True,
            text=True,
        )

    def test_doctor_reports_ready_without_mutating_git(self):
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        before = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=True,
        ).stdout

        result = self.run_doctor()

        after = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=True,
        ).stdout
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("ready", json.loads(result.stdout)["status"])
        self.assertEqual(before, after)
        refs = subprocess.run(
            ["git", "for-each-ref", "--format=%(refname)", "refs/codex-doctor"],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=True,
        ).stdout
        self.assertEqual("", refs)

    def test_doctor_names_the_bounded_plan_read_and_the_successor(self):
        """A claimed slice must arrive with its own reading command attached.

        Both agents are told to read only the slice's plan heading, and
        `tools/heading.py` is the reader that does it, but neither the policy
        files nor the lifecycle output named it: a 24-task Codex sample used
        it zero times and read the whole 25 KB queue instead. The command is
        cheap to emit here and impossible to get wrong downstream.
        """
        self.write_queue("`absent: scripts/sample.gd :: new_function`")

        result = self.run_doctor()

        self.assertEqual(0, result.returncode, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(
            'python tools/heading.py plans/fixture.md "fixture"', payload["read"]
        )
        self.assertEqual("none -- fixture plan is complete", payload["next_after"])

    def test_doctor_reports_whether_the_global_git_excludes_file_is_readable(self):
        """Report the excludes path and what to type; never change it.

        Codex rollouts log a permissions warning naming the user-level Git
        excludes file, which reads fine from an ordinary Windows session --
        so the warning is about sandbox scope, not an ACL. The diagnostic
        exists so the next run captures which it is instead of guessing, and
        it is deliberately not a failure: the lifecycle works either way.
        """
        self.write_queue("`absent: scripts/sample.gd :: new_function`")

        result = self.run_doctor()

        self.assertEqual(0, result.returncode, result.stderr)
        diagnostic = json.loads(result.stdout)["git_excludes"]
        self.assertRegex(diagnostic, r"^(readable|absent|unreadable) \(")
        if diagnostic.startswith("unreadable"):
            self.assertIn("icacls", diagnostic)

    def test_doctor_and_doc_check_share_unbackticked_proof_error(self):
        self.write_queue("absent: scripts/sample.gd :: new_function")
        doc_errors = []
        check_docs.validate_queue_proof(
            "- Proof: absent: scripts/sample.gd :: new_function",
            1,
            self.root,
            doc_errors,
        )

        result = self.run_doctor()

        self.assertNotEqual(0, result.returncode)
        self.assertIn(doc_errors[0], result.stderr)

    def test_doctor_reports_all_environment_failures_together(self):
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        subprocess.run(
            ["git", "config", "user.name", ""], cwd=self.root, check=True
        )
        subprocess.run(
            ["git", "config", "user.email", ""], cwd=self.root, check=True
        )
        (self.root / ".codex" / "config.toml").write_text(
            "[mcp_servers.godot.env]\nGODOT_PATH = 'missing-godot.exe'\n",
            encoding="utf-8",
        )
        subprocess.run(
            ["git", "remote", "set-url", "origin", str(self.root / "missing.git")],
            cwd=self.root,
            check=True,
        )

        result = self.run_doctor("-PythonPath", str(self.root / "missing-python.exe"))

        self.assertNotEqual(0, result.returncode)
        for prefix in ("Python:", "Godot:", "Git identity:", "Remote reachability:"):
            self.assertIn(prefix, result.stderr)

    def test_branch_verification_ignores_another_lanes_stale_ledger_row(self):
        """A branch's own suites must not fail on the other lane's leftover
        ledger bookkeeping -- only the primary checkout's run is on the hook
        for that (see check_docs.py's `primary_checkout` docstring)."""
        self.write_queue("`absent: scripts/sample.gd :: new_function`")

        stub_exit_zero = "import sys\nsys.exit(0)\n"
        tests_dir = self.root / "tests"
        tests_dir.mkdir()
        (tests_dir / "__init__.py").write_text("", encoding="utf-8")
        (tests_dir / "source_checks.py").write_text(stub_exit_zero, encoding="utf-8")
        (tests_dir / "balance_tests.py").write_text(stub_exit_zero, encoding="utf-8")
        (tests_dir / "test_source_checks.py").write_text(
            "import unittest\n\n\n"
            "class Placeholder(unittest.TestCase):\n"
            "    def test_noop(self):\n"
            "        pass\n",
            encoding="utf-8",
        )
        (self.root / "tools" / "update_function_map.py").write_text(
            stub_exit_zero, encoding="utf-8"
        )
        (self.root / "tools" / "godot_compile_check.py").write_text(
            stub_exit_zero, encoding="utf-8"
        )
        (self.root / "tools" / "stage_reference.py").write_text(
            stub_exit_zero, encoding="utf-8"
        )

        # A row naming a worktree that was never created with 'git worktree
        # add' -- exactly what a killed session, or a lane mid-closeout,
        # leaves behind.
        ledger_path = self.root / "plans" / "workstreams.md"
        ledger_path.write_text(
            ledger_path.read_text(encoding="utf-8")
            + "| `.worktrees/ghost` (`codex/ghost`) | Codex |\n",
            encoding="utf-8",
        )

        subprocess.run(["git", "add", "."], cwd=self.root, check=True)
        subprocess.run(
            ["git", "commit", "-m", "fixture: stub suites and a stale ledger row"],
            cwd=self.root,
            check=True,
        )

        worktree = self.root / ".worktrees" / "scope-test"
        subprocess.run(
            ["git", "worktree", "add", "-b", "claude/scope-test", str(worktree)],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=True,
        )

        branch_result = subprocess.run(
            [
                self.powershell,
                "-NoProfile",
                "-File",
                str(worktree / "tools" / "verify.ps1"),
                "-Scope",
                "branch",
                "-PythonPath",
                sys.executable,
            ],
            cwd=worktree,
            capture_output=True,
            text=True,
            timeout=120,
        )
        self.assertEqual(
            0, branch_result.returncode, branch_result.stdout + branch_result.stderr
        )

        primary_result = subprocess.run(
            [
                self.powershell,
                "-NoProfile",
                "-File",
                str(self.root / "tools" / "verify.ps1"),
                "-Scope",
                "primary",
                "-PythonPath",
                sys.executable,
            ],
            cwd=self.root,
            capture_output=True,
            text=True,
            timeout=120,
        )
        self.assertNotEqual(0, primary_result.returncode)
        self.assertIn(
            "stale row, worktree no longer exists: .worktrees/ghost",
            primary_result.stdout + primary_result.stderr,
        )

    def test_mock_slice_can_claim_commit_and_close(self):
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet)\n"
            "if ($PythonPath -and -not (Test-Path -LiteralPath $PythonPath)) { exit 1 }\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\n"
            "exit 0\n",
            encoding="utf-8",
        )
        subprocess.run(
            ["git", "add", "NEXTSTEPS.md", "tools/verify.ps1"],
            cwd=self.root,
            check=True,
        )
        subprocess.run(
            ["git", "commit", "-m", "use mock verifier"],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=True,
        )

        start = subprocess.run(
            [
                self.powershell,
                "-NoProfile",
                "-File",
                str(self.root / "tools" / "slice.ps1"),
                "start",
                "-Lane",
                "Codex",
            ],
            cwd=self.root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, start.returncode, start.stderr)
        worktree = self.root / ".worktrees" / "T-1"
        with (worktree / "scripts" / "sample.gd").open(
            "a", encoding="utf-8"
        ) as source:
            source.write("\nfunc new_function():\n\tpass\n")
        self.write_refill(worktree)

        finish = subprocess.run(
            [
                self.powershell,
                "-NoProfile",
                "-Command",
                "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                    str(worktree).replace("'", "''"),
                    str(worktree / "tools" / "slice.ps1").replace("'", "''"),
                ),
            ],
            cwd=self.root,
            capture_output=True,
            text=True,
            timeout=90,
        )
        self.assertEqual(0, finish.returncode, finish.stderr)
        self.assertIn("Slice landed: T-1", finish.stdout)
        self.assertFalse(worktree.exists())
        self.assertEqual(
            [],
            subprocess.run(
                ["git", "branch", "--list", "codex/T-1"],
                cwd=self.root,
                capture_output=True,
                text=True,
                check=True,
            ).stdout.splitlines(),
        )
        self.assertIn(
            "func new_function():",
            (self.root / "scripts" / "sample.gd").read_text(encoding="utf-8"),
        )

    def test_finish_completes_when_the_worktree_directory_cannot_be_deleted(self):
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet)\n"
            "if ($PythonPath -and -not (Test-Path -LiteralPath $PythonPath)) { exit 1 }\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\n"
            "exit 0\n",
            encoding="utf-8",
        )
        subprocess.run(
            ["git", "add", "NEXTSTEPS.md", "tools/verify.ps1"],
            cwd=self.root,
            check=True,
        )
        subprocess.run(
            ["git", "commit", "-m", "use mock verifier"],
            cwd=self.root,
            capture_output=True,
            text=True,
            check=True,
        )

        start = subprocess.run(
            [
                self.powershell,
                "-NoProfile",
                "-File",
                str(self.root / "tools" / "slice.ps1"),
                "start",
                "-Lane",
                "Codex",
            ],
            cwd=self.root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(0, start.returncode, start.stderr)
        worktree = self.root / ".worktrees" / "T-1"
        with (worktree / "scripts" / "sample.gd").open(
            "a", encoding="utf-8"
        ) as source:
            source.write("\nfunc new_function():\n\tpass\n")
        self.write_refill(worktree)

        held_path = worktree / "held-open.txt"
        held_path.write_text("locked", encoding="utf-8")
        handle = open(held_path, "r", encoding="utf-8")
        try:
            finish = subprocess.run(
                [
                    self.powershell,
                    "-NoProfile",
                    "-Command",
                    "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                        str(worktree).replace("'", "''"),
                        str(worktree / "tools" / "slice.ps1").replace("'", "''"),
                    ),
                ],
                cwd=self.root,
                capture_output=True,
                text=True,
                timeout=90,
            )
            self.assertEqual(0, finish.returncode, finish.stderr)
            self.assertIn("Slice landed: T-1", finish.stdout)
            self.assertIn("queued in pending deletions", finish.stdout)
            self.assertTrue(worktree.exists())

            self.assertEqual(
                [],
                subprocess.run(
                    ["git", "branch", "--list", "codex/T-1"],
                    cwd=self.root,
                    capture_output=True,
                    text=True,
                    check=True,
                ).stdout.splitlines(),
            )
            self.assertEqual(
                [],
                [
                    line
                    for line in (self.root / "plans" / "workstreams.md")
                    .read_text(encoding="utf-8")
                    .splitlines()
                    if "T-1" in line
                ],
            )

            common_dir = subprocess.run(
                ["git", "rev-parse", "--git-common-dir"],
                cwd=self.root,
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
            queue_path = (
                (self.root / common_dir).resolve() / "meadow-slice-pending-deletions"
            )
            self.assertTrue(queue_path.exists())
            self.assertIn(
                ".worktrees/T-1", queue_path.read_text(encoding="utf-8")
            )

            # check_docs.py's orphan-directory check must skip a directory
            # named in the pending-deletions queue rather than fail on it.
            errors: list[str] = []
            warnings: list[str] = []
            original_root = check_docs.ROOT
            check_docs.ROOT = self.root
            try:
                check_docs.check_workstreams(errors, warnings)
            finally:
                check_docs.ROOT = original_root
            self.assertEqual([], errors)
            self.assertTrue(
                any("meadow-slice-pending-deletions" in warning for warning in warnings)
            )
        finally:
            handle.close()

        doctor = self.run_doctor()
        self.assertFalse(worktree.exists())
        self.assertFalse(queue_path.exists())

    def test_resume_completes_a_failure_after_merge(self):
        """A merge is durable even when the original finish process dies."""
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet)\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\nexit 0\n",
            encoding="utf-8",
        )
        subprocess.run(
            ["git", "add", "NEXTSTEPS.md", "tools/verify.ps1"], cwd=self.root, check=True
        )
        subprocess.run(["git", "commit", "-m", "use mock verifier"], cwd=self.root, check=True)
        start = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "start", "-Lane", "Codex"],
            cwd=self.root, capture_output=True, text=True,
        )
        self.assertEqual(0, start.returncode, start.stderr)
        worktree = self.root / ".worktrees" / "T-1"
        (worktree / "scripts" / "sample.gd").write_text("func new_function():\n\tpass\n", encoding="utf-8")
        self.write_refill(worktree)
        failed = subprocess.run(
            [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                str(worktree).replace("'", "''"), str(worktree / "tools" / "slice.ps1").replace("'", "''")
            )],
            cwd=self.root, capture_output=True, text=True,
            env={**os.environ, "MEADOW_SLICE_FAIL_AFTER": "merged"},
        )
        self.assertNotEqual(0, failed.returncode)
        resumed = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "resume", "-Lane", "Codex"],
            cwd=self.root, capture_output=True, text=True,
        )
        self.assertEqual(0, resumed.returncode, resumed.stderr)
        self.assertFalse(worktree.exists())
        self.assertEqual("", subprocess.run(
            ["git", "branch", "--list", "codex/T-1"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout)
        self.assertNotIn(".worktrees/T-1", (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8"))

    def test_resume_completes_every_durable_finish_phase(self):
        """Each recorded closeout boundary can be retried without Git repair."""
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet)\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\nexit 0\n",
            encoding="utf-8",
        )
        subprocess.run(
            ["git", "add", "NEXTSTEPS.md", "tools/verify.ps1"], cwd=self.root, check=True
        )
        subprocess.run(["git", "commit", "-m", "use mock verifier"], cwd=self.root, check=True)

        phases = (
            "started", "verified", "branch-committed", "archived", "refilled",
            "merged", "pushed", "worktree-removed", "branch-deleted", "ledger-deleted",
        )
        for phase in phases:
            with self.subTest(phase=phase):
                start_env = {**os.environ}
                if phase == "started":
                    start_env["MEADOW_SLICE_FAIL_AFTER"] = phase
                started = subprocess.run(
                    [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "start", "-Lane", "Codex"],
                    cwd=self.root, capture_output=True, text=True, env=start_env,
                )
                if phase == "started":
                    self.assertNotEqual(0, started.returncode)
                    # The worktree still exists despite the injected failure
                    # (it lands after `git worktree add`) -- resume finishes
                    # it, which means the same archive/refill edit a session
                    # would already have made has to be there too.
                    (self.root / ".worktrees" / "T-1" / "scripts" / "sample.gd").write_text(
                        "func new_function():\n\tpass\n", encoding="utf-8"
                    )
                    self.write_refill(self.root / ".worktrees" / "T-1")
                else:
                    self.assertEqual(0, started.returncode, started.stderr)
                    (self.root / ".worktrees" / "T-1" / "scripts" / "sample.gd").write_text(
                        "func new_function():\n\tpass\n", encoding="utf-8"
                    )
                    self.write_refill(self.root / ".worktrees" / "T-1")
                    failed = subprocess.run(
                        [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                            str(self.root / ".worktrees" / "T-1").replace("'", "''"),
                            str(self.root / ".worktrees" / "T-1" / "tools" / "slice.ps1").replace("'", "''"),
                        )],
                        cwd=self.root, capture_output=True, text=True,
                        env={**os.environ, "MEADOW_SLICE_FAIL_AFTER": phase},
                    )
                    self.assertNotEqual(0, failed.returncode)

                resumed = subprocess.run(
                    [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "resume", "-Lane", "Codex"],
                    cwd=self.root, capture_output=True, text=True,
                )
                self.assertEqual(0, resumed.returncode, resumed.stderr)
                self.assertFalse((self.root / ".worktrees" / "T-1").exists())
                self.assertEqual("", subprocess.run(
                    ["git", "branch", "--list", "codex/T-1"], cwd=self.root,
                    capture_output=True, text=True, check=True,
                ).stdout)
                self.assertNotIn(".worktrees/T-1", (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8"))

                # The refill just consumed T-1 from NEXTSTEPS.md, and every
                # phase (including "started", whose worktree still went
                # through the same resume-driven finish) restored the mock
                # source to the queued proof. Put both back before claiming
                # the next subcase -- ordinary fixture setup, pushed with the
                # next iteration's own merge.
                (self.root / "scripts" / "sample.gd").write_text(
                    "func existing():\n\tpass\n", encoding="utf-8"
                )
                self.write_queue("`absent: scripts/sample.gd :: new_function`")
                subprocess.run(["git", "add", "scripts/sample.gd", "NEXTSTEPS.md"], cwd=self.root, check=True)
                subprocess.run(["git", "commit", "-m", "reset mock source and queue"], cwd=self.root, check=True)

    def test_finish_is_resumable_after_every_injected_phase(self):
        """Every durable closeout phase resumes to the same final state.

        L-2 of plans/now/agent-lifecycle.md: an injected failure after any
        of the seven phases below must still leave `resume` able to finish
        the job, with the merge actually landed on master -- not just the
        worktree and branch cleaned up, which a resumed run could satisfy
        by abandoning the change instead of completing it.
        """
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet)\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\nexit 0\n",
            encoding="utf-8",
        )
        subprocess.run(
            ["git", "add", "NEXTSTEPS.md", "tools/verify.ps1"], cwd=self.root, check=True
        )
        subprocess.run(["git", "commit", "-m", "use mock verifier"], cwd=self.root, check=True)

        phases = (
            "verified", "branch-committed", "archived", "refilled", "merged", "pushed",
            "worktree-removed", "branch-deleted", "ledger-deleted",
        )
        for phase in phases:
            with self.subTest(phase=phase):
                started = subprocess.run(
                    [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "start", "-Lane", "Codex"],
                    cwd=self.root, capture_output=True, text=True,
                )
                self.assertEqual(0, started.returncode, started.stderr)
                (self.root / ".worktrees" / "T-1" / "scripts" / "sample.gd").write_text(
                    "func new_function():\n\tpass\n", encoding="utf-8"
                )
                self.write_refill(self.root / ".worktrees" / "T-1")
                failed = subprocess.run(
                    [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                        str(self.root / ".worktrees" / "T-1").replace("'", "''"),
                        str(self.root / ".worktrees" / "T-1" / "tools" / "slice.ps1").replace("'", "''"),
                    )],
                    cwd=self.root, capture_output=True, text=True,
                    env={**os.environ, "MEADOW_SLICE_FAIL_AFTER": phase},
                )
                self.assertNotEqual(0, failed.returncode)

                resumed = subprocess.run(
                    [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "resume", "-Lane", "Codex"],
                    cwd=self.root, capture_output=True, text=True,
                )
                self.assertEqual(0, resumed.returncode, resumed.stderr)
                self.assertFalse((self.root / ".worktrees" / "T-1").exists())
                self.assertEqual("", subprocess.run(
                    ["git", "branch", "--list", "codex/T-1"], cwd=self.root,
                    capture_output=True, text=True, check=True,
                ).stdout)
                self.assertNotIn(".worktrees/T-1", (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8"))
                self.assertIn(
                    "func new_function():",
                    (self.root / "scripts" / "sample.gd").read_text(encoding="utf-8"),
                )

                (self.root / "scripts" / "sample.gd").write_text(
                    "func existing():\n\tpass\n", encoding="utf-8"
                )
                self.write_queue("`absent: scripts/sample.gd :: new_function`")
                subprocess.run(["git", "add", "scripts/sample.gd", "NEXTSTEPS.md"], cwd=self.root, check=True)
                subprocess.run(["git", "commit", "-m", "reset mock source and queue"], cwd=self.root, check=True)

    def test_closeout_pushes_exactly_once(self):
        """The whole transaction reaches the remote in one push.

        Before L-5, finish pushed once after the ready-index commit and
        again after the ledger commit. Counting reflog entries on the bare
        remote's master ref is a direct count of push invocations: each
        `git push` adds exactly one entry regardless of how many commits it
        carries.
        """
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet)\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\nexit 0\n",
            encoding="utf-8",
        )
        subprocess.run(
            ["git", "add", "NEXTSTEPS.md", "tools/verify.ps1"], cwd=self.root, check=True
        )
        subprocess.run(["git", "commit", "-m", "use mock verifier"], cwd=self.root, check=True)
        subprocess.run(
            ["git", "config", "core.logAllRefUpdates", "always"],
            cwd=self.remote,
            check=True,
        )

        start = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "start", "-Lane", "Codex"],
            cwd=self.root, capture_output=True, text=True,
        )
        self.assertEqual(0, start.returncode, start.stderr)
        worktree = self.root / ".worktrees" / "T-1"
        (worktree / "scripts" / "sample.gd").write_text("func new_function():\n\tpass\n", encoding="utf-8")
        self.write_refill(worktree)

        before = subprocess.run(
            ["git", "reflog", "show", "--format=%H", "refs/heads/master"],
            cwd=self.remote, capture_output=True, text=True,
        ).stdout.splitlines()

        finish = subprocess.run(
            [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                str(worktree).replace("'", "''"), str(worktree / "tools" / "slice.ps1").replace("'", "''")
            )],
            cwd=self.root, capture_output=True, text=True, timeout=90,
        )
        self.assertEqual(0, finish.returncode, finish.stderr)

        after = subprocess.run(
            ["git", "reflog", "show", "--format=%H", "refs/heads/master"],
            cwd=self.remote, capture_output=True, text=True,
        ).stdout.splitlines()
        self.assertEqual(1, len(after) - len(before), finish.stdout + finish.stderr)

    def test_refill_promotes_the_named_successor(self):
        """`refilled` gates on the branch's own edit rather than authoring
        it; once that edit is committed, closeout confirms the queue is one
        item shorter, the successor leads, and the spec has moved."""
        (self.root / "NEXTSTEPS.md").write_text(
            "## Next up\n\n"
            "1. **[Codex] T-1 -- fixture.**\n"
            "   - Plan: `plans/fixture.md` -- fixture\n"
            "   - Files: `scripts/sample.gd`\n"
            "   - Check: deterministic\n"
            "   - Proof: `absent: scripts/sample.gd :: new_function`\n"
            "   - Next after: T-2 -- the fixture's own successor.\n"
            "\n"
            "2. **[Codex] T-2 -- fixture successor.**\n"
            "   - Plan: `plans/fixture.md` -- fixture successor\n"
            "   - Files: `scripts/other.gd`\n"
            "   - Check: deterministic\n"
            "   - Proof: `absent: scripts/other.gd :: new_function`\n"
            "   - Next after: none -- fixture plan is complete\n",
            encoding="utf-8",
        )
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet)\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\nexit 0\n",
            encoding="utf-8",
        )
        subprocess.run(
            ["git", "add", "NEXTSTEPS.md", "tools/verify.ps1"], cwd=self.root, check=True
        )
        subprocess.run(["git", "commit", "-m", "use mock verifier"], cwd=self.root, check=True)

        start = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "start", "-Lane", "Codex"],
            cwd=self.root, capture_output=True, text=True,
        )
        self.assertEqual(0, start.returncode, start.stderr)
        worktree = self.root / ".worktrees" / "T-1"
        (worktree / "scripts" / "sample.gd").write_text("func new_function():\n\tpass\n", encoding="utf-8")

        archive_dir = worktree / "plans" / "archive"
        archive_dir.mkdir(parents=True, exist_ok=True)
        (archive_dir / "T-1_2026-01-01.md").write_text(
            "# T-1 (archived)\n\nShipped in this fixture.\n", encoding="utf-8"
        )
        (worktree / "NEXTSTEPS.md").write_text(
            "## Next up\n\n"
            "1. **[Codex] T-2 -- fixture successor.**\n"
            "   - Plan: `plans/fixture.md` -- fixture successor\n"
            "   - Files: `scripts/other.gd`\n"
            "   - Check: deterministic\n"
            "   - Proof: `absent: scripts/other.gd :: new_function`\n"
            "   - Next after: none -- fixture plan is complete\n",
            encoding="utf-8",
        )
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(
            ["git", "commit", "-m", "archive T-1 and promote T-2"], cwd=worktree, check=True
        )

        finish = subprocess.run(
            [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                str(worktree).replace("'", "''"), str(worktree / "tools" / "slice.ps1").replace("'", "''")
            )],
            cwd=self.root, capture_output=True, text=True, timeout=90,
        )
        self.assertEqual(0, finish.returncode, finish.stderr)
        self.assertIn("Next slice:   T-2 -- fixture successor.", finish.stdout)

        merged_queue = (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8")
        self.assertNotIn("[Codex] T-1", merged_queue)
        self.assertIn("[Codex] T-2", merged_queue)
        self.assertTrue((self.root / "plans" / "archive" / "T-1_2026-01-01.md").exists())

    def test_status_reports_a_claimed_slice(self):
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        start = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "start", "-Lane", "Codex"],
            cwd=self.root, capture_output=True, text=True,
        )
        self.assertEqual(0, start.returncode, start.stderr)
        status = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "status", "-Lane", "Codex"],
            cwd=self.root, capture_output=True, text=True,
        )
        self.assertEqual(0, status.returncode, status.stderr)
        self.assertEqual("working", json.loads(status.stdout)["state"])

    def test_stale_lifecycle_lock_does_not_require_manual_removal(self):
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        # A process killed while holding the old CreateNew lock left this file
        # behind. A new command must reclaim it once its OS handle is gone.
        (self.root / ".git" / "meadow-slice-lifecycle.lock").write_text(
            "stale", encoding="utf-8"
        )

        started = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "start", "-Lane", "Codex"],
            cwd=self.root, capture_output=True, text=True,
        )

        self.assertEqual(0, started.returncode, started.stderr)
        aborted = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "abort", "-Lane", "Codex"],
            cwd=self.root, capture_output=True, text=True,
        )
        self.assertEqual(0, aborted.returncode, aborted.stderr)


class CodexPermissionProfileTest(unittest.TestCase):
    def test_meadow_profile_is_least_privilege_and_remote_scoped(self):
        config = tomllib.loads(CODEX_CONFIG_PATH.read_text(encoding="utf-8"))
        meadow = config["permissions"]["meadow"]

        self.assertEqual("meadow", config["default_permissions"])
        self.assertTrue(config["features"]["network_proxy"])
        self.assertEqual(":workspace", meadow["extends"])
        self.assertEqual(
            {
                "~/Documents/Meadow/meadow": True,
                "~/Documents/Meadow/meadow/.worktrees": True,
            },
            meadow["workspace_roots"],
        )
        self.assertEqual(
            {
                "~/Documents/Meadow/meadow/.git": "write",
                ":workspace_roots": {
                    ".": "write",
                    ".git": "write",
                    ".worktrees": "write",
                },
            },
            meadow["filesystem"],
        )
        self.assertEqual(
            {"enabled": True, "domains": {"github.com": "allow"}},
            meadow["network"],
        )

    def test_windows_environment_bootstraps_git_and_exposes_slice_actions(self):
        environment = tomllib.loads(
            ENVIRONMENT_CONFIG_PATH.read_text(encoding="utf-8")
        )
        setup = environment["setup"]["win32"]["script"]
        commands = {
            action["name"]: action["command"]
            for action in environment["actions"]
        }

        self.assertIn("git config --global --add safe.directory", setup)
        self.assertIn(".worktrees", setup)
        self.assertEqual(
            "powershell -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 doctor -Lane Codex",
            commands["Check slice readiness"],
        )
        self.assertEqual(
            "powershell -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 start -Lane Codex",
            commands["Claim Codex slice"],
        )
        self.assertEqual(
            "powershell -NoProfile -ExecutionPolicy Bypass -File tools/slice.ps1 finish",
            commands["Finish slice"],
        )
        self.assertEqual(
            "powershell -NoProfile -ExecutionPolicy Bypass "
            "-File tools/slice.ps1 resume -Lane Codex",
            commands["Resume slice closeout"],
        )

    def test_every_environment_action_is_a_single_unchained_command(self):
        """One action, one exact command -- no wrapper, no second segment.

        This is the enforcement half of the invocation-shape rule. A
        lifecycle command chained onto `cd`, `git status` or `Get-Content`,
        or wrapped in `powershell -Command`, no longer matches
        .codex/rules/meadow.rules and is denied, which reads in the
        transcript as the lifecycle failing rather than as a malformed call.
        """
        environment = tomllib.loads(
            ENVIRONMENT_CONFIG_PATH.read_text(encoding="utf-8")
        )

        for action in environment["actions"]:
            command = action["command"]
            with self.subTest(action=action["name"]):
                for forbidden in ("&&", "||", ";", "|", "2>&1", "-Command"):
                    self.assertNotIn(forbidden, command)
                self.assertTrue(
                    command.startswith(
                        "powershell -NoProfile -ExecutionPolicy Bypass -File tools/"
                    ),
                    command,
                )

    def test_exec_policy_allows_only_canonical_slice_entry_points(self):
        rules = CODEX_RULES_PATH.read_text(encoding="utf-8")

        self.assertIn('["doctor", "start", "finish", "resume"]', rules)
        self.assertIn('decision = "allow"', rules)
        self.assertIn("tools/slice.ps1 abandon", rules)
        self.assertNotIn('pattern = ["git"', rules)

    def test_exec_policy_allows_resume_but_not_destructive_abort(self):
        """`resume` is the only recovery path, so withholding it cost runs.

        `finish` pushes the merge before it removes the worktree and the
        ledger row: an interrupted closeout leaves work merged and pushed
        with cleanup outstanding, and `resume` is what completes it. A
        24-task Codex sample made 19 resume attempts against a rule that did
        not allow the command. `abort` throws work away and stays out.
        """
        rules = CODEX_RULES_PATH.read_text(encoding="utf-8")

        self.assertIn(
            "powershell -NoProfile -ExecutionPolicy Bypass "
            "-File tools/slice.ps1 resume -Lane Codex",
            rules,
        )
        allowed, rejected = rules.split("not_match = [", 1)
        self.assertNotIn("abort", allowed)
        self.assertIn("tools/slice.ps1 abort -Lane Codex", rejected)

    def test_exec_policy_rejects_wrapped_and_chained_lifecycle_commands(self):
        """The allowed shape is one exact command, not a command inside one.

        The rule matches an argv list, so the same words wrapped in
        `-Command "..."` or chained onto `cd`/`git status` are a different
        argv and are denied. Sampled runs kept composing those forms and
        reading the denial as a lifecycle failure, so both shapes are pinned
        here as counter-examples.
        """
        rules = CODEX_RULES_PATH.read_text(encoding="utf-8")
        rejected = rules.split("not_match = [", 1)[1]

        self.assertIn("-Command", rejected)
        self.assertIn("; git status", rejected)


class VerifyPythonResolutionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        system_powershell = (
            Path(os.environ.get("SystemRoot", r"C:\Windows"))
            / "System32"
            / "WindowsPowerShell"
            / "v1.0"
            / "powershell.exe"
        )
        cls.powershell = (
            str(system_powershell)
            if system_powershell.is_file()
            else shutil.which("pwsh") or shutil.which("powershell")
        )
        if not cls.powershell:
            raise unittest.SkipTest("PowerShell is required for verify.ps1 tests")

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.dependencies = (
            self.root / "codex-primary-runtime" / "dependencies"
        )
        self.python = self.dependencies / "python" / "python.exe"
        self.python.parent.mkdir(parents=True)
        self.python.touch()
        self.path_seed = self.dependencies / "native" / "powershell"
        self.path_seed.mkdir(parents=True)

    def tearDown(self):
        self.temp_dir.cleanup()

    def resolve_python(self, *extra_args: str) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["PATH"] = str(self.path_seed)
        return subprocess.run(
            [
                self.powershell,
                "-NoProfile",
                "-File",
                str(VERIFY_PATH),
                "-ResolvePythonOnly",
                *extra_args,
            ],
            capture_output=True,
            text=True,
            env=env,
        )

    def test_bundled_python_is_found_from_codex_dependency_path(self):
        result = self.resolve_python()

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(self.python.resolve(), Path(result.stdout.strip()).resolve())

    def test_explicit_python_override_wins_over_bundled_runtime(self):
        override = self.root / "explicit-python.exe"
        override.touch()

        result = self.resolve_python("-PythonPath", str(override))

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(override.resolve(), Path(result.stdout.strip()).resolve())


class TwoLaneCloseoutTest(unittest.TestCase):
    """L-6: the concurrency contract as a test, over the five cases that
    actually happened (plans/now/agent-lifecycle.md). Every fixture claims
    one [Claude] and one [Codex] item that share no file."""

    # Every line is deliberately distinct between the two items, including
    # "Next after:" -- an identical line in both blocks (e.g. two items both
    # ending "none -- fixture plan is complete") gives Git's merge an
    # ambiguous anchor to match, and it picks the wrong one. A third,
    # unclaimed item sits between them: Git's merge cannot cleanly resolve
    # two adjacent-but-different deletions with no unchanged line between
    # them, even when the deletions themselves are disjoint -- exactly the
    # spurious conflict a two-item queue would hit on every double-finish,
    # which the real queue's floor of three items never does.
    CLAUDE_ITEM = (
        "1. **[Claude] A-1 -- claude fixture.**\n"
        "   - Plan: `plans/fixture.md` -- claude fixture\n"
        "   - Files: `scripts/sample.gd`\n"
        "   - Check: deterministic, claude-owned\n"
        "   - Proof: `absent: scripts/sample.gd :: new_function`\n"
        "   - Next after: none -- claude fixture plan is complete\n"
    )
    ANCHOR_ITEM = (
        "2. **[Claude] Z-9 -- unclaimed filler.**\n"
        "   - Plan: `plans/fixture.md` -- filler\n"
        "   - Files: `scripts/filler.gd`\n"
        "   - Check: deterministic, filler\n"
        "   - Proof: `absent: scripts/filler.gd :: new_function`\n"
        "   - Next after: none -- filler plan is complete\n"
    )
    CODEX_ITEM = (
        "3. **[Codex] B-1 -- codex fixture.**\n"
        "   - Plan: `plans/fixture.md` -- codex fixture\n"
        "   - Files: `scripts/other.gd`\n"
        "   - Check: deterministic, codex-owned\n"
        "   - Proof: `absent: scripts/other.gd :: new_function`\n"
        "   - Next after: none -- codex fixture plan is complete\n"
    )

    @classmethod
    def setUpClass(cls):
        cls.powershell = shutil.which("pwsh") or shutil.which("powershell")
        if not cls.powershell:
            raise unittest.SkipTest("PowerShell is required for slice.ps1 lifecycle tests")

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.remote_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.remote = Path(self.remote_dir.name) / "origin.git"
        (self.root / "tools").mkdir()
        (self.root / "plans").mkdir()
        (self.root / "scripts").mkdir()
        (self.root / "checks" / "ready").mkdir(parents=True)
        shutil.copy2(SLICE_PATH, self.root / "tools" / "slice.ps1")
        shutil.copy2(VERIFY_PATH, self.root / "tools" / "verify.ps1")
        shutil.copy2(CHECK_DOCS_PATH, self.root / "tools" / "check_docs.py")
        (self.root / "plans" / "workstreams.md").write_text(
            "| Worktree path (branch) | Lane |\n| --- | --- |\n", encoding="utf-8"
        )
        (self.root / "checks" / "ready.md").write_text(
            "# Ready hands-on checks\n\n## Ready to run\n\n", encoding="utf-8"
        )
        (self.root / "scripts" / "sample.gd").write_text(
            "func existing():\n\tpass\n", encoding="utf-8"
        )
        (self.root / "scripts" / "other.gd").write_text(
            "func existing():\n\tpass\n", encoding="utf-8"
        )
        subprocess.run(["git", "init", "-b", "master"], cwd=self.root, capture_output=True, text=True, check=True)
        subprocess.run(["git", "init", "--bare", str(self.remote)], capture_output=True, text=True, check=True)
        subprocess.run(["git", "config", "user.name", "Meadow Test"], cwd=self.root, check=True)
        subprocess.run(["git", "config", "user.email", "meadow@example.invalid"], cwd=self.root, check=True)
        # A mock verifier: -Scope branch|primary succeed unconditionally so
        # these tests exercise the lifecycle transaction, not the real suites.
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet, [string]$Scope)\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\nexit 0\n",
            encoding="utf-8",
        )
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-m", "fixture"], cwd=self.root, capture_output=True, text=True, check=True)
        subprocess.run(["git", "remote", "add", "origin", str(self.remote)], cwd=self.root, check=True)
        subprocess.run(["git", "push", "-u", "origin", "master"], cwd=self.root, capture_output=True, text=True, check=True)

    def tearDown(self):
        self.temp_dir.cleanup()
        self.remote_dir.cleanup()

    def write_two_lane_queue(self, items=None):
        body = "".join(
            items if items is not None
            else [self.CLAUDE_ITEM, "\n", self.ANCHOR_ITEM, "\n", self.CODEX_ITEM]
        )
        (self.root / "NEXTSTEPS.md").write_text("## Next up\n\n" + body, encoding="utf-8")
        subprocess.run(["git", "add", "NEXTSTEPS.md"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-m", "queue both lanes"], cwd=self.root, capture_output=True, text=True, check=True)

    def run_slice(self, *args, env=None, cwd=None, timeout=90):
        return subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), *args],
            cwd=cwd or self.root, capture_output=True, text=True, timeout=timeout,
            env={**os.environ, **env} if env else None,
        )

    def run_finish(self, worktree, env=None, timeout=90):
        return subprocess.run(
            [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                str(worktree).replace("'", "''"), str(worktree / "tools" / "slice.ps1").replace("'", "''")
            )],
            cwd=self.root, capture_output=True, text=True, timeout=timeout,
            env={**os.environ, **env} if env else None,
        )

    def deliver(self, worktree, source_file, delivered_id, keep_item):
        """Edit the delivered source file to satisfy its proof, archive its
        spec, and rewrite NEXTSTEPS.md keeping only the other lane's item --
        the archive+refill edit L-5 requires committed on the branch."""
        (worktree / "scripts" / source_file).write_text(
            "func new_function():\n\tpass\n", encoding="utf-8"
        )
        archive_dir = worktree / "plans" / "archive"
        archive_dir.mkdir(parents=True, exist_ok=True)
        (archive_dir / f"{delivered_id}_2026-01-01.md").write_text(
            f"# {delivered_id} (archived)\n\nShipped in this fixture.\n", encoding="utf-8"
        )
        (worktree / "NEXTSTEPS.md").write_text(
            "## Next up\n\n" + (keep_item or ""), encoding="utf-8"
        )
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(
            ["git", "commit", "-m", f"archive {delivered_id} and refill the queue"],
            cwd=worktree, check=True,
        )

    def branch_exists(self, branch):
        return bool(subprocess.run(
            ["git", "branch", "--list", branch], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip())

    def test_two_lanes_close_out_independently(self):
        self.write_two_lane_queue()
        start_a = self.run_slice("start", "-Lane", "Claude")
        self.assertEqual(0, start_a.returncode, start_a.stderr)
        start_b = self.run_slice("start", "-Lane", "Codex")
        self.assertEqual(0, start_b.returncode, start_b.stderr)
        worktree_a = self.root / ".worktrees" / "A-1"
        worktree_b = self.root / ".worktrees" / "B-1"

        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)
        finish_a = self.run_finish(worktree_a)
        self.assertEqual(0, finish_a.returncode, finish_a.stderr)

        self.deliver(worktree_b, "other.gd", "B-1", self.CLAUDE_ITEM + "\n" + self.ANCHOR_ITEM)
        finish_b = self.run_finish(worktree_b)
        self.assertEqual(0, finish_b.returncode, finish_b.stderr)

        self.assertFalse(worktree_a.exists())
        self.assertFalse(worktree_b.exists())
        self.assertFalse(self.branch_exists("claude/A-1"))
        self.assertFalse(self.branch_exists("codex/B-1"))
        ledger = (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8")
        self.assertNotIn("A-1", ledger)
        self.assertNotIn("B-1", ledger)
        merged_queue = (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8")
        self.assertNotIn("A-1", merged_queue)
        self.assertNotIn("B-1", merged_queue)
        self.assertIn("func new_function():", (self.root / "scripts" / "sample.gd").read_text(encoding="utf-8"))
        self.assertIn("func new_function():", (self.root / "scripts" / "other.gd").read_text(encoding="utf-8"))

    def test_simultaneous_claims_one_wins_the_lock(self):
        self.write_two_lane_queue()
        common_dir = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip()
        lock_path = (self.root / common_dir).resolve() / "meadow-slice-lifecycle.lock"

        holder_script = (
            "$stream = [System.IO.File]::Open('{}', [System.IO.FileMode]::OpenOrCreate, "
            "[System.IO.FileAccess]::Write, [System.IO.FileShare]::None)\n"
            "Start-Sleep -Seconds 4\n"
            "$stream.Dispose()\n"
        ).format(str(lock_path).replace("'", "''"))
        holder = subprocess.Popen(
            [self.powershell, "-NoProfile", "-Command", holder_script],
            cwd=self.root, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        try:
            time.sleep(1.5)
            loser = self.run_slice("start", "-Lane", "Claude")
            self.assertNotEqual(0, loser.returncode)
            self.assertIn("slice lifecycle is busy", loser.stderr)
        finally:
            holder.wait(timeout=30)

        retry = self.run_slice("start", "-Lane", "Claude")
        self.assertEqual(0, retry.returncode, retry.stderr)
        self.assertTrue((self.root / ".worktrees" / "A-1").exists())

    def test_one_lane_finishing_leaves_the_other_untouched(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        self.assertEqual(0, self.run_slice("start", "-Lane", "Codex").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        worktree_b = self.root / ".worktrees" / "B-1"

        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)
        finish_a = self.run_finish(worktree_a)
        self.assertEqual(0, finish_a.returncode, finish_a.stderr)

        # The other lane's worktree, branch and ledger row survive A's merge
        # untouched -- it never rebases onto the new master tip.
        self.assertTrue(worktree_b.exists())
        self.assertTrue(self.branch_exists("codex/B-1"))
        self.assertIn("B-1", (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8"))
        b_head_before = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=worktree_b, capture_output=True, text=True, check=True
        ).stdout.strip()

        self.deliver(worktree_b, "other.gd", "B-1", self.CLAUDE_ITEM + "\n" + self.ANCHOR_ITEM)
        b_head_after_deliver = subprocess.run(
            ["git", "rev-parse", "HEAD~0"], cwd=worktree_b, capture_output=True, text=True, check=True
        ).stdout.strip()
        # deliver() only added one commit on top of the pre-A-merge head --
        # no rebase happened underneath it.
        parent = subprocess.run(
            ["git", "rev-parse", f"{b_head_after_deliver}^"], cwd=worktree_b, capture_output=True, text=True, check=True
        ).stdout.strip()
        self.assertEqual(b_head_before, parent)

        finish_b = self.run_finish(worktree_b)
        self.assertEqual(0, finish_b.returncode, finish_b.stderr)
        self.assertFalse(worktree_b.exists())
        self.assertFalse(self.branch_exists("codex/B-1"))

    def test_remote_ahead_integrates_or_fails_naming_remote_state(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)

        # An unrelated commit lands on the remote's master from outside this
        # checkout -- exactly what the other lane's own finish, pushing from
        # its own primary checkout, would also produce.
        other_clone_dir = tempfile.TemporaryDirectory()
        try:
            other_clone = Path(other_clone_dir.name) / "clone"
            subprocess.run(["git", "clone", str(self.remote), str(other_clone)], capture_output=True, text=True, check=True)
            subprocess.run(["git", "config", "user.name", "Other Lane"], cwd=other_clone, check=True)
            subprocess.run(["git", "config", "user.email", "other@example.invalid"], cwd=other_clone, check=True)
            (other_clone / "unrelated.txt").write_text("unrelated change\n", encoding="utf-8")
            subprocess.run(["git", "add", "unrelated.txt"], cwd=other_clone, check=True)
            subprocess.run(["git", "commit", "-m", "unrelated remote commit"], cwd=other_clone, check=True)
            subprocess.run(["git", "push", "origin", "master"], cwd=other_clone, capture_output=True, text=True, check=True)
        finally:
            other_clone_dir.cleanup()

        finish = self.run_finish(worktree_a)
        if finish.returncode == 0:
            # Integrated: the unrelated remote commit is present on local
            # master and the slice still landed cleanly.
            self.assertIn("unrelated.txt", subprocess.run(
                ["git", "ls-tree", "-r", "--name-only", "HEAD"], cwd=self.root, capture_output=True, text=True, check=True
            ).stdout)
            self.assertIn("func new_function():", (self.root / "scripts" / "sample.gd").read_text(encoding="utf-8"))
        else:
            combined = finish.stdout + finish.stderr
            self.assertTrue(
                any(marker in combined for marker in ("rejected", "non-fast-forward", "fetch first", "behind")),
                combined,
            )
            # Never a half-pushed transaction: resume must still be able to
            # find and complete this lane's outstanding work, not silently
            # report it already done.
            resumed = self.run_slice("resume", "-Lane", "Claude")
            self.assertEqual(0, resumed.returncode, resumed.stdout + resumed.stderr)
            self.assertFalse(worktree_a.exists())
            self.assertFalse(self.branch_exists("claude/A-1"))

    def test_dirty_coordination_file_refuses_before_the_merge(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)

        # An uncommitted edit to the shared ledger in the primary checkout --
        # never made from inside a feature branch, per CLAUDE.md, but a stray
        # edit or an interrupted `start` from the other lane can leave one.
        ledger_path = self.root / "plans" / "workstreams.md"
        ledger_path.write_text(ledger_path.read_text(encoding="utf-8") + "dirty\n", encoding="utf-8")
        before = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip()

        finish = self.run_finish(worktree_a)
        self.assertNotEqual(0, finish.returncode)
        self.assertIn("plans/workstreams.md", finish.stdout + finish.stderr)
        after = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip()
        self.assertEqual(before, after)
        self.assertTrue(worktree_a.exists())
        self.assertTrue(self.branch_exists("claude/A-1"))

        # Clean it up (the edit reverts to what is already committed, so
        # there is nothing left to commit), then both lanes refill
        # NEXTSTEPS.md on their own branches and merge in sequence -- the
        # conflict Dave's 12 Sep decision allows, over the queue file rather
        # than the ledger.
        subprocess.run(["git", "checkout", "--", "plans/workstreams.md"], cwd=self.root, check=True)

        self.assertEqual(0, self.run_slice("start", "-Lane", "Codex").returncode)
        worktree_b = self.root / ".worktrees" / "B-1"
        self.deliver(worktree_b, "other.gd", "B-1", self.CLAUDE_ITEM + "\n" + self.ANCHOR_ITEM)

        finish_a = self.run_finish(worktree_a)
        self.assertEqual(0, finish_a.returncode, finish_a.stderr)

        finish_b = self.run_finish(worktree_b)
        combined = finish_b.stdout + finish_b.stderr
        if finish_b.returncode == 0:
            self.assertFalse(worktree_b.exists())
        else:
            self.assertIn("NEXTSTEPS.md", combined)
        # Never a half-pushed transaction either way.
        resumed = self.run_slice("resume", "-Lane", "Codex")
        self.assertEqual(0, resumed.returncode, resumed.stdout + resumed.stderr)

    def test_resume_after_push_succeeded_and_cleanup_failed(self):
        self.write_two_lane_queue()
        self.assertEqual(0, self.run_slice("start", "-Lane", "Claude").returncode)
        worktree_a = self.root / ".worktrees" / "A-1"
        self.deliver(worktree_a, "sample.gd", "A-1", self.ANCHOR_ITEM + "\n" + self.CODEX_ITEM)

        failed = self.run_finish(worktree_a, env={"MEADOW_SLICE_FAIL_AFTER": "pushed"})
        self.assertNotEqual(0, failed.returncode)

        resumed = self.run_slice("resume", "-Lane", "Claude")
        self.assertEqual(0, resumed.returncode, resumed.stderr)
        self.assertFalse(worktree_a.exists())
        self.assertFalse(self.branch_exists("claude/A-1"))
        self.assertNotIn("A-1", (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8"))
        self.assertIn("func new_function():", (self.root / "scripts" / "sample.gd").read_text(encoding="utf-8"))

        remote_head = subprocess.run(
            ["git", "rev-parse", "master"], cwd=self.remote, capture_output=True, text=True, check=True
        ).stdout.strip()
        local_head = subprocess.run(
            ["git", "rev-parse", "master"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip()
        self.assertEqual(local_head, remote_head)


class CodexLocalEnvironmentTest(unittest.TestCase):
    def test_setup_and_action_use_the_canonical_verifier(self):
        config = tomllib.loads(ENVIRONMENT_CONFIG_PATH.read_text(encoding="utf-8"))
        command = (
            "powershell -NoProfile -ExecutionPolicy Bypass "
            "-File tools/verify.ps1"
        )

        self.assertEqual(1, config["version"])
        self.assertEqual(command, config["setup"]["script"])
        self.assertIn(command, config["setup"]["win32"]["script"])
        self.assertEqual(
            {
                "name": "Verify",
                "icon": "test",
                "command": command,
                "platform": "win32",
            },
            config["actions"][0],
        )

if __name__ == "__main__":
    unittest.main()
