"""tools/refill_lane.py --check: the read-only queue check slice.ps1 finish
runs on a staged merge before committing it (CQ-R14 closeout, 27 Oct 2026)."""
from __future__ import annotations

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import refill_lane  # noqa: E402


class RefillLaneCheckTest(unittest.TestCase):
    def _run(self, errors: list[str]) -> tuple[int, str, str]:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "NEXTSTEPS.md").write_text("queue text\n", encoding="utf-8")
            # main() reconfigures its streams, which a StringIO cannot do.
            raw = io.BytesIO()
            out = io.TextIOWrapper(raw, encoding="utf-8")
            argv = ["refill_lane.py", "--check", "--root", str(root)]
            with patch.object(sys, "argv", argv), \
                    patch.object(refill_lane, "queue_errors", return_value=errors) as checked, \
                    patch.object(refill_lane, "lifecycle_lock") as lock, \
                    contextlib.redirect_stdout(out):
                code = refill_lane.main()
            out.flush()
            printed = raw.getvalue().decode("utf-8")
            self.assertEqual(checked.call_args.args[0], "queue text\n")
            lock.assert_not_called()
            text = (root / "NEXTSTEPS.md").read_text(encoding="utf-8")
        return code, printed, text

    def test_colliding_queue_fails_and_names_the_error(self) -> None:
        error = "NEXTSTEPS.md: a [Claude] and a [Codex] item both name scripts/hud.gd"
        code, out, text = self._run([error])
        self.assertEqual(code, 1)
        self.assertIn(f"ERROR: {error}", out)
        self.assertEqual(text, "queue text\n")

    def test_clean_queue_passes_silently(self) -> None:
        code, out, _ = self._run([])
        self.assertEqual(code, 0)
        self.assertEqual(out, "")


if __name__ == "__main__":
    unittest.main()
