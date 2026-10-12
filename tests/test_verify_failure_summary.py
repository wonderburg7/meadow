"""finish's stop cause names an import-cache failure as not a code fault.

slice.ps1's Get-VerifyFailureSummary is lifted out of the script and run on
its own, so the test needs no repository fixture.
"""

import re
import shutil
import subprocess
import unittest
from pathlib import Path

from tools import godot_cache

SLICE_TOOL = Path(__file__).resolve().parents[1] / "tools" / "slice.ps1"
VERIFY_TOOL = Path(__file__).resolve().parents[1] / "tools" / "verify.ps1"


def summary_function() -> str:
    source = SLICE_TOOL.read_text(encoding="utf-8")
    match = re.search(r"(?ms)^function Get-VerifyFailureSummary \{.*?^\}", source)
    if match is None:
        raise AssertionError("Get-VerifyFailureSummary was not found in slice.ps1")
    return match.group(0)


@unittest.skipIf(shutil.which("powershell") is None, "Windows PowerShell is not installed")
class VerifyFailureSummaryTest(unittest.TestCase):
    def summarise(self, lines: list[str]) -> str:
        quoted = ", ".join("'%s'" % line.replace("'", "''") for line in lines)
        script = "%s\nGet-VerifyFailureSummary -Output @(%s)" % (summary_function(), quoted)
        finished = subprocess.run(
            ["powershell", "-NoProfile", "-NonInteractive", "-Command", script],
            capture_output=True, text=True, timeout=60,
        )
        self.assertEqual(0, finished.returncode, finished.stderr)
        return finished.stdout.strip()

    def test_a_cache_fault_says_change_no_code_and_carries_its_fix(self):
        line = godot_cache.CACHE_FAULT + (
            " -- `godot --headless --import` in C:\\w did not finish within 180 seconds. "
            "Your code was not at fault. Fix: in Windows PowerShell: cd C:\\w; python tools/godot_cache.py --force")
        summary = self.summarise([
            "godot boot: FAILED (the Godot import cache, not a code fault -- run the Fix command printed below)",
            "godot cache: re-imported (a source was newer than the cache)",
            line,
        ])
        self.assertIn("NOT a code fault -- change no code", summary)
        self.assertIn("python tools/godot_cache.py --force", summary)

    def test_a_code_failure_still_names_its_stage(self):
        summary = self.summarise(["unit tests: FAILED", "FAIL: test_x"])
        self.assertEqual("failed: unit tests", summary)


class CacheFaultParityTest(unittest.TestCase):
    """The prefix and exit code are matched as text in the PowerShell tools."""

    def test_slice_matches_the_cache_fault_prefix(self):
        self.assertIn('"%s"' % godot_cache.CACHE_FAULT, summary_function())

    def test_verify_notes_the_cache_fault_exit_code(self):
        self.assertIn("-ExitNotes @{ %d = " % godot_cache.CACHE_FAULT_EXIT,
                      VERIFY_TOOL.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
