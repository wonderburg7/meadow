extends RefCounted
## Crab spiders -- ambush predators that sit motionless on one flower of
## whichever species this run has rolled as dangerous. See
## CRAB_SPIDER_PLAN.md for the full design and biology this is grounded
## in. Built in bundles; this file grows one function per bundle -- see
## the plan's "Implementation bundles" section.
##
## Usage: const CrabSpider = preload("res://scripts/crab_spider.gd")
##        CrabSpider.maybe_spawn(flower)
##
## Plain static functions that take a flower/bee node and act on it,
## same shape as bee_survival.gd/bee_foraging.gd/roles.gd -- see the
## plan's "Architecture" section for why this is its own file rather
## than logic folded into flower.gd/bee_foraging.gd directly.

const BeeEnums = preload("res://scripts/bee_enums.gd")
const FlowerSpecies = preload("res://scripts/flower_species.gd")
const ProblemMessages = preload("res://scripts/problem_messages.gd")
## flower.gd preloads this file, so this file must not preload flower.gd
## back (that would close a compile-time cycle) -- but flower_species.gd
## is a plain data file with no dependency on flower.gd, so preloading
## it here is safe.

## Called wherever a flower is created (world-seed and regrowth alike).
## Rolls this run's preferred species the first time it's needed, then
## gives a flower of that species a small chance of carrying a spider.
## No-op while predators are off, and for every flower of any other
## species -- so this costs nothing for the vast majority of flowers.
static func maybe_spawn(flower: Node2D) -> void:
	if not GameConfig.predators_on:
		return
	if Session.crab_spider_preferred_species == "":
		Session.crab_spider_preferred_species = FlowerSpecies.roll_preferred_species()
	if flower.species_name != Session.crab_spider_preferred_species:
		return
	if randf() >= GameConfig.crab_spider_flower_fraction:
		return
	flower.has_crab_spider = true
	flower.crab_spider_settled_at = Session.sim_time

## Called every frame from flower.gd::_process(). Guarded so it costs
## essentially nothing for the great majority of flowers that never
## carry a spider -- see CRAB_SPIDER_PLAN.md section 3.
static func update(flower: Node2D, _delta: float) -> void:
	if not flower.has_crab_spider:
		return
	if Session.sim_time - flower.crab_spider_settled_at >= GameConfig.crab_spider_residency_seconds:
		relocate(flower, true)

## Called when a flower's spider's residency is up, or when that flower
## is about to die with a spider still on it. Hands the spider to a new
## flower of the same species rather than letting it vanish -- real
## spiders relocate rather than starve on a spent patch. `show_departure`
## is false when called from the dying-flower path, since that flower is
## being freed the same frame anyway and a flash there would be
## invisible.
static func relocate(flower: Node2D, show_departure: bool) -> void:
	if show_departure:
		flower.crab_spider_reveal_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds
	flower.has_crab_spider = false
	var candidates: Array = []
	for f in flower.get_tree().get_nodes_in_group("flowers"):
		if f == flower or not is_instance_valid(f) or f.has_crab_spider:
			continue
		if f.species_name != flower.species_name or not f.in_season():
			continue
		candidates.append(f)
	if candidates.is_empty():
		# Nowhere to go -- this spider is lost, much as a real one that
		# can't find fresh hunting ground eventually isn't found again.
		# The rarity spawn roll (maybe_spawn, above) keeps numbers up
		# over time without this needing to guarantee a home.
		return
	var new_home: Node2D = candidates[randi() % candidates.size()]
	new_home.has_crab_spider = true
	new_home.crab_spider_settled_at = Session.sim_time
	new_home.crab_spider_reveal_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds


