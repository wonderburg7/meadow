"""Unit tests for pure helper functions in tools/godot_cache.py."""

import unittest
from pathlib import Path
from unittest.mock import patch

from tools import godot_cache


class TestGodotCacheHelpers(unittest.TestCase):
    def test_fix_command_secondary_worktree(self):
        worktree = Path("/repo/worktrees/branch").resolve()
        primary = Path("/repo").resolve()
        with patch.object(godot_cache, "primary_root", return_value=primary):
            cmd = godot_cache.fix_command(worktree)
        expected = f"in Windows PowerShell: cd {worktree}; python tools/godot_cache.py --force"
        self.assertEqual(cmd, expected)

    def test_fix_command_primary_checkout_godot_found(self):
        primary = Path("/repo").resolve()
        with patch.object(godot_cache, "primary_root", return_value=primary):
            with patch.object(godot_cache, "_compile_check") as mock_compile:
                mock_compile.return_value.find_godot.return_value = "C:/Godot/Godot.exe"
                cmd = godot_cache.fix_command(primary)
        expected = "in Windows PowerShell: cd %s; & 'C:/Godot/Godot.exe' --headless --import --path ." % primary
        self.assertEqual(cmd, expected)

    def test_fix_command_primary_checkout_no_godot_found(self):
        primary = Path("/repo").resolve()
        with patch.object(godot_cache, "primary_root", return_value=primary):
            with patch.object(godot_cache, "_compile_check") as mock_compile:
                mock_compile.return_value.find_godot.return_value = None
                cmd = godot_cache.fix_command(primary)
        expected = "in Windows PowerShell: cd %s; & '<path to Godot.exe>' --headless --import --path ." % primary
        self.assertEqual(cmd, expected)

    def test_fix_command_primary_checkout_exception_fallback(self):
        primary = Path("/repo").resolve()
        with patch.object(godot_cache, "primary_root", return_value=primary):
            with patch.object(godot_cache, "_compile_check", side_effect=RuntimeError("cannot compile")):
                cmd = godot_cache.fix_command(primary)
        expected = "in Windows PowerShell: cd %s; & '<path to Godot.exe>' --headless --import --path ." % primary
        self.assertEqual(cmd, expected)

    def test_cache_fault_format(self):
        root = Path("/repo").resolve()
        with patch.object(godot_cache, "fix_command", return_value="run-fix"):
            msg = godot_cache.cache_fault("disk corrupt", root)
        self.assertEqual(
            msg,
            f"{godot_cache.CACHE_FAULT} -- disk corrupt. Your code was not at fault. Fix: run-fix",
        )


if __name__ == "__main__":
    unittest.main()
