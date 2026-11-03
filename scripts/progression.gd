extends RefCounted
## The thin resolver -- the one place that answers ownership, afford,
## feature-validity and branch-tier questions about the skill tree.
##
## Usage: const Progression = preload("res://scripts/progression.gd")
##        var tree := Progression.new(GameConfig, main.stage_gate)
##        if tree.can_purchase(Skills.ORIENTATION_FLIGHT, stores): ...
##
## Scope (progression.md section 3, Phase A step 2). It reads
## skills.gd/adaptations.gd/features.gd and stage_gate.gd, and nothing
## else. Two of section 3's rules are enforced by tests rather than left
## as intentions: nothing else in the codebase answers these questions
## (tests/source_checks.py::check_progression_resolver), and **nothing
## here ever writes GameConfig** -- progression.gd is deliberately absent
## from source_checks.py's GAMECONFIG_WRITE_ALLOWLIST, so an assignment
## added here fails the suite.
##
## Nothing calls this file yet. It is wired into a running game by the
## foraging vertical slice (Phase B step 6); until then the two tier-1
## foraging nodes still ship as the plain GameConfig toggles
## `tarsal_markers_on` and `orientation_flight_on`, and this resolver is
## proved against those two entries in tests/ rather than in play.
##
## Effective values (Phase A step 4). `effective_value()` resolves base
## GameConfig plus every owned skill's `add_value`/`multiply_value`
## effects, additive first then multiplicative, each modifier keeping its
## source skill (section 3, section 9.1). `is_behaviour_enabled()`
## answers the boolean question the same two effects can't: Tarsal
## secretions and Orientation flight transcribe as `enable_behaviour`
## rather than a numeric modifier, since they are a plain owned/not-owned
## switch, not a magnitude. Nothing calls either yet -- see the note above
## about Phase B step 6 -- and no effect in the shipped catalogue exercises
## add_value/multiply_value today, so those two are proved in tests/
## against constructed data, the same way section 3's other rules were
## proved against skills.gd before anything called them.
##
## What is deliberately not here
## -----------------------------
## **Run policy.** Section 4.5's "permitted by the run/Challenge stage"
## is answered by stage_gate.gd plus this run's explicit
## `skill_grants`/`skill_bans`/`skill_delays` (Phase A step 3, authored on
## the levels.gd entry or scenario JSON and set via set_skill_policy()),
## which is why the gate is a function of its own rather
## than an inline stage_gate call. main.gd hands both in once per run
## start through begin_run(), from run_availability.gd's sheet.
##
## **Ranks.** Section 4.4 holds every skill at `max_rank` 1 for this
## pass, so ownership is yes/no and there is no rank arithmetic. The
## field exists so ranks can arrive later without a save migration.

const Skills = preload("res://scripts/skills.gd")
const Adaptations = preload("res://scripts/adaptations.gd")
const Features = preload("res://scripts/features.gd")

# --- blockers -----------------------------------------------------
## Why a purchase is refused, as keys rather than sentences: section 0's
## language note keeps display text out of anything a caller branches on.
## purchase_blocker() returns one of these, or "" when the skill can be
## bought; the tree panel (Phase B step 6) turns them into player words.

const BLOCK_NO_SUCH_SKILL := "block.no_such_skill"
const BLOCK_BASELINE := "block.baseline"
const BLOCK_UNKNOWN := "block.unknown"
const BLOCK_NOT_PERMITTED := "block.not_permitted"
const BLOCK_FEATURE := "block.feature"
const BLOCK_PREREQUISITES := "block.prerequisites"
const BLOCK_PREVIOUS_TIER := "block.previous_tier"
const BLOCK_ALREADY_OWNED := "block.already_owned"
const BLOCK_COST := "block.cost"

# --- typed effects --------------------------------------------------
## Section 9.1's fixed vocabulary, the three types this step's lookup
## reads. The other six (unlock_feature and the rest) gate presence
## questions the tree panel already has its own way to ask and are not
## numeric or boolean modifiers, so effective_value() and
## is_behaviour_enabled() below have no reason to know their names.

const EFFECT_ADD_VALUE := "add_value"
const EFFECT_MULTIPLY_VALUE := "multiply_value"
const EFFECT_ENABLE_BEHAVIOUR := "enable_behaviour"

