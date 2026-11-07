extends Control
## A presentation-only clock: simulation time is the sole source of its hand.

func _init() -> void:
	custom_minimum_size = Vector2(26, 16)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func day_fraction() -> float:
	return fposmod(Session.sim_time, GameConfig.seconds_per_day) / GameConfig.seconds_per_day


func _draw() -> void:
	var centre := Vector2(size.x / 2.0, 14.0)
	var radius := 11.0
	var colour := Color(0.9, 0.9, 0.9)
	draw_arc(centre, radius, PI, TAU, 24, colour, 1.5, true)
	var angle := PI + PI * day_fraction()
	draw_line(centre, centre + Vector2(cos(angle), sin(angle)) * radius, colour, 1.5, true)
