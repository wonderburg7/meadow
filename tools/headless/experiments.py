"""Typed experiment-manifest contracts and aggregate verdict evaluation.

The runner owns process launch and artefact directories. This module is pure
Python so malformed manifests and aggregate comparisons can fail before a
single Godot process is started.
"""

from __future__ import annotations

import copy
import math
import re
from dataclasses import dataclass
from typing import Any

from headless.verdicts import ContractError


_CASE_NAME = re.compile(r"^[A-Za-z][A-Za-z0-9_-]*$")
_METRIC_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$")
_COMPARISON_OPERATORS = frozenset({"eq", "ne", "lt", "lte", "gt", "gte"})
# These are the numeric/count summary fields emitted by DiagnosticLog. Keeping
# this list explicit makes a misspelled experiment metric a pre-launch
# contract error instead of wasting every case/seed launch first.
SUMMARY_METRICS = frozenset({
    "game_time", "day", "queen_alive", "total_deaths", "deaths_by_cause", "deaths_by_role",
    "gynes_released", "crab_spider_events", "recruitment_matches", "scouting_settled",
    "orientation_flights", "recruitment_followups", "recruit_partner_overlaps", "foragers_settled",
    "tarsal_marks", "tarsal_rejections", "flower_visits", "unique_flowers_visited", "stall_recoveries",
    "brood_feeds", "brood_hatches", "brood_hatches_by_role_mode", "jelly_batches", "larval_deaths",
    "cells_completed", "cells_cleaned", "cells_evicted", "cells_restocked", "blocks_mined",
    "honey_batches_deposited", "cells_ripened",
})


@dataclass(frozen=True)
class ExperimentManifest:
    name: str
    base_scenario: str
    seeds: tuple[int, ...]
    cases: dict[str, dict[str, Any]]
    expectations: tuple[dict[str, Any], ...]
    report: dict[str, Any]


def validate_manifest(raw: Any) -> ExperimentManifest:
    """Validate the deliberately small, reproducible experiment vocabulary."""
    if not isinstance(raw, dict):
        raise ContractError("experiment manifest must be a JSON object")
    unknown = set(raw) - {"name", "base_scenario", "seeds", "cases", "expect", "report"}
    if unknown:
        raise ContractError("unknown experiment keys: %s" % ", ".join(sorted(unknown)))
    name = raw.get("name")
    if not isinstance(name, str) or not name:
        raise ContractError("experiment.name must be a non-empty string")
    base_scenario = raw.get("base_scenario")
    if not isinstance(base_scenario, str) or not base_scenario:
        raise ContractError("experiment.base_scenario must be a non-empty string")
    seeds = raw.get("seeds")
    if not isinstance(seeds, list) or not seeds:
        raise ContractError("experiment.seeds must be a non-empty array")
    if any(isinstance(seed, bool) or not isinstance(seed, int) for seed in seeds):
        raise ContractError("experiment.seeds must contain integers")
    if len(set(seeds)) != len(seeds):
        raise ContractError("experiment.seeds must not contain duplicates")
    cases = _validate_cases(raw.get("cases"))
    expectations = _validate_expectations(raw.get("expect", []), cases)
    report = _validate_report(raw.get("report", {}))
    return ExperimentManifest(name, base_scenario, tuple(seeds), cases, expectations, report)


def _validate_cases(raw: Any) -> dict[str, dict[str, Any]]:
    if not isinstance(raw, dict) or not raw:
        raise ContractError("experiment.cases must be a non-empty object")
    cases: dict[str, dict[str, Any]] = {}
    for name, overlay in raw.items():
        if not isinstance(name, str) or not _CASE_NAME.fullmatch(name):
            raise ContractError("experiment case names must use letters, digits, _ or -")
        if not isinstance(overlay, dict):
            raise ContractError("experiment case %s must be an object" % name)
        unknown = set(overlay) - {"config_overrides"}
        if unknown:
            raise ContractError(
                "experiment case %s may only change config_overrides; starting-state fields are not allowed" % name
            )
        overrides = overlay.get("config_overrides", {})
        if not isinstance(overrides, dict):
            raise ContractError("experiment case %s.config_overrides must be an object" % name)
        if any(not isinstance(key, str) or not key for key in overrides):
            raise ContractError("experiment case %s.config_overrides keys must be non-empty strings" % name)
        _json_values(overrides, "experiment case %s.config_overrides" % name)
        cases[name] = {"config_overrides": copy.deepcopy(overrides)}
    return cases


