"""Tests for tools/self_call_check.py."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import self_call_check  # noqa: E402


class TestSelfCallCheck(unittest.TestCase):
    def test_real_tree_passes(self) -> None:
        """The real tree on origin/master must have no un-allowlisted self-calls."""
        files = self_call_check.tracked_gd_files(ROOT)
        self.assertGreater(len(files), 0, "Expected to find GDScript files in scripts/")
        problems: list[str] = []
        for path in files:
            problems.extend(self_call_check.check_file(path))
        self.assertEqual(problems, [], f"Unexpected self-calls on real tree: {problems}")

    def test_cli_main_passes_on_repo(self) -> None:
        """main() returns 0 when run on the repo."""
        code = self_call_check.main([])
        self.assertEqual(code, 0)

    def test_bare_self_call_detected(self) -> None:
        """A bare self-call inside a function body is flagged."""
        sample = (
            "extends Node\n"
            "\n"
            "func perform_work() -> void:\n"
            "    print('working')\n"
            "    perform_work()\n"
        )
        problems = self_call_check.check_file("scripts/dummy_test.gd", text=sample)
        self.assertEqual(len(problems), 1)
        self.assertIn("perform_work()", problems[0])

    def test_qualified_calls_ignored(self) -> None:
        """Calls via super., self., or other objects are not bare self-calls."""
        sample = (
            "extends Node\n"
            "\n"
            "func process_data() -> void:\n"
            "    super.process_data()\n"
            "    self.process_data()\n"
            "    helper.process_data()\n"
        )
        problems = self_call_check.check_file("scripts/dummy_test.gd", text=sample)
        self.assertEqual(problems, [])

    def test_comments_and_strings_ignored(self) -> None:
        """Mentions of the function name inside comments or strings are ignored."""
        sample = (
            "extends Node\n"
            "\n"
            "func do_something() -> void:\n"
            "    # do_something() should be called later\n"
            "    var msg := 'calling do_something() now'\n"
            "    print(msg)\n"
        )
        problems = self_call_check.check_file("scripts/dummy_test.gd", text=sample)
        self.assertEqual(problems, [])

    def test_allowlist_entry_ignored(self) -> None:
        """Functions in ALLOWLIST are permitted to call themselves."""
        sample = (
            "extends RefCounted\n"
            "\n"
            "func _add_with_prerequisites(skill_id: String, path: Dictionary) -> void:\n"
            "    path[skill_id] = true\n"
            "    _add_with_prerequisites(skill_id, path)\n"
        )
        problems = self_call_check.check_file("scripts/progression.gd", text=sample)
        self.assertEqual(problems, [])


if __name__ == "__main__":
    unittest.main()
