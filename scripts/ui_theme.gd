extends RefCounted
## Single source for every UI colour, corner radius, border width and
## panel depth value, plus the text-scale/typeface Theme resource. See
## UI_PLAN.md sections 6 and 7.
##
## Every panel script should ask this for a stylebox or a colour rather
## than building its own StyleBoxFlat or hardcoding a hex -- the same
## "read from one table, never hardcode" rule roles.gd already applies
## to role colours, applied here to the whole interface. A colour then
## changes in one place instead of in every panel that happened to copy
## it.
##
## Usage: const UiTheme = preload("res://scripts/ui_theme.gd")
##        panel.add_theme_stylebox_override("panel", UiTheme.panel_stylebox())
##        label.theme = UiTheme.active_theme()
##        label.theme_type_variation = "Body"

# --- token palettes --------------------------------------------------
## All three themes share this exact set of token names, so no panel
## script ever needs an `if theme == ...` branch -- it just asks for a
## token and gets whatever the active theme maps it to.

const DARK := {
	"panel_bg": Color("#370C00"),
	# Honeycomb relief line: panel_bg lightened ~6% in HSV value, drawn at
	# low opacity rather than a contrasting colour (identical-hue lines on
	# identical-hue fill only read as texture through a relief/opacity
	# difference). Proposed starting point, not a final answer -- see
	# UI_PLAN.md section 6 and section 16.
	"panel_line": Color("#460F00", 0.15),
	"text_primary": Color("#F5E9DC"),
	"text_secondary": Color("#C9B8A8"),
	"accent_nectar": Color("#C9D5B5"),
	"accent_honey": Color("#A44200"),
	"accent_wax": Color("#D58936"),
	"accent_grass": Color("#678D58"),
	"accent_soil": Color("#3C1518"),
	# Reused literally from the winter forecast's existing green verdict
	# colour and hud.gd's SIGNAL_COLOURS[1]/[2] -- see UI_PLAN.md section 6.
	"success": Color(0.5, 0.95, 0.55),
	"warning": Color(1.0, 0.85, 0.4),
	"danger": Color(1.0, 0.45, 0.4),
	"focus_ring": Color("#4FD6E8"),
	"disabled": Color(0.6, 0.55, 0.52),
	"locked": Color(0.55, 0.45, 0.65),
}

const LIGHT := {
	"panel_bg": Color("#F6DFC8"),
	"panel_line": Color("#B97A4E"),
	"text_primary": Color("#3C1518"),
	"text_secondary": Color("#7A5A44"),
	"accent_nectar": Color("#C9D5B5"),
	"accent_honey": Color("#A44200"),
	"accent_wax": Color("#D58936"),
	"accent_grass": Color("#678D58"),
	"accent_soil": Color("#3C1518"),
	"success": Color(0.5, 0.95, 0.55),
	"warning": Color(1.0, 0.85, 0.4),
	"danger": Color(1.0, 0.45, 0.4),
	"focus_ring": Color("#1E7A87"),
	"disabled": Color("#B8A08C"),
	"locked": Color("#8B6FA8"),
}

## Near-black/near-white with a small set of highly saturated, mutually
## distinct accent hues, rather than a darker/lighter variant of the
## brand colours -- the same approach OS-level high-contrast modes use.
## Every text pairing here clears WCAG AAA (7:1) against panel_bg.
## accent_honey is brightened from the brand hex (#A44200, ~3.2:1) to
## #E8720A (~6.5:1) to clear AA (4.5:1); accent_nectar/wax/grass/soil
## already clear it unbrightened -- see UI_PLAN.md section 6.
const HIGH_CONTRAST := {
	"panel_bg": Color("#0A0A0A"),
	"panel_line": Color("#2A2A2A"),
	"text_primary": Color("#FFFFFF"),
	"text_secondary": Color("#E0E0E0"),
	"accent_nectar": Color("#C9D5B5"),
	"accent_honey": Color("#E8720A"),
	"accent_wax": Color("#D58936"),
	"accent_grass": Color("#678D58"),
	"accent_soil": Color("#3C1518"),
	"success": Color("#00E676"),
	"warning": Color("#FFD400"),
	"danger": Color("#FF6B6B"),
	"focus_ring": Color("#00E5FF"),
	"disabled": Color("#808080"),
	"locked": Color("#B388FF"),
}

static func palette() -> Dictionary:
	match Session.ui_theme:
		"light":
			return LIGHT
		"high_contrast":
			return HIGH_CONTRAST
		_:
			return DARK

## Loud fallback (magenta) rather than a silent black, so a typo'd token
## name is obvious on screen instead of just blending into the panel.
static func color(token: String) -> Color:
	return palette().get(token, Color(1.0, 0.0, 1.0))

# --- panel construction ------------------------------------------------
## Rounded, pixel-built panel background with visible thickness -- the
## shared shape every drawer/window/tray should use instead of building
## its own StyleBoxFlat. Corner radius is deliberately modest (not a
## smooth circular arc) so the pixel-art language survives the rounding,
## per UI_PLAN.md section 6.
static var _panel_stylebox: StyleBoxFlat
static var _button_styleboxes: Dictionary = {}
static var _active_theme: Theme