def _json_values(value: Any, label: str) -> None:
    if value is None or isinstance(value, (str, int, float, bool)):
        if isinstance(value, float) and not math.isfinite(value):
            raise ContractError("%s must not contain non-finite numbers" % label)
        return
    if isinstance(value, list):
        for item in value:
            _json_values(item, label)
        return
    if isinstance(value, dict):
        for key, item in value.items():
            if not isinstance(key, str):
                raise ContractError("%s must use string object keys" % label)
            _json_values(item, label)
        return
    raise ContractError("%s must contain JSON values" % label)


def _validate_expectations(raw: Any, cases: dict[str, dict[str, Any]]) -> tuple[dict[str, Any], ...]:
    if not isinstance(raw, list):
        raise ContractError("experiment.expect must be an array")
    results: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, expectation in enumerate(raw):
        if not isinstance(expectation, dict):
            raise ContractError("experiment.expect[%d] must be an object" % index)
        unknown = set(expectation) - {"id", "left", "metric", "op", "right", "value"}
        if unknown:
            raise ContractError("unknown experiment expectation keys: %s" % ", ".join(sorted(unknown)))
        identifier = expectation.get("id", "expect_%d" % index)
        if not isinstance(identifier, str) or not identifier:
            raise ContractError("experiment.expect[%d].id must be a non-empty string" % index)
        if identifier in seen:
            raise ContractError("duplicate experiment expectation id: %s" % identifier)
        seen.add(identifier)
        left = expectation.get("left", expectation.get("metric"))
        if not isinstance(left, str) or not _METRIC_NAME.fullmatch(left):
            raise ContractError("experiment.expect[%s] requires a metric path" % identifier)
        _validate_aggregate_path(left, cases, identifier)
        operator = expectation.get("op")
        if operator not in _COMPARISON_OPERATORS:
            raise ContractError("experiment.expect[%s] has unsupported operator" % identifier)
        has_right = "right" in expectation
        has_value = "value" in expectation
        if has_right == has_value:
            raise ContractError("experiment.expect[%s] requires exactly one of right or value" % identifier)
        if has_right:
            right = expectation["right"]
            if not isinstance(right, str) or not _METRIC_NAME.fullmatch(right):
                raise ContractError("experiment.expect[%s].right must be a metric path" % identifier)
            _validate_aggregate_path(right, cases, identifier)
        else:
            value = expectation["value"]
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
                raise ContractError("experiment.expect[%s].value must be a finite number" % identifier)
        results.append({"id": identifier, "left": left, "op": operator,
                        **({"right": expectation["right"]} if has_right else {"value": expectation["value"]})})
    return tuple(results)


def _validate_aggregate_path(path: str, cases: dict[str, dict[str, Any]], identifier: str) -> None:
    parts = path.split(".")
    if (len(parts) != 3 or parts[0] not in cases or parts[1] not in SUMMARY_METRICS
            or parts[2] not in {"min", "mean", "max"}):
        raise ContractError(
            "experiment.expect[%s] metric must be case.summary_field.min, .mean or .max" % identifier
        )


