extends RefCounted
## Non-visual query for whether a mechanic is available right now, and why
## not when it isn't.
##
## Usage: const Availability = preload("res://scripts/availability.gd")
##        Availability.mode_query(Roles.FORAGER, "pollen", main.stage_gate)
##
## Before this file, "can a bee be set to this role/mode/designation"
## lived only as a filter against `stage_gate.is_unlocked()`, computed
## once in challenge_runner.gd to build an allow-list and a second time
## in hud.gd to check membership in it -- two copies of the same
## namespacing formula with a comment on each telling the reader to keep
## them in sync by hand (see hud.gd's `_build_doing_row` and
## challenge_runner.gd's `_apply_stage_gate_to_ui`).
##
## This composes the facts that decide availability -- does the key
## exist at all, is it behind a GameConfig flag, is it unlocked for this
## level/Challenge, is it temporarily suppressed -- into one call
## returning a stable reason, instead of a bare bool. Callers that only
## need the bool can still just check `.available`.
##
## `stage_gate` is only consulted while `stage_gate.active` is true (a
## Challenge run in progress); outside that it behaves as "always
## unlocked", matching `StageGate.is_unlocked()`'s own contract.

const Roles = preload("res://scripts/roles.gd")
const Resources = preload("res://scripts/resources.gd")

const OK := "ok"
const REASON_UNKNOWN_KEY := "unknown_key"
const REASON_CONFIG_DISABLED := "config_disabled"
const REASON_LOCKED := "locked"
const REASON_SUPPRESSED := "suppressed"

## Developer/debug suppression, keyed the same as everything else here.
## Nothing sets this yet; it exists so a future debug toggle or
## time-limited effect has one place to hide a key rather than inventing
## a parallel gate the rest of this service doesn't know about.
static var _suppressed: Dictionary = {}

static func suppress(key: String) -> void:
	_suppressed[key] = true

static func unsuppress(key: String) -> void:
	_suppressed.erase(key)

static func is_suppressed(key: String) -> bool:
	return _suppressed.has(key)

## The exact key `stage_gate`/`allowed_mode_keys` use for one role's
## sub-mode: bare for Forager ("nectar", "pollen"), "<role_key>_<mode_key>"
## for every other role (Nurse and Comb worker both have a mode keyed
## "both", so a bare key would let one role's unlock leak into the
## other's). The single formula both challenge_runner.gd and hud.gd read.
static func mode_gate_key(role_id: int, mode_key: String) -> String:
	if role_id == Roles.FORAGER:
		return mode_key
	return "%s_%s" % [Roles.key_for(role_id), mode_key]

## Whether `mode_key` is available for `role_id` right now. Composes:
## code existence (the mode belongs to this role in roles.gd), config
## gate (none currently defined for any mode), level/Challenge unlock
## (`stage_gate`, only while a run is active) and suppression.
static func mode_query(role_id: int, mode_key: String, stage_gate = null) -> Dictionary:
	var mode_keys: Array = Roles.modes_for(role_id).map(func(m): return m.key)
	if mode_key not in mode_keys:
		return {"available": false, "reason": REASON_UNKNOWN_KEY}
	var gate_key: String = mode_gate_key(role_id, mode_key)
	if _suppressed.has(gate_key):
		return {"available": false, "reason": REASON_SUPPRESSED}
	if stage_gate != null and stage_gate.active and not stage_gate.is_unlocked(gate_key):
		return {"available": false, "reason": REASON_LOCKED}
	return {"available": true, "reason": OK}

## Whether `resource_key` is a known, currently-enabled resource. Composes
## catalogue existence and `resources.gd`'s own `config_flag` (empty means
## no config gate; nectar/pollen have none today).
static func resource_query(resource_key: String) -> Dictionary:
	if not Resources.is_valid(resource_key):
		return {"available": false, "reason": REASON_UNKNOWN_KEY}
	var flag: String = Resources.entry(resource_key).get("config_flag", "")
	if not flag.is_empty() and not GameConfig.get(flag):
		return {"available": false, "reason": REASON_CONFIG_DISABLED}
	if _suppressed.has(resource_key):
		return {"available": false, "reason": REASON_SUPPRESSED}
	return {"available": true, "reason": OK}
