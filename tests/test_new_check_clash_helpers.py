"""Unit tests for clash and confirmation functions in tools/new_check.py."""

from pathlib import Path
import unittest
from unittest.mock import MagicMock, patch

from tools import new_check


class TestNewCheckClashHelpers(unittest.TestCase):
    def test_ids_in(self) -> None:
        self.assertEqual(new_check.ids_in(""), set())
        self.assertEqual(new_check.ids_in("No check id here"), set())
        self.assertEqual(new_check.ids_in("C-1 and C-42"), {1, 42})
        self.assertEqual(new_check.ids_in("C-005, C-150, C-9999"), {5, 150, 9999})
        self.assertEqual(new_check.ids_in("C-1 C-1 C-2"), {1, 2})

    def test_ids_spent_on_mocked_git(self) -> None:
        def fake_git_text(root: Path, *args: str) -> str:
            if args[0] == "ls-tree" and args[-1] == "checks/ready/":
                return "checks/ready/C-10.md\nchecks/ready/C-20.md\n"
            if args[0] == "show":
                ref_path = args[1]
                if ref_path.endswith("checks/blocked.md"):
                    return "# Blocked\nC-30 is blocked\n"
                if ref_path.endswith(new_check.ARCHIVE_REL):
                    return "# Archive\nC-40 was confirmed\n"
                raise RuntimeError(f"Unknown ref_path: {ref_path}")
            raise RuntimeError(f"Unexpected git args: {args}")

        with patch.object(new_check, "git_text", side_effect=fake_git_text):
            spent = new_check.ids_spent_on(Path("/repo"), "origin/master")
            self.assertEqual(spent, {10, 20, 30, 40})

    def test_ids_spent_on_missing_git_files(self) -> None:
        def fake_git_text(root: Path, *args: str) -> str:
            if args[0] == "ls-tree":
                return "checks/ready/C-5.md\n"
            if args[0] == "show":
                raise RuntimeError("fatal: Path does not exist in ref")
            raise RuntimeError(f"Unexpected git args: {args}")

        with patch.object(new_check, "git_text", side_effect=fake_git_text):
            spent = new_check.ids_spent_on(Path("/repo"), "HEAD")
            self.assertEqual(spent, {5})

    def test_confirm_main_invalid_id(self) -> None:
        with patch("sys.stderr"):
            code = new_check.confirm_main(["invalid_id"], note="Test")
            self.assertEqual(code, 1)

    def test_confirm_main_index_regen_failure(self) -> None:
        fake_removed = [Path("/repo/checks/ready/C-1.md")]
        with patch.object(new_check, "confirm_checks", return_value=fake_removed), \
             patch("subprocess.run") as mock_run, \
             patch("builtins.print"), \
             patch("sys.stderr"):
            mock_proc = MagicMock()
            mock_proc.returncode = 1
            mock_run.return_value = mock_proc

            code = new_check.confirm_main(["C-1"], note="Done")
            self.assertEqual(code, 1)

    def test_confirm_main_success(self) -> None:
        fake_removed = [Path("/repo/checks/ready/C-1.md")]
        with patch.object(new_check, "confirm_checks", return_value=fake_removed), \
             patch("subprocess.run") as mock_run, \
             patch.object(new_check, "still_mentioned", return_value=["plans/now/ui.md:12: C-1"]), \
             patch("builtins.print") as mock_print:
            mock_proc = MagicMock()
            mock_proc.returncode = 0
            mock_run.return_value = mock_proc

            code = new_check.confirm_main(["C-1"], note="Done")
            self.assertEqual(code, 0)
            mock_print.assert_any_call(f"C-1 archived to {new_check.ARCHIVE_REL}")
            mock_print.assert_any_call("Still named here -- release any work these checks were holding back:")
            mock_print.assert_any_call("  plans/now/ui.md:12: C-1")


if __name__ == "__main__":
    unittest.main()
