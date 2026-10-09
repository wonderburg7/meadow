extends Node2D
## T2-4b: the body of a bee who died inside the hive.
##
## Lies on the floor where she fell, blocking no cell, until a Comb worker
## who owns Cleaning carries it out through the waste exit (bee_building.gd,
## the same walk a dead larva takes). Until then it counts towards disease at
## a dead larva's rate (season.gd::_advance_disease). A bee who dies in the
## meadow leaves none; winter's dead are laid inside the entrance
## (season.gd::_resolve_winter), so they lie there at spring.
##
## hive.gd holds every body in one list, `bodies`, oldest first, and is the
## only thing that creates or frees one. The list changes on a death, a
## clear, the cap (GameConfig.max_hive_bodies) or a restore -- never per
## frame -- and this node does no per-frame work of its own.
##
## Not death_marker.gd: that mark is presentation only and fades. This is
## simulation state, saved with the run (save_game.gd's "hive" block).

const State = preload("res://scripts/bee_enums.gd").State

## Session.sim_time at the moment she died. Saved, and what makes "oldest"
## mean the same thing after a load.
var died_at: float = 0.0
## Seconds a Comb worker has spent lifting this body, against
## GameConfig.cell_clean_time (the same time a dead larva takes).
var clear_progress: float = 0.0
## The Comb worker on her way to, or lifting, this body. Only one carries
## a body, so a second idle worker looks for another. Read through
## is_claimed(), which treats an interrupted or dead claimant as no claim.
var claimant: Node2D = null


func _ready() -> void:
	z_index = 1   # on the floor, under live bees
	queue_redraw()


func _draw() -> void:
	# A small curled bee lying on her side: dark, unmoving, legible as a
	# body at hive zoom without a cross like the death marker's.
	draw_circle(Vector2(-2.5, 0.0), 2.6, Color(0.22, 0.17, 0.10, 0.9))
	draw_circle(Vector2(1.5, 0.5), 3.2, Color(0.30, 0.24, 0.12, 0.9))
	draw_line(Vector2(0.6, -2.4), Vector2(0.6, 3.2), Color(0.12, 0.10, 0.08, 0.9), 1.0)
	draw_line(Vector2(2.6, -2.4), Vector2(2.6, 3.2), Color(0.12, 0.10, 0.08, 0.9), 1.0)


## Whether a Comb worker is still on this job. One who was interrupted
## (fed, reassigned) or died has moved on, so the body is free again.
func is_claimed() -> bool:
	if claimant == null or not is_instance_valid(claimant) or claimant.is_dying:
		return false
	if claimant.target_body != self:
		return false
	return claimant.state == State.TO_CLEAN_CELL or claimant.state == State.CLEANING
