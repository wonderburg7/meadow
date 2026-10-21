"""CQ-R0: display-text golden harness.

Runs tests/display_text_golden_test.gd in a headless Godot. It writes every
player-facing string a bee, a cell and the hud build from game state to a JSON
file, and this test compares that file with tests/fixtures/display_text_golden.json,
captured on master. A refactor of bee.gd's task/idle/role/carrying text, the
hud's selection and cell-popup text, the corner signal rows or a cell's
info_label proves the text unchanged by passing this.

Line endings are normalised before comparing (the checkout may hold the fixture
with CRLF); every other byte must match.

When the text changes on purpose, regenerate the fixture and review the diff:
    python -m tests.test_display_text_golden --update

Requires a real Godot executable -- skips where none is installed.

Run with: python -m unittest tests.test_display_text_golden
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import godot_compile_check as gcc  # noqa: E402

TEST_SCRIPT = "res://tests/display_text_golden_test.gd"
FIXTURE = ROOT / "tests" / "fixtures" / "display_text_golden.json"
TIMEOUT_SECONDS = 300


def capture(out_path: Path) -> tuple[str, int]:
    """Run the Godot script, writing the strings to out_path. Returns (output, exit code)."""
    godot = gcc.find_godot()
    gcc.ensure_writable_user_dir()
    finished = subprocess.run(
        [godot, "--headless", "--disable-crash-handler", "--path", str(ROOT),
         "--script", TEST_SCRIPT, "--", "--golden-out=%s" % out_path],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        timeout=TIMEOUT_SECONDS,
    )
    return gcc.combined_output(finished), finished.returncode


def _normalise(data: bytes) -> bytes:
    return data.replace(b"\r\n", b"\n")


class DisplayTextGoldenTest(unittest.TestCase):
    def test_text_matches_the_master_capture(self):
        godot = gcc.find_godot()
        if not godot:
            self.skipTest("no Godot executable found -- this test needs a real boot")
        gcc.ensure_writable_user_dir()
        if not gcc.engine_can_boot(godot):
            self.skipTest("the installed Godot engine cannot initialise headlessly here")
        self.assertTrue(gcc.prepare_cache(godot), "could not prepare the Godot import cache")
        with tempfile.TemporaryDirectory() as tmp:
            out_path = Path(tmp) / "display_text_golden.json"
            output, code = capture(out_path)
            script_errors = gcc.failing_lines(output)
            failures = [line for line in output.splitlines() if line.startswith("CQ-R0 FAIL")]
            self.assertEqual(script_errors, [], "script errors:\n" + "\n".join(script_errors))
            self.assertEqual(failures, [], "\n".join(failures))
            self.assertIn("CQ-R0 PASS", output, "the test script did not report a pass:\n" + output[-2000:])
            self.assertEqual(code, 0, "Godot exited with code %d" % code)
            actual = _normalise(out_path.read_bytes())
        expected = _normalise(FIXTURE.read_bytes())
        if actual != expected:
            self.fail(_describe_difference(expected, actual))


def _describe_difference(expected: bytes, actual: bytes) -> str:
    import json
    want = json.loads(expected.decode("utf-8"))
    got = json.loads(actual.decode("utf-8"))
    lines = []
    for key in sorted(set(want) | set(got)):
        if want.get(key) != got.get(key):
            lines.append("%s\n  golden: %r\n  now:    %r" % (key, want.get(key), got.get(key)))
    shown = lines[:12]
    more = len(lines) - len(shown)
    text = "display text differs from the golden capture in %d place(s):\n" % len(lines) + "\n".join(shown)
    if more > 0:
        text += "\n... and %d more" % more
    return text or "display text differs from the golden capture (bytes only)"


if __name__ == "__main__":
    if "--update" in sys.argv:
        sys.argv.remove("--update")
        FIXTURE.parent.mkdir(parents=True, exist_ok=True)
        text, rc = capture(FIXTURE)
        print(text[-1500:])
        raise SystemExit(rc)
    unittest.main()
