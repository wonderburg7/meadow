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
	# Honeycomb line: a warm wax tone at low opacity, about 1.3:1 against
	# panel_bg once composited (UT-1; the old panel_bg-lightened line was
	# 1.01:1 and invisible). text_primary stays above 8:1 over it.
	"panel_line": Color("#C87A3C", 0.2),
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
	# Status colours double as small-text colours. These darker light-theme
	# variants clear WCAG AA against panel_bg; the bright variants used by the
	# dark and high-contrast palettes do not.
	"success": Color("#2F6B36"),
	"warning": Color("#7A5100"),
	"danger": Color("#A12A2A"),
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

## Preserve an accent's identity while making it readable as small panel text.
## Light mode needs a stronger blend towards its dark primary text: 0.65 keeps
## even the palest role colour above 4.5:1 against the cream panel background.
static func readable_accent(accent: Color) -> Color:
	var blend := 0.65 if Session.ui_theme == "light" else 0.35
	return accent.lerp(color("text_primary"), blend)

# --- panel construction ------------------------------------------------
## Rounded, pixel-built panel background with visible thickness -- the
## shared shape every drawer/window/tray should use instead of building
## its own StyleBoxFlat. Corner radius is deliberately modest (not a
## smooth circular arc) so the pixel-art language survives the rounding,
## per UI_PLAN.md section 6.
static var _panel_stylebox: PanelBox
static var _texture_cache: Dictionary = {}
static var _button_styleboxes: Dictionary = {}
static var _active_theme: Theme
## Live colour bindings: [WeakRef(control), property, token]. Re-applied by refresh().
static var _color_bindings: Array = []

static func panel_stylebox() -> StyleBox:
	if _panel_stylebox == null:
		_panel_stylebox = PanelBox.new()
		_panel_stylebox.texture_source = Callable(panel_texture_image)
		_refresh_panel_stylebox(_panel_stylebox)
	return _panel_stylebox

const PANEL_BORDER_WIDTH := 2

static func _refresh_panel_stylebox(box: PanelBox) -> void:
	box.flat.bg_color = color("panel_bg")
	box.flat.set_corner_radius_all(10)
	box.flat.set_border_width_all(PANEL_BORDER_WIDTH)
	box.flat.border_color = color("panel_bg").lightened(0.15)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.emit_changed()

## Panel stylebox that draws the flat rounded panel exactly as StyleBoxFlat
## would, then lays the chosen `panel_texture` inside the border. Margins and
## the outer rectangle are untouched, so no layout moves when it changes.
## It extends StyleBox, not StyleBoxFlat: a StyleBoxFlat draws in C++ and
## never calls a script _draw (see docs/known-pitfalls.md).
class PanelBox:
	extends StyleBox
	var flat := StyleBoxFlat.new()
	## Returns the texture to lay inside the border (or null); set by
	## panel_stylebox() since an inner class cannot name its own script.
	var texture_source: Callable

	func _draw(to_canvas_item: RID, rect: Rect2) -> void:
		flat.draw(to_canvas_item, rect)
		# High contrast always draws plain panels, whatever Panel texture says.
		if Session.ui_theme == "high_contrast":
			return
		var tex: Texture2D = texture_source.call(Session.panel_texture)
		if tex == null:
			return
		var inset := float(PANEL_BORDER_WIDTH) + 2.0
		var inner := rect.grow(-inset)
		if inner.size.x <= 0.0 or inner.size.y <= 0.0:
			return
		RenderingServer.canvas_item_add_texture_rect(
			to_canvas_item, inner, tex.get_rid(), true)

## Tileable texture for a panel_texture option, or null for "flat". Cached per
## option and palette; refresh() clears the cache on any appearance change.
static func panel_texture_image(mode: String) -> Texture2D:
	if mode != "comb" and mode != "grain":
		return null
	var key := mode + ":" + Session.ui_theme
	if not _texture_cache.has(key):
		_texture_cache[key] = _build_panel_texture(mode)
	return _texture_cache[key]

static func _build_panel_texture(mode: String) -> Texture2D:
	return ImageTexture.create_from_image(_build_panel_image(mode))

