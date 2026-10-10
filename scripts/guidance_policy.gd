extends RefCounted
## The one owner of diagnostic guidance eligibility and shown-in-this-run
## history. A fact is consumed only after its explanation reaches a view.

const Catalogue = preload("res://scripts/guidance_catalogue.gd")
const HISTORY_LIMIT := 20

var facts: Dictionary = {}
var _shown: Dictionary = {}
var _order: Array[String] = []

func update_facts(snapshot: Dictionary) -> void:
	facts = snapshot.duplicate(true)

func eligible_id() -> String:
	for fact_id in Catalogue.supported_ids():
		if int(facts.get(fact_id, 0)) > 0 and not _shown.has(fact_id):
			return fact_id
	return ""

func current_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for fact_id in Catalogue.supported_ids():
		if int(facts.get(fact_id, 0)) > 0:
			entries.append(Catalogue.explanation(fact_id, facts))
	return entries

func shown_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for fact_id in _order:
		entries.append(_shown[fact_id].duplicate(true))
	return entries

func mark_rendered(entry: Dictionary) -> void:
	var fact_id: String = str(entry.get("id", ""))
	if fact_id.is_empty() or _shown.has(fact_id):
		return
	_shown[fact_id] = entry.duplicate(true)
	_order.append(fact_id)
	if _order.size() > HISTORY_LIMIT:
		_shown.erase(_order.pop_front())
