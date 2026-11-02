"""Unit tests for tools/bee_idle_dispatch_check.py."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import bee_idle_dispatch_check  # noqa: E402


class TestBeeIdleDispatchCheck(unittest.TestCase):
    def test_real_tree_passes(self) -> None:
        """The real tree on origin/master passes bee idle dispatch checks."""
        files = [ROOT / "scripts" / "bee.gd", ROOT / "scripts" / "challenge_stages.gd"]
        problems: list[str] = []
        for path in files:
            problems.extend(bee_idle_dispatch_check.check_file(path))
        self.assertEqual(problems, [], f"Unexpected idle dispatch problems on real tree: {problems}")

    def test_cli_main_passes_on_repo(self) -> None:
        """main() returns 0 when run on the repo defaults."""
        code = bee_idle_dispatch_check.main([])
        self.assertEqual(code, 0)

    def test_cli_files_argument(self) -> None:
        """main() accepts specific file paths."""
        code = bee_idle_dispatch_check.main(["scripts/bee.gd"])
        self.assertEqual(code, 0)

    def test_bee_set_focus_without_idling_wake_fails(self) -> None:
        """Removing State.IDLING handling from set_focus in bee.gd fails the check."""
        code = (
            "extends Node2D\n"
            "func set_focus(new_focus: String) -> void:\n"
            "    focus = new_focus\n"
            "    if not _is_inside_hive():\n"
            "        state = State.SEEK_FLOWER\n"
            "    _update_label()\n"
        )
        problems = bee_idle_dispatch_check.check_focus_idle_dispatch(code, filename="scripts/bee.gd")
        self.assertEqual(len(problems), 1)
        self.assertIn("does not handle State.IDLING", problems[0])

    def test_challenge_stage_freeze_without_subsequent_resume_fails(self) -> None:
        """Freezing a bee in a stage whose next stage does not provide a resume/setup path fails."""
        code = (
            'const STAGES := [\n'
            '    {\n'
            '        "id": "1.1", "goal": "first",\n'
            '        "on_exit": ["freeze_bee:queen"],\n'
            '    },\n'
            '    {\n'
            '        "id": "1.2", "goal": "second",\n'
            '    },\n'
            ']\n'
        )
        problems = bee_idle_dispatch_check.check_challenge_stages(code, filename="scripts/challenge_stages.gd")
        self.assertEqual(len(problems), 1)
        self.assertIn("stage 1.1 freezes bee, but subsequent stage 1.2 does not define how the bee starts again", problems[0])

    def test_challenge_stage_freeze_with_subsequent_resume_passes(self) -> None:
        """Freezing a bee followed by a stage with setup/instruction passes."""
        code = (
            'const STAGES := [\n'
            '    {\n'
            '        "id": "1.1", "goal": "first",\n'
            '        "on_exit": ["freeze_bee:queen"],\n'
            '    },\n'
            '    {\n'
            '        "setup": {"queen_role": "forager"},\n'
            '        "id": "1.2", "goal": "second",\n'
            '        "instruction": "give her the Forager role",\n'
            '    },\n'
            ']\n'
        )
        problems = bee_idle_dispatch_check.check_challenge_stages(code, filename="scripts/challenge_stages.gd")
        self.assertEqual(problems, [])


if __name__ == "__main__":
    unittest.main()
