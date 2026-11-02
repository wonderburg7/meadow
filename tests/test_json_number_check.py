"""Unit tests for tools/json_number_check.py."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import json_number_check  # noqa: E402


class TestJsonNumberCheck(unittest.TestCase):
    def test_real_tree_passes(self) -> None:
        """The real tree on origin/master must pass json_number_check."""
        files = json_number_check.tracked_gd_files(ROOT)
        self.assertGreater(len(files), 0, "Expected to find GDScript files in scripts/")
        problems: list[str] = []
        for path in files:
            problems.extend(json_number_check.check_file(path))
        self.assertEqual(problems, [], f"Unexpected errors on real tree: {problems}")

    def test_cli_main_passes_on_repo(self) -> None:
        """main() returns 0 when run on the repo."""
        code = json_number_check.main([])
        self.assertEqual(code, 0)

    def test_uncoerced_json_loop_variable_flagged(self) -> None:
        """A loop variable over parsed numeric data checked in an array without int() is flagged."""
        bad_sample = (
            "extends RefCounted\n"
            "\n"
            "static func completed_challenges(data: Dictionary) -> Array:\n"
            "    var levels: Array = []\n"
            "    for value in data.get('completed_challenges', []):\n"
            "        if not levels.has(value):\n"
            "            levels.append(value)\n"
            "    return levels\n"
        )
        problems = json_number_check.check_file("scripts/dummy.gd", text=bad_sample)
        self.assertEqual(len(problems), 1)
        self.assertIn("uncoerced JSON loop variable 'value'", problems[0])

    def test_coerced_json_loop_variable_passes(self) -> None:
        """Coercing with int(...) before membership check passes."""
        good_sample = (
            "extends RefCounted\n"
            "\n"
            "static func completed_challenges(data: Dictionary) -> Array:\n"
            "    var levels: Array = []\n"
            "    for value in data.get('completed_challenges', []):\n"
            "        var level := int(value)\n"
            "        if not levels.has(level):\n"
            "            levels.append(level)\n"
            "    return levels\n"
        )
        problems = json_number_check.check_file("scripts/dummy.gd", text=good_sample)
        self.assertEqual(problems, [])

    def test_string_array_membership_passes(self) -> None:
        """Accept string-array membership (e.g. data.get('names') or keys/tags)."""
        sample = (
            "extends RefCounted\n"
            "\n"
            "static func check_names(data: Dictionary, key: String) -> bool:\n"
            "    for name in data.get('names', []):\n"
            "        if names.has(key):\n"
            "            return true\n"
            "    return false\n"
        )
        problems = json_number_check.check_file("scripts/dummy.gd", text=sample)
        self.assertEqual(problems, [])

    def test_taint_expires_at_loop_and_reused_variable_passes(self) -> None:
        """Loop variable taint expires at loop scope exit; reused variable later passes."""
        sample = (
            "extends RefCounted\n"
            "\n"
            "func check_stuff(data: Dictionary) -> void:\n"
            "    for value in data.get('completed_challenges', []):\n"
            "        pass\n"
            "    # Second loop reuses 'value' for pure integers\n"
            "    var known_ints := [1, 2, 3]\n"
            "    for value in [1, 2, 3]:\n"
            "        if known_ints.has(value):\n"
            "            pass\n"
        )
        problems = json_number_check.check_file("scripts/dummy.gd", text=sample)
        self.assertEqual(problems, [])

    def test_raw_numeric_get_lookup_flagged(self) -> None:
        """Direct raw numeric .get lookup inside .has() is flagged."""
        bad_sample = (
            "extends RefCounted\n"
            "\n"
            "func test_raw_get(data: Dictionary, levels: Array) -> bool:\n"
            "    return levels.has(data.get('level'))\n"
        )
        problems = json_number_check.check_file("scripts/dummy.gd", text=bad_sample)
        self.assertEqual(len(problems), 1)
        self.assertIn("uncoerced JSON numeric get", problems[0])

    def test_mutation_proof_player_profile(self) -> None:
        """Mutation proof: removing int() coercion in player_profile.gd triggers the check."""
        real_content = (ROOT / "scripts" / "player_profile.gd").read_text(encoding="utf-8")
        mutated = real_content.replace(
            "for value: Variant in data.get(\"completed_challenges\", []):\n\t\tvar level := int(value)",
            "for value: Variant in data.get(\"completed_challenges\", []):\n\t\tif not levels.has(value):",
        )
        self.assertNotEqual(real_content, mutated, "Mutation failed to apply to player_profile.gd")
        problems = json_number_check.check_file("scripts/player_profile.gd", text=mutated)
        self.assertEqual(len(problems), 1)
        self.assertIn("uncoerced JSON loop variable 'value'", problems[0])


if __name__ == "__main__":
    unittest.main()
