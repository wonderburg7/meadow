"""Focused regression tests for Meadow's source and workflow checks."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
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
DEBUG_PANEL_PATH = SOURCE_CHECKS_PATH.parent.parent / "scripts" / "debug_panel.gd"
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

        debug_panel_source = DEBUG_PANEL_PATH.read_text(encoding="utf-8")
        prerequisite_cascade = debug_panel_source.split("static func _cascade_prerequisites_on_static", 1)[1].split(
            "static func _cascade_dependents_off_static", 1
        )[0]
        self.assertIn("_cascade_mutual_exclusion_static(parent)", prerequisite_cascade)


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
        shutil.copy2(SLICE_PATH, self.root / "tools" / "slice.ps1")
        shutil.copy2(VERIFY_PATH, self.root / "tools" / "verify.ps1")
        (self.root / "plans" / "workstreams.md").write_text(
            "| Worktree path (branch) | Lane |\n| --- | --- |\n", encoding="utf-8"
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
        self.assertIn("Python:", result.stderr)
        self.assertIn("Godot:", result.stderr)
        self.assertIn("Git identity:", result.stderr)
        self.assertIn("Remote reachability:", result.stderr)

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

    def test_exec_policy_allows_only_canonical_slice_entry_points(self):
        rules = CODEX_RULES_PATH.read_text(encoding="utf-8")

        self.assertIn('["doctor", "start", "finish"]', rules)
        self.assertIn('decision = "allow"', rules)
        self.assertIn("tools/slice.ps1 abandon", rules)
        self.assertNotIn('pattern = ["git"', rules)


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
