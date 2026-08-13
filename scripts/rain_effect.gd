extends Node2D
## Falling rain over the meadow.
##
## Drawn rather than simulated: a fixed pool of streaks, each with its own
## position and speed, wrapped back to the top when it falls off the
## bottom. Nothing here is a node -- the whole effect is one _draw call
## over an array of floats, so a heavy shower costs about as much as a
## light one and neither costs anything worth measuring.
##
## The streaks live in *screen* space, not world space, so panning and
## zooming don't drag the rain around with the ground or leave a
## rain-shaped hole where the camera has moved to. Rain falls on the
## view, which is also how it reads.

## How many streaks at full intensity. At lower intensity a share of them
## are simply skipped, so easing off is gradual rather than a switch.
const MAX_DROPS := 260
const FALL_SPEED := Vector2(-90.0, 900.0)   # slanted, as wind-driven rain is
const SPEED_VARIATION := 0.45
const STREAK_LENGTH := 14.0

var drops: Array = []          # each {pos: Vector2, speed: float, alpha: float}
var view_size: Vector2 = Vector2(1920, 1080)

func _ready() -> void:
	# Above the world, below the HUD. The CanvasLayer this is parented to
	# already puts it in the right band; this orders it within that.
	z_index = 50
	visible = false
	set_process(true)
	_seed_drops()

func _seed_drops() -> void:
	drops.clear()
	for i in range(MAX_DROPS):
		drops.append({
			"pos": Vector2(randf_range(-200.0, view_size.x + 200.0), randf_range(-view_size.y, view_size.y)),
			"speed": randf_range(1.0 - SPEED_VARIATION, 1.0 + SPEED_VARIATION),
			"alpha": randf_range(0.25, 0.7),
		})

## Visibility is main.gd's to set, not this script's -- rain shouldn't
## show while you're looking at the hive interior, and that isn't
## something this node knows about. All it does here is stop working when
## there's nothing to draw.
func _process(delta: float) -> void:
	if not visible or GameConfig.rain_intensity <= 0.01:
		return

	# Track the window, so resizing doesn't leave a dry strip down one
	# side or streaks falling outside the view.
	var current: Vector2 = get_viewport_rect().size
	if not current.is_equal_approx(view_size):
		view_size = current
		_seed_drops()

	# Heavier rain falls faster as well as thicker, which is most of what
	# makes a downpour read as a downpour.
	var pace: float = lerpf(0.75, 1.35, GameConfig.rain_intensity)
	for drop in drops:
		drop.pos += FALL_SPEED * drop.speed * pace * delta
		if drop.pos.y > view_size.y + STREAK_LENGTH:
			drop.pos = Vector2(randf_range(-200.0, view_size.x + 200.0), -STREAK_LENGTH)
		elif drop.pos.x < -220.0:
			drop.pos = Vector2(view_size.x + randf_range(0.0, 200.0), randf_range(-view_size.y, 0.0))
	queue_redraw()

func _draw() -> void:
	var intensity: float = GameConfig.rain_intensity
	if intensity <= 0.01:
		return
	# Below full intensity only a share of the pool is drawn. Taking a
	# prefix of the array rather than a random subset each frame keeps
	# each streak's identity from one frame to the next -- picking
	# randomly would make the rain flicker rather than fall.
	var count: int = int(MAX_DROPS * clampf(intensity, 0.0, 1.0))
	var direction: Vector2 = FALL_SPEED.normalized() * STREAK_LENGTH
	for i in range(count):
		var drop: Dictionary = drops[i]
		draw_line(
			drop.pos, drop.pos + direction,
			Color(0.78, 0.86, 0.98, drop.alpha * intensity),
			1.2
		)
