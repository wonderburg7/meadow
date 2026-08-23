extends Label
## Two lines under the plot, same 4Hz cadence, driven by the same
## version counter so neither falls out of step with the other:
##   - the top eight instrumented sections by rolling average -- good
##     for a steady cost, answers "which process correlates with the
##     drop" at a glance without opening the debug panel;
##   - the section breakdown of the single worst frame in the most
##     recently closed window -- unsmoothed, so it actually explains a
##     one-off spike the average line can't. A 60ms frame barely nudges
##     a 0.1-lerp average; it fully appears here.
##
## Widened from five to eight partway through the investigation (Dave
## noted the list keeps changing as sections get split further) and
## wrapped rather than left to overflow, since eight names no longer
## reliably fits on one line.

const SHOWN := 8

var _last_version: int = -1

func _ready() -> void:
	add_theme_font_size_override("font_size", 11)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	custom_minimum_size = Vector2(140, 0)

func _process(_delta: float) -> void:
	if not visible:
		return
	if Perf.history_version == _last_version:
		return
	_last_version = Perf.history_version
	var parts: Array = []
	for key in Perf.top_sections(SHOWN):
		parts.append("%s %dms" % [key, roundi(float(Perf.averages[key]))])
	var lines: Array = ["  ·  ".join(parts)]

	var worst_parts: Array = []
	for key in Perf.worst_sections(SHOWN):
		worst_parts.append("%s %dms" % [key, roundi(float(Perf.last_worst_breakdown[key]))])
	if not worst_parts.is_empty():
		lines.append("worst frame (%dms): %s" % [roundi(Perf.last_worst_ms), "  ·  ".join(worst_parts)])

	# p95 across the plotted window-worst samples -- the average line
	# hides a frame-in-twenty spike, and the worst-frame line only ever
	# shows the single worst one; this is the middle ground, "how bad
	# does it get regularly" rather than "on average" or "at its worst
	# ever seen".
	if not Perf.frame_history.is_empty():
		lines.append("p95 worst-frame: %dms" % roundi(Perf.percentile_ms(0.95)))
	text = "\n".join(lines)
