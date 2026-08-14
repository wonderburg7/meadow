extends Node
## Autoload. Frame-time instrumentation, built to find a 250ms frame
## rather than guess at it. See PERF_PLAN.md for why this exists and
## the order it was built in.
##
## Must be nearly free when off: every entry point checks
## Session.perf_enabled and returns before touching the clock, so a
## shipped build -- or a session where nobody has starred "fps" -- pays
## for one boolean read per call and nothing else.

# --- this frame's accumulators ---------------------------------------
## Section name -> time its `begin` was called, in usec. Cleared every
## frame regardless of whether it was matched, so a `begin` with no
## `end` shows up as a section whose time silently goes missing that
## frame rather than leaking into the next one.
var _open: Dictionary = {}
## Section name -> accumulated usec so far this frame. A section can be
## begun and ended more than once in a frame (e.g. "bee_path" once per
## bee that repaths); the totals just add up.
var _totals: Dictionary = {}
## One-off events this frame (Perf.mark), so a periodic sweep can be
## matched to the frame it fired on. Cleared every frame.
var marks: Array = []

# --- the rolling picture, read by the HUD breakdown -------------------
## Section name -> rolling average ms. Exponential smoothing rather
## than a proper window -- a dozen sections don't need more than that.
var averages: Dictionary = {}

# --- the plot's history ------------------------------------------------
const WINDOW_USEC := 250000   # 0.25s buckets, four points a second
const HISTORY_SLOTS := 120    # about 30 seconds
## Worst frame time in each window, oldest first. Grows to
## HISTORY_SLOTS then slides.
var frame_history: Array = []
## Bumped every time a new sample lands in frame_history, so the HUD's
## plot and its breakdown label can each notice on their own rather
## than racing to consume a single "new sample" flag.
var history_version: int = 0

var _window_worst_ms: float = 0.0
var _window_start_usec: int = 0
var _frame_start_usec: int = 0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

## Start timing a named section. Call from the top of the function
## being measured.
func begin(section: String) -> void:
	if not Session.perf_enabled:
		return
	_open[section] = Time.get_ticks_usec()

## Finish timing a named section. Must be called from the same
## function as the matching `begin` -- keep the pair adjacent, so a
## missing `end` is obvious in a diff rather than something that only
## shows up as a hole in the numbers later.
func end(section: String) -> void:
	if not Session.perf_enabled:
		return
	if not _open.has(section):
		return
	var elapsed: int = Time.get_ticks_usec() - int(_open[section])
	_totals[section] = int(_totals.get(section, 0)) + elapsed
	_open.erase(section)

## Record a one-off event, for spotting which periodic sweep fired on
## the frame that spiked.
func mark(label: String) -> void:
	if not Session.perf_enabled:
		return
	marks.append(label)

## The `n` sections with the highest rolling average, worst first. Used
## by the HUD breakdown line.
func top_sections(n: int) -> Array:
	var keys: Array = averages.keys()
	keys.sort_custom(func(a, b): return averages[a] > averages[b])
	return keys.slice(0, n)

func _process(_delta: float) -> void:
	if not Session.perf_enabled:
		# Dropped rather than carried over: re-enabling later shouldn't
		# attribute time from before the toggle to the first new frame.
		_totals.clear()
		_open.clear()
		marks.clear()
		_frame_start_usec = 0
		_window_start_usec = 0
		_window_worst_ms = 0.0
		return

	var now: int = Time.get_ticks_usec()
	if _frame_start_usec != 0:
		var frame_ms: float = float(now - _frame_start_usec) / 1000.0
		_window_worst_ms = max(_window_worst_ms, frame_ms)

		for section in _totals:
			var ms: float = _totals[section] / 1000.0
			if averages.has(section):
				averages[section] = lerpf(float(averages[section]), ms, 0.1)
			else:
				averages[section] = ms

		if _window_start_usec == 0:
			_window_start_usec = now
		elif now - _window_start_usec >= WINDOW_USEC:
			frame_history.append(_window_worst_ms)
			if frame_history.size() > HISTORY_SLOTS:
				frame_history.pop_front()
			history_version += 1
			_window_worst_ms = 0.0
			_window_start_usec = now

	_frame_start_usec = now
	_totals.clear()
	_open.clear()
	marks.clear()