# --- state --------------------------------------------------------
## `config` is GameConfig, read only and never written. `stage_gate` is
## main.stage_gate, or null outside a run -- a null gate permits
## everything, matching stage_gate.gd's own "outside a Challenge every
## key reads unlocked" rule, so callers need no "am I in a Challenge"
## test of their own.
##
## Ownership is two dictionaries rather than one, because section 4.1
## keeps them apart: mastered skills are bought between runs and are
## owned free at the start of every permitted run, temporary ones are
## bought during a run with colony stores and are lost when it ends. Both
## count as owned everywhere else, branch-tier progress included.

var config: Object = null
var stage_gate: Node = null

## Discovery only exists in the campaign meta tree (section 4.1), which
## is post-alpha work. While this is false every catalogued skill reads
## as known, so Scenarios, Sandbox and the Challenges are unaffected.
var campaign_discovery: bool = false

var _mastered: Dictionary = {}      # skill id -> true
var _temporary: Dictionary = {}     # skill id -> true
var _discovered: Dictionary = {}    # skill id -> true
var _adaptations: Dictionary = {}   # adaptation id -> true
## is_behaviour_enabled's answers, behaviour key -> bool (AP-2). The
## foraging reads ask per flower considered, and walking owned_ids() there
## allocates and scans every time. Cleared by the three ownership writers
## -- grant_temporary, set_mastered_ids and end_run -- so a purchase flips
## the answer on the very next read.
var _behaviour_cache: Dictionary = {}

## This run's explicit skill-policy overrides (section 4.5, set by
## set_skill_policy() below). A ban is absolute; a grant overrides the
## stage gate; a delay redirects is_permitted() to a different stage-gate
## key instead of the skill's own id. All three are empty until a caller
## sets them, matching "no run behaves differently" until Phase B step 6.
var _skill_grants: Dictionary = {}  # skill id -> true
var _skill_bans: Dictionary = {}    # skill id -> true
var _skill_delays: Dictionary = {}  # skill id -> stage-gate key
## BS-2: skills a Challenge stage hands out free, set by the runner on entering
## the stage. Run state: end_run() clears it and a save does not hold it.
var _waived: Dictionary = {}        # skill id -> true


func _init(game_config: Object = null, gate: Node = null) -> void:
	config = game_config
	stage_gate = gate

# --- ownership ----------------------------------------------------
## Section 5.7's baseline capabilities are owned from the first frame and
## are never bought, so they answer true here without appearing in either
## dictionary.

func is_owned(skill_id: String) -> bool:
	if Skills.is_baseline(skill_id):
		return true
	return _mastered.has(skill_id) or _temporary.has(skill_id)


## T2-8a: owned, or not in the catalogue at all -- for a rule written ahead
## of its node (season.gd's Shiver Cluster bill), which must change nothing
## until the node exists.
func is_owned_or_absent(skill_id: String) -> bool:
	return not Skills.has(skill_id) or is_owned(skill_id)


func is_temporary(skill_id: String) -> bool:
	return _temporary.has(skill_id)


## Everything owned right now, baseline capabilities included, so a
## caller counting progress sees the same set the gates below do.
func owned_ids() -> Array:
	var ids: Array = Skills.baseline_ids()
	for skill_id: Variant in _mastered:
		if not ids.has(skill_id):
			ids.append(skill_id)
	for skill_id: Variant in _temporary:
		if not ids.has(skill_id):
			ids.append(skill_id)
	return ids


## Meta-tree ownership, captured at the start of a run. Section 4.1: a
## mastered skill is owned free and counts towards branch-tier progress
## as if bought, and a Challenge's own policy still overrides it.
func set_mastered_ids(ids: Array) -> void:
	_mastered.clear()
	_behaviour_cache.clear()
	for skill_id: Variant in ids:
		if Skills.has(skill_id):
			_mastered[skill_id] = true


## Ownership bought during this run. Kept apart from mastered so
## end_run() drops exactly the run's own purchases.
func grant_temporary(skill_id: String) -> void:
	if Skills.has(skill_id):
		_temporary[skill_id] = true
		_behaviour_cache.clear()


## Section 4.1: temporary ownership is lost when the run ends and nothing
## bought during a run is carried out of it -- so the run's chosen
## adaptations go with it, and the mastered set does not.
func end_run() -> void:
	_temporary.clear()
	_waived.clear()
	_behaviour_cache.clear()
	_adaptations.clear()

# --- the gates ----------------------------------------------------
## Section 4.5's conditions, one function each. purchase_blocker() below
## is the only place they are combined, so a condition cannot be quietly
## dropped at one call site while another still applies it.

