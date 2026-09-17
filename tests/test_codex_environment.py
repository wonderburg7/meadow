"""Codex permission profile, local environment and verify.ps1's Python resolution."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
# Shared paths, the loaded source_checks/check_docs modules and the stdlib
# imports every workflow test file uses.
from workflow_test_support import *  # noqa: E402,F401,F403


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
