"""Stable, dependency-free constants for the versioned headless contract.

Slice 0 deliberately does not wire these into ``run_scenario.py``. Slice 1
will use them when it adds result and failure artefacts.
"""

from __future__ import annotations

SCHEMA_VERSION = 1
SUCCESS_STDOUT_BUDGET_BYTES = 1024
FAILURE_STDOUT_BUDGET_BYTES = 4096

RESULT_STATUSES = frozenset({"passed", "failed", "contract_error", "timed_out", "crashed"})
EXPECTATION_OPERATORS = frozenset({
    "eq", "ne", "lt", "lte", "gt", "gte", "empty", "not_empty", "between", "all_true", "exists",
})


def fits_stdout_budget(output: str | bytes, *, failed: bool) -> bool:
    """Whether already-rendered terminal output fits its contract budget.

    The caller chooses ``failed`` from the terminal verdict, rather than
    inferring it from text. This keeps presentation validation deterministic.
    """
    size = len(output if isinstance(output, bytes) else output.encode("utf-8"))
    budget = FAILURE_STDOUT_BUDGET_BYTES if failed else SUCCESS_STDOUT_BUDGET_BYTES
    return size <= budget
