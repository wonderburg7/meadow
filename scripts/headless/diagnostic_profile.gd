## Scenario-only diagnostic capture selection.
class_name HeadlessDiagnosticProfile
extends RefCounted

const HeadlessDiagnosticProbes = preload("res://scripts/headless/diagnostic_probes.gd")
const VERSION := 1
const EVENT_TYPES := ["action", "death", "crab_spider_event", "recruitment_match", "recruitment_followup", "forager_settled", "orientation_flight", "stall_recovery", "scouting_settled"]
const PROFILE_NAMES := ["standard", "verdict", "behaviour", "balance", "performance", "custom"]

static func standard() -> Dictionary:
	return {"ok": true, "profile": "standard", "version": VERSION, "events": EVENT_TYPES.duplicate(), "snapshots": {}, "limits": {}, "legacy_standard": true}

static func parse(raw: Variant) -> Dictionary:
	if raw == null: return standard()
	if not (raw is Dictionary): return _error("diagnostics must be an object")
	var profile: String = str(raw.get("profile", "standard"))
	if not profile in PROFILE_NAMES: return _error("unknown diagnostic profile: %s" % profile)
	var result := standard()
	result["profile"] = profile
	result["legacy_standard"] = profile == "standard" and raw.is_empty()
	result["events"] = _default_events(profile)
	result["snapshots"] = _default_snapshots(profile)
	if raw.has("events"):
		var events = _valid_strings(raw.events, EVENT_TYPES, "diagnostics.events")
		if not events.ok: return events
		result["events"] = events.value
	if raw.has("snapshots"):
		var snapshots = _parse_snapshots(raw.snapshots, profile)
		if not snapshots.ok: return snapshots
		result["snapshots"] = snapshots.value
	if raw.has("limits"):
		var limits = _parse_limits(raw.limits)
		if not limits.ok: return limits
		result["limits"] = limits.value
	return result

static func _default_events(profile: String) -> Array:
	match profile:
		"standard", "behaviour": return EVENT_TYPES.duplicate()
		"verdict", "balance", "performance": return ["action", "death"]
		_: return []

static func _default_snapshots(profile: String) -> Dictionary:
	if profile == "balance": return {"every_sim_seconds": "day", "fields": ["population.total", "resources.food_stores", "environment.winter_here"], "only_when_changed": false}
	if profile == "performance": return {"every_sim_seconds": "day", "fields": ["performance.fps", "performance.top_sections_ms"], "only_when_changed": false}
	return {}

static func _parse_snapshots(raw: Variant, profile: String) -> Dictionary:
	if not (raw is Dictionary): return _error("diagnostics.snapshots must be an object")
	var fields = _valid_strings(raw.get("fields", []), HeadlessDiagnosticProbes.SNAPSHOT_FIELDS, "diagnostics.snapshots.fields")
	if not fields.ok: return fields
	var interval = raw.get("every_sim_seconds", null)
	if interval is String:
		if not (interval == "day" and profile in ["balance", "performance"]):
			return _error("diagnostics.snapshots.every_sim_seconds must be a positive number")
	elif not (interval is float or interval is int) or float(interval) <= 0.0:
		return _error("diagnostics.snapshots.every_sim_seconds must be a positive number")
	var changed = raw.get("only_when_changed", false)
	if not (changed is bool): return _error("diagnostics.snapshots.only_when_changed must be boolean")
	return {"ok": true, "value": {"every_sim_seconds": interval, "fields": fields.value, "only_when_changed": changed}}

static func _parse_limits(raw: Variant) -> Dictionary:
	if not (raw is Dictionary): return _error("diagnostics.limits must be an object")
	var result := {}
	for key in ["event_lines_per_type", "snapshot_lines"]:
		if not raw.has(key): continue
		var value = raw[key]
		if not (value is int or value is float) or value <= 0 or floor(float(value)) != float(value):
			return _error("diagnostics.limits.%s must be a positive integer" % key)
		result[key] = int(value)
	return {"ok": true, "value": result}

static func _valid_strings(raw: Variant, allowed: Array, name: String) -> Dictionary:
	if not (raw is Array): return _error("%s must be an array" % name)
	var values: Array = []
	for item in raw:
		if not (item is String) or not item in allowed: return _error("unknown %s: %s" % [name, str(item)])
		if not item in values: values.append(item)
	return {"ok": true, "value": values}

static func _error(message: String) -> Dictionary:
	return {"ok": false, "error": message}
