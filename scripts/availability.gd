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
## challenge_runner.gd's `_apply_stage_gate_to_ui`). UI_GATES below does
## the same for whole HUD controls (F2s).
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
const Actions = preload("res://scripts/actions.gd")

const OK := "ok"
const REASON_UNKNOWN_KEY := "unknown_key"
const REASON_CONFIG_DISABLED := "config_disabled"
const REASON_LOCKED := "locked"
const REASON_SUPPRESSED := "suppressed"
const REASON_SKILL_NOT_OWNED := "skill_not_owned"

## G3: moves on whenever anything action_query reads may have changed, so a
## bee can cache its answers between changes instead of asking every think
## tick. stage_gate.gd bumps it on every unlock, lock, start and stop, and
## suppress/unsuppress below do too. Whatever grants or sells a skill must
## call invalidate() as well -- progression.gd does not know about this
## cache, and no action row is skill-gated yet.
static var gate_epoch: int = 0

## Developer/debug suppression, keyed the same as everything else here.
## Nothing sets this yet; it exists so a future debug toggle or
## time-limited effect has one place to hide a key rather than inventing
## a parallel gate the rest of this service doesn't know about.
static var _suppressed: Dictionary = {}

# --- UI gate table ------------------------------------------------

## F2s (plans/design/architecture-review.md): which stage-gate key governs
## which HUD controls. hud.gd registers each named control as it builds it
## and its apply_gates() walks this table, so a newly gated control is one
## row here and one registration there -- the Challenge runner no longer
## knows HUD widget names.
##
## "controls" are hud.gd member names, shown or hidden whole.
## "designations" are the cell popup's "Reserve for" keys ("any" is
## Unreserve); they filter that rebuilt row through
## set_allowed_designation_keys instead. Honey and jelly sit behind keys no
## Challenge 2 stage unlocks -- those systems are deferred entirely, not
## just until designation is taught (2.5).
##
## No stage_gate.ACCESSIBILITY_KEYS entry may appear here: accessibility
## toggles are outside the hide/reveal system altogether.
## tests/source_checks.py enforces that, and that every key a stage in
## challenge_stages.gd unlocks has a row here or a reason for none.
const UI_GATES := {
	"colony_window": {"controls": ["colony_button", "colony_info"]},
	"nursery_window": {"controls": ["nursery_button", "nursery_info"]},
	"meadow_view": {"controls": ["view_button", "view_info"]},
	"foraging_window": {"controls": ["foraging_button"]},
	"hatch_lock": {"controls": ["lock_row"]},
	"miner": {"controls": ["soil_mark_btn", "soil_clear_btn"]},
	# AP-7: no Challenge stage unlocks either key, so both buttons stay hidden
	# throughout a Challenge and show in every other run (progression.md 8.5).
	"skills_window": {"controls": ["skills_button"]},
	"saves_window": {"controls": ["saves_button"]},
	"cell_designation": {"designations": ["nectar", "pollen", "brood", "any"]},
	"honey_designation": {"designations": ["honey"]},
	"jelly_designation": {"designations": ["jelly"]},
}

## Stage-gate keys that deliberately have no UI_GATES row, with the reason.
## Every roles.gd role key and every mode_gate_key() has none either,
## without needing a line here: those filter the Job and Doing rows through
## hud.gd's set_allowed_role_keys/set_allowed_mode_keys, and the source
## check derives them from roles.gd.
const UNTABLED_GATE_KEYS := {
	"queen_commands": "Challenge 1's event-trigger documentation hook. The queen's command lock follows stage 1.1 in challenge_runner.gd, not this key, so no control shows or hides with it.",
}

static func invalidate() -> void:
	gate_epoch += 1

static func suppress(key: String) -> void:
	_suppressed[key] = true
	invalidate()

static func unsuppress(key: String) -> void:
	_suppressed.erase(key)
	invalidate()

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

## G3: whether the actions.gd row `action_id` may be started right now.
## Composes the same four facts mode_query does -- the row exists, its
## config flag is on, its stage-gate key is unlocked (only while a Challenge
## is active), it is not suppressed -- plus its skill being owned. Only the
## gate fields the row fills are looked at. A row's `feature` is not asked
## here: only progression.gd's resolver may read features.gd, and it has no
## plain "is this feature on" query yet, so the source check keeps `feature`
## empty until it does.
## `bee` is part of the contract for a per-bee fact; nothing reads it yet.
## Callers cache the answer against gate_epoch (bee.gd::_action_available)
## rather than asking per action per think tick.
static func action_query(action_id: String, _bee = null, stage_gate = null, progression = null) -> Dictionary:
	var action: Dictionary = Actions.by_id(action_id)
	if action.is_empty():
		return {"available": false, "reason": REASON_UNKNOWN_KEY}
	if _suppressed.has(action_id):
		return {"available": false, "reason": REASON_SUPPRESSED}
	var flag: String = action.get("config_flag", "")
	if flag != "" and not GameConfig.get(flag):
		return {"available": false, "reason": REASON_CONFIG_DISABLED}
	var gate_key: String = action.get("gate_key", "")
	if gate_key != "" and stage_gate != null and stage_gate.active and not stage_gate.is_unlocked(gate_key):
		return {"available": false, "reason": REASON_LOCKED}
	var skill: String = action.get("skill", "")
	if skill != "" and (progression == null or not progression.is_owned(skill)):
		return {"available": false, "reason": REASON_SKILL_NOT_OWNED}
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
