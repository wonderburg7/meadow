"""tools/slice.ps1 doctor, start, finish and resume against a throwaway repository."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
# Shared paths, the loaded source_checks/check_docs modules and the stdlib
# imports every workflow test file uses.
from workflow_test_support import *  # noqa: E402,F401,F403


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
        shutil.copy2(DIAGNOSTICS_PATH, self.root / "tools" / "diagnostics.ps1")
        shutil.copy2(CHECK_DOCS_PATH, self.root / "tools" / "check_docs.py")
        shutil.copy2(BACKLOG_PATH, self.root / "tools" / "backlog.py")
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
            f"# {delivered_id} -- fixture (archived)\n\nShipped in this fixture.\n",
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

    def test_doctor_advises_model_and_connectors_from_the_plan_level(self):
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        (self.root / "plans" / "fixture.md").write_text(
            "# Fixture\n\n## fixture\n\n**Level:** high.\n", encoding="utf-8"
        )

        result = self.run_doctor()

        self.assertEqual(0, result.returncode, result.stderr)
        advice = json.loads(result.stdout)["advice"]
        self.assertEqual("high", advice["level"])
        self.assertIn("reasoning", advice["model"])  # a Codex item
        self.assertEqual([], advice["connectors_on"])

    def test_a_finish_stop_prints_the_standard_failure_block(self):
        result = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "finish"],
            cwd=self.root, capture_output=True, text=True, timeout=120,
        )

        self.assertEqual(1, result.returncode)
        for label in ("slice finish stopped", "Step:", "Cause:", "Fix:", "Retry:"):
            self.assertIn(label, result.stderr)
        self.assertNotIn("At line:", result.stderr)

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

    def test_godot_capability_names_each_failure_state(self):
        """Get-GodotCapability must tell an MCP failure apart from an
        editor, environment or import-cache one, and from a genuinely ready
        Godot -- see L-8. Today all five shared one exit path.
        """
        self.write_queue("`absent: scripts/sample.gd :: new_function`")
        godot_dir = self.root / ".godot"
        system_root = Path(os.environ.get("SystemRoot", r"C:\Windows"))
        cmd_exe = system_root / "System32" / "cmd.exe"

        # mcp_unavailable: checked ahead of the editor and cache states
        # below, so an unresolvable MCP command is named even when a
        # perfectly good Godot is also configured.
        (self.root / ".mcp.json").write_text(
            json.dumps(
                {"mcpServers": {"godot": {"command": "meadow-test-nonexistent-mcp"}}}
            ),
            encoding="utf-8",
        )
        result = self.run_doctor()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(
            "mcp_unavailable", json.loads(result.stdout)["godot_capability"]["state"]
        )
        (self.root / ".mcp.json").unlink()

        # editor_unavailable already blocks doctor outright, unchanged by
        # this slice, so it is driven and proven the same way as
        # test_doctor_reports_all_environment_failures_together: through
        # the failure message, since doctor never reaches the JSON payload
        # in this case.
        (self.root / ".codex" / "config.toml").write_text(
            "[mcp_servers.godot.env]\nGODOT_PATH = 'missing-godot.exe'\n",
            encoding="utf-8",
        )
        result = self.run_doctor()
        self.assertNotEqual(0, result.returncode)
        self.assertIn("Godot: configured executable does not exist", result.stderr)

        # import_cache_missing: a real, existing executable but no .godot
        # directory yet -- the false alarm this state exists to name before
        # the boot probe below ever runs and could misreport it.
        (self.root / ".codex" / "config.toml").write_text(
            "[mcp_servers.godot.env]\n"
            f"GODOT_PATH = '{Path(self.powershell).as_posix()}'\n",
            encoding="utf-8",
        )
        self.assertFalse(godot_dir.exists())
        result = self.run_doctor()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(
            "import_cache_missing",
            json.loads(result.stdout)["godot_capability"]["state"],
        )

        godot_dir.mkdir()

        # environment_crash: the fixture executable runs but rejects the
        # Godot-style probe flags it is given -- a real access violation is
        # not reproducible portably, but a non-zero exit drives the same
        # branch.
        result = self.run_doctor()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(
            "environment_crash",
            json.loads(result.stdout)["godot_capability"]["state"],
        )

        # ready: a real executable that accepts (and ignores) the probe's
        # arguments and exits cleanly once its closed stdin hits EOF.
        (self.root / ".codex" / "config.toml").write_text(
            "[mcp_servers.godot.env]\n"
            f"GODOT_PATH = '{cmd_exe.as_posix()}'\n",
            encoding="utf-8",
        )
        result = self.run_doctor()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(
            "ready", json.loads(result.stdout)["godot_capability"]["state"]
        )

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
        for module in ("test_source_checks", "test_slice_lifecycle", "test_two_lane_closeout", "test_codex_environment", "test_verify_generated"):
            (tests_dir / f"{module}.py").write_text(
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
            "started", "verified", "branch-committed", "actions-committed", "archived", "refilled",
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
            "# T-1 -- fixture (archived)\n\nShipped in this fixture.\n", encoding="utf-8"
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

    def test_finish_archives_the_plan_its_last_slice_completed(self):
        """A closeout that archives its plan's last slice and marks the plan
        complete used to leave the plan in plans/now/, failing check_docs on
        every later branch (CB-2, T-3, V-4, ST-1). finish now moves it after
        the merge, once the ledger row citing it is gone, in the same push."""
        shutil.copy2(SLICE_PATH.with_name("archive_slice.py"), self.root / "tools" / "archive_slice.py")
        shutil.copy2(SLICE_PATH.with_name("heading.py"), self.root / "tools" / "heading.py")
        (self.root / "plans" / "now").mkdir()
        (self.root / "plans" / "now" / "sample.md").write_text(
            "# Sample plan\n\n"
            "Status: active | Owner: t | Next: T-1 | Dependency: none | Verified: 2026-09-18\n\n"
            "The one open slice is specified in the queue.\n",
            encoding="utf-8",
        )
        (self.root / "NEXTSTEPS.md").write_text(
            "## Next up\n\n"
            "1. **[Codex] T-1 -- fixture.**\n"
            "   - Plan: `plans/now/sample.md` -- fixture\n"
            "   - Files: `scripts/sample.gd`\n"
            "   - Check: deterministic\n"
            "   - Proof: `absent: scripts/sample.gd :: new_function`\n"
            "   - Next after: none -- the sample plan is complete\n",
            encoding="utf-8",
        )
        (self.root / "tools" / "verify.ps1").write_text(
            "param([string]$PythonPath, [switch]$ResolvePythonOnly, [switch]$Quiet)\n"
            "if ($ResolvePythonOnly) { Write-Output $PSCommandPath }\nexit 0\n",
            encoding="utf-8",
        )
        subprocess.run(["git", "add", "-A"], cwd=self.root, check=True)
        subprocess.run(["git", "commit", "-m", "sample plan and mock verifier"], cwd=self.root, check=True)

        start = subprocess.run(
            [self.powershell, "-NoProfile", "-File", str(self.root / "tools" / "slice.ps1"), "start", "-Lane", "Codex"],
            cwd=self.root, capture_output=True, text=True,
        )
        self.assertEqual(0, start.returncode, start.stderr)
        self.assertIn("`plans/now/sample.md`", (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8"))
        worktree = self.root / ".worktrees" / "T-1"
        (worktree / "scripts" / "sample.gd").write_text("func new_function():\n\tpass\n", encoding="utf-8")
        # The session's own closeout edits: the slice record, the emptied
        # queue and the plan marked complete -- everything but the plan move.
        (worktree / "plans" / "archive").mkdir(parents=True)
        (worktree / "plans" / "archive" / "T-1_2026-01-01.md").write_text(
            "Landed 2026-01-01 on `codex/T-1`. Live plan: `plans/now/sample.md`.\n\n# T-1 -- fixture\n",
            encoding="utf-8",
        )
        (worktree / "NEXTSTEPS.md").write_text("## Next up\n\n", encoding="utf-8")
        (worktree / "plans" / "now" / "sample.md").write_text(
            "# Sample plan\n\n"
            "Status: active | Owner: t | Next: None -- plan complete | Dependency: none | Verified: 2026-09-18\n\n"
            "T-1 shipped 2026-01-01; its specification is `plans/archive/T-1_2026-01-01.md`.\n",
            encoding="utf-8",
        )
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(["git", "commit", "-m", "archive T-1 and complete the plan"], cwd=worktree, check=True)

        finish = subprocess.run(
            [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish -PythonPath '{}'".format(
                str(worktree).replace("'", "''"), str(worktree / "tools" / "slice.ps1").replace("'", "''"),
                sys.executable.replace("'", "''"),
            )],
            cwd=self.root, capture_output=True, text=True, timeout=90,
        )
        self.assertEqual(0, finish.returncode, finish.stdout + finish.stderr)

        archived_rel = f"plans/archive/sample_{time.strftime('%Y-%m-%d')}.md"
        self.assertFalse((self.root / "plans" / "now" / "sample.md").exists())
        self.assertIn(
            "Status: complete | Owner: t | Next: None -- plan complete",
            (self.root / archived_rel).read_text(encoding="utf-8"),
        )
        self.assertTrue(
            (self.root / "plans" / "archive" / "T-1_2026-01-01.md").read_text(encoding="utf-8").startswith(
                f"Landed 2026-01-01 on `codex/T-1`. Live plan: `{archived_rel}` (archived)."
            )
        )
        self.assertNotIn("sample.md", (self.root / "plans" / "workstreams.md").read_text(encoding="utf-8"))
        self.assertEqual(
            "",
            subprocess.run(["git", "status", "--porcelain", "--untracked-files=no"],
                           cwd=self.root, capture_output=True, text=True, check=True).stdout,
        )
        # The move rode the transaction's one push.
        local = subprocess.run(["git", "rev-parse", "HEAD"], cwd=self.root, capture_output=True, text=True, check=True)
        remote = subprocess.run(["git", "rev-parse", "origin/master"], cwd=self.root, capture_output=True, text=True, check=True)
        self.assertEqual(local.stdout, remote.stdout)

    DEFERRED_SUCCESSOR_SECTION = (
        "## Not in the queue, and why\n\n"
        "- **T-2** (`plans/fixture.md`) -- follows T-1 but waits on T-9.\n"
        "- **T-9** (`plans/fixture.md`) -- waits on something else.\n"
    )

    def finish_with_a_deferred_successor(self, lane_after_refill=""):
        """Close T-1, whose `Next after:` names T-2, with T-2 deferred under
        '## Not in the queue, and why' and $lane_after_refill as the Codex
        lane the refill leaves. Returns the finish process."""
        (self.root / "NEXTSTEPS.md").write_text(
            "## Next up\n\n"
            "1. **[Codex] T-1 -- fixture.**\n"
            "   - Plan: `plans/fixture.md` -- fixture\n"
            "   - Files: `scripts/sample.gd`\n"
            "   - Check: deterministic\n"
            "   - Proof: `absent: scripts/sample.gd :: new_function`\n"
            "   - Next after: T-2 -- the fixture's own successor.\n"
            "\n## Not in the queue, and why\n\n"
            "- **T-9** (`plans/fixture.md`) -- waits on something else.\n",
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
            "# T-1 -- fixture (archived)\n\nShipped in this fixture.\n", encoding="utf-8"
        )
        (worktree / "NEXTSTEPS.md").write_text(
            "## Next up\n\n" + lane_after_refill + self.DEFERRED_SUCCESSOR_SECTION,
            encoding="utf-8",
        )
        subprocess.run(["git", "add", "-A"], cwd=worktree, check=True)
        subprocess.run(
            ["git", "commit", "-m", "archive T-1 and defer T-2"], cwd=worktree, check=True
        )

        return subprocess.run(
            [self.powershell, "-NoProfile", "-Command", "Set-Location -LiteralPath '{}'; & '{}' finish".format(
                str(worktree).replace("'", "''"), str(worktree / "tools" / "slice.ps1").replace("'", "''")
            )],
            cwd=self.root, capture_output=True, text=True, timeout=90,
        )

    def test_refill_accepts_a_successor_that_is_not_startable_yet(self):
        """A successor is not always admissible when its predecessor lands.
        G2's was G3, which waits on F2s. The refill gate takes a bullet under
        '## Not in the queue, and why' in place of a lane item, so closeout
        never has to queue unstartable work or weaken a `Next after:` line."""
        finish = self.finish_with_a_deferred_successor()
        self.assertEqual(0, finish.returncode, finish.stdout + finish.stderr)

        merged_queue = (self.root / "NEXTSTEPS.md").read_text(encoding="utf-8")
        self.assertNotIn("[Codex] T-1", merged_queue)
        self.assertIn("**T-2**", merged_queue)
        self.assertIn(
            "Next slice:   none -- the Codex lane is empty (T-2 is deferred: follows T-1 but waits on T-9.)",
            finish.stdout,
        )

    def test_report_names_the_lane_lead_when_the_successor_is_deferred(self):
        """Closing L-13 on 19 Sep 2026, whose successor L-12 is gated, printed
        'L-12 -- (not found in NEXTSTEPS.md; check the refill)', which read as
        a failed refill. A deferred successor is deliberate: the next slice is
        the lane's new lead, and the report says why the successor waits."""
        finish = self.finish_with_a_deferred_successor(
            "1. **[Codex] T-3 -- fixture lead.**\n"
            "   - Plan: `plans/fixture.md` -- fixture lead\n"
            "   - Files: `scripts/other.gd`\n"
            "   - Check: deterministic\n"
            "   - Proof: `absent: scripts/other.gd :: new_function`\n"
            "   - Next after: none -- fixture plan is complete\n\n"
        )
        self.assertEqual(0, finish.returncode, finish.stdout + finish.stderr)
        self.assertIn(
            "Next slice:   T-3 -- fixture lead.  (T-2 is deferred: follows T-1 but waits on T-9.)",
            finish.stdout,
        )
        self.assertNotIn("not found in NEXTSTEPS.md", finish.stdout)

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