## The tile as an Image, before it becomes a texture, so the contrast numbers
## below can read it under the headless dummy renderer.
static func _build_panel_image(mode: String) -> Image:
	var bg := color("panel_bg")
	var line := color("panel_line")
	if line.a >= 1.0:
		line.a = 0.35
	var img: Image
	if mode == "comb":
		# Pointy-top hexagon lattice, period 12x18: centres at (0,0) and
		# (6,9). A pixel is on an edge where its two nearest centres are
		# almost equally far.
		img = Image.create(12, 18, false, Image.FORMAT_RGBA8)
		var centres := []
		for cy in range(-1, 3):
			for cx in range(-1, 3):
				centres.append(Vector2(cx * 12, cy * 18))
				centres.append(Vector2(cx * 12 + 6, cy * 18 + 9))
		for y in 18:
			for x in 12:
				var p := Vector2(x + 0.5, y + 0.5)
				var d1 := 1e9
				var d2 := 1e9
				for c in centres:
					var d := p.distance_to(c)
					if d < d1:
						d2 = d1
						d1 = d
					elif d < d2:
						d2 = d
				img.set_pixel(x, y, line if d2 - d1 < 1.3 else Color(0, 0, 0, 0))
	else:
		# Per-pixel value jitter around panel_bg. Dark leans lighter because
		# its background cannot get much darker; Light leans darker for the
		# same reason in reverse. (High contrast never draws a texture.)
		var light_share := 0.5
		var max_lighter := 0.22
		var max_darker := 0.03
		if Session.ui_theme == "light":
			max_lighter = 0.06
			max_darker = 0.18
		var rng := RandomNumberGenerator.new()
		rng.seed = 20260919
		img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var c: Color
				if rng.randf() < light_share:
					c = bg.lightened(rng.randf_range(0.0, max_lighter))
				else:
					c = bg.darkened(rng.randf_range(0.0, max_darker))
				c.a = 0.6
				img.set_pixel(x, y, c)
	return img

## WCAG relative-luminance contrast ratio, always >= 1.0.
static func contrast_ratio(a: Color, b: Color) -> float:
	var la := _relative_luminance(a)
	var lb := _relative_luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

static func _relative_luminance(c: Color) -> float:
	var ch := [c.r, c.g, c.b]
	for i in 3:
		var v: float = ch[i]
		ch[i] = v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2]

## Contrast of the composited texture against panel_bg for the active theme.
## `mode` is "comb", "grain", or anything else for both. Keys: comb,
## grain_lightest, grain_darkest, grain_share (fraction of grain pixels at
## 1.10:1 or more), text_min (worst text_primary contrast over any composited
## texture pixel). High contrast draws no texture, so every ratio is 1.0 and
## `drawn` is false. Reads the Image, not a texture; not for per-frame use.
static func panel_texture_contrast(mode: String) -> Dictionary:
	var out := {"drawn": Session.ui_theme != "high_contrast"}
	var bg := color("panel_bg")
	var text := color("text_primary")
	var text_min := contrast_ratio(text, bg)
	if mode != "grain":
		var comb := 1.0
		if out["drawn"]:
			var img := _build_panel_image("comb")
			for y in img.get_height():
				for x in img.get_width():
					var px := img.get_pixel(x, y)
					if px.a <= 0.0:
						continue
					var over := bg.lerp(Color(px.r, px.g, px.b), px.a)
					comb = maxf(comb, contrast_ratio(over, bg))
					text_min = minf(text_min, contrast_ratio(text, over))
		out["comb"] = comb
	if mode != "comb":
		var lightest := 1.0
		var darkest := 1.0
		var share := 0.0
		if out["drawn"]:
			var gimg := _build_panel_image("grain")
			var seen := 0
			var visible := 0
			darkest = 99.0
			for y in gimg.get_height():
				for x in gimg.get_width():
					var px := gimg.get_pixel(x, y)
					var over := bg.lerp(Color(px.r, px.g, px.b), px.a)
					var r := contrast_ratio(over, bg)
					seen += 1
					if r >= 1.10:
						visible += 1
					# "Lightest"/"darkest" name the pixels' side of panel_bg,
					# reported as the largest ratio on each side.
					if _relative_luminance(over) >= _relative_luminance(bg):
						lightest = maxf(lightest, r)
					else:
						darkest = maxf(darkest if darkest < 99.0 else 1.0, r)
					text_min = minf(text_min, contrast_ratio(text, over))
			share = float(visible) / float(maxi(seen, 1))
		out["grain_lightest"] = lightest
		out["grain_darkest"] = darkest if darkest < 99.0 else 1.0
		out["grain_share"] = share
	out["text_min"] = text_min
	return out

## The seven interaction states every interactive control should draw
## from (UI_PLAN.md section 11), rather than each panel inventing its
## own subset the way ui.gd::mark_as_current does for one button type.
const BUTTON_STATES := [
	"normal", "hover", "pressed", "focus", "selected", "disabled", "locked",
]

