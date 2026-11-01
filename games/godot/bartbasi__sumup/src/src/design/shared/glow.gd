extends RefCounted
## One soft round glow texture, white in the middle fading to clear at the
## edge, built in code once and shared (DESIGN_SYSTEM.md 1.5). Callers draw
## it tinted with a palette color, so the texture holds no color of its own.

const _SIZE: int = 128

static var _texture: GradientTexture2D = null


## The shared glow texture. Its visible light reaches the edge of the rect it
## is drawn in.
static func texture() -> GradientTexture2D:
	if _texture != null:
		return _texture
	var gradient: Gradient = Gradient.new()
	# Close to a (1 - d) squared falloff, so the light has no hard rim.
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.56),
		Color(1.0, 1.0, 1.0, 0.25),
		Color(1.0, 1.0, 1.0, 0.06),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var made: GradientTexture2D = GradientTexture2D.new()
	made.gradient = gradient
	made.width = _SIZE
	made.height = _SIZE
	made.fill = GradientTexture2D.FILL_RADIAL
	made.fill_from = Vector2(0.5, 0.5)
	made.fill_to = Vector2(1.0, 0.5)
	_texture = made
	return _texture


## Draws the glow centered on center with radius radius, tinted color.
static func draw(item: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	item.draw_texture_rect(texture(), Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)
