extends Label
## The top eight instrumented sections by rolling average, shown under
## the plot. Answers "which process correlates with the drop" at a
## glance, without opening the debug panel. Same 4Hz cadence as the
## plot, driven by the same version counter so the two never fall out
## of step with each other.
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
	text = "  ·  ".join(parts)
