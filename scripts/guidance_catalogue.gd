extends RefCounted
## Wording for the first diagnostic explanations. ColonyDiagnostics owns the
## facts; this catalogue only turns a supplied fact snapshot into copy.

const ENTRIES := {
	# FC-2 (plans/now/crisis-readiness.md): the first crisis's persistent
	# explanation, current while its heavy rain falls.
	"first_crisis_rain": {
		"title": "Heavy rain keeping foragers in",
		"evidence": "Rain at %d%% intensity. Foragers kept in by it: %d. Too low on energy to fly at all: %d.",
		"evidence_facts": ["rain_percent", "rain_grounded_foragers", "rain_unable_foragers"],
		"current_state": "Rain at %d%%; the stores feed the colony for about %d more minutes. %s",
		"state_facts": ["rain_percent", "food_cover_minutes"],
		"active_state": "Foragers are still kept in.",
		"cleared_state": "The heavy rain has passed; foragers can fly again.",
		"cause": "Heavy rain waters down the nectar in the open flowers and soaks the bees' wings, so a trip would cost more energy than it brings home. Past that point foragers stay at the hive. A forager who is low on energy cannot fly for that reason, rain or not.",
		"consequence": "Nothing is foraged while it lasts, so the colony eats from its stores, and they fall until the rain eases.",
		"responses": [
			"If the stores are low, keep indoor work light while it rains, and have foragers ready to go out as soon as it clears.",
			"If a forager is too low on energy to fly, let her refuel from the comb first; another job will not get her airborne sooner.",
		],
	},
	"missing_nurse_workforce": {
		"title": "Brood waiting for a nurse",
		"evidence": "%d brood cells waiting; %d nurses assigned.",
		"evidence_facts": ["brood_cells", "nurses"],
		"current_state": "%d brood cells; %d nurses assigned. %s",
		"state_facts": ["brood_cells", "nurses"],
		"active_state": "Still waiting for a nurse.",
		"cleared_state": "That shortage has cleared.",
		"cause": "There is brood to tend, but no bee is assigned to nursing. The queen may help, though she cannot cover every need indefinitely.",
		"consequence": "If feeding waits too long, the brood can starve before it grows.",
		"responses": [
			"If a worker can leave another job, assigning her to nursing gives the brood dedicated care, but slows that job.",
			"If workers are scarce, reduce competing work or wait for another bee to emerge; watch the brood meanwhile.",
		],
	},
	"missing_comb_workforce": {
		"title": "Cells waiting to be cleared",
		"evidence": "%d cells blocked by corpses; %d comb workers assigned.",
		"evidence_facts": ["blocked_cells", "comb_workers"],
		"current_state": "%d blocked cells; %d comb workers assigned. %s",
		"state_facts": ["blocked_cells", "comb_workers"],
		"active_state": "Still waiting for a comb worker.",
		"cleared_state": "That shortage has cleared.",
		"cause": "Dead bees occupy cells, but no bee is assigned to comb work to clear them.",
		"consequence": "Those cells stay unavailable, and leaving corpses in the comb raises disease pressure.",
		"responses": [
			"If a worker can leave another job, assigning her to comb work clears cells at the cost of that job's progress.",
			"If other work is urgent, leave the cells for now and revisit the assignment before the blockage spreads.",
		],
	},
	"hungry_brood": {
		"title": "Brood without food",
		"evidence": "%d brood cells unfed.",
		"evidence_facts": ["hungry_brood"],
		"current_state": "%d brood cells unfed. %s",
		"state_facts": ["hungry_brood"],
		"active_state": "Those cells still need feeding.",
		"cleared_state": "That shortage has cleared.",
		"cause": "The counter can see brood without food, but not whether the trouble is stores, workers, or a delayed journey.",
		"consequence": "If feeding waits too long, those larvae can starve before they grow.",
		"responses": [
			"If food and a nurse are available, directing a worker to nursing can feed the brood, but leaves her other job slower.",
			"If workers or stores are scarce, reduce competing work and watch the cells while you decide what the colony can spare.",
		],
	},
	"starving": {
		"title": "Bees running out of energy",
		"evidence": "%d bees below 15%% energy.",
		"evidence_facts": ["starving"],
		"current_state": "%d bees below 15%% energy. %s",
		"state_facts": ["starving"],
		"active_state": "Those bees need energy soon.",
		"cleared_state": "That shortage has cleared.",
		"cause": "The counter can see low energy, but not whether a route ran dry, weather delayed a flight, or another demand kept bees moving.",
		"consequence": "Without a chance to refuel, those bees may starve before they can return to useful work.",
		"responses": [
			"If forage or stored food is reachable, let the bees refuel first; that delays the work they were doing.",
			"If food is not ready, move a healthy worker from less urgent work to secure it, accepting that the other job will slow.",
		],
	},
}

static func supported_ids() -> Array[String]:
	return ["first_crisis_rain", "missing_nurse_workforce", "missing_comb_workforce", "hungry_brood", "starving"]

static func explanation(fact_id: String, facts: Dictionary) -> Dictionary:
	if not ENTRIES.has(fact_id):
		return {}
	var data: Dictionary = ENTRIES[fact_id]
	var evidence := _fact_line(data.evidence, data.evidence_facts, facts)
	var text := "%s\n%s\n%s\n\n%s\n%s" % [
		evidence, data.cause, data.consequence,
		data.responses[0], data.responses[1],
	]
	return {"id": fact_id, "title": data.title, "evidence": evidence, "text": text}

static func current_state(fact_id: String, facts: Dictionary) -> String:
	if not ENTRIES.has(fact_id):
		return ""
	var data: Dictionary = ENTRIES[fact_id]
	var values := _fact_values(data.state_facts, facts)
	values.append(data.active_state if int(facts.get(fact_id, 0)) > 0 else data.cleared_state)
	return data.current_state % values

static func _fact_line(pattern: String, fact_ids: Array, facts: Dictionary) -> String:
	return pattern % _fact_values(fact_ids, facts)

static func _fact_values(fact_ids: Array, facts: Dictionary) -> Array:
	var values: Array = []
	for fact_id in fact_ids:
		values.append(int(facts.get(fact_id, 0)))
	return values
