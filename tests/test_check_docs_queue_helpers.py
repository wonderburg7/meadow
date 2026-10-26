"""Unit tests for tools/check_docs.py queue helper functions (J-19).

Tests proof_error_is_shape, check_queue_files, and check_queue_admission using
in-memory string fixtures and temporary directories, never reading real NEXTSTEPS.md.
"""

import sys
import unittest
from pathlib import Path

# Add tools directory to path so check_docs can be imported
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from check_docs import (
    check_queue_admission,
    check_queue_files,
    proof_error_is_shape,
)


class TestCheckDocsQueueHelpers(unittest.TestCase):
    def test_proof_error_is_shape(self) -> None:
        """proof_error_is_shape accepts malformed shape errors and rejects proof-holding failures."""
        malformed_error = (
            "NEXTSTEPS.md item 1: Proof: must be backticked; use `present|absent: <path> :: <substring>`"
        )
        holding_failed_error = (
            "NEXTSTEPS.md item 1: Proof: proof no longer holds: string not found in file"
        )
        self.assertTrue(proof_error_is_shape(malformed_error))
        self.assertFalse(proof_error_is_shape(holding_failed_error))

    def test_check_queue_files(self) -> None:
        """check_queue_files reports errors for invalid file backticks and passes well-formed items."""
        valid_queue_text = (
            "## Next up\n\n"
            "### Claude lane\n\n"
            "1. **[Claude] TEST-1 -- Test item title**\n"
            "   - Plan: `plans/test.md`\n"
            "   - Files: `scripts/main.gd`\n"
            "   - Check: `python tests/source_checks.py`\n"
            "   - Proof: `present: scripts/main.gd :: extends Node`\n"
            "   - Next after: TEST-2 -- next item\n"
        )
        errors: list[str] = []
        check_queue_files(errors, text=valid_queue_text)
        self.assertEqual(errors, [])

        invalid_queue_text = (
            "## Next up\n\n"
            "### Claude lane\n\n"
            "1. **[Claude] TEST-1 -- Test item title**\n"
            "   - Plan: `plans/test.md`\n"
            "   - Files: placeholder prose without backticks\n"
            "   - Check: `python tests/source_checks.py`\n"
            "   - Proof: `present: scripts/main.gd :: extends Node`\n"
            "   - Next after: TEST-2 -- next item\n"
        )
        errors_invalid: list[str] = []
        check_queue_files(errors_invalid, text=invalid_queue_text)
        self.assertEqual(len(errors_invalid), 1)
        self.assertIn("Files: must contain only backticked", errors_invalid[0])

    def test_check_queue_admission(self) -> None:
        """check_queue_admission passes admissible items and warns on inadmissible items."""
        admissible_text = (
            "## Next up\n\n"
            "### Claude lane\n\n"
            "1. **[Claude] TEST-1 -- Test item title**\n"
            "   - Plan: `plans/test.md`\n"
            "   - Files: `scripts/main.gd`\n"
            "   - Check: `python tests/source_checks.py`\n"
            "   - Proof: `present: scripts/main.gd :: extends Node`\n"
            "   - Next after: TEST-2 -- next item\n"
        )
        warnings_clean: list[str] = []
        check_queue_admission(warnings_clean, text=admissible_text, root=Path("."))
        self.assertEqual(warnings_clean, [])

        # Two items in different lanes sharing the same file makes item inadmissible
        inadmissible_text = (
            "## Next up\n\n"
            "### Claude lane\n\n"
            "1. **[Claude] TEST-1 -- Test item title**\n"
            "   - Plan: `plans/test.md`\n"
            "   - Files: `scripts/main.gd`\n"
            "   - Check: `python tests/source_checks.py`\n"
            "   - Proof: `present: scripts/main.gd :: extends Node`\n"
            "   - Next after: TEST-2 -- next item\n\n"
            "### Codex lane\n\n"
            "1. **[Codex] TEST-2 -- Test item 2 title**\n"
            "   - Plan: `plans/test.md`\n"
            "   - Files: `scripts/main.gd`\n"
            "   - Check: `python tests/source_checks.py`\n"
            "   - Proof: `present: scripts/main.gd :: extends Node`\n"
            "   - Next after: TEST-3 -- next item\n"
        )
        warnings_inadmissible: list[str] = []
        check_queue_admission(warnings_inadmissible, text=inadmissible_text, root=Path("."))
        self.assertGreaterEqual(len(warnings_inadmissible), 1)
        self.assertIn("NEXTSTEPS.md: TEST-1", warnings_inadmissible[0])


if __name__ == "__main__":
    unittest.main()
