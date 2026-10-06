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
## Given the run's progression (the developer table does; main.gd's run
## start does not need to), a skill the tree would offer but whose feature is
## off in this run is "unavailable", and each feature a skill depends on gets
## a row -- both through progression.gd's feature_valid(), since only the
## resolver reads features.gd (BS-5). Never changes what a run starts owning.
## The developer table's "introduced at stage" and "free at stage" columns
## are answered here too, by introduced_stage() and free_stages(), read from
## challenge_stages.gd's two stage lists.
##
## Sheet shape:
##   "skills":   skill id -> {"source": SOURCE_*, "reason": REASON_*}
##   "roles":    skill-gated role key -> {"skill": id, "source", "reason"},
##               the same answer as that skill's row
##   "features": feature id -> {"source": start/unavailable, "reason"}, empty
##               without a progression
##   "starting": skill ids the run starts owning (never a baseline one --
##               the resolver owns those anyway)
##   "grants"/"bans"/"delays": the run's skill policy, as levels.gd names it

const Skills = preload("res://scripts/skills.gd")
const Roles = preload("res://scripts/roles.gd")
const Stages = preload("res://scripts/challenge_stages.gd")

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
const REASON_CUT := "reason.cut"
const REASON_FEATURE_OFF := "reason.feature_off"
const REASON_FEATURE_ON := "reason.feature_on"

static func sheet_for(run_definition: Dictionary, progression = null) -> Dictionary:
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
		elif Skills.is_cut(skill_id):
			rows[skill_id] = {"source": SOURCE_UNAVAILABLE, "reason": REASON_CUT}
		elif progression != null and not progression.feature_valid(skill_id):
			rows[skill_id] = {"source": SOURCE_UNAVAILABLE, "reason": REASON_FEATURE_OFF}
		else:
			rows[skill_id] = {"source": SOURCE_TREE, "reason": REASON_TREE}
	var starting := []
	for skill_id in rows:
		if rows[skill_id].source == SOURCE_START and rows[skill_id].reason != REASON_BASELINE:
			starting.append(skill_id)
	return {
		"skills": rows,
		"roles": _role_rows(rows),
		"features": _feature_rows(progression),
		"starting": starting,
		"grants": grants,
		"bans": bans,
		"delays": run_definition.get("skill_delays", {}),
	}


## The id of the first Challenge stage whose cumulative `unlocked_keys` name
## this skill ("2.5" for Nurses), or "" when no stage does.
static func introduced_stage(skill_id: String) -> String:
	for stages in [Stages.STAGES_1, Stages.STAGES_2]:
		for stage in stages:
			for entry in stage.get("unlocked_keys", []):
				var key: String = str(entry.get("key", "")) if entry is Dictionary else str(entry)
				if key == skill_id:
					return str(stage.id)
	return ""


## The ids of the Challenge stages whose `free_skills` name this skill, in
## order; empty when none does.
static func free_stages(skill_id: String) -> Array:
	var found := []
	for stages in [Stages.STAGES_1, Stages.STAGES_2]:
		for stage in stages:
			if stage.get("free_skills", []).has(skill_id):
				found.append(str(stage.id))
	return found


## A skill's display name, for the developer table, which may not read
## skills.gd itself (tests/source_checks.py's CATALOGUE_READERS).
static func skill_label(skill_id: String) -> String:
	return Skills.label_for(skill_id)


## One row per role a skill unlocks, answering as that skill's row does.
static func _role_rows(skill_rows: Dictionary) -> Dictionary:
	var roles := {}
	for role in Roles.ROLES:
		if role.skill != "" and skill_rows.has(role.skill):
			var row: Dictionary = skill_rows[role.skill]
			roles[role.key] = {"skill": role.skill, "source": row.source, "reason": row.reason}
	return roles


## One row per feature some skill depends on, on or off in this run as
## progression.feature_valid() judges that skill. Empty with no progression.
static func _feature_rows(progression) -> Dictionary:
	var features := {}
	if progression == null:
		return features
	for skill_id in Skills.ids():
		var feature: String = Skills.entry(skill_id).get("feature", "")
		if feature == "" or features.has(feature):
			continue
		var on: bool = progression.feature_valid(skill_id)
		features[feature] = {
			"source": SOURCE_START if on else SOURCE_UNAVAILABLE,
			"reason": REASON_FEATURE_ON if on else REASON_FEATURE_OFF,
		}
	return features


## The skills this run starts owning: its `skill_grants` plus the skill of
## every role it seeds, less any it bans.
static func starting_skills(run_definition: Dictionary) -> Array:
	return sheet_for(run_definition).starting


## Skill id -> true for every gated role the run definition puts bees in.
static func _seeded_skills(run_definition: Dictionary) -> Dictionary:
	var seeded := {}
	for role in Roles.ROLES:
		if role.skill == "" or role.start_count_key == "":
			continue
		if int(run_definition.get(role.start_count_key, 0)) > 0:
			seeded[role.skill] = true
	var backup_skill := Roles.skill_for(Roles.id_for_key(str(run_definition.get("queen_laying_backup", ""))))
	if backup_skill != "":
		seeded[backup_skill] = true
	return seeded
