"""Typed, dependency-free verdict evaluation for one completed headless run."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from headless.contracts import EXPECTATION_OPERATORS


class ContractError(ValueError):
    """The scenario requested a verdict the stable contract cannot evaluate."""


@dataclass(frozen=True)
class ExpectationResult:
    identifier: str
    passed: bool
    expected: Any
    actual: Any


# Slice 1 intentionally exposes only cheap final-run facts already present in
# analyze_session.py. Slice 3's probe registry will widen this allowlist.
_METRICS = {
    "summary.outcome": lambda analysis: analysis["summary"]["outcome"],
    "summary.game_time": lambda analysis: analysis["summary"]["game_time"],
    "summary.day": lambda analysis: analysis["summary"]["day"],
    "summary.total_deaths": lambda analysis: analysis["summary"]["total_deaths"],
    "summary.queen_alive": lambda analysis: analysis["summary"]["queen_alive"],
    "summary.gynes_released": lambda analysis: analysis["summary"]["gynes_released"],
    "actions.total": lambda analysis: analysis["actions"]["total"],
    "actions.problems": lambda analysis: analysis["actions"]["problems"],
}


def validate_expectations(expectations: Any) -> list[dict[str, Any]]:
    """Validate a scenario's declarative ``expect`` block before launch."""
    if expectations is None:
        return []
    if not isinstance(expectations, list):
        raise ContractError("expect must be an array")

    seen: set[str] = set()
    validated: list[dict[str, Any]] = []
    for index, raw in enumerate(expectations):
        if not isinstance(raw, dict):
            raise ContractError("expect[%d] must be an object" % index)
        metric = raw.get("metric")
        operator = raw.get("op")
        identifier = raw.get("id", metric or "expect_%d" % index)
        if not isinstance(identifier, str) or not identifier:
            raise ContractError("expect[%d].id must be a non-empty string" % index)
        if identifier in seen:
            raise ContractError("duplicate expectation id: %s" % identifier)
        seen.add(identifier)
        if metric not in _METRICS:
            raise ContractError("unknown expectation metric: %r" % metric)
        if operator not in EXPECTATION_OPERATORS:
            raise ContractError("unsupported expectation operator: %r" % operator)
        if operator in {"eq", "ne", "lt", "lte", "gt", "gte"} and "value" not in raw:
            raise ContractError("expect[%s] requires value" % identifier)
        if operator == "between":
            if "min" not in raw or "max" not in raw:
                raise ContractError("expect[%s] requires min and max" % identifier)
            _require_number(raw["min"], identifier)
            _require_number(raw["max"], identifier)
        if operator in {"empty", "not_empty", "all_true", "exists"} and any(
            key in raw for key in ("value", "min", "max")
        ):
            raise ContractError("expect[%s] does not take a comparison value" % identifier)
        validated.append(dict(raw, id=identifier))
    return validated


def evaluate_expectations(analysis: dict[str, Any], expectations: list[dict[str, Any]]) -> list[ExpectationResult]:
    """Evaluate validated expectations against a completed summary."""
    if analysis.get("summary") is None:
        raise ContractError("cannot evaluate expectations without a summary")
    results: list[ExpectationResult] = []
    for expectation in expectations:
        metric = expectation["metric"]
        try:
            actual = _METRICS[metric](analysis)
        except KeyError as error:
            raise ContractError("metric %s was absent from this run" % metric) from error
        operator = expectation["op"]
        expected = _expected_value(expectation)
        results.append(ExpectationResult(
            expectation["id"], _compare(actual, operator, expectation), expected, actual
        ))
    return results


def _expected_value(expectation: dict[str, Any]) -> Any:
    if expectation["op"] == "between":
        return {"min": expectation["min"], "max": expectation["max"]}
    return expectation.get("value")


def _require_number(value: Any, identifier: str) -> None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ContractError("expect[%s] requires numeric bounds" % identifier)


def _compare(actual: Any, operator: str, expectation: dict[str, Any]) -> bool:
    if operator == "exists":
        return actual is not None
    if operator == "empty":
        return _is_empty(actual)
    if operator == "not_empty":
        return not _is_empty(actual)
    if operator == "all_true":
        if not isinstance(actual, (list, tuple)):
            raise ContractError("all_true requires a list metric")
        return all(item is True for item in actual)

    value = expectation.get("value")
    if operator == "between":
        _require_number(actual, expectation["id"])
        return expectation["min"] <= actual <= expectation["max"]
    if operator in {"lt", "lte", "gt", "gte"}:
        _require_number(actual, expectation["id"])
        _require_number(value, expectation["id"])
    if operator == "eq":
        return actual == value
    if operator == "ne":
        return actual != value
    if operator == "lt":
        return actual < value
    if operator == "lte":
        return actual <= value
    if operator == "gt":
        return actual > value
    if operator == "gte":
        return actual >= value
    raise ContractError("unsupported expectation operator: %r" % operator)


def _is_empty(value: Any) -> bool:
    if value is None:
        return True
    if isinstance(value, (str, list, tuple, dict, set)):
        return not value
    raise ContractError("empty/not_empty requires a collection metric")
