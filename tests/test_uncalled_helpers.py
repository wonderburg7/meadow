import tempfile
import unittest
from pathlib import Path

from tools.uncalled import (
    find_gdscript_functions,
    is_function_referenced,
    preindex_file_contents,
)


class TestUncalledHelpers(unittest.TestCase):
    def test_find_gdscript_functions_and_preindex_and_referenced(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            scripts_dir = tmp / "scripts"
            scripts_dir.mkdir(parents=True, exist_ok=True)

            a_gd = scripts_dir / "a.gd"
            b_gd = scripts_dir / "b.gd"

            a_content = (
                "extends Node\n"
                "func used():\n"
                "    pass\n"
                "func unused():\n"
                "    pass\n"
                "static func helper():\n"
                "    used()\n"
                "func _ready():\n"
                "    pass\n"
            )
            b_content = (
                "extends Node\n"
                "func _process(_delta):\n"
                "    used()\n"
            )

            a_gd.write_text(a_content, encoding="utf-8")
            b_gd.write_text(b_content, encoding="utf-8")

            # Check find_gdscript_functions
            funcs = find_gdscript_functions(scripts_dir)
            # Should find used, unused, helper in scripts/a.gd, and none for _ready or _process
            self.assertEqual(
                funcs,
                [
                    ("scripts/a.gd", "used", 2),
                    ("scripts/a.gd", "unused", 4),
                    ("scripts/a.gd", "helper", 6),
                ],
            )

            # Check missing directory returns []
            self.assertEqual(find_gdscript_functions(tmp / "nonexistent"), [])

            # Check preindex_file_contents
            files = [a_gd, b_gd]
            cache = preindex_file_contents(files, tmp)
            expected_cache = [
                ("scripts/a.gd", a_content.splitlines(), a_content),
                ("scripts/b.gd", b_content.splitlines(), b_content),
            ]
            self.assertEqual(cache, expected_cache)

            # Check is_function_referenced
            # used is called in a.gd (line 7) and b.gd (line 3), def line is line 2
            self.assertTrue(is_function_referenced("used", "scripts/a.gd", 2, cache))

            # unused has no references outside line 4
            self.assertFalse(is_function_referenced("unused", "scripts/a.gd", 4, cache))

            # helper: referenced only on line 6 (def line) -> False
            self.assertFalse(is_function_referenced("helper", "scripts/a.gd", 6, cache))

            # Check true when only other mention is a second line of defining file
            # E.g. create a test cache where helper is referenced on another line in scripts/a.gd
            a_self_ref_content = (
                "func helper():\n"
                "    helper()\n"
            )
            a_self_ref_gd = tmp / "scripts" / "self_ref.gd"
            a_self_ref_gd.write_text(a_self_ref_content, encoding="utf-8")
            self_cache = preindex_file_contents([a_self_ref_gd], tmp)
            self.assertTrue(is_function_referenced("helper", "scripts/self_ref.gd", 1, self_cache))

            # Check false for 'use' (whole-word match, so 'used' does not count as 'use')
            self.assertFalse(is_function_referenced("use", "scripts/a.gd", 1, cache))


if __name__ == "__main__":
    unittest.main()
