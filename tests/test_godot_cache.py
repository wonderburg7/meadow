"""Unit tests for the worktree Godot cache: staleness, import and fault naming."""

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools import godot_cache


class CacheActionTest(unittest.TestCase):
    def test_primary_checkout_is_never_touched(self):
        self.assertEqual(godot_cache.cache_action(True, False, None, None), "present")
        self.assertEqual(godot_cache.cache_action(True, True, 1.0, 9.0), "present")

    def test_missing_cache_is_seeded(self):
        self.assertEqual(godot_cache.cache_action(False, False, None, 5.0), "seed")

    def test_unstamped_cache_is_refreshed_once(self):
        self.assertEqual(godot_cache.cache_action(False, True, None, 5.0), "refresh")

    def test_source_newer_than_stamp_is_stale(self):
        # A merge rewrites the merged files, so their mtimes pass the stamp.
        self.assertEqual(godot_cache.cache_action(False, True, 100.0, 101.0), "refresh")

    def test_cache_stamped_after_the_newest_source_is_current(self):
        self.assertEqual(godot_cache.cache_action(False, True, 100.0, 100.0), "present")
        self.assertEqual(godot_cache.cache_action(False, True, 100.0, 50.0), "present")
        self.assertEqual(godot_cache.cache_action(False, True, 100.0, None), "present")


class CacheFailureTest(unittest.TestCase):
    def test_unresolved_script_or_preload_is_a_cache_failure(self):
        self.assertTrue(godot_cache.is_cache_failure(
            'SCRIPT ERROR: Parse Error: Could not resolve script "res://scripts/x.gd".'))
        self.assertTrue(godot_cache.is_cache_failure(
            'SCRIPT ERROR: Parse Error: Could not preload resource "res://y.tres".'))

    def test_a_real_parse_error_is_not(self):
        self.assertFalse(godot_cache.is_cache_failure(
            'SCRIPT ERROR: Parse Error: Identifier "foo" not declared in the current scope.'))


# What a boot printed on 12 Oct 2026 when the cache lacked one sprite import.
SPRITE = "res://assets/sprites/meadow/hive_skep_rival_sheet.png"
MISSING_SPRITE_HITS = [
    'SCRIPT ERROR: Parse Error: Could not preload resource file "%s".' % SPRITE,
    'SCRIPT ERROR: Parse Error: Cannot infer the type of "HIVE_SKEP_RIVAL_SHEET" constant because the value doesn\'t have a set type.',
    "SCRIPT ERROR: Compile Error: Failed to compile depended scripts.",
    'SCRIPT ERROR: Parse Error: Could not resolve external class member "HIVE_SKEP_RIVAL_SHEET".',
    'ERROR: Failed to load script "res://scripts/main.gd" with error "Compilation failed".',
]


class TempRootTest(unittest.TestCase):
    def make_dir(self) -> Path:
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        return Path(temp.name).resolve()


class MissingImportsTest(TempRootTest):
    def setUp(self):
        self.root = self.make_dir()
        sprite = self.root / "assets" / "sprites" / "meadow" / "hive_skep_rival_sheet.png"
        sprite.parent.mkdir(parents=True)
        sprite.write_bytes(b"png")

    def test_an_existing_file_and_its_cascade_is_the_cache(self):
        self.assertEqual(godot_cache.missing_imports(MISSING_SPRITE_HITS, self.root), [SPRITE])

    def test_a_file_that_really_is_missing_is_the_code(self):
        (self.root / "assets" / "sprites" / "meadow" / "hive_skep_rival_sheet.png").unlink()
        self.assertEqual(godot_cache.missing_imports(MISSING_SPRITE_HITS, self.root), [])

    def test_a_parse_error_alongside_is_the_code(self):
        hits = MISSING_SPRITE_HITS + [
            'SCRIPT ERROR: Parse Error: Identifier "Skills" not declared in the current scope.']
        self.assertEqual(godot_cache.missing_imports(hits, self.root), [])

    def test_cascade_lines_alone_name_nothing(self):
        self.assertEqual(godot_cache.missing_imports(MISSING_SPRITE_HITS[2:3], self.root), [])


