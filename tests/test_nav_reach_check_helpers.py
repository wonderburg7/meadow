"""Unit tests for pure helper functions in tools/nav_reach_check.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from nav_reach_check import _extract_sum_terms  # noqa: E402


class TestNavReachCheckHelpers(unittest.TestCase):
    """Covers _extract_sum_terms in tools/nav_reach_check.py."""

    def test_extract_single_term(self) -> None:
        """Single term without addition operators is returned as single element."""
        self.assertEqual(_extract_sum_terms("reach"), ["reach"])
        self.assertEqual(_extract_sum_terms("10"), ["10"])
        self.assertEqual(_extract_sum_terms("GameConfig.hive_interior_rings"), ["GameConfig.hive_interior_rings"])

    def test_extract_additive_terms(self) -> None:
        """Additive binary operations are extracted in syntactic order."""
        terms = _extract_sum_terms("a + b")
        self.assertEqual(terms, ["a", "b"])

        three_terms = _extract_sum_terms(
            "GameConfig.hive_interior_rings + GameConfig.hive_soil_depth + GameConfig.hive_rock_rings"
        )
        self.assertEqual(
            three_terms,
            [
                "GameConfig.hive_interior_rings",
                "GameConfig.hive_soil_depth",
                "GameConfig.hive_rock_rings",
            ],
        )

    def test_extract_additive_terms_with_whitespace_and_parentheses(self) -> None:
        """Whitespace and parenthesized multiline expressions in additive expressions are normalised."""
        expr = "(  a  +\n  b  +\n  c  )"
        self.assertEqual(_extract_sum_terms(expr), ["a", "b", "c"])

    def test_extract_additive_terms_wrapped_in_int(self) -> None:
        """int(...) wrapper around additive expression is unwrapped and parsed."""
        self.assertEqual(
            _extract_sum_terms("int(a + b + c)"),
            ["a", "b", "c"],
        )
        self.assertEqual(
            _extract_sum_terms("int(10)"),
            ["10"],
        )

    def test_reject_non_int_outer_call(self) -> None:
        """Function calls other than int(...) return None if treated as container or non-additive."""
        self.assertEqual(_extract_sum_terms("float(a + b)"), ["float(a+b)"])
        # Multi-argument int call is rejected as an int unwrap, treated as single expression node
        self.assertEqual(_extract_sum_terms("int(a, 10)"), ["int(a,10)"])

    def test_reject_subtraction(self) -> None:
        """Expressions containing subtraction operators return None."""
        self.assertIsNone(_extract_sum_terms("a - b"))
        self.assertIsNone(_extract_sum_terms("a + b - c"))
        self.assertIsNone(_extract_sum_terms("int(a - b)"))

    def test_reject_multiplication_and_division(self) -> None:
        """Expressions containing multiplication or division operators return None."""
        self.assertIsNone(_extract_sum_terms("a * b"))
        self.assertIsNone(_extract_sum_terms("a / b"))
        self.assertIsNone(_extract_sum_terms("a + b * c"))

    def test_reject_bitwise_operators(self) -> None:
        """Expressions containing bitwise operators return None when parsed as BinOp."""
        self.assertIsNone(_extract_sum_terms("a | b"))
        self.assertIsNone(_extract_sum_terms("a & b"))
        self.assertIsNone(_extract_sum_terms("a ^ b"))

    def test_syntax_errors_return_none(self) -> None:
        """Invalid Python syntax expressions return None."""
        self.assertIsNone(_extract_sum_terms("a +"))
        self.assertIsNone(_extract_sum_terms("+ +"))
        self.assertIsNone(_extract_sum_terms("()("))
        self.assertIsNone(_extract_sum_terms(""))


if __name__ == "__main__":
    unittest.main()
