"""Unit tests for tools/nearest_exclusion_check.py.

Guards the pitfall documented in docs/known-pitfalls.md:
"Nearest-thing searches picking the thing you're standing on"
"""

import io
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

from tools.nearest_exclusion_check import check_file, main, strip_code


class TestNearestExclusionCheck(unittest.TestCase):
    def test_strip_code(self):
        self.assertEqual(strip_code("var x = 1 # comment"), "var x = 1 ")
        self.assertEqual(strip_code('var s = "hello # world"'), 'var s = ""')
        self.assertEqual(strip_code("var c = 'test' # note"), 'var c = "" ')

    def test_clean_nearest_flower(self):
        code = """
class_name BeeForaging

static func nearest_flower(bee: Node2D, strict: bool, radius: float) -> Node2D:
\tvar accept := func(f: Variant) -> bool:
\t\tif bee.flower_cooldowns.has(f):
\t\t\treturn false
\t\tif strict:
\t\t\tif f.is_marked(bee):
\t\t\t\treturn false
\t\treturn true
\treturn null
"""
        problems = check_file("test_clean.gd", text=code)
        self.assertEqual(problems, [])

    def test_missing_cooldown_check(self):
        code = """
class_name BeeForaging

static func nearest_flower(bee: Node2D, strict: bool, radius: float) -> Node2D:
\tvar accept := func(f: Variant) -> bool:
\t\tif strict:
\t\t\tif f.is_marked(bee):
\t\t\t\treturn false
\t\treturn true
\treturn null
"""
        problems = check_file("test_missing.gd", text=code)
        self.assertEqual(len(problems), 1)
        self.assertIn("missing flower_cooldowns exclusion check", problems[0])

    def test_cooldown_nested_inside_strict(self):
        code = """
class_name BeeForaging

static func nearest_flower(bee: Node2D, strict: bool, radius: float) -> Node2D:
\tvar accept := func(f: Variant) -> bool:
\t\tif strict:
\t\t\tif bee.flower_cooldowns.has(f):
\t\t\t\treturn false
\t\t\tif f.is_marked(bee):
\t\t\t\treturn false
\t\treturn true
\treturn null
"""
        problems = check_file("test_strict_cooldown.gd", text=code)
        self.assertEqual(len(problems), 1)
        self.assertIn("must apply unconditionally", problems[0])

    def test_main_passes_on_repo(self):
        out = io.StringIO()
        err = io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = main(["scripts/bee_foraging.gd"])
        self.assertEqual(code, 0)
        self.assertIn("files checked, nearest queries properly exclude cooldowns", out.getvalue())

    def test_main_fails_on_problematic_file(self):
        import tempfile
        with tempfile.NamedTemporaryFile("w", suffix=".gd", delete=False) as f:
            f.write("""
static func nearest_flower(bee: Node2D, strict: bool, radius: float) -> Node2D:
\treturn null
""")
            tmp_name = f.name
        try:
            out = io.StringIO()
            err = io.StringIO()
            with redirect_stdout(out), redirect_stderr(err):
                code = main([tmp_name])
            self.assertEqual(code, 1)
            self.assertIn("FAILED -- nearest exclusion check found problems:", err.getvalue())
        finally:
            Path(tmp_name).unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
