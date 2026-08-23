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
## Good for a steady cost (fog's per-frame draw, say); close to useless
## for a one-off spike, since a single 60ms frame barely nudges a
## 0.1-lerp average -- see `last_worst_breakdown` below for that case.
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

## The worst single frame's own section breakdown, from the most
## recently closed window -- a raw snapshot, not smoothed, so it
## actually shows what was running during the frame that made
## `frame_history`'s number, not an average diluted across many others.
## This is what `frame_history`'s plot has never been able to explain by
## itself: the plot says *when* a spike happened, this says *what was
## running* when it did. Section name -> ms.
var last_worst_ms: float = 0.0
var last_worst_breakdown: Dictionary = {}

var _window_worst_ms: float = 0.0
## `_totals` as of the moment `_window_worst_ms` was last raised this
## window -- becomes `last_worst_breakdown` when the window closes.
var _window_worst_totals: Dictionary = {}
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

## The `n` sections with the highest share of the last worst frame,
## worst first. Same shape as `top_sections`, different dictionary.
func worst_sections(n: int) -> Array:
	var keys: Array = last_worst_breakdown.keys()
	keys.sort_custom(func(a, b): return last_worst_breakdown[a] > last_worst_breakdown[b])
	return keys.slice(0, n)

## The p-th percentile (0-1) of the plotted window-worst samples
## (frame_history) -- e.g. percentile_ms(0.95) for p95. Read-only and
## cheap: at most HISTORY_SLOTS (120) floats, sorted only when asked for,
## not maintained continuously.
func percentile_ms(p: float) -> float:
	if frame_history.is_empty():
		return 0.0
	var sorted: Array = frame_history.duplicate()
	sorted.sort()
	var idx: int = clampi(int(ceil(p * sorted.size())) - 1, 0, sorted.size() - 1)
	return sorted[idx]

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
		_window_worst_totals.clear()
		return

	var now: int = Time.get_ticks_usec()
	if _frame_start_usec != 0:
		var frame_ms: float = float(now - _frame_start_usec) / 1000.0
		if frame_ms >= _window_worst_ms:
			_window_worst_ms = frame_ms
			_window_worst_totals = _totals.duplicate()

		# A section that didn't run this frame decays toward zero instead
		# of freezing at its last reading -- otherwise a toggled-off
		# system (fog of war with fog_of_war_on false, etc.) keeps
		# showing a stale cost in the breakdown forever. Dropped once
		# negligible so top_sections() stops surfacing a dead section
		# ahead of ones still actually running.
		var stale: Array = []
		for section in averages:
			if not _totals.has(section):
				var decayed: float = lerpf(float(averages[section]), 0.0, 0.1)
				if decayed < 0.01:
					stale.append(section)
				else:
					averages[section] = decayed
		for section in stale:
			averages.erase(section)

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
			last_worst_ms = _window_worst_ms
			last_worst_breakdown.clear()
			for section in _window_worst_totals:
				last_worst_breakdown[section] = _window_worst_totals[section] / 1000.0
			_window_worst_ms = 0.0
			_window_worst_totals.clear()
			_window_start_usec = now

	_frame_start_usec = now
	_totals.clear()
	_open.clear()
	marks.clear()