## Known: discovered in the campaign meta tree by completing the
## Challenge that introduces it. Everything is known while the campaign
## tree does not exist.
func is_known(skill_id: String) -> bool:
	if not Skills.has(skill_id):
		return false
	if not campaign_discovery:
		return true
	return _discovered.has(skill_id)


func discover(skill_id: String) -> void:
	if Skills.has(skill_id):
		_discovered[skill_id] = true


## Section 11 Phase A step 3: this run's explicit skill_grants/
## skill_bans/skill_delays, from the run definition by way of
## run_availability.gd's sheet (begin_run below). A ban always wins,
## even over a grant naming the same
## skill by mistake -- refusing outright is the safe reading of
## contradictory data. A grant then wins over the stage gate, so a
## Challenge can hand a skill out early. Clears both dictionaries and
## replaces the delay map wholesale, so a later run's policy never
## inherits an earlier one's.
func set_skill_policy(grants: Array, bans: Array, delays: Dictionary) -> void:
	_skill_grants.clear()
	for skill_id: Variant in grants:
		_skill_grants[skill_id] = true
	_skill_bans.clear()
	for skill_id: Variant in bans:
		_skill_bans[skill_id] = true
	_skill_delays = delays.duplicate()


## BS-1: the run start. Applies the run's skill policy and grants the
## skills it starts owning, both taken from run_availability.gd's sheet --
## the one place starting ownership is derived (plans/now/brood-spine.md),
## so this reads the sheet's `grants`/`bans`/`delays`/`starting` and
## decides nothing itself. Starting skills are temporary ownership: a save
## records them with the run's purchases and end_run() drops them. The
## caller invalidates availability.gd's cache, which this file does not
## know about.
func begin_run(sheet: Dictionary) -> void:
	set_skill_policy(sheet.get("grants", []), sheet.get("bans", []), sheet.get("delays", {}))
	for skill_id: Variant in sheet.get("starting", []):
		grant_temporary(str(skill_id))


## Permitted by the run or Challenge stage. A skill's stage-gate key is
## its own stable ID, so a sub-stage reveals a node the way it reveals
## any other piece of UI -- unless this run's skill_delays redirects it
## to a different key. A ban refuses regardless of the stage gate; a
## grant permits regardless of it. Both are empty until set_skill_policy()
## is called, so this answers exactly as before until then.
func is_permitted(skill_id: String) -> bool:
	if Skills.is_cut(skill_id):
		return false
	if _skill_bans.has(skill_id):
		return false
	if _skill_grants.has(skill_id):
		return true
	if stage_gate == null:
		return true
	var gate_key: String = _skill_delays.get(skill_id, skill_id)
	return stage_gate.is_unlocked(gate_key)


## The skill's feature dependency holds in this run. An unbuilt feature
## is never available however the config is set (features.gd), so a skill
## depending on drought stays unbuyable until a drought slice lands.
## Without a config there is no toggle to read, and refusing is the safe
## answer rather than a guess.
func feature_valid(skill_id: String) -> bool:
	var feature: String = Skills.entry(skill_id).get("feature", "")
	if feature == "":
		return true
	if config == null:
		return false
	return Features.is_available(feature, config)


## Every `all_of` prerequisite owned, and at least one member of each
## `any_of` group. An empty group could never be satisfied, so it counts
## as unmet rather than vacuously true.
func prerequisites_met(skill_id: String) -> bool:
	var entry: Dictionary = Skills.entry(skill_id)
	if entry.is_empty():
		return false
	for required: Variant in entry.get("all_of", []):
		if not is_owned(required):
			return false
	for group: Variant in entry.get("any_of", []):
		var satisfied := false
		for option: Variant in group:
			if is_owned(option):
				satisfied = true
				break
		if not satisfied:
			return false
	return true


## Section 4.3: a branch's tier N+1 opens only when *every* skill in that
## branch's tier N that this run offers is owned -- not any one of them, and per branch. Tier
## 1 has no tier below it, and a run definition waiving
## `requires_previous_tier` is the only thing that skips the rule.
func branch_tier_open(skill_id: String) -> bool:
	var entry: Dictionary = Skills.entry(skill_id)
	if entry.is_empty():
		return false
	if not entry.get("requires_previous_tier", true):
		return true
	var tier: int = entry.get("tier", 0)
	if tier <= 1:
		return true
	for sibling: Dictionary in Skills.for_sector_tier(entry.get("sector", ""), tier - 1):
		if not _offered_in_run(sibling.id):
			continue
		if not is_owned(sibling.id):
			return false
	return true


