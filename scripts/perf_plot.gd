extends Control
## The frame-time plot: bars, not a line, because a single bad frame is
## exactly what a line chart smooths away and exactly what this exists
## to catch. Added under the fps readout in hud.gd's corner_column when
## "fps" is starred.
##
## Keeps no state of its own beyond "which history sample have I
## already drawn" -- everything else is read straight from Perf, which
## is the thing being measured, not this.

const GOOD_MS := 16.7   # 60fps
const WARN_MS := 33.0   # 30fps

var _last_version: int = -1

## Redraws at most four times a second, driven by Perf.history_version
## rather than every frame -- a plot that redrew every frame would be
## part of the problem it is meant to measure.
func _process(_delta: float) -> void:
	if not visible:
		return
	if Perf.history_version == _last_version:
		return
	_last_version = Perf.history_version
	queue_redraw()

func _draw() -> void:
	var history: Array = Perf.frame_history
	if history.is_empty():
		return
	var w: float = size.x
	var h: float = size.y

	# Autoscaled with a floor at the 30fps line, so a quiet stretch
	# doesn't blow the bars up to fill the plot on nothing but noise.
	var worst: float = WARN_MS
	for ms in history:
		worst = max(worst, ms)

	var bar_w: float = w / float(Perf.HISTORY_SLOTS)
	for i in history.size():
		var ms: float = history[i]
		var bar_h: float = clampf(ms / worst, 0.0, 1.0) * h
		var colour := Color(0.35, 0.75, 0.4)
		if ms > WARN_MS:
			colour = Color(0.85, 0.3, 0.3)
		elif ms > GOOD_MS:
			colour = Color(0.85, 0.7, 0.3)
		var x: float = i * bar_w
		draw_rect(Rect2(x, h - bar_h, max(1.0, bar_w - 1.0), bar_h), colour)

	draw_line(Vector2(0, h - (GOOD_MS / worst) * h), Vector2(w, h - (GOOD_MS / worst) * h), Color(1, 1, 1, 0.25))
	draw_line(Vector2(0, h - (WARN_MS / worst) * h), Vector2(w, h - (WARN_MS / worst) * h), Color(1, 1, 1, 0.25))
