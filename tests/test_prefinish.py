"""Unit tests for tools/prefinish.py, the one pre-finish command."""

from contextlib import redirect_stdout
from io import StringIO
import unittest
from unittest.mock import patch

from tools import prefinish


def fake_grep(index):
    return lambda term: index.get(term, [])


class SelectModulesTest(unittest.TestCase):
    def test_a_changed_test_module_runs_itself(self):
        chosen = prefinish.select_modules(["tests/test_godot_cache.py"], fake_grep({}))
        self.assertEqual({"tests.test_godot_cache": ["tests/test_godot_cache.py"]}, chosen)

    def test_a_python_tool_is_found_by_module_name_and_gdscript_by_file_name(self):
        self.assertEqual("godot_cache", prefinish.search_term("tools/godot_cache.py"))
        self.assertEqual("orders_zones.gd", prefinish.search_term("scripts/orders_zones.gd"))
        self.assertIsNone(prefinish.search_term("tools/__init__.py"))

    def test_tests_naming_a_changed_file_run_with_their_reason(self):
        chosen = prefinish.select_modules(
            ["scripts/orders_zones.gd"],
            fake_grep({"orders_zones.gd": ["tests/test_source_checks.py", "tests/test_godot_cache.py"]}))
        self.assertEqual(["tests.test_godot_cache", "tests.test_source_checks"], list(chosen))
        self.assertEqual(["scripts/orders_zones.gd"], chosen["tests.test_source_checks"])

    def test_the_lifecycle_suite_is_left_to_finish(self):
        chosen = prefinish.select_modules(
            ["tools/slice.ps1", "tests/test_slice_lifecycle.py"],
            fake_grep({"slice.ps1": ["tests/test_two_lane_closeout.py", "tests/test_source_checks.py"]}))
        self.assertEqual(["tests.test_source_checks"], list(chosen))

    def test_a_broadly_named_file_runs_only_its_own_tests(self):
        index = {"godot_compile_check": ["tests/test_godot_compile_check.py"] +
                 ["tests/test_scenario_%d.py" % n for n in range(prefinish.BROAD + 1)]}
        broad: list[str] = []
        chosen = prefinish.select_modules(["tools/godot_compile_check.py"], fake_grep(index), broad=broad)
        self.assertEqual(["tests.test_godot_compile_check"], list(chosen))
        self.assertEqual(["tools/godot_compile_check.py"], broad)


class MainTest(unittest.TestCase):
    def run_main(self, codes):
        steps: list[str] = []

        def step(name, command):
            steps.append(name)
            return codes.pop(0)

        output = StringIO()
        with patch.object(prefinish, "run_step", side_effect=step), \
             patch.object(prefinish, "changed_files", return_value=["tests/test_prefinish.py"]), \
             redirect_stdout(output):
            result = prefinish.main([])
        return result, steps, output.getvalue()

    def test_a_cache_fault_stops_first_and_keeps_exit_3(self):
        result, steps, output = self.run_main([3])
        self.assertEqual(3, result)
        self.assertEqual(["godot boot"], steps)
        self.assertIn("not the code", output)

    def test_a_source_check_failure_stops_before_unit_tests(self):
        result, steps, _ = self.run_main([0, 1])
        self.assertEqual(1, result)
        self.assertEqual(["godot boot", "source checks"], steps)

    def test_all_three_steps_run_in_order(self):
        result, steps, output = self.run_main([0, 0, 0])
        self.assertEqual(0, result)
        self.assertEqual(["godot boot", "source checks", "unit tests (1 modules)"], steps)
        self.assertIn("tests.test_prefinish", output)


if __name__ == "__main__":
    unittest.main()
