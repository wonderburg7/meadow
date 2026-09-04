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
## What is deliberately not here
## -----------------------------
## **Effective values.** Section 3's other half -- base GameConfig plus
## additive and multiplicative modifiers with source tracking -- is Phase
## A step 4, and arrives once `effects` in skills.gd stops being empty.
## Adding a lookup now would be a schema guessed against no data.
##
## **Run policy.** Section 4.5's "permitted by the run/Challenge stage"
## is answered here only by stage_gate.gd. A Challenge's explicit
## `skill_grants`/`skill_bans`/`skill_delays` are Phase A step 3; they
## land inside is_permitted(), which is why the gate is a function of its
## own rather than an inline stage_gate call.
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


func is_mastered(skill_id: String) -> bool:
	return _mastered.has(skill_id)


func is_temporary(skill_id: String) -> bool:
	return _temporary.has(skill_id)


## Everything owned right now, baseline capabilities included, so a
## caller counting progress sees the same set the gates below do.
func owned_ids() -> Array:
	var ids: Array = Skills.baseline_ids()
	for skill_id in _mastered:
		if not ids.has(skill_id):
			ids.append(skill_id)
	for skill_id in _temporary:
		if not ids.has(skill_id):
			ids.append(skill_id)
	return ids


## Meta-tree ownership, captured at the start of a run. Section 4.1: a
## mastered skill is owned free and counts towards branch-tier progress
## as if bought, and a Challenge's own policy still overrides it.
func set_mastered_ids(ids: Array) -> void:
	_mastered.clear()
	for skill_id in ids:
		if Skills.has(skill_id):
			_mastered[skill_id] = true


## Ownership bought during this run. Kept apart from mastered so
## end_run() drops exactly the run's own purchases.
func grant_temporary(skill_id: String) -> void:
	if Skills.has(skill_id):
		_temporary[skill_id] = true


## Section 4.1: temporary ownership is lost when the run ends and nothing
## bought during a run is carried out of it -- so the run's chosen
## adaptations go with it, and the mastered set does not.
func end_run() -> void:
	_temporary.clear()
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


## Permitted by the run or Challenge stage. A skill's stage-gate key is
## its own stable ID, so a sub-stage reveals a node the way it reveals
## any other piece of UI. Phase A step 3 adds a run definition's explicit
## grants, bans and delays here.
func is_permitted(skill_id: String) -> bool:
	if stage_gate == null:
		return true
	return stage_gate.is_unlocked(skill_id)


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
	for required in entry.get("all_of", []):
		if not is_owned(required):
			return false
	for group in entry.get("any_of", []):
		var satisfied := false
		for option in group:
			if is_owned(option):
				satisfied = true
				break
		if not satisfied:
			return false
	return true


## Section 4.3: a branch's tier N+1 opens only when *every* skill in that
## branch's tier N is owned -- not any one of them, and per branch. Tier
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
	for sibling in Skills.for_sector_tier(entry.get("sector", ""), tier - 1):
		if not is_owned(sibling.id):
			return false
	return true


## Section 4.2: the recipe is spent from the colony's stores, so it has
## to be affordable in full. `stores` maps a resource key (skills.gd's
## NECTAR, POLLEN, HONEY and the rest) to an amount; a resource the
## colony has never held is simply absent, which reads as none.
func can_afford(skill_id: String, stores: Dictionary) -> bool:
	var cost: Dictionary = Skills.cost_for(skill_id)
	for resource in cost:
		if float(stores.get(resource, 0)) < float(cost[resource]):
			return false
	return true

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
	var cost: Dictionary = Skills.cost_for(skill_id)
	for resource in cost:
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
	return Adaptations.offerable_ids().filter(func(a): return adaptation_eligible(a))


func choose_adaptation(adaptation_id: String) -> bool:
	if not adaptation_eligible(adaptation_id):
		return false
	_adaptations[adaptation_id] = true
	return true


func chosen_adaptation_ids() -> Array:
	return _adaptations.keys()
