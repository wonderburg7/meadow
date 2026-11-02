"""Unit tests for pure helper functions in tools/pacing_gates.py."""

import unittest

from tools.pacing_gates import _day_length


class TestPacingGatesHelpers(unittest.TestCase):
    def test_day_length_valid_float_and_int(self):
        self.assertEqual(_day_length({"settings": {"seconds_per_day": 120.0}}), 120.0)
        self.assertEqual(_day_length({"settings": {"seconds_per_day": 90}}), 90.0)

    def test_day_length_missing_settings_or_key_raises(self):
        with self.assertRaises(ValueError):
            _day_length({})
        with self.assertRaises(ValueError):
            _day_length({"settings": {}})

    def test_day_length_rejects_bool(self):
        with self.assertRaises(ValueError):
            _day_length({"settings": {"seconds_per_day": True}})
        with self.assertRaises(ValueError):
            _day_length({"settings": {"seconds_per_day": False}})

    def test_day_length_rejects_non_numeric(self):
        with self.assertRaises(ValueError):
            _day_length({"settings": {"seconds_per_day": "120"}})
        with self.assertRaises(ValueError):
            _day_length({"settings": {"seconds_per_day": None}})

    def test_day_length_rejects_non_positive(self):
        with self.assertRaises(ValueError):
            _day_length({"settings": {"seconds_per_day": 0}})
        with self.assertRaises(ValueError):
            _day_length({"settings": {"seconds_per_day": -10.5}})


if __name__ == "__main__":
    unittest.main()