## T2-9: this run offers the skill -- permitted and its feature holds. A
## skill the run cuts, bans, has not yet unlocked or lacks the feature for
## cannot be bought, so it must not keep the tier above it shut.
func _offered_in_run(skill_id: String) -> bool:
	return is_permitted(skill_id) and feature_valid(skill_id)


## Section 4.2: the recipe is spent from the colony's stores, so it has
## to be affordable in full. `stores` maps a resource key (skills.gd's
## NECTAR, POLLEN, HONEY and the rest) to an amount; a resource the
## colony has never held is simply absent, which reads as none.
## BS-2: replaces the waived set wholesale, so each stage names exactly what
## it gives away and a later stage never inherits an earlier one's.
func waive_cost(skill_ids: Array) -> void:
	_waived.clear()
	for skill_id: Variant in skill_ids:
		_waived[str(skill_id)] = true


func is_free(skill_id: String) -> bool:
	return _waived.has(skill_id)


## What buying the skill costs in this run: nothing when a stage waives it.
## The one resolver purchase(), can_afford() and the skill tree read.
func cost_for(skill_id: String) -> Dictionary:
	if _waived.has(skill_id):
		return {}
	return Skills.cost_for(skill_id)


func can_afford(skill_id: String, stores: Dictionary) -> bool:
	return _covers(cost_for(skill_id), stores)


## The one price rule: every resource in `cost` is held in full.
func _covers(cost: Dictionary, stores: Dictionary) -> bool:
	for resource: Variant in cost:
		if float(stores.get(resource, 0)) < float(cost[resource]):
			return false
	return true


## T2-7: the stores cover the cheapest first tier-2 path -- Honey worker (the
## spine), plus one tier-1 and one tier-2 node of one branch, with their
## `all_of` prerequisites, summed per resource and checked by _covers(). Only
## nodes the tree offers (not cut) count. Read once per diagnostic snapshot.
func first_tier2_path_covered(stores: Dictionary) -> bool:
	for sector: String in Skills.sector_keys():
		for first: Dictionary in Skills.for_sector_tier(sector, 1):
			for second: Dictionary in Skills.for_sector_tier(sector, 2):
				if Skills.is_cut(first.id) or Skills.is_cut(second.id):
					continue
				var path := {Skills.HONEY_WORKER: true}
				_add_with_prerequisites(first.id, path)
				_add_with_prerequisites(second.id, path)
				if _path_offered(path) and _covers(_path_cost(path), stores):
					return true
	return false


## PP-6: the stores cover Gyne rearing's whole path from zero -- Honey worker
## (the spine) plus Gyne rearing and its `all_of` chain (Bee bread, Royal
## jelly), summed per resource by _path_cost() and checked by _covers(), the
## way first_tier2_path_covered counts. Read once per diagnostic snapshot.
func gyne_rearing_path_covered(stores: Dictionary) -> bool:
	var path := {Skills.HONEY_WORKER: true}
	_add_with_prerequisites(Skills.GYNE_REARING, path)
	return _path_offered(path) and _covers(_path_cost(path), stores)


func _add_with_prerequisites(skill_id: String, path: Dictionary) -> void:
	if path.has(skill_id) and skill_id != Skills.HONEY_WORKER:
		return
	path[skill_id] = true
	for required: Variant in Skills.entry(skill_id).get("all_of", []):
		if not path.has(required):
			_add_with_prerequisites(required, path)


func _path_offered(path: Dictionary) -> bool:
	for skill_id: Variant in path:
		if Skills.is_cut(skill_id) or not Skills.has(skill_id):
			return false
	return true


func _path_cost(path: Dictionary) -> Dictionary:
	var total := {}
	for skill_id: Variant in path:
		var cost: Dictionary = cost_for(skill_id)
		for resource: Variant in cost:
			total[resource] = float(total.get(resource, 0)) + float(cost[resource])
	return total

# --- effective values -----------------------------------------------
## Section 9.1's resolution order, restricted to what this step can
## prove: base GameConfig value, then every owned skill's additive
## modifiers summed, then every owned skill's multiplicative modifiers
## applied. The run/Challenge-override and explicit-cap stages are out of
## scope until a run definition or a skill actually feeds one.

## Every add_value/multiply_value effect naming `key`, across every
## owned skill -- baseline capabilities included, since section 5.7's
## capabilities are owned like anything else. Kept separate from
## effective_value() so a caller (a future tree panel tooltip) can show
## "which skills changed this" rather than only the resolved number.
func modifiers_for(key: String) -> Array:
	var modifiers: Array = []
	for skill_id: Variant in owned_ids():
		for effect: Variant in Skills.entry(skill_id).get("effects", []):
			if effect.get("key", "") != key:
				continue
			var op: String = effect.get("type", "")
			if op != EFFECT_ADD_VALUE and op != EFFECT_MULTIPLY_VALUE:
				continue
			modifiers.append({
				"source": skill_id, "op": op,
				"amount": float(effect.get("amount", 0.0)),
			})
	return modifiers


