extends RefCounted
## Wording for the first diagnostic explanations. ColonyDiagnostics owns the
## facts; this catalogue only turns a supplied fact snapshot into copy.

const ENTRIES := {
	"missing_nurse_workforce": {
		"title": "Brood waiting for a nurse",
		"cause": "There is brood to tend, but no bee is assigned to nursing. The queen may help, though she cannot cover every need indefinitely.",
		"consequence": "If feeding waits too long, the brood can starve before it grows.",
		"responses": [
			"If a worker can leave another job, assigning her to nursing gives the brood dedicated care, but slows that job.",
			"If workers are scarce, reduce competing work or wait for another bee to emerge; watch the brood meanwhile.",
		],
	},
	"missing_comb_workforce": {
		"title": "Cells waiting to be cleared",
		"cause": "Dead bees occupy cells, but no bee is assigned to comb work to clear them.",
		"consequence": "Those cells stay unavailable, and leaving corpses in the comb raises disease pressure.",
		"responses": [
			"If a worker can leave another job, assigning her to comb work clears cells at the cost of that job's progress.",
			"If other work is urgent, leave the cells for now and revisit the assignment before the blockage spreads.",
		],
	},
}

static func supported_ids() -> Array[String]:
	return ["missing_nurse_workforce", "missing_comb_workforce"]

static func explanation(fact_id: String, facts: Dictionary) -> Dictionary:
	if not ENTRIES.has(fact_id):
		return {}
	var data: Dictionary = ENTRIES[fact_id]
	var evidence := ""
	if fact_id == "missing_nurse_workforce":
		evidence = "%d brood cells waiting; %d nurses assigned." % [int(facts.get("brood_cells", 0)), int(facts.get("nurses", 0))]
	else:
		evidence = "%d cells blocked by corpses; %d comb workers assigned." % [int(facts.get("blocked_cells", 0)), int(facts.get("comb_workers", 0))]
	var text := "%s\n%s\n%s\n\n%s\n%s" % [
		evidence, data.cause, data.consequence,
		data.responses[0], data.responses[1],
	]
	return {"id": fact_id, "title": data.title, "evidence": evidence, "text": text}

static func current_state(fact_id: String, facts: Dictionary) -> String:
	if fact_id == "missing_nurse_workforce":
		return "%d brood cells; %d nurses assigned. %s" % [
			int(facts.get("brood_cells", 0)), int(facts.get("nurses", 0)),
			"Still waiting for a nurse." if int(facts.get(fact_id, 0)) > 0 else "That shortage has cleared.",
		]
	if fact_id == "missing_comb_workforce":
		return "%d blocked cells; %d comb workers assigned. %s" % [
			int(facts.get("blocked_cells", 0)), int(facts.get("comb_workers", 0)),
			"Still waiting for a comb worker." if int(facts.get(fact_id, 0)) > 0 else "That shortage has cleared.",
		]
	return ""
