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

    def test_executable_membership_only(self):
        prefix = "func check(data):\n    for value in data.get('completed_challenges', []):\n"
        for statement, count in [
            ('print("levels.has(value)")', 0),
            ("# levels.has(value)", 0),
            ("if levels.has(value): # int(value)", 1),
            ('if levels.has(value): print("int(value)")', 1),
            ("if levels.has(value) and int(value) > 0:", 1),
            ("if levels.has(int(value)):", 0),
            ('print("""levels.has(value)\nlevels.has(value)""")', 0),
        ]:
            with self.subTest(statement=statement):
                self.assertEqual(len(json_number_check.check_file("fake.gd", prefix + "        " + statement)), count)

    def test_function_boundary_and_numeric_names(self):
        sample = """func first(data):
    for value in data.get('completed_challenges', []):
        pass
func second(value):
    return levels.has(value)
func strings(data):
    for level in data.get('names', []):
        if names.has(level):
            pass
"""
        self.assertEqual(json_number_check.check_file("fake.gd", sample), [])

    def test_cast_comment_does_not_hide_direct_get(self):
        for expr, count in [("data.get('level')", 1), ("int(data.get('level'))", 0),
                            ("data.get('name')", 0)]:
            self.assertEqual(len(json_number_check.check_file("fake.gd",
                f"func check(data):\n    return levels.has({expr}) # int(value)\n")), count)


if __name__ == "__main__":
    unittest.main()
