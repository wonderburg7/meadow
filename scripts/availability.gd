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
## cache, and every Nurse and Honey worker row is gated by its role's skill
## (BS-3, role_query).
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
## set_allowed_designation_keys instead. Honey, jelly and bee bread sit
## behind keys no Challenge 2 stage unlocks -- those systems are deferred
## entirely, not just until designation is taught (2.5).
## A row may also name a "skill" (BB-1): its designations are offered in any
## run only once that skill is owned (designation_owned below).
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
	# AP-7: no Challenge stage unlocks this key, so the button stays hidden
	# throughout a Challenge and shows in every other run (progression.md 8.5).
	"skills_window": {"controls": ["skills_button"]},
	"cell_designation": {"designations": ["nectar", "pollen", "brood", "any"]},
	"honey_designation": {"designations": ["honey"]},
	"jelly_designation": {"designations": ["jelly"]},
	"bee_bread_designation": {"designations": ["bee_bread"], "skill": "skill.brood.bee_bread"},
}

## Stage-gate keys that deliberately have no UI_GATES row, with the reason.
## Every roles.gd role key and every mode_gate_key() has none either,
## without needing a line here: those filter the Job and Doing rows through
## hud.gd's set_allowed_role_keys/set_allowed_mode_keys, and the source
## check derives them from roles.gd.
const UNTABLED_GATE_KEYS := {
	"queen_commands": "Challenge 1's event-trigger documentation hook. The queen's command lock follows stage 1.1 in challenge_runner.gd, not this key, so no control shows or hides with it.",
}

## BB-1: whether the skills owned offer the cell popup's "Reserve for"
## `designation_key`. Only a UI_GATES row naming a "skill" can refuse; with
## no `progression` a skill-gated key is refused, as role_query does.
static func designation_owned(designation_key: String, progression: Object) -> bool:
	for key: Variant in UI_GATES:
		var row: Dictionary = UI_GATES[key]
		if not designation_key in row.get("designations", []):
			continue
		var skill: String = row.get("skill", "")
		if skill != "" and (progression == null or not progression.is_owned(skill)):
			return false
	return true

static func invalidate() -> void:
	gate_epoch += 1

static func suppress(key: String) -> void:
	_suppressed[key] = true
	invalidate()

static func unsuppress(key: String) -> void:
	_suppressed.erase(key)
	invalidate()

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
static func mode_query(role_id: int, mode_key: String, stage_gate: Node = null, progression: Object = null) -> Dictionary:
	var mode: Dictionary = {}
	for m: Variant in Roles.modes_for(role_id):
		if m.key == mode_key:
			mode = m
	if mode.is_empty():
		return {"available": false, "reason": REASON_UNKNOWN_KEY}
	var gate_key: String = mode_gate_key(role_id, mode_key)
	if _suppressed.has(gate_key):
		return {"available": false, "reason": REASON_SUPPRESSED}
	if stage_gate != null and stage_gate.active and not stage_gate.is_unlocked(gate_key):
		return {"available": false, "reason": REASON_LOCKED}
	# T2-2: a mode may name a skill (Miner's automine: Automation). Only an
	# explicit progression is asked, so a caller that passes none sees the
	# mode as before.
	var skill: String = mode.get("skill", "")
	if skill != "" and progression != null and not progression.is_owned(skill):
		return {"available": false, "reason": REASON_SKILL_NOT_OWNED}
	return {"available": true, "reason": OK}

## BS-3: whether a bee may be put in `role_id`, or a cell set to raise one,
## right now. Composes: the role exists, its key is not suppressed, its
## stage-gate key is unlocked (only while a Challenge is active; pass a null
## `stage_gate` to leave the stage out), and the skill that unlocks it
## (roles.gd `skill`) is owned. A skill-gated role with no `progression` is
## not available, the same convention action_query keeps for a row's skill.
## `bee` is the asking bee (null for a colony-wide answer): the queen is let
## past the skill for QUEEN_FREE_ROLES.
## The one rule the HUD's Job and Raises rows, orders_zones.gd's role and
## hatch commands and action_query all read.
static func role_query(role_id: int, stage_gate: Node = null, progression: Object = null, bee: Node2D = null) -> Dictionary:
	var role: Dictionary = Roles.entry(role_id)
	if role.id != role_id:
		return {"available": false, "reason": REASON_UNKNOWN_KEY}
	if _suppressed.has(role.key):
		return {"available": false, "reason": REASON_SUPPRESSED}
	if stage_gate != null and stage_gate.active and not stage_gate.is_unlocked(role.key):
		return {"available": false, "reason": REASON_LOCKED}
	if not _role_skill_owned(role_id, progression, bee):
		return {"available": false, "reason": REASON_SKILL_NOT_OWNED}
	return {"available": true, "reason": OK}

## T2-1: the roles the queen may take without their skill (progression step
## 8 decision, Dave 6 Oct 2026). Workers always need the skill.
const QUEEN_FREE_ROLES := [Roles.NURSE, Roles.COMB_WORKER]

static func _role_skill_owned(role_id: int, progression: Object, bee: Node2D = null) -> bool:
	if bee != null and bee.is_queen and role_id in QUEEN_FREE_ROLES:
		return true
	var skill: String = Roles.skill_for(role_id)
	return skill == "" or (progression != null and progression.is_owned(skill))

## G3: whether the actions.gd row `action_id` may be started right now.
## Composes the same four facts mode_query does -- the row exists, its
## config flag is on, its stage-gate key is unlocked (only while a Challenge
## is active), it is not suppressed -- plus its skill being owned, and
## (BS-3) the skill of every role it serves: a row of a role the colony has
## not bought is never worked. Only the gate fields the row fills are looked
## at, besides that role skill. A row's `feature` is not asked
## here: only progression.gd's resolver may read features.gd, and it has no
## plain "is this feature on" query yet, so the source check keeps `feature`
## empty until it does.
## `bee` is the bee asking (null for a colony-wide answer). Decision 7
## (BS-9): the queen nurses without the Nurses skill -- for her the role
## check passes for QUEEN_FREE_ROLES (T2-1 adds Comb worker), so a Challenge with no nurse yet still
## feeds its brood. Workers still need the skill (role_query is unchanged).
## Callers cache the answer against gate_epoch (bee.gd::_action_available)
## rather than asking per action per think tick.
static func action_query(action_id: String, bee: Node2D = null, stage_gate: Node = null, progression: Object = null) -> Dictionary:
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
	for role_id: Variant in action.get("roles", []):
		if not _role_skill_owned(role_id, progression, bee):
			return {"available": false, "reason": REASON_SKILL_NOT_OWNED}
	return {"available": true, "reason": OK}
