"""Unit tests for pure helper functions in tools/forager_tuning.py."""

from __future__ import annotations

import unittest

from tools import forager_tuning as tuning


class ForagerTuningHelpersTests(unittest.TestCase):
    def test_rank_returns_minimum_ratio_and_stage_two_median(self) -> None:
        # Medians: stage 0 = 10, stage 1 = 20, stage 2 = 39, stage 3 = 78
        # Ratios:
        #   r0 = 20 / 10 = 2.0
        #   r1 = 39 / 20 = 1.95 -> r1 / 1.3 = 1.5
        #   r2 = 78 / 39 = 2.0
        # Metric = min(2.0, 1.5, 2.0) = 1.5
        # Delivery = middles[2] = 39.0
        result = {
            "values": [
                [10.0, 10.0, 10.0],
                [20.0, 20.0, 20.0],
                [39.0, 39.0, 39.0],
                [78.0, 78.0, 78.0],
            ]
        }
        metric, delivery = tuning.rank(result)
        self.assertAlmostEqual(metric, 1.5)
        self.assertAlmostEqual(delivery, 39.0)

    def test_rank_with_first_ratio_bottleneck(self) -> None:
        # Medians: 10, 11, 26, 52
        # r0 = 1.1
        # r1 = 26 / 11 = 2.3636... -> r1 / 1.3 = 1.818...
        # r2 = 2.0
        # Metric = min(1.1, 1.818..., 2.0) = 1.1
        result = {
            "values": [
                [10.0],
                [11.0],
                [26.0],
                [52.0],
            ]
        }
        metric, delivery = tuning.rank(result)
        self.assertAlmostEqual(metric, 1.1)
        self.assertAlmostEqual(delivery, 26.0)

    def test_rank_with_third_ratio_bottleneck(self) -> None:
        # Medians: 10, 20, 39, 40
        # r0 = 2.0
        # r1 = 1.95 -> 1.5
        # r2 = 40 / 39 = 1.02564...
        # Metric = min(2.0, 1.5, 1.02564...) = 40 / 39
        result = {
            "values": [
                [10.0],
                [20.0],
                [39.0],
                [40.0],
            ]
        }
        metric, delivery = tuning.rank(result)
        self.assertAlmostEqual(metric, 40.0 / 39.0)
        self.assertAlmostEqual(delivery, 39.0)


if __name__ == "__main__":
    unittest.main()
