extends RefCounted
## One run's availability sheet: for every skill, whether the run starts
## owning it, leaves it to be bought in the tree, or does not offer it at
## all -- and why (plans/now/brood-spine.md, BS-1).
##
## Usage: const RunAvailability = preload("res://scripts/run_availability.gd")
##        var sheet := RunAvailability.sheet_for(Levels.get_level(Session.starting_level))
##        Session.ensure_progression(stage_gate).begin_run(sheet)
##
## Derived, never authored: it reads the run definition (a levels.gd entry
## or a scenario's JSON, both through Levels.get_level), skills.gd and
## roles.gd. main.gd computes it once per run start and hands it to
## progression.gd::begin_run(); nothing else computes starting ownership,
## and nothing here answers "is this owned" -- progression.gd does.
##
## Brood-spine decision 2, "seeding implies owning": a run that starts with
## bees in a gated role -- a non-zero `nurses`/`honey_makers` count, or the
## role `queen_laying_backup` names (Challenge 1's queen) -- starts owning
## that role's skill (roles.gd's `skill`). The run's `skill_grants` are
## owned from the start as well as permitted. A `skill_bans` entry wins
## over both, the same reading progression.gd::is_permitted() gives
## contradictory data.
##
## Columns still to come, each in its own slice: "introduced at stage" and
## "free at stage", from challenge_stages.gd (BS-2); feature rows and a
## feature-driven "unavailable" (BS-5, through progression.gd's
## feature_valid(), since only the resolver reads features.gd).
##
## Sheet shape:
##   "skills":   skill id -> {"source": SOURCE_*, "reason": REASON_*}
##   "starting": skill ids the run starts owning (never a baseline one --
##               the resolver owns those anyway)
##   "grants"/"bans"/"delays": the run's skill policy, as levels.gd names it

const Skills = preload("res://scripts/skills.gd")
const Roles = preload("res://scripts/roles.gd")

const SOURCE_START := "start"
const SOURCE_TREE := "tree"
const SOURCE_UNAVAILABLE := "unavailable"

## Keys rather than sentences, the same as progression.gd's blockers: the
## developer table (BS-5) turns them into text.
const REASON_BASELINE := "reason.baseline"
const REASON_RUN_GRANT := "reason.run_grant"
const REASON_SEEDED_ROLE := "reason.seeded_role"
const REASON_RUN_BAN := "reason.run_ban"
const REASON_TREE := "reason.tree"

## levels.gd's starting-count key for each role that has a skill. A newly
## gated role adds its count key here; sheet_for() reports one missing.
const SEED_COUNT_KEYS := {
	Roles.NURSE: "nurses",
	Roles.HONEY: "honey_makers",
}


static func sheet_for(run_definition: Dictionary) -> Dictionary:
	var bans: Array = run_definition.get("skill_bans", [])
	var grants: Array = run_definition.get("skill_grants", [])
	var seeded := _seeded_skills(run_definition)
	var rows := {}
	for skill_id in Skills.ids():
		if bans.has(skill_id):
			rows[skill_id] = {"source": SOURCE_UNAVAILABLE, "reason": REASON_RUN_BAN}
		elif Skills.is_baseline(skill_id):
			rows[skill_id] = {"source": SOURCE_START, "reason": REASON_BASELINE}
		elif grants.has(skill_id):
			rows[skill_id] = {"source": SOURCE_START, "reason": REASON_RUN_GRANT}
		elif seeded.has(skill_id):
			rows[skill_id] = {"source": SOURCE_START, "reason": REASON_SEEDED_ROLE}
		else:
			rows[skill_id] = {"source": SOURCE_TREE, "reason": REASON_TREE}
	var starting := []
	for skill_id in rows:
		if rows[skill_id].source == SOURCE_START and rows[skill_id].reason != REASON_BASELINE:
			starting.append(skill_id)
	return {
		"skills": rows,
		"starting": starting,
		"grants": grants,
		"bans": bans,
		"delays": run_definition.get("skill_delays", {}),
	}


## The skills this run starts owning: its `skill_grants` plus the skill of
## every role it seeds, less any it bans.
static func starting_skills(run_definition: Dictionary) -> Array:
	return sheet_for(run_definition).starting


## Skill id -> true for every gated role the run definition puts bees in.
static func _seeded_skills(run_definition: Dictionary) -> Dictionary:
	var seeded := {}
	for role in Roles.ROLES:
		if role.skill == "":
			continue
		if not SEED_COUNT_KEYS.has(role.id):
			push_error("run_availability.gd: role %s has a skill but no SEED_COUNT_KEYS entry" % role.key)
			continue
		if int(run_definition.get(SEED_COUNT_KEYS[role.id], 0)) > 0:
			seeded[role.skill] = true
	var backup_skill := Roles.skill_for(Roles.id_for_key(str(run_definition.get("queen_laying_backup", ""))))
	if backup_skill != "":
		seeded[backup_skill] = true
	return seeded
