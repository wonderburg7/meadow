"""Tests for the untested pure ID parser in tools/new_check.py."""

import unittest

from tools import new_check


class TestNewCheckClashHelpers(unittest.TestCase):
    def test_ids_in(self) -> None:
        self.assertEqual(new_check.ids_in(""), set())
        self.assertEqual(new_check.ids_in("No check id here"), set())
        self.assertEqual(new_check.ids_in("C-1 and C-42"), {1, 42})
        self.assertEqual(new_check.ids_in("C-005, C-150, C-9999"), {5, 150, 9999})
        self.assertEqual(new_check.ids_in("C-1 C-1 C-2"), {1, 2})



if __name__ == "__main__":
    unittest.main()
