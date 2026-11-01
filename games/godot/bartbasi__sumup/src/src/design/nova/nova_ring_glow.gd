extends Control
## The aurora glow round an active Nova ring (DESIGN_SYSTEM.md 6.7): accent
## at ring_glow_alpha at the ring's edge, turning toward accent_violet and
## fading to clear at ring_glow_spread times the ring radius. It is its own
## control so Motion.pulse() can breathe its alpha without touching the ring,
## and it draws behind its parent so the filled ring sits on top of it.
##
## The light falls off as (1 - t) squared across the band outside the ring, so
## it is faint by the time it reaches the cost under the ring: there it adds
## well under a third of accent to bg_glow, which keeps the cost's text pair
## (accent on bg_glow) above 4.5:1.

const _SIZE: int = 128
## Points across the band outside the ring, enough for a smooth falloff.
const _BAND_STEPS: int = 6

static var _texture: GradientTexture2D = null

var _spread: float = 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true


func setup(skin: SkinData) -> void:
	_spread = skin.num(&"ring_glow_spread")
	if _texture == null:
		_texture = _build(skin)
	queue_redraw()


## Centers the glow on center (parent space) round a ring of ring_radius.
func place(center: Vector2, ring_radius: float) -> void:
	var radius: float = ring_radius * _spread
	size = Vector2(radius, radius) * 2.0
	position = center - Vector2(radius, radius)
	pivot_offset = size * 0.5
	queue_redraw()


func _draw() -> void:
	if _texture != null:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)


static func _build(skin: SkinData) -> GradientTexture2D:
	var accent: Color = skin.color(&"accent")
	var violet: Color = skin.color(&"accent_violet")
	var alpha: float = skin.num(&"ring_glow_alpha")
	var edge: float = 1.0 / skin.num(&"ring_glow_spread")
	var offsets: PackedFloat32Array = PackedFloat32Array([0.0])
	var colors: PackedColorArray = PackedColorArray([Color(accent, alpha)])
	for i: int in _BAND_STEPS + 1:
		var t: float = float(i) / float(_BAND_STEPS)
		offsets.append(lerpf(edge, 1.0, t))
		colors.append(Color(accent.lerp(violet, t), alpha * (1.0 - t) * (1.0 - t)))
	var gradient: Gradient = Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors
	var made: GradientTexture2D = GradientTexture2D.new()
	made.gradient = gradient
	made.width = _SIZE
	made.height = _SIZE
	made.fill = GradientTexture2D.FILL_RADIAL
	made.fill_from = Vector2(0.5, 0.5)
	made.fill_to = Vector2(1.0, 0.5)
	return made