## Called from BeeForaging.start_collecting() the instant a bee actually
## starts feeding at a spider's flower -- landing and inspecting are
## still safe, this is the only risk in the whole mechanic. Marks the
## flower as alarmed either way (a miss is still worth fleeing from, per
## the biology this is grounded in -- see CRAB_SPIDER_PLAN.md section 5).
## Returns true if the bee is still alive and should carry on into
## State.COLLECTING as normal; false if she died (BeeSurvival.die already
## handled everything) or escaped (caller must not enter State.COLLECTING,
## resolve_attack already moved her back to State.SEEK_FLOWER).
static func resolve_attack(bee: Node2D) -> bool:
	var flower: Node2D = bee.current_flower
	flower.crab_spider_alarm_at = Session.sim_time
	flower.crab_spider_reveal_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds
	if randf() < GameConfig.crab_spider_attack_success_chance:
		# Logged here, not left to BeeSurvival.log_death alone -- the death
		# log doesn't carry which species/flower it happened at, and this
		# is the one place that context still exists. die() itself still
		# calls log_death as normal straight after.
		DiagnosticLog.log_crab_spider_event(bee, flower, "kill")
		load("res://scripts/bee_survival.gd").die(bee, "crab spider ambush")
		return false
	# Escaped -- a much longer cooldown on this exact flower than an
	# ordinary rejection gets, and a snapshot of where/what she was
	# foraging at the time for recruitment suppression (Bundle 3).
	DiagnosticLog.log_crab_spider_event(bee, flower, "escape")
	# Visible even without alarm_pheromone_on -- see bee.gd's
	# attack_flash_until field comment for why this is a separate signal
	# from alarm_ring rather than reusing it.
	bee.attack_flash_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds
	# predator_flower_cooldowns, not flower_cooldowns -- this needs to
	# survive nearest_flower()'s scarcity fallback, unlike an ordinary
	# rejection. See bee.gd's field comment.
	bee.predator_flower_cooldowns[flower] = Session.sim_time + GameConfig.crab_spider_escape_cooldown_seconds
	bee.was_attacked_by_predator = true
	bee.attacked_at_start_point = bee.forage_start_point
	bee.attacked_at_preferred_species = bee.preferred_species
	flower.release(bee)
	bee.current_flower = null
	bee.state = BeeEnums.State.SEEK_FLOWER
	_announce_escape(bee)
	return false


## Throttled the same way BeeSurvival._announce_death throttles epitaphs,
## arbitrated at the channel (see UI-Q-1 in plans/now/ui.md) -- a bad patch
## of near-misses shouldn't spam the corner.
static func _announce_escape(bee: Node2D) -> void:
	if bee.world == null or not is_instance_valid(bee.world):
		return
	bee.world.hud.show_warning(
		ProblemMessages.crab_spider_escape(bee.bee_name),
		"crab_spider_escape", GameConfig.crab_spider_escape_min_gap, bee.world.hud.SEVERITY_DANGER
	)


## Whether `bee` should be held back from becoming an entrance mentor
## because she's still pointing recruits towards wherever she was
## attacked. Not a one-off flag -- it's a live comparison against the
## snapshot resolve_attack took, so it lifts on its own the moment either
## her forage_start_point or her preferred_species (both routinely
## rewritten elsewhere -- re-scouting, being mentored herself, an
## entrance-wait timeout) no longer match what they were at the attack.
## See CRAB_SPIDER_PLAN.md section 6 for why comparison beats a
## clear-the-flag hook at every one of those sites.
static func recruitment_suppressed(bee: Node2D) -> bool:
	if not (GameConfig.crab_spider_recruit_suppression_on and bee.was_attacked_by_predator):
		return false
	return bee.forage_start_point == bee.attacked_at_start_point \
		and bee.preferred_species == bee.attacked_at_preferred_species


## Placeholder for a future skill-tree unlock (see CRAB_SPIDER_PLAN.md
## section 5) -- while `alarm_pheromone_on`, a bee that reaches
## State.INSPECTING at a flower another bee was recently attacked at
## (hit or miss) notices and leaves before ever risking State.COLLECTING
## there. `crab_spider_alarm_at` is set by resolve_attack() regardless of
## outcome, since a miss is still worth fleeing from.
static func is_alarmed(flower: Node2D) -> bool:
	return Session.sim_time - flower.crab_spider_alarm_at < GameConfig.crab_spider_alarm_marker_seconds

## Called from BeeForaging.inspect()/drink_at_flower() the moment
## worth_feeding() turns a bee away from an alarmed flower under
## alarm_pheromone_on -- the caller still has to call reject_flower()
## itself afterwards, this only handles the reaction: a brief flash on
## the bee herself (see bee.gd's alarm_ring) so the moment is visible,
## same treatment an attack/relocation gives the flower (section 7), and
## a diagnostic log line so the mechanic leaves evidence of firing.
static func flee_alarm(bee: Node2D, flower: Node2D) -> void:
	bee.alarm_flash_until = Session.sim_time + GameConfig.crab_spider_reveal_seconds
	DiagnosticLog.log_crab_spider_event(bee, flower, "alarm_flee")
