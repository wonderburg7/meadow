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
	for fact_id: String in Catalogue.supported_ids():
		if int(facts.get(fact_id, 0)) > 0 and not _shown.has(fact_id):
			return fact_id
	return ""

func current_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for fact_id: String in Catalogue.supported_ids():
		if int(facts.get(fact_id, 0)) > 0:
			entries.append(Catalogue.explanation(fact_id, facts))
	return entries

func shown_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for fact_id: Variant in _order:
		entries.append(_shown[fact_id].duplicate(true))
	return entries

## The facts are freshly diagnosed after a load. The rendered explanations,
## however, are this run's ledger: retain their contemporary evidence so Why
## can still explain what the player was shown after that condition has passed.
func save_data() -> Dictionary:
	return {"shown": _shown.duplicate(true), "order": _order.duplicate()}

## Guidance was added after saves already existed, so an absent or malformed
## block deliberately restores an empty ledger rather than replaying a line.
func restore(data: Dictionary) -> void:
	_shown.clear()
	_order.clear()
	var saved_shown: Variant = data.get("shown", {})
	var saved_order: Variant = data.get("order", [])
	if typeof(saved_shown) != TYPE_DICTIONARY or typeof(saved_order) != TYPE_ARRAY:
		return
	for value: Variant in saved_order:
		var fact_id := str(value)
		var entry: Variant = saved_shown.get(fact_id)
		if fact_id.is_empty() or _shown.has(fact_id) or typeof(entry) != TYPE_DICTIONARY:
			continue
		_shown[fact_id] = entry.duplicate(true)
		_order.append(fact_id)
		if _order.size() > HISTORY_LIMIT:
			_shown.erase(_order.pop_front())

func mark_rendered(entry: Dictionary) -> void:
	var fact_id: String = str(entry.get("id", ""))
	if fact_id.is_empty() or _shown.has(fact_id):
		return
	_shown[fact_id] = entry.duplicate(true)
	_order.append(fact_id)
	if _order.size() > HISTORY_LIMIT:
		_shown.erase(_order.pop_front())
