"""Unit tests for the worktree Godot cache's staleness decision."""

import unittest

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


if __name__ == "__main__":
    unittest.main()
