"""Unit tests for tools/freeze_bee_check.py."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import freeze_bee_check  # noqa: E402


class TestFreezeBeeCheck(unittest.TestCase):
    def test_repo_passes(self) -> None:
        """The repository tree on origin/master passes freeze_bee_check."""
        problems = freeze_bee_check.check_repo(ROOT)
        self.assertEqual(problems, [], f"Unexpected problems on repo: {problems}")

    def test_main_cli_success(self) -> None:
        """CLI invocation succeeds with code 0."""
        code = freeze_bee_check.main([str(ROOT)])
        self.assertEqual(code, 0)

    def test_detects_missing_state_idling_in_set_focus(self) -> None:
        """Mutation proof: removing State.IDLING handling in set_focus fails the check."""
        sample_bee = (
            "func set_focus(new_focus: String) -> void:\n"
            "    focus = new_focus\n"
            "    if not _is_inside_hive():\n"
            "        state = State.SEEK_FLOWER\n"
        )
        problems = freeze_bee_check.check_bee_set_focus(sample_bee)
        self.assertTrue(
            any("set_focus does not handle 'State.IDLING'" in p for p in problems),
            f"Expected State.IDLING warning, got {problems}",
        )

    def test_detects_incomplete_freeze_effect(self) -> None:
        """Mutation proof: omitting clear_navigation_state from freeze_bee:queen fails."""
        sample_runner = (
            '\t\t\t"freeze_bee:queen":\n'
            "\t\t\t\tmain.queen._release_everything()\n"
            "\t\t\t\tmain.queen.state = main.Bee.State.IDLING\n"
        )
        problems = freeze_bee_check.check_challenge_runner_freeze(sample_runner)
        self.assertTrue(
            any("clear_navigation_state" in p for p in problems),
            f"Expected clear_navigation_state error, got {problems}",
        )

    def test_detects_unwoken_freeze_stage(self) -> None:
        """Mutation proof: a stage freezing the queen followed by a stage with no wake path fails."""
        sample_stages = (
            '[\n'
            '    {\n'
            '        "id": "1.1",\n'
            '        "setup": {"queen_at": "hive_floor"},\n'
            '        "on_exit": ["freeze_bee:queen"]\n'
            '    },\n'
            '    {\n'
            '        "id": "1.2",\n'
            '        "setup": {"built_cells": 1},\n'
            '        "unlocked_keys": []\n'
            '    }\n'
            ']\n'
        )
        problems = freeze_bee_check.check_challenge_stages_wake_path(sample_stages)
        self.assertTrue(
            any("provides no wake-up path or commands" in p for p in problems),
            f"Expected unwoken freeze stage error, got {problems}",
        )

    def test_actual_assignment_mutations(self):
        bee = (ROOT / "scripts/bee.gd").read_text(encoding="utf-8")
        old = "\t\tstate = State.IN_HIVE_TO_EXIT"
        self.assertIn(old, bee)
        for replacement in ["\t\tvar _unused = State.IN_HIVE_TO_EXIT",
                            '\t\tvar _unused = "state = State.IN_HIVE_TO_EXIT"',
                            "\t\tstate == State.IN_HIVE_TO_EXIT"]:
            with self.subTest(replacement=replacement):
                self.assertTrue(freeze_bee_check.check_bee_set_focus(bee.replace(old, replacement)))

    def test_stage_words_false_flags_and_debug_setup_are_not_wake(self):
        prefix = '[{"id":"1.1","on_exit":["freeze_bee:queen"]},'
        for extra in ['"player_driven":false', '"player_driven":true',
                      '"instruction":"assign role forager queen_commands"',
                      '"setup":{"queen_role":"forager"}',
                      '"prompts":[{"id":"queen_commands","text":"assign role"}]']:
            with self.subTest(extra=extra):
                sample = prefix + '{"id":"1.2","unlocked_keys":[],' + extra + '}]'
                self.assertTrue(freeze_bee_check.check_challenge_stages_wake_path(sample))
        good = prefix + '{"id":"1.2","unlocked_keys":[{"key":"queen_commands","trigger":"event"}]}]'
        self.assertEqual(freeze_bee_check.check_challenge_stages_wake_path(good), [])

    def test_actual_command_transition_is_required(self):
        bee = (ROOT / "scripts/bee.gd").read_text(encoding="utf-8")
        runner = (ROOT / "scripts/challenge_runner.gd").read_text(encoding="utf-8")
        selection = (ROOT / "scripts/input_selection.gd").read_text(encoding="utf-8")
        for old in ["state = State.MOVE_TO_POINT", "state = State.IN_HIVE_TO_EXIT"]:
            self.assertIn(old, bee)
            self.assertTrue(freeze_bee_check.check_command_wake(
                bee.replace(old, 'var _unused = "' + old + '"'), runner, selection))
        self.assertTrue(freeze_bee_check.check_command_wake(bee, runner,
            selection.replace("b.command_move_to(", "# b.command_move_to(")))

    def test_strings_cannot_supply_freeze_reset(self):
        source = (ROOT / "scripts/challenge_runner.gd").read_text(encoding="utf-8")
        old = "main.queen.clear_navigation_state()"
        self.assertIn(old, source)
        self.assertTrue(freeze_bee_check.check_challenge_runner_freeze(
            source.replace(old, 'var _unused = "' + old + '"')))


if __name__ == "__main__":
    unittest.main()
