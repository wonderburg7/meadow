class_name PixelSprite
extends RefCounted
## Texture presentation for pixel art: the two view scales, one shared
## sharp-bilinear material (shared so every sprite still batches) and
## `apply`. Set once per sprite; no per-frame work.

const SHADER := preload("res://assets/shaders/pixel_sharp.gdshader")
## World units per art pixel in the meadow view.
const MEADOW_SCALE := 1.5
## The hive's cell art is 32 px wide and spans two cell spacings.
const HIVE_ART_WIDTH := 32.0

static var _material: ShaderMaterial


## World units per art pixel in the hive view (1.1875 at spacing 19).
static func hive_scale() -> float:
	return GameConfig.hive_cell_spacing * 2.0 / HIVE_ART_WIDTH


static func shared_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	return _material


static func apply(sprite: Sprite2D, px_scale: float) -> void:
	sprite.material = shared_material()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2.ONE * px_scale