## Builds and refreshes the box only the first time a given state is
## requested -- every later call just returns the same cached resource,
## same as panel_stylebox() above. Re-mutating it on every lookup (the
## previous behaviour) emitted a `changed` signal every single time any
## button anywhere called _style_button(), which every other button
## sharing that state's box picks up as a redraw/minimum-size recalc --
## with hundreds of buttons across the settings/debug panels alone, that
## turned every fresh button creation into an O(all buttons) cascade.
## `refresh()` below remains the one deliberate path that re-mutates an
## already-built box, for an actual theme/palette/scale change.
static func button_stylebox(state: String) -> StyleBoxFlat:
	if not _button_styleboxes.has(state):
		var box := StyleBoxFlat.new()
		_refresh_button_stylebox(box, state)
		_button_styleboxes[state] = box
	return _button_styleboxes[state]

static func _refresh_button_stylebox(box: StyleBoxFlat, state: String) -> void:
	var base: Color = color("panel_bg")
	# Ordinary buttons need a visible resting surface: this deliberately sits
	# below hover and selected, but no longer reads as floating text on a panel.
	var bg: Color = base.lightened(0.16)
	var border: Color = base.lightened(0.24)
	var border_width := 1
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
	"Heading": 18,
	"Body": 15,
	"Small": 13,
	"Tiny": 11,
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

## The settings whose change must reach every open control. One list, read
## by the settings window and by the headless set_config verb alike, so a
## fixture that changes text scale sees what the player sees (C-53).
const APPEARANCE_KEYS := ["text_scale", "ui_theme", "ui_typeface", "panel_texture"]

static func refresh_for_setting(key: String) -> void:
	if key in APPEARANCE_KEYS:
		refresh()

## Applies a palette token to a control's theme colour now and re-applies it
## on every appearance change. Runs only from refresh(), never per frame.
static func bind_color(control: Control, property: String, token: String) -> void:
	control.add_theme_color_override(property, color(token))
	for entry in _color_bindings:
		if entry[0].get_ref() == control and entry[1] == property:
			entry[2] = token
			return
	_color_bindings.append([weakref(control), property, token])

static func _refresh_color_bindings() -> void:
	var live: Array = []
	for entry in _color_bindings:
		var control = entry[0].get_ref()
		if control == null:
			continue
		control.add_theme_color_override(entry[1], color(entry[2]))
		live.append(entry)
	_color_bindings = live

## Reapplies all palette, scale and typeface values to the same resources.
## Theme and StyleBox resources emit change notifications as they mutate, so
## controls already holding them redraw without being rebuilt.
static func refresh() -> void:
	var theme := active_theme()
	# Block change signals while mutating so controls re-shape text once, after
	# the font swap is complete, not part-way through it (SC-2).
	theme.set_block_signals(true)
	if _panel_stylebox != null:
		_panel_stylebox.set_block_signals(true)
	for state in _button_styleboxes:
		_button_styleboxes[state].set_block_signals(true)
	_refresh_theme_resource(theme)
	_texture_cache.clear()
	if _panel_stylebox != null:
		_refresh_panel_stylebox(_panel_stylebox)
	for state in _button_styleboxes:
		_refresh_button_stylebox(_button_styleboxes[state], state)
	theme.set_block_signals(false)
	if _panel_stylebox != null:
		_panel_stylebox.set_block_signals(false)
		_panel_stylebox.emit_changed()
	for state in _button_styleboxes:
		_button_styleboxes[state].set_block_signals(false)
		_button_styleboxes[state].emit_changed()
	theme.emit_changed()
	_refresh_color_bindings()

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
		theme.set_font_size("font_size", base_type, int(round(TYPE_SIZES["Body"] * scale)))
		theme.set_color("font_color", base_type, color("text_primary"))
		if font != null:
			theme.set_font("font", base_type, font)
		elif theme.has_font("font", base_type):
			theme.clear_font("font", base_type)
	# Button state colours are explicit rather than inherited from Godot's
	# default Theme. That default is not designed for our dark/light palettes
	# and can turn text illegible while a control is hovered or pressed.
	# Focus uses the ordinary font colour plus the focus-ring StyleBox above.
	theme.set_color("font_hover_color", "Button", color("text_primary"))
	theme.set_color("font_pressed_color", "Button", color("text_primary"))
	theme.set_color("font_hover_pressed_color", "Button", color("text_primary"))
	theme.set_color("font_disabled_color", "Button", color("disabled"))

static func _typeface_font(typeface: String) -> Font:
	var path := _typeface_path(typeface)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Font

static func _typeface_path(typeface: String) -> String:
	match typeface:
		"atkinson":
			return "res://assets/fonts/Atkinson-Hyperlegible-Regular-102.otf"
		"opendyslexic":
			return "res://assets/fonts/OpenDyslexic-Regular.otf"
		"opensans":
			return "res://assets/fonts/OpenSans-Regular.ttf"
		"munro":
			return "res://assets/fonts/munro.ttf"
		"silkscreen":
			return "res://assets/fonts/slkscr.ttf"
		_:
			return ""  # "sans" -- Godot's built-in default, no asset needed
