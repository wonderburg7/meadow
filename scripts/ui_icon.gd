extends Control
## Tiny procedural placeholder icon for the top-right bar's window/view
## buttons -- a shape drawn with _draw() rather than a sprite, since no
## bespoke pixel art exists yet (UI_PLAN.md section 8). Same "polygon,
## not art" idea perf_plot.gd already uses for its bars and
## gallerin_panel.gd uses for Dr Gallerin's body.
##
## Usage: var icon := UiIcon.new()
##        icon.shape = "bee"   # "bee", "hex", "flower", "hive", "snow",
##                             # "arrow_up" or "save"
##        icon.custom_minimum_size = Vector2(16, 16)

const Shapes = preload("res://scripts/shapes.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")

var shape: String = "bee"

func _draw() -> void:
	var c: Vector2 = size / 2.0
	var col: Color = UiTheme.color("text_primary")
	match shape:
		"bee":
			draw_circle(c, size.x * 0.34, col)
		"hex":
			var pts := Shapes.hexagon_points(size.x * 0.42)
			var outline := PackedVector2Array()
			for p in pts:
				outline.append(p + c)
			outline.append(outline[0])
			for i in range(outline.size() - 1):
				draw_line(outline[i], outline[i + 1], col, 2.0)
		"flower":
			for i in range(5):
				var angle: float = TAU * i / 5.0
				var petal: Vector2 = c + Vector2(cos(angle), sin(angle)) * size.x * 0.22
				draw_circle(petal, size.x * 0.15, col)
			draw_circle(c, size.x * 0.12, UiTheme.color("accent_wax"))
		"hive":
			var pts := PackedVector2Array([
				c + Vector2(-size.x * 0.36, size.y * 0.36),
				c + Vector2(size.x * 0.36, size.y * 0.36),
				c + Vector2(size.x * 0.22, -size.y * 0.10),
				c + Vector2(0.0, -size.y * 0.36),
				c + Vector2(-size.x * 0.22, -size.y * 0.10),
			])
			draw_colored_polygon(pts, col)
		"snow":
			# Six-pointed snowflake: three lines through the centre at 60°.
			for i in range(3):
				var angle: float = PI / 3.0 * i
				var dir: Vector2 = Vector2(cos(angle), sin(angle)) * size.x * 0.38
				draw_line(c - dir, c + dir, col, 2.0)
		"arrow_up":
			# The Skills button (progression.md 8.5): a head over a stem.
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0.0, -size.y * 0.40),
				c + Vector2(size.x * 0.34, 0.0),
				c + Vector2(-size.x * 0.34, 0.0),
			]), col)
			draw_rect(Rect2(c + Vector2(-size.x * 0.12, -size.y * 0.02), Vector2(size.x * 0.24, size.y * 0.40)), col)
		"save":
			# The Saves button: a floppy disk -- body, label slot, shutter.
			var body := Rect2(c - size * 0.38, size * 0.76)
			draw_rect(body, col)
			var hole := UiTheme.color("panel_bg")
			draw_rect(Rect2(body.position + Vector2(size.x * 0.14, size.y * 0.06), Vector2(size.x * 0.40, size.y * 0.22)), hole)
			draw_rect(Rect2(body.position + Vector2(size.x * 0.12, size.y * 0.44), Vector2(size.x * 0.52, size.y * 0.26)), hole)
