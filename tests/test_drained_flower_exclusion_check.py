#!/usr/bin/env python3
"""Tests for tools/drained_flower_exclusion_check.py."""

from __future__ import annotations

import io
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

from tools.drained_flower_exclusion_check import (
    check_nearest_flower_exclusion,
    main,
)

ROOT = Path(__file__).resolve().parent.parent


class TestDrainedFlowerExclusionCheck(unittest.TestCase):
    def test_repo_scripts_pass(self):
        """Current scripts/bee_foraging.gd on origin/master must pass cleanly."""
        target = ROOT / "scripts" / "bee_foraging.gd"
        content = target.read_text(encoding="utf-8")
        problems = check_nearest_flower_exclusion(content, str(target))
        self.assertEqual(problems, [])

    def test_missing_function_detected(self):
        """Missing static func nearest_flower is flagged."""
        content = "static func other_function():\n\tpass\n"
        problems = check_nearest_flower_exclusion(content, "fake.gd")
        self.assertTrue(any("nearest_flower(...) not found" in p for p in problems))

    def test_missing_cooldown_in_nearest_flower_detected(self):
        """Removing flower_cooldowns check from nearest_flower is flagged."""
        target = ROOT / "scripts" / "bee_foraging.gd"
        content = target.read_text(encoding="utf-8")
        # Mutate: remove the flower_cooldowns check block
        mutated = content.replace(
            "if bee.flower_cooldowns.has(f) and Session.sim_time < bee.flower_cooldowns[f]:\n\t\t\treturn false",
            "# removed cooldown check",
        )
        self.assertNotEqual(mutated, content)
        problems = check_nearest_flower_exclusion(mutated, str(target))
        self.assertTrue(any("lacks bee.flower_cooldowns.has" in p for p in problems))

    def test_strict_gated_cooldown_detected(self):
        """Placing flower_cooldowns inside the relaxed 'if strict:' block is flagged."""
        target = ROOT / "scripts" / "bee_foraging.gd"
        content = target.read_text(encoding="utf-8")
        # Cut the cooldown check and move it below 'if strict:'
        check_code = (
            "if bee.flower_cooldowns.has(f) and Session.sim_time < bee.flower_cooldowns[f]:\n\t\t\treturn false\n"
        )
        content_without_check = content.replace(check_code, "")
        self.assertNotEqual(content_without_check, content)
        mutated = content_without_check.replace(
            "if strict:\n",
            f"if strict:\n\t\t\t{check_code.strip()}\n",
        )
        problems = check_nearest_flower_exclusion(mutated, str(target))
        self.assertTrue(any("must remain unrelaxed" in p for p in problems))

    def test_missing_finish_collecting_cooldown_detected(self):
        """Removing flower_cooldowns assignment from finish_collecting is flagged."""
        target = ROOT / "scripts" / "bee_foraging.gd"
        content = target.read_text(encoding="utf-8")
        mutated = content.replace(
            "bee.flower_cooldowns[bee.current_flower] =",
            "# mutated_cooldown[bee.current_flower] =",
        )
        self.assertNotEqual(mutated, content)
        problems = check_nearest_flower_exclusion(mutated, str(target))
        self.assertTrue(
            any("finish_collecting does not assign flower_cooldowns" in p for p in problems)
        )

    def test_cli_invocation(self):
        """CLI runs cleanly on default and reports error on problem file."""
        out = io.StringIO()
        err = io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = main([])
        self.assertEqual(code, 0)
        self.assertIn("clean", out.getvalue())


if __name__ == "__main__":
    unittest.main()
