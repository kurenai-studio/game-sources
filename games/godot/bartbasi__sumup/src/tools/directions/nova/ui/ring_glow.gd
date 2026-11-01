extends Control
## The soft aurora glow around an active Nova ring: aurora cyan at the ring
## edge fading through accent_violet to clear, ring_glow_spread times the
## ring radius. It draws behind its parent, so the parent's filled ring sits
## on top of it. Kept as its own control so Motion.pulse() can breathe its
## alpha without touching the ring.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")

const _SIZE: int = 128

static var _texture: GradientTexture2D = null

var _tokens: DirectionTokens = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	if _texture == null:
		_texture = _build(tokens)
	queue_redraw()


## Centers the glow on center (parent space) around a ring of ring_radius.
func place(center: Vector2, ring_radius: float) -> void:
	if _tokens == null:
		return
	var radius: float = ring_radius * _tokens.num("ring_glow_spread")
	size = Vector2(radius, radius) * 2.0
	position = center - Vector2(radius, radius)
	pivot_offset = size * 0.5
	queue_redraw()


func _draw() -> void:
	if _texture != null:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)


static func _build(tokens: DirectionTokens) -> GradientTexture2D:
	var accent: Color = tokens.color("accent")
	var violet: Color = tokens.color("accent_violet")
	var alpha: float = tokens.num("ring_glow_alpha")
	var edge: float = 1.0 / tokens.num("ring_glow_spread")
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, edge, lerpf(edge, 1.0, 0.3), lerpf(edge, 1.0, 0.65), 1.0])
	gradient.colors = PackedColorArray([
		Color(accent, alpha),
		Color(accent, alpha),
		Color(accent.lerp(violet, 0.5), alpha * 0.45),
		Color(violet, alpha * 0.15),
		Color(violet, 0.0),
	])
	var made: GradientTexture2D = GradientTexture2D.new()
	made.gradient = gradient
	made.width = _SIZE
	made.height = _SIZE
	made.fill = GradientTexture2D.FILL_RADIAL
	made.fill_from = Vector2(0.5, 0.5)
	made.fill_to = Vector2(1.0, 0.5)
	return made
