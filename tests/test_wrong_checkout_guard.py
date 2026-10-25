"""verify.ps1 and prefinish.py refuse to run from inside a different checkout.

Each tests the checkout it lives in, not the one you stand in: on 12 Oct 2026
`../../tools/verify.ps1` from a worktree tested the primary checkout instead.
"""

from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_test_support import windows_powershell  # noqa: E402

from tools import prefinish  # noqa: E402

VERIFY_PATH = Path(prefinish.ROOT) / "tools" / "verify.ps1"


class OtherCheckoutTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.other = Path(self.temp_dir.name).resolve() / "other"
        self.other.mkdir()
        subprocess.run(["git", "init", "-q", "-b", "master", str(self.other)], check=True)
        self.plain = Path(self.temp_dir.name).resolve() / "plain"
        self.plain.mkdir()

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_prefinish_refuses_another_checkout_and_names_both(self):
        refusal = prefinish.wrong_checkout(self.other)
        self.assertIsNotNone(refusal)
        self.assertIn(str(prefinish.ROOT), refusal)
        self.assertIn("other", refusal)
        self.assertIn("python tools/prefinish.py", refusal)

    def test_prefinish_runs_from_its_own_checkout_or_outside_git(self):
        self.assertIsNone(prefinish.wrong_checkout(prefinish.ROOT))
        self.assertIsNone(prefinish.wrong_checkout(prefinish.ROOT / "tools"))
        if subprocess.run(["git", "-C", str(self.plain), "rev-parse"],
                          capture_output=True).returncode == 0:
            self.skipTest("the temporary directory sits inside a git checkout")
        self.assertIsNone(prefinish.wrong_checkout(self.plain))

    def run_verify(self, *args, env=None):
        powershell = windows_powershell()
        if not powershell:
            self.skipTest("PowerShell is required for verify.ps1 tests")
        return subprocess.run(
            [powershell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(VERIFY_PATH), *args],
            capture_output=True, text=True, cwd=self.other, env=env, timeout=60)

    def test_verify_refuses_another_checkout_and_names_both(self):
        env = os.environ.copy()
        env.pop("MEADOW_FINISH_VERIFY", None)
        result = self.run_verify("-Docs", env=env)
        self.assertEqual(2, result.returncode, result.stdout + result.stderr)
        self.assertIn("verify: stopped", result.stdout)
        self.assertIn(str(prefinish.ROOT), result.stdout)
        self.assertIn(r".\tools\verify.ps1", result.stdout)

    def test_slice_ps1_calls_from_another_checkout_still_run(self):
        # finish calls each checkout's copy by full path from wherever it stands.
        resolved = self.run_verify("-ResolvePythonOnly")
        self.assertEqual(0, resolved.returncode, resolved.stdout + resolved.stderr)
        self.assertNotIn("verify: stopped", resolved.stdout)


if __name__ == "__main__":
    unittest.main()