if __name__ == "__main__":
    unittest.main()


class ArchiveSliceTest(unittest.TestCase):
    """tools/archive_slice.py against a throwaway repository (L-10). Pure
    Python, so it runs where the PowerShell suites above skip."""

    PLAN = (
        "# Plan\n\n"
        "<!-- CONTEXT: plan | LAYER: immediate-task -->\n"
        "Status: active | Owner: t | Next: X-1 | Dependency: none | Verified: 2026-09-18\n\n"
        "| Slice | Outcome | Level |\n| --- | --- | --- |\n"
        "| X-1 | first | low |\n| X-2 | second | low |\n\n"
        "## X-1 — the first slice\n\n"
        "Body of the first slice.\n\n"
        "```gd\n## a doc comment that is not a heading\n```\n\n"
        "Level: low\n\n"
        "## X-2 — the second slice\n\n"
        "Body of the second slice, byte for byte.\n"
    )
    QUEUE = (
        "# Next steps\n\n## Next up\n\n### Claude lane\n\n"
        "1. **[Claude] X-1 -- the first slice**\n"
        "   - Plan: `plans/now/x.md` -- \"X-1 — the first slice\"\n"
        "   - Files: `scripts/x.gd`\n"
        "   - Check: something\n"
        "   - Proof: `absent: scripts/x.gd :: thing`\n"
        "   - Next after: X-2 -- the second slice.\n\n"
        "### Codex lane\n\n"
        "1. **[Codex] Y-1 -- another**\n"
        "   - Plan: `plans/now/y.md` -- \"Y-1\"\n"
        "   - Files: `scripts/y.gd`\n"
        "   - Check: something\n"
        "   - Proof: `absent: scripts/y.gd :: thing`\n"
        "   - Next after: none -- y is complete.\n\n"
        "## Not in the queue, and why\n"
    )

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        (self.root / "plans" / "now").mkdir(parents=True)
        (self.root / "plans" / "now" / "x.md").write_text(self.PLAN, encoding="utf-8")
        (self.root / "NEXTSTEPS.md").write_text(self.QUEUE, encoding="utf-8")
        for args in (["init", "-q", "-b", "master"], ["add", "."],
                     ["-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "seed"]):
            subprocess.run(["git", *args], cwd=self.root, check=True, capture_output=True)

    def tearDown(self):
        self.temp_dir.cleanup()

    def run_tool(self, *extra):
        return subprocess.run(
            [sys.executable, str(SLICE_PATH.with_name("archive_slice.py")), "X-1",
             "--root", str(self.root), "--date", "2026-09-18", *extra],
            capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=self.root,
        )

    def test_moves_the_section_verbatim_and_leaves_a_pointer(self):
        result = self.run_tool()

        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        first_start = self.PLAN.index("## X-1")
        second_start = self.PLAN.index("## X-2")
        first_section = self.PLAN[first_start:second_start]
        archived = (self.root / "plans" / "archive" / "X-1_2026-09-18.md").read_text(encoding="utf-8")
        self.assertIn(first_section, archived)
        self.assertTrue(archived.startswith("Landed 2026-09-18 on `master`. Live plan: `plans/now/x.md`."))

        plan = (self.root / "plans" / "now" / "x.md").read_text(encoding="utf-8")
        expected_pointer = "X-1 shipped 2026-09-18; its specification is `plans/archive/X-1_2026-09-18.md`.\n\n"
        self.assertEqual(
            self.PLAN[:first_start].replace("| X-1 | first | low |\n", "") + expected_pointer + self.PLAN[second_start:],
            plan,
        )
        self.assertNotIn("## X-1", plan)
        self.assertIn("## X-2 — the second slice\n\nBody of the second slice, byte for byte.\n", plan)

    def test_refuses_a_dirty_working_tree(self):
        (self.root / "NEXTSTEPS.md").write_text(self.QUEUE + "\n- **Z** -- edited.\n", encoding="utf-8")

        result = self.run_tool()

        self.assertNotEqual(0, result.returncode)
        self.assertIn("uncommitted", result.stderr)
        self.assertFalse((self.root / "plans" / "archive").exists())
        self.assertEqual(self.PLAN, (self.root / "plans" / "now" / "x.md").read_text(encoding="utf-8"))

    def test_reads_the_queue_from_master_when_the_branch_has_refilled(self):
        subprocess.run(["git", "checkout", "-q", "-b", "claude/X-1"], cwd=self.root, check=True, capture_output=True)
        (self.root / "NEXTSTEPS.md").write_text(self.QUEUE.replace("X-1", "X-9"), encoding="utf-8")
        subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-am", "refill"],
                       cwd=self.root, check=True, capture_output=True)

        result = self.run_tool()

        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertTrue((self.root / "plans" / "archive" / "X-1_2026-09-18.md").exists())


class ArchiveCompletePlansTest(unittest.TestCase):
    """tools/archive_slice.py --complete-plans: the plan a closeout leaves live
    with "Next: None -- plan complete" after archiving its last slice (CB-2,
    T-3, V-4, ST-1) moves to plans/archive/ with every reference repointed."""

    DONE_PLAN = (
        "# Done plan\n\n"
        "<!-- CONTEXT: plan | LAYER: immediate-task -->\n"
        "Status: active | Owner: t | Next: None -- plan complete | Dependency: none | Verified: 2026-09-18\n\n"
        "D-1 shipped 2026-09-18; its specification is `plans/archive/D-1_2026-09-18.md`.\n"
    )
    OPEN_PLAN = (
        "# Open plan\n\n"
        "Status: active | Owner: t | Next: O-2 | Dependency: none | Verified: 2026-09-18\n\n"
        "## O-2 — still to do\n"
    )
    RECORD = "Landed 2026-09-18 on `claude/D-1`. Live plan: `plans/now/done.md`.\n\n## D-1 — the slice\n"
    NOTE = "Promoted to a new plan, `plans/now/done.md`, on 18 Sep.\n"

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        files = {
            "plans/now/done.md": self.DONE_PLAN,
            "plans/now/open.md": self.OPEN_PLAN,
            "plans/archive/D-1_2026-09-18.md": self.RECORD,
            "plans/observations/notes.md": self.NOTE,
            "NEXTSTEPS.md": "# Next steps\n\n## Next up\n\n### Claude lane\n\n",
            "plans/workstreams.md": "| Worktree path (branch) | Lane |\n| --- | --- |\n",
        }
        for rel, text in files.items():
            (self.root / rel).parent.mkdir(parents=True, exist_ok=True)
            (self.root / rel).write_text(text, encoding="utf-8")
        self.git("init", "-q", "-b", "master")
        self.git("add", ".")
        self.git("commit", "-q", "-m", "seed")

    def tearDown(self):
        self.temp_dir.cleanup()

    def git(self, *args):
        return subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", *args],
                              cwd=self.root, check=True, capture_output=True, text=True)

    def run_tool(self):
        return subprocess.run(
            [sys.executable, str(SLICE_PATH.with_name("archive_slice.py")), "--complete-plans",
             "--root", str(self.root), "--date", "2026-09-23"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=self.root,
        )

    def test_moves_a_finished_plan_and_repoints_every_reference(self):
        result = self.run_tool()

        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        new_rel = "plans/archive/done_2026-09-23.md"
        self.assertFalse((self.root / "plans" / "now" / "done.md").exists())
        archived = (self.root / new_rel).read_text(encoding="utf-8")
        self.assertIn("Status: complete | Owner: t | Next: None -- plan complete", archived)
        self.assertEqual(self.DONE_PLAN.split("Status:")[0], archived.split("Status:")[0])
        record = (self.root / "plans" / "archive" / "D-1_2026-09-18.md").read_text(encoding="utf-8")
        self.assertTrue(record.startswith(f"Landed 2026-09-18 on `claude/D-1`. Live plan: `{new_rel}` (archived)."))
        note = (self.root / "plans" / "observations" / "notes.md").read_text(encoding="utf-8")
        self.assertEqual(self.NOTE.replace("plans/now/done.md", new_rel), note)
        self.assertEqual(self.OPEN_PLAN, (self.root / "plans" / "now" / "open.md").read_text(encoding="utf-8"))

        touched = sorted(line[len("touched: "):] for line in result.stdout.splitlines()
                         if line.startswith("touched: "))
        self.assertEqual(sorted(["plans/now/done.md", new_rel, "plans/archive/D-1_2026-09-18.md",
                                 "plans/observations/notes.md"]), touched)
        # Everything is staged, so a caller commits exactly the touched paths.
        self.assertEqual("", self.git("diff", "--name-only").stdout)
        staged = self.git("diff", "--cached", "--name-status", "-M").stdout
        self.assertIn("plans/now/done.md", staged)
        self.assertIn(new_rel, staged)

    def test_keeps_a_plan_live_while_the_queue_or_ledger_still_cites_it(self):
        for citer in ("NEXTSTEPS.md", "plans/workstreams.md"):
            with self.subTest(citer=citer):
                path = self.root / citer
                original = path.read_text(encoding="utf-8")
                path.write_text(original + "`plans/now/done.md`\n", encoding="utf-8")
                self.git("commit", "-q", "-am", f"cite from {citer}")

                result = self.run_tool()

                self.assertEqual(1, result.returncode, result.stdout + result.stderr)
                self.assertIn(f"plan kept live: plans/now/done.md -- {citer} still cite", result.stderr)
                self.assertTrue((self.root / "plans" / "now" / "done.md").exists())
                self.assertFalse((self.root / "plans" / "archive" / "done_2026-09-23.md").exists())
                self.assertEqual("", self.git("status", "--porcelain").stdout)
                path.write_text(original, encoding="utf-8")
                self.git("commit", "-q", "-am", f"uncite from {citer}")

    def test_keeps_a_plan_live_when_a_file_it_would_touch_is_dirty(self):
        (self.root / "plans" / "observations" / "notes.md").write_text(self.NOTE + "edit\n", encoding="utf-8")

        result = self.run_tool()

        self.assertEqual(1, result.returncode)
        self.assertIn("uncommitted changes", result.stderr)
        self.assertTrue((self.root / "plans" / "now" / "done.md").exists())

    def test_does_nothing_when_no_live_plan_is_finished(self):
        self.git("rm", "-q", "plans/now/done.md")
        self.git("commit", "-q", "-m", "no finished plan")

        result = self.run_tool()

        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("", result.stdout)
        self.assertEqual("", self.git("status", "--porcelain").stdout)
