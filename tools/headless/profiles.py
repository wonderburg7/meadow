"""Validation for scenario-selectable diagnostic capture profiles."""

from __future__ import annotations

from typing import Any

from headless.verdicts import ContractError


PROFILE_VERSION = 1
PROFILE_NAMES = frozenset({"standard", "verdict", "behaviour", "balance", "performance", "custom"})
EVENT_TYPES = frozenset({
    "action", "death", "crab_spider_event", "recruitment_match", "recruitment_followup",
    "forager_settled", "orientation_flight", "stall_recovery", "scouting_settled", "build_target",
    "forager_return", "flight_start_resolved",
})
DEFAULT_EVENT_TYPES = EVENT_TYPES - {"build_target", "forager_return", "flight_start_resolved"}
SNAPSHOT_FIELDS = frozenset({
    "population.total", "resources.food_stores", "resources.stored_nectar",
    "resources.stored_pollen", "environment.winter_here", "environment.flowers_by_species",
    "environment.flowers_in_season", "environment.flowers_out_of_season",
    "role_outcomes.cells_completed_total", "performance.fps", "performance.top_sections_ms",
    "colony.milestone_days",
})
SUMMARY_FIELDS = frozenset({
    "outcome", "total_deaths", "deaths_by_cause", "deaths_by_role", "queen_alive",
    "flower_visits", "unique_flowers_visited", "stall_recoveries", "cells_completed",
})

_DEFAULTS = {
    "standard": {"events": sorted(DEFAULT_EVENT_TYPES), "snapshots": None},
    "verdict": {"events": ["action", "death"], "snapshots": None},
    "behaviour": {"events": sorted(DEFAULT_EVENT_TYPES), "snapshots": None},
    "balance": {"events": ["action", "death"], "snapshots": {
        "every_sim_seconds": "day", "fields": ["population.total", "resources.food_stores", "environment.winter_here"],
    }},
    "performance": {"events": ["action", "death"], "snapshots": {
        "every_sim_seconds": "day", "fields": ["performance.fps", "performance.top_sections_ms"],
    }},
    "custom": {"events": [], "snapshots": None},
}


def validate_diagnostics(raw: Any) -> dict[str, Any]:
    """Return a normalised selection or raise a contract error before launch."""
    if raw is None:
        return {"profile": "standard", "version": PROFILE_VERSION, "events": sorted(DEFAULT_EVENT_TYPES), "snapshots": None,
                "limits": {"event_lines_per_type": None, "snapshot_lines": None}}
    if not isinstance(raw, dict):
        raise ContractError("diagnostics must be an object")
    unknown = set(raw) - {"profile", "events", "summary", "snapshots", "limits"}
    if unknown:
        raise ContractError("unknown diagnostics keys: %s" % ", ".join(sorted(unknown)))
    profile = raw.get("profile", "standard")
    if profile not in PROFILE_NAMES:
        raise ContractError("unknown diagnostic profile: %r" % profile)
    defaults = _DEFAULTS[profile]
    events = _string_list(raw.get("events", defaults["events"]), "diagnostics.events", EVENT_TYPES)
    snapshots = _validate_snapshots(raw.get("snapshots", defaults["snapshots"]), profile)
    if "summary" in raw:
        _string_list(raw["summary"], "diagnostics.summary", SUMMARY_FIELDS)
    limits = _validate_limits(raw.get("limits", {}))
    return {"profile": profile, "version": PROFILE_VERSION, "events": events, "snapshots": snapshots, "limits": limits}


def _string_list(value: Any, name: str, allowed: set[str] | frozenset[str]) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise ContractError("%s must be an array of strings" % name)
    unknown = set(value) - allowed
    if unknown:
        raise ContractError("unknown %s: %s" % (name, ", ".join(sorted(unknown))))
    return list(dict.fromkeys(value))


def _validate_snapshots(raw: Any, profile: str) -> dict[str, Any] | None:
    if raw is None:
        return None
    if not isinstance(raw, dict):
        raise ContractError("diagnostics.snapshots must be an object")
    unknown = set(raw) - {"every_sim_seconds", "fields", "only_when_changed"}
    if unknown:
        raise ContractError("unknown diagnostics.snapshots keys: %s" % ", ".join(sorted(unknown)))
    fields = _string_list(raw.get("fields"), "diagnostics.snapshots.fields", SNAPSHOT_FIELDS)
    interval = raw.get("every_sim_seconds")
    if interval == "day" and profile in {"balance", "performance"}:
        interval = "day"
    elif isinstance(interval, (int, float)) and not isinstance(interval, bool) and interval > 0:
        interval = float(interval)
    else:
        raise ContractError("diagnostics.snapshots.every_sim_seconds must be a positive number")
    changed = raw.get("only_when_changed", False)
    if not isinstance(changed, bool):
        raise ContractError("diagnostics.snapshots.only_when_changed must be boolean")
    return {"every_sim_seconds": interval, "fields": fields, "only_when_changed": changed}


def _validate_limits(raw: Any) -> dict[str, int | None]:
    if not isinstance(raw, dict):
        raise ContractError("diagnostics.limits must be an object")
    unknown = set(raw) - {"event_lines_per_type", "snapshot_lines"}
    if unknown:
        raise ContractError("unknown diagnostics.limits keys: %s" % ", ".join(sorted(unknown)))
    result: dict[str, int | None] = {}
    for key in ("event_lines_per_type", "snapshot_lines"):
        value = raw.get(key)
        if value is not None and (isinstance(value, bool) or not isinstance(value, int) or value <= 0):
            raise ContractError("diagnostics.limits.%s must be a positive integer" % key)
        result[key] = value
    return result
