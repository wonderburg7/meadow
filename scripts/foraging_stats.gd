extends Node
## Foraging ecology plan, Slice 1: event-based trip accounting for
## foraging_panel.gd. A plain Node child of main, same pattern as
## orders_zones.gd/world_building.gd -- holds live aggregated counters
## for this run only, rebuilt fresh on every scene reload (Restart Run
## etc all go through get_tree().reload_current_scene(), which recreates
## main and everything under it, so there's no reset() to call).
##
## Fed entirely from BeeForaging._score_trip's existing call site --
## never scans the bee list itself, so the panel reading this can redraw
## as often as it likes without walking every bee. Only receives a
## "trip" once GameConfig.scouting_on or GameConfig.auto_recruitment_on
## is on, matching the existing gate around trip_start_time/
## trip_load_amount in bee_foraging.gd -- with both off, no trip is ever
## scored today, so there is nothing yet for this file to observe.
## See FORAGING_ECOLOGY_PLAN.md's Slice 1.

var trips_recorded: int = 0
var total_flowers_visited: int = 0
var total_search_flight_seconds: float = 0.0
var total_handling_seconds: float = 0.0
var total_trip_seconds: float = 0.0
var empty_returns: int = 0

## "resource_type|species" -> stats dictionary. "" species means no
## floral-constancy preference and not mid-scout-bout.
var _by_species: Dictionary = {}


## Called once per scored trip, from BeeForaging._score_trip. `species`
## is whatever species this trip was actually working (preferred_species
## if floral constancy has settled one, otherwise the in-progress
## scout_species, otherwise ""). `amount` is the trip's raw delivered
## load, the same value _score_trip already computed its rate from --
## an empty return is one that came back under min_worthwhile_amount,
## the same threshold collect() itself uses to decide a flower isn't
## worth lingering at.
func record_trip(resource_type: String, species: String, search_flight_seconds: float,
		handling_seconds: float, total_seconds: float, flowers_visited: int, amount: float) -> void:
	trips_recorded += 1
	total_flowers_visited += flowers_visited
	total_search_flight_seconds += search_flight_seconds
	total_handling_seconds += handling_seconds
	total_trip_seconds += total_seconds
	var is_empty: bool = amount < GameConfig.min_worthwhile_amount
	if is_empty:
		empty_returns += 1

	var key: String = "%s|%s" % [resource_type, species]
	if not _by_species.has(key):
		_by_species[key] = {
			"resource_type": resource_type,
			"species": species,
			"trips": 0,
			"flowers_visited": 0,
			"search_flight_seconds": 0.0,
			"handling_seconds": 0.0,
			"trip_seconds": 0.0,
			"empty_returns": 0,
		}
	var s: Dictionary = _by_species[key]
	s.trips += 1
	s.flowers_visited += flowers_visited
	s.search_flight_seconds += search_flight_seconds
	s.handling_seconds += handling_seconds
	s.trip_seconds += total_seconds
	if is_empty:
		s.empty_returns += 1


## Read by foraging_panel.gd's Species section. Sorted by trip count,
## busiest patch first, so the panel doesn't need its own sort logic.
func species_breakdown() -> Array:
	var rows: Array = _by_species.values()
	rows.sort_custom(func(a, b): return a.trips > b.trips)
	return rows