func effective_value(key: String, base: float) -> float:
	var value := base
	for modifier: Variant in modifiers_for(key):
		if modifier["op"] == EFFECT_ADD_VALUE:
			value += modifier["amount"]
	for modifier: Variant in modifiers_for(key):
		if modifier["op"] == EFFECT_MULTIPLY_VALUE:
			value *= modifier["amount"]
	return value


## The enable_behaviour question: owned by any skill that switches `key`
## on, Tarsal secretions/Orientation flight's shape rather than
## add_value/multiply_value's. There is no "base" side to combine with --
## the behaviour is off until something turns it on, matching
## tarsal_markers_on/orientation_flight_on's own default.
func is_behaviour_enabled(key: String) -> bool:
	if _behaviour_cache.has(key):
		return _behaviour_cache[key]
	var enabled := false
	for skill_id: Variant in owned_ids():
		for effect: Variant in Skills.entry(skill_id).get("effects", []):
			if effect.get("type", "") == EFFECT_ENABLE_BEHAVIOUR and effect.get("key", "") == key:
				enabled = true
	_behaviour_cache[key] = enabled
	return enabled

# --- the chain ----------------------------------------------------

## Section 4.5's list, in its order, and the only place the gates are
## combined. Returns "" when the skill can be bought, or the first
## BLOCK_* reason it cannot -- first, so a panel explains the most
## fundamental problem rather than the last one tested.
func purchase_blocker(skill_id: String, stores: Dictionary) -> String:
	if not Skills.has(skill_id):
		return BLOCK_NO_SUCH_SKILL
	if Skills.is_baseline(skill_id):
		return BLOCK_BASELINE
	if not is_known(skill_id):
		return BLOCK_UNKNOWN
	if not is_permitted(skill_id):
		return BLOCK_NOT_PERMITTED
	if not feature_valid(skill_id):
		return BLOCK_FEATURE
	if not prerequisites_met(skill_id):
		return BLOCK_PREREQUISITES
	if not branch_tier_open(skill_id):
		return BLOCK_PREVIOUS_TIER
	if is_owned(skill_id):
		return BLOCK_ALREADY_OWNED
	if not can_afford(skill_id, stores):
		return BLOCK_COST
	return ""


func can_purchase(skill_id: String, stores: Dictionary) -> bool:
	return purchase_blocker(skill_id, stores) == ""


## Buys the skill: spends the recipe out of `stores` and records
## temporary ownership. `stores` is modified in place, which is what
## keeps deduction in one place rather than in every future call site.
## False, and nothing spent, when the purchase was not allowed.
func purchase(skill_id: String, stores: Dictionary) -> bool:
	if not can_purchase(skill_id, stores):
		return false
	var cost: Dictionary = cost_for(skill_id)
	for resource: Variant in cost:
		stores[resource] = float(stores.get(resource, 0)) - float(cost[resource])
	grant_temporary(skill_id)
	return true

# --- adaptations --------------------------------------------------
## Section 7 defers the build, so this is the eligibility half only: what
## may reach an offer at all in this run. Drawing three distinct cards
## out of the eligible set is the offer's job rather than a question
## about one card, and arrives with the milestone that offers them.

func adaptation_eligible(adaptation_id: String) -> bool:
	var entry: Dictionary = Adaptations.entry(adaptation_id)
	if entry.is_empty() or not entry.get("offerable", false):
		return false
	if _adaptations.has(adaptation_id):
		return false
	var skill_id: String = entry.get("requires_skill", "")
	if skill_id != "" and not is_owned(skill_id):
		return false
	var feature: String = entry.get("requires_feature", "")
	if feature == "":
		return true
	if config == null:
		return false
	return Features.is_available(feature, config)


func eligible_adaptation_ids() -> Array:
	return Adaptations.offerable_ids().filter(func(a: Variant) -> bool: return adaptation_eligible(a))


func choose_adaptation(adaptation_id: String) -> bool:
	if not adaptation_eligible(adaptation_id):
		return false
	_adaptations[adaptation_id] = true
	return true


func chosen_adaptation_ids() -> Array:
	return _adaptations.keys()
