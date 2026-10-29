"""Unit tests for tools/update_function_map.py's signature joining helpers."""

import unittest
from tools.update_function_map import _paren_balance, _joined_signature


class TestUpdateFunctionMapHelpers(unittest.TestCase):
    def test_paren_balance_counts(self) -> None:
        """_paren_balance counts opening brackets up and closing brackets down."""
        self.assertEqual(_paren_balance("func f(a: int, b: list[int]) -> {int: str}:"), 0)
        self.assertEqual(_paren_balance("func f(a: int, b: Array["), 2)
        self.assertEqual(_paren_balance("a: int, b: int) -> void:"), -1)
        self.assertEqual(_paren_balance("{ [ ( ) ] }"), 0)

    def test_paren_balance_strings_and_escapes(self) -> None:
        """_paren_balance ignores brackets inside double and single quoted strings."""
        self.assertEqual(_paren_balance('var s = "( [{ {"'), 0)
        self.assertEqual(_paren_balance("var s = '( [{ {'"), 0)
        self.assertEqual(_paren_balance(r'var s = "escaped quote \" ( [{ "'), 0)
        self.assertEqual(_paren_balance(r"var s = 'escaped quote \' ( [{ '"), 0)
        self.assertEqual(_paren_balance('func f(a = "(", b = 1):'), 0)

    def test_paren_balance_comments(self) -> None:
        """_paren_balance stops counting at a comment # outside strings."""
        self.assertEqual(_paren_balance("func f(a: int): # ( ignored bracket"), 0)
        self.assertEqual(_paren_balance('var s = "hash # inside string (" # ( comment bracket'), 0)

    def test_joined_signature_unchanged_when_no_trailing_open_bracket(self) -> None:
        """_joined_signature returns line unchanged if it does not end with (, [, or {."""
        lines = [
            "func f(a: int, b: int) -> void:",
            "    pass",
        ]
        self.assertEqual(_joined_signature(lines, 0, lines[0]), "func f(a: int, b: int) -> void:")

        # Hand-wrapped line not ending in open bracket:
        lines_hand = [
            "func f(a: int,",
            "       b: int) -> void:",
        ]
        self.assertEqual(_joined_signature(lines_hand, 0, lines_hand[0]), "func f(a: int,")

    def test_joined_signature_folds_wrapped_parameters(self) -> None:
        """_joined_signature folds a parameter-per-line signature into a single line."""
        lines = [
            "func f(",
            "    a: int,",
            "    b: int,",
            ") -> void:",
        ]
        expected = "func f(a: int, b: int) -> void:"
        self.assertEqual(_joined_signature(lines, 0, lines[0]), expected)

    def test_joined_signature_folds_wrapped_default_array(self) -> None:
        """_joined_signature folds wrapped '[' default value signature."""
        lines = [
            "func f(a: Array = [",
            "    1,",
            "    2,",
            "]) -> void:",
        ]
        expected = "func f(a: Array = [1, 2]) -> void:"
        self.assertEqual(_joined_signature(lines, 0, lines[0]), expected)

    def test_joined_signature_unclosed_brackets_stops_at_last_line(self) -> None:
        """_joined_signature stops at last line without raising if brackets never close."""
        lines = [
            "func f(",
            "    a: int,",
            "    b: int,",
        ]
        expected = "func f(a: int, b: int,"
        self.assertEqual(_joined_signature(lines, 0, lines[0]), expected)


if __name__ == "__main__":
    unittest.main()
