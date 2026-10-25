"""CQ-L2: the tools that read GDScript as text give the same answers after gdformat.

CQ-L3 reformats the whole repository with gdformat (gdtoolkit 4.5.0). Four tools
read `.gd` files as text rather than through Godot: tests/source_checks.py,
tools/stage_reference.py, tools/update_function_map.py and tools/sprites.py.
This copies the tracked `.gd` files (outside addons/) into a temporary tree,
formats the copy, and runs each tool on both. Nothing in the repository is
reformatted.

Skips with one line where gdtoolkit is missing (pip install gdtoolkit==4.5.0).
"""
from __future__ import annotations

import contextlib
import importlib.util
import io
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tests"))

import sprites  # noqa: E402
import stage_reference  # noqa: E402
import update_function_map  # noqa: E402
import source_checks  # noqa: E402

HAVE_GDTOOLKIT = importlib.util.find_spec("gdtoolkit") is not None

# Tracked paths beyond the .gd files that source_checks.py and sprites.py read.
SUPPORT_DIRS = ("tools", "test_scenarios", "assets/sprites", "tests")
SUPPORT_FILES = ("project.godot",)


def _tracked(*pathspec: str) -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "-z", "--", *pathspec],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout
    return [p for p in out.split("\0") if p]


def _squash(text: str) -> str:
    return re.sub(r"\s+", "", text)


@unittest.skipUnless(HAVE_GDTOOLKIT, "gdtoolkit is not installed: skipping gdformat survival")
class GdformatSurvival(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._tmp = tempfile.TemporaryDirectory()
        cls.original = Path(cls._tmp.name) / "original"
        cls.formatted = Path(cls._tmp.name) / "formatted"
        gd_files = [p for p in _tracked("*.gd") if not p.startswith("addons/")]
        others = [
            p for p in _tracked(*SUPPORT_DIRS, *SUPPORT_FILES)
            if not p.endswith(".gd")
        ]
        for tree in (cls.original, cls.formatted):
            for rel in gd_files + others:
                target = tree / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / rel, target)
        # One gdformat run per folder keeps the command line short.
        for folder in sorted({str(Path(p).parent) for p in gd_files}):
            files = [str(cls.formatted / p) for p in gd_files if str(Path(p).parent) == folder]
            result = subprocess.run(
                [sys.executable, "-m", "gdtoolkit.formatter", *files],
                capture_output=True, text=True,
            )
            if result.returncode != 0:
                raise RuntimeError("gdformat failed in %s:\n%s%s" % (folder, result.stdout, result.stderr))

    @classmethod
    def tearDownClass(cls):
        cls._tmp.cleanup()

    def test_formatting_really_changed_the_copy(self):
        """Guards the comparison: an unformatted copy would pass everything."""
        changed = [
            p for p in (self.formatted / "scripts").glob("*.gd")
            if p.read_bytes() != (self.original / "scripts" / p.name).read_bytes()
        ]
        self.assertTrue(changed, "gdformat changed no scripts/*.gd file")

    def test_stage_reference(self):
        before = stage_reference.render(self.original / "scripts" / "challenge_stages.gd")
        after = stage_reference.render(self.formatted / "scripts" / "challenge_stages.gd")
        self.assertEqual(before, after)

    def test_function_map(self):
        for name in sorted(p.name for p in (self.original / "scripts").glob("*.gd")):
            lines_before = (self.original / "scripts" / name).read_text(encoding="utf-8").splitlines()
            lines_after = (self.formatted / "scripts" / name).read_text(encoding="utf-8").splitlines()
            before = [text for _, text in update_function_map.index_entries(lines_before)]
            after = [text for _, text in update_function_map.index_entries(lines_after)]
            self.assertEqual(len(before), len(after), "%s: entry count changed" % name)
            for old, new in zip(before, after):
                # A signature hand-wrapped today is indexed by its first line
                # only; the formatted form carries all of it, so the old text
                # must open the new one.
                self.assertTrue(
                    _squash(new).startswith(_squash(old)) or old == new,
                    "%s: %r became %r" % (name, old, new),
                )

    def test_wrapped_signature_with_hash_in_string(self):
        lines = ["func f(", '	a: String = "#fff",', "	b: int,", ") -> void:", "	pass"]
        entries = update_function_map.index_entries(lines)
        self.assertEqual(entries, [(1, 'func f(a: String = "#fff", b: int) -> void')])

    def test_sprites_catalogue(self):
        results = []
        for tree in (self.original, self.formatted):
            lines: list[str] = []
            code = sprites.run(tree, True, out=lines.append)
            results.append((code, lines))
        self.assertEqual(results[0], results[1])
        self.assertEqual(results[0][0], 0, "\n".join(results[0][1]))

    def test_source_checks(self):
        results = []
        saved_root = source_checks.ROOT
        saved_uids = source_checks.check_script_uids_tracked
        # The uid check asks git, and the copies are not repositories.
        source_checks.check_script_uids_tracked = lambda problems: None
        try:
            for tree in (self.original, self.formatted):
                source_checks.ROOT = str(tree / "scripts")
                buffer = io.StringIO()
                with contextlib.redirect_stdout(buffer):
                    code = source_checks.main()
                results.append((code, buffer.getvalue()))
        finally:
            source_checks.ROOT = saved_root
            source_checks.check_script_uids_tracked = saved_uids
        self.assertEqual(results[0], results[1])
        self.assertEqual(results[0][0], 0, results[0][1])


if __name__ == "__main__":
    unittest.main()