def _validate_report(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise ContractError("experiment.report must be an object")
    unknown = set(raw) - {"mode", "metrics"}
    if unknown:
        raise ContractError("unknown experiment.report keys: %s" % ", ".join(sorted(unknown)))
    mode = raw.get("mode", "verdict")
    if mode not in {"verdict", "table", "artifact", "debug"}:
        raise ContractError("experiment.report.mode must be verdict, table, artifact or debug")
    metrics = raw.get("metrics", [])
    if not isinstance(metrics, list) or not all(isinstance(metric, str) and _METRIC_NAME.fullmatch(metric)
                                                for metric in metrics):
        raise ContractError("experiment.report.metrics must be an array of summary field paths")
    unknown_metrics = set(metrics) - SUMMARY_METRICS
    if unknown_metrics:
        raise ContractError("unknown experiment summary metrics: %s" % ", ".join(sorted(unknown_metrics)))
    return {"mode": mode, "metrics": list(dict.fromkeys(metrics))}


def compose_case_scenario(base: dict[str, Any], case: dict[str, Any]) -> dict[str, Any]:
    """Copy base setup unchanged, applying only its declared config overlay."""
    if not isinstance(base, dict):
        raise ContractError("base scenario must be a JSON object")
    composed = copy.deepcopy(base)
    existing = composed.get("config_overrides", {})
    if not isinstance(existing, dict):
        raise ContractError("base scenario config_overrides must be an object")
    composed["config_overrides"] = dict(existing, **case["config_overrides"])
    return composed


def aggregate_case_metrics(summaries: dict[str, list[dict[str, Any]]], metrics: list[str]) -> dict[str, Any]:
    """Produce min/mean/max for selected numeric final-summary fields."""
    aggregate: dict[str, Any] = {}
    for case, runs in summaries.items():
        case_metrics: dict[str, Any] = {}
        for metric in metrics:
            values = [_numeric_summary_metric(summary, metric) for summary in runs]
            case_metrics[metric] = {
                "min": min(values), "mean": sum(values) / len(values), "max": max(values),
            }
        aggregate[case] = case_metrics
    return aggregate


def required_metrics(manifest: ExperimentManifest) -> list[str]:
    metrics = set(manifest.report["metrics"])
    for expectation in manifest.expectations:
        metrics.add(expectation["left"].split(".")[1])
        if "right" in expectation:
            metrics.add(expectation["right"].split(".")[1])
    return sorted(metrics)


def evaluate_aggregate_expectations(aggregate: dict[str, Any], expectations: tuple[dict[str, Any], ...]) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    for expectation in expectations:
        actual = _aggregate_value(aggregate, expectation["left"])
        expected = (_aggregate_value(aggregate, expectation["right"])
                    if "right" in expectation else expectation["value"])
        passed = _compare(actual, expectation["op"], expected)
        results.append({"id": expectation["id"], "passed": passed,
                        "actual": actual, "expected": expected})
    return results


def _aggregate_value(aggregate: dict[str, Any], path: str) -> float:
    case, metric, statistic = path.split(".")
    try:
        value = aggregate[case][metric][statistic]
    except KeyError as error:
        raise ContractError("aggregate metric was unavailable: %s" % path) from error
    return float(value)


def _numeric_summary_metric(summary: dict[str, Any], metric: str) -> float:
    value: Any = summary
    for part in metric.split("."):
        if not isinstance(value, dict) or part not in value:
            raise ContractError("summary metric was absent from a run: %s" % metric)
        value = value[part]
    if isinstance(value, bool):
        return float(value)
    if isinstance(value, (int, float)) and math.isfinite(value):
        return float(value)
    if isinstance(value, dict) and all(isinstance(item, (int, float)) and not isinstance(item, bool)
                                       and math.isfinite(item) for item in value.values()):
        return float(sum(value.values()))
    raise ContractError("summary metric is not numeric: %s" % metric)


def _compare(actual: float, operator: str, expected: float) -> bool:
    return {
        "eq": actual == expected, "ne": actual != expected, "lt": actual < expected,
        "lte": actual <= expected, "gt": actual > expected, "gte": actual >= expected,
    }[operator]