static func panel_stylebox() -> StyleBoxFlat:
	if _panel_stylebox == null:
		_panel_stylebox = StyleBoxFlat.new()
		_refresh_panel_stylebox(_panel_stylebox)
	return _panel_stylebox

static func _refresh_panel_stylebox(box: StyleBoxFlat) -> void:
	box.bg_color = color("panel_bg")
	box.set_corner_radius_all(10)
	box.set_border_width_all(2)
	box.border_color = color("panel_bg").lightened(0.15)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8

## The seven interaction states every interactive control should draw
## from (UI_PLAN.md section 11), rather than each panel inventing its
## own subset the way ui.gd::mark_as_current does for one button type.
const BUTTON_STATES := [
	"normal", "hover", "pressed", "focus", "selected", "disabled", "locked",
]

static func button_stylebox(state: String) -> StyleBoxFlat:
	if not _button_styleboxes.has(state):
		_button_styleboxes[state] = StyleBoxFlat.new()
	var box: StyleBoxFlat = _button_styleboxes[state]
	_refresh_button_stylebox(box, state)
	return box

static func _refresh_button_stylebox(box: StyleBoxFlat, state: String) -> void:
	var base: Color = color("panel_bg")
	var bg: Color = base.lightened(0.10)
	var border: Color = Color(0, 0, 0, 0)
	var border_width := 0
	match state:
		"hover":
			bg = base.lightened(0.18)
		"pressed":
			bg = base.lightened(0.02)
		"focus":
			border = color("focus_ring")
			border_width = 2
		"selected":
			bg = base.lightened(0.06)
			border = color("text_primary")
			border_width = 1
		"disabled":
			bg.a = 0.5
		"locked":
			border = color("locked")
			border_width = 2
		_:
			pass  # "normal" -- the defaults above already cover it
	box.bg_color = bg
	box.set_corner_radius_all(6)
	box.set_border_width_all(border_width)
	box.border_color = border
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4

# --- text scale and typeface architecture -------------------------------
## A project Theme resource with named type variations, per UI_PLAN.md
## section 7's accessibility/future-proofing decision -- not a multiplier
## threaded through every panel's own add_theme_font_size_override calls.
## A panel written after this asks for a variation by name (theme_type_
## variation = "Body") and automatically tracks whatever Session.text_
## scale/ui_typeface are currently set to.
const TYPE_SIZES := {
	"Heading": 16,
	"Body": 13,
	"Small": 11,
	"Tiny": 9,
}

## Returns the shared mutable Theme used by every panel. Keeping one resource
## means refresh() updates controls that are already open, rather than only
## controls created after an appearance setting changes.
static func active_theme() -> Theme:
	if _active_theme == null:
		_active_theme = Theme.new()
		_refresh_theme_resource(_active_theme)
	return _active_theme

## Compatibility wrapper for existing panel call sites. New code should use
## active_theme() to make the shared-resource behaviour explicit.
static func build_theme() -> Theme:
	return active_theme()

## Reapplies all palette, scale and typeface values to the same resources.
## Theme and StyleBox resources emit change notifications as they mutate, so
## controls already holding them redraw without being rebuilt.
static func refresh() -> void:
	var theme := active_theme()
	_refresh_theme_resource(theme)
	if _panel_stylebox != null:
		_refresh_panel_stylebox(_panel_stylebox)
	for state in _button_styleboxes:
		_refresh_button_stylebox(_button_styleboxes[state], state)

static func _refresh_theme_resource(theme: Theme) -> void:
	var scale: float = Session.text_scale
	var font: Font = _typeface_font(Session.ui_typeface)
	for variation in TYPE_SIZES:
		theme.set_type_variation(variation, "Label")
		theme.set_font_size("font_size", variation, int(round(TYPE_SIZES[variation] * scale)))
		theme.set_color("font_color", variation, color("text_primary"))
		if font != null:
			theme.set_font("font", variation, font)
		elif theme.has_font("font", variation):
			theme.clear_font("font", variation)
	for base_type in ["Label", "Button"]:
		theme.set_color("font_color", base_type, color("text_primary"))
		if font != null:
			theme.set_font("font", base_type, font)
		elif theme.has_font("font", base_type):
			theme.clear_font("font", base_type)

## The three non-default faces are placeholder options until their font
## files are sourced under assets/fonts/ (UI_PLAN.md section 8) --
## picking one before then falls back to the default font rather than
## erroring, exactly like any other not-yet-built content per section 10.
static func _typeface_font(typeface: String) -> Font:
	var path := _typeface_path(typeface)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Font

static func _typeface_path(typeface: String) -> String:
	match typeface:
		"atkinson":
			return "res://assets/fonts/AtkinsonHyperlegible-Regular.ttf"
		"dyslexia":
			return "res://assets/fonts/OpenDyslexic-Regular.otf"
		"pixel":
			return "res://assets/fonts/PixelOperator.ttf"
		_:
			return ""  # "sans" -- Godot's built-in default, no asset needed
