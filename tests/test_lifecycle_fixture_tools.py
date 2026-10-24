"""The fixture repositories copy every tool their copied tools import.

The lifecycle tests build a throwaway repository and copy into it only the
tools they name. When a copied tool gains an import of a sibling the fixture
does not copy, every fixture run crashes inside that tool -- L-35's
`import stop_causes` in check_docs.py stopped three lifecycle tests on 23 Oct
2026, and its try/except then skipped the check silently. This reads the test
files and the tools statically, so the next such import fails here, in
seconds, naming the line to add."""

from __future__ import annotations

import ast
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
TESTS = ROOT / "tests"

# The modules verify.ps1 runs as the lifecycle suite; the other fixture-copying
# tests (test_verify_generated.py) are found by searching for shutil.copy2.
LIFECYCLE_MODULES = ("test_slice_lifecycle.py", "test_two_lane_closeout.py")

# Sibling imports a copied tool guards and a fixture may leave out on purpose.
OPTIONAL_IMPORTS = {
    # check_docs.py's refill lookahead is advice; the tests that exercise the
    # refill copy refill_lane.py themselves.
    "refill_lane": "check_docs.py skips the refill lookahead without it",
}


def sibling_imports(tool: Path) -> set[str]:
    """Names of other tools/*.py modules `tool` imports, at any depth."""
    names = set()
    for node in ast.walk(ast.parse(tool.read_text(encoding="utf-8"))):
        if isinstance(node, ast.Import):
            names.update(alias.name.split(".")[0] for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            names.add(node.module.split(".")[0])
    return {name for name in names if name != tool.stem and (TOOLS / f"{name}.py").exists()}


def _string(node: ast.AST) -> str | None:
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return node.value
    return None


def _loop_values(function: ast.FunctionDef) -> dict[str, list[str]]:
    """`for name in ("a.py", "b.py"):` -> {"name": ["a.py", "b.py"]}."""
    values = {}
    for node in ast.walk(function):
        if (isinstance(node, ast.For) and isinstance(node.target, ast.Name)
                and isinstance(node.iter, (ast.Tuple, ast.List))):
            strings = [_string(element) for element in node.iter.elts]
            if all(strings):
                values[node.target.id] = strings
    return values


def _source_name(node: ast.AST) -> str | None:
    """The file name a copy's source path ends in: `TOOLS / "x.py"`."""
    if isinstance(node, ast.BinOp):
        return _string(node.right)
    return None


def copied_tools(function: ast.FunctionDef) -> set[str]:
    """tools/ file names `function` copies into `self.root / "tools"`."""
    loops = _loop_values(function)
    names = set()
    for node in ast.walk(function):
        if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
                and node.func.attr == "copy2" and len(node.args) >= 2):
            continue
        source, target = node.args[:2]
        if not isinstance(target, ast.BinOp):
            continue
        if _string(target.right) == "tools":
            # shutil.copy2(TOOLS / "x.py", self.root / "tools")
            name = _source_name(source)
            names.update([name] if name else [])
        elif isinstance(target.left, ast.BinOp) and _string(target.left.right) == "tools":
            name = _string(target.right)
            if name:
                names.add(name)
            elif isinstance(target.right, ast.Name):
                names.update(loops.get(target.right.id, []))
    return names


def fixture_copy_sets(test_file: Path) -> dict[str, set[str]]:
    """{"Class.method": tools copied by the class's setUp plus the method}.

    A helper such as use_real_closeout_tools gets its own entry, so a test
    that calls it is covered by the helper's set. A class that borrows
    another's fixture (`setUp = SliceDoctorTest.setUp`) gets that base."""
    sets = {}
    bases: dict[str, set[str]] = {}
    for cls in ast.parse(test_file.read_text(encoding="utf-8")).body:
        if not isinstance(cls, ast.ClassDef):
            continue
        methods = [node for node in cls.body if isinstance(node, ast.FunctionDef)]
        base = set().union(*(copied_tools(m) for m in methods if m.name in ("setUp", "setUpClass")))
        for node in cls.body:
            if (isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "setUp" for t in node.targets)
                    and isinstance(node.value, ast.Attribute) and isinstance(node.value.value, ast.Name)):
                base |= bases.get(node.value.value.id, set())
        bases[cls.name] = base
        if base:
            sets[f"{cls.name}.setUp"] = base
        for method in methods:
            own = copied_tools(method)
            if own and method.name not in ("setUp", "setUpClass"):
                sets[f"{cls.name}.{method.name}"] = base | own
    return sets


def fixture_test_files() -> list[Path]:
    return sorted(path for path in TESTS.glob("test_*.py")
                  if path.name != Path(__file__).name
                  and "copy2" in path.read_text(encoding="utf-8"))


def lifecycle_trigger_paths() -> set[str]:
    """The files whose change makes verify.ps1 run the lifecycle suite."""
    text = (TOOLS / "verify.ps1").read_text(encoding="utf-8")
    body = text.split("function Test-LifecycleTouched", 1)[1]
    paths = re.search(r"\$paths = @\(([^)]*)\)", body).group(1)
    return set(re.findall(r'"([^"]+)"', paths))


class LifecycleFixtureToolsTest(unittest.TestCase):
    def test_the_parser_sees_the_fixture_copies(self):
        # Guards the guard: if the copy lines change shape and nothing is
        # found, every other assertion here would pass vacuously.
        sets = fixture_copy_sets(TESTS / "test_two_lane_closeout.py")
        self.assertIn("check_docs.py", sets["TwoLaneCloseoutTest.setUp"])
        self.assertIn("archive_slice.py", sets["TwoLaneCloseoutTest.use_real_closeout_tools"])

    def test_every_copied_tool_has_its_sibling_imports_copied(self):
        problems = []
        for test_file in fixture_test_files():
            for where, copied in fixture_copy_sets(test_file).items():
                stems = {Path(name).stem for name in copied}
                for name in sorted(n for n in copied if n.endswith(".py")):
                    for module in sorted(sibling_imports(TOOLS / name) - stems - set(OPTIONAL_IMPORTS)):
                        problems.append(
                            f"tests/{test_file.name} {where} copies tools/{name}, which imports "
                            f"{module}: copy tools/{module}.py there too, or add it to "
                            f"OPTIONAL_IMPORTS with the reason the fixture can do without it")
        self.assertEqual([], problems, "\n".join(problems))

    def test_verify_runs_the_lifecycle_suite_when_a_copied_tool_changes(self):
        triggers = lifecycle_trigger_paths()
        missing = set()
        for module in LIFECYCLE_MODULES:
            for copied in fixture_copy_sets(TESTS / module).values():
                missing.update(f"tools/{name}" for name in copied if f"tools/{name}" not in triggers)
        self.assertEqual(set(), missing,
                         "add these to $paths in Test-LifecycleTouched (tools/verify.ps1): "
                         + ", ".join(sorted(missing)))


if __name__ == "__main__":
    unittest.main()