class EnsureCacheTest(TempRootTest):
    """The worktree imports its own sources; the primary's health is never
    asked and its cache never written (12 Oct 2026: a primary missing one
    sprite import refused every worktree's check with "Fix master first")."""

    def setUp(self):
        self.primary = self.make_dir()
        (self.primary / ".godot").mkdir()
        (self.primary / ".godot" / "from_primary").write_text("p", encoding="utf-8")
        self.root = self.make_dir()
        self.imports: list[list[str]] = []

    def fake_run(self, returncode=0, raises=None):
        def run(command, **kwargs):
            self.imports.append(command)
            if raises:
                raise raises
            # Godot's import writes the worktree's cache.
            (Path(command[-1]) / ".godot").mkdir(exist_ok=True)
            return subprocess.CompletedProcess(command, returncode, b"", b"")
        return run

    def ensure(self, run, force=False, newest=None):
        with patch.object(godot_cache, "primary_root", return_value=self.primary), \
             patch.object(godot_cache, "newest_source_mtime", return_value=newest), \
             patch.object(godot_cache.subprocess, "run", side_effect=run), \
             patch.object(godot_cache, "_compile_check", side_effect=AssertionError("the primary was booted")):
            return godot_cache.ensure_cache(self.root, "Godot", force=force)

    def test_seed_copies_the_primary_without_booting_it_then_imports_here(self):
        ok, line = self.ensure(self.fake_run())

        self.assertTrue(ok, line)
        self.assertTrue((self.root / ".godot" / "from_primary").is_file())
        self.assertEqual([["Godot", "--headless", "--import", "--path", str(self.root)]], self.imports)
        self.assertIsNotNone(godot_cache.stamp_mtime(self.root / ".godot"))

    def test_seed_imports_cold_when_the_primary_has_no_cache(self):
        shutil.rmtree(self.primary / ".godot")
        ok, line = self.ensure(self.fake_run())

        self.assertTrue(ok, line)
        self.assertIn("cold", line)
        self.assertEqual(1, len(self.imports))

    def test_a_stale_cache_is_imported_in_place_and_the_primary_left_alone(self):
        (self.root / ".godot").mkdir()
        (self.root / ".godot" / "own").write_text("w", encoding="utf-8")
        godot_cache.mark_fresh(self.root)
        stamp = godot_cache.stamp_mtime(self.root / ".godot")

        ok, line = self.ensure(self.fake_run(), newest=stamp + 10)

        self.assertTrue(ok, line)
        self.assertTrue((self.root / ".godot" / "own").is_file())
        self.assertFalse((self.root / ".godot" / "from_primary").exists())
        self.assertEqual(["p"], [f.read_text(encoding="utf-8") for f in (self.primary / ".godot").iterdir()])

    def test_force_rebuilds_from_cold(self):
        (self.root / ".godot").mkdir()
        (self.root / ".godot" / "own").write_text("w", encoding="utf-8")

        ok, line = self.ensure(self.fake_run(), force=True)

        self.assertTrue(ok, line)
        self.assertFalse((self.root / ".godot" / "own").exists())
        self.assertEqual(1, len(self.imports))

    def test_an_import_that_times_out_is_a_cache_fault_naming_its_fix(self):
        ok, line = self.ensure(self.fake_run(raises=subprocess.TimeoutExpired("Godot", 180)))

        self.assertFalse(ok)
        self.assertTrue(line.startswith(godot_cache.CACHE_FAULT), line)
        self.assertIn("did not finish within", line)
        self.assertIn("cd %s; python tools/godot_cache.py --force" % self.root, line)
        self.assertNotIn("Fix master first", line)

    def test_a_failed_import_is_not_stamped(self):
        ok, line = self.ensure(self.fake_run(returncode=1))

        self.assertFalse(ok)
        self.assertIn("exited with code 1", line)
        self.assertIsNone(godot_cache.stamp_mtime(self.root / ".godot"))

    def test_refresh_after_failure_rebuilds_cold_and_retries(self):
        (self.root / ".godot").mkdir()
        (self.root / ".godot" / "own").write_text("w", encoding="utf-8")
        with patch.object(godot_cache, "primary_root", return_value=self.primary), \
             patch.object(godot_cache.subprocess, "run", side_effect=self.fake_run()):
            retry, line = godot_cache.refresh_after_failure(self.root, "Godot", "\n".join(MISSING_SPRITE_HITS))

        self.assertTrue(retry, line)
        self.assertFalse((self.root / ".godot" / "own").exists())

    def test_the_primary_is_never_rebuilt_automatically(self):
        with patch.object(godot_cache, "primary_root", return_value=self.root), \
             patch.object(godot_cache.subprocess, "run", side_effect=AssertionError("imported the primary")):
            retry, line = godot_cache.refresh_after_failure(self.root, "Godot", "\n".join(MISSING_SPRITE_HITS))

        self.assertEqual((False, None), (retry, line))


if __name__ == "__main__":
    unittest.main()
