"""WC-5: keep session cost's allowed models aligned with slice advice."""

import re
import unittest
from pathlib import Path

from tools.session_cost import LEVEL_MODELS


SLICE_TOOL = Path(__file__).resolve().parents[1] / "tools" / "slice.ps1"


class LevelModelParityTests(unittest.TestCase):
    def test_claude_advice_models_are_allowed_at_their_level(self):
        source = SLICE_TOOL.read_text(encoding="utf-8")
        advice = re.search(r"(?ms)^function Get-SliceAdvice \{(.*?)^\}", source)
        self.assertIsNotNone(advice, "Get-SliceAdvice was not found")
        claude_switch = re.search(
            r'(?s)if \(\$Lane -eq "Codex"\).*?\belse\s*\{\s*\$model = switch \(\$level\) \{(.*?)^\s*\}',
            advice.group(1),
            re.MULTILINE,
        )
        self.assertIsNotNone(claude_switch, "Claude-lane level switch was not found")

        for level in ("high", "medium", "low"):
            with self.subTest(level=level):
                entry = re.search(
                    rf'(?m)^\s*"{level}"\s*\{{\s*"(claude-[^" ]+)',
                    claude_switch.group(1),
                )
                self.assertIsNotNone(entry, f"Claude-lane {level} model was not found")
                advised = entry.group(1)
                allowed = LEVEL_MODELS[level]
                self.assertTrue(
                    any(advised.startswith(prefix) for prefix in allowed),
                    f"Claude-lane {level} advises {advised}; LEVEL_MODELS[{level!r}] allows {allowed}",
                )


if __name__ == "__main__":
    unittest.main()
