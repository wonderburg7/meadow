extends Label
## The top five instrumented sections by rolling average, shown under
## the plot. Answers "which process correlates with the drop" at a
## glance, without opening the debug panel. Same 4Hz cadence as the
## plot, driven by the same version counter so the two never fall out
## of step with each other.

var _last_version: int = -1

func _ready() -> void:
	add_theme_font_size_override("font_size", 11)

func _process(_delta: float) -> void:
	if not visible:
		return
	if Perf.history_version == _last_version:
		return
	_last_version = Perf.history_version
	var parts: Array = []
	for key in Perf.top_sections(5):
		parts.append("%s %dms" % [key, roundi(float(Perf.averages[key]))])
	text = "  ·  ".join(parts)
