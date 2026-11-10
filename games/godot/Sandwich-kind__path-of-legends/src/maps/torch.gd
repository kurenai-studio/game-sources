class_name Torch
extends Node2D
# Факел на стене колизея. Ночью горит: пламя колышется, вокруг тёплое свечение.

var lit := false
var glow_layer: CanvasLayer          # слой, на котором рисуется свечение (не затемняется ночью)
var _flame: Polygon2D
var _inner: Polygon2D
var _glow: Sprite2D
var _t := 0.0

static var _glow_tex: Texture2D

static func glow_texture() -> Texture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.62, 0.28, 0.55))
		g.set_color(1, Color(1.0, 0.45, 0.15, 0.0))
		g.add_point(0.45, Color(1.0, 0.55, 0.2, 0.22))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_glow_tex = t
	return _glow_tex

# Мягкое свечение для слоя света (факелы, луна, фонарь игрока)
static func make_glow(size: float, tint := Color.WHITE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = glow_texture()
	s.scale = Vector2.ONE * size / 128.0
	s.modulate = tint
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	return s

func _ready() -> void:
	z_index = -8
	# деревянная рукоять с обмоткой и железная чаша с ободом
	var holder := Tex.slab(Vector2(8, 26), "log", Color(0.36, 0.25, 0.15), 3)
	holder.position = Vector2(0, 13)
	add_child(holder)
	for y in [6.0, 14.0]:
		var band := ColorRect.new()
		band.color = Color(0.25, 0.24, 0.26)
		band.size = Vector2(10, 3)
		band.position = Vector2(-5, y)
		add_child(band)
	var cup := Polygon2D.new()
	cup.polygon = PackedVector2Array([Vector2(-9, -5), Vector2(9, -5), Vector2(6, 4), Vector2(-6, 4)])
	cup.color = Color(0.24, 0.22, 0.24)
	add_child(cup)
	var rim := ColorRect.new()
	rim.color = Color(0.45, 0.42, 0.44)
	rim.size = Vector2(18, 2)
	rim.position = Vector2(-9, -6)
	add_child(rim)
	if not lit:
		return
	_flame = Polygon2D.new()
	_flame.color = Color(1.0, 0.55, 0.15)
	add_child(_flame)
	_inner = Polygon2D.new()
	_inner.color = Color(1.0, 0.92, 0.5)
	add_child(_inner)
	if glow_layer:
		_glow = make_glow(300.0)
		_glow.position = global_position + Vector2(0, -12)
		glow_layer.add_child(_glow)
	_t = randf() * 10.0

func _process(delta: float) -> void:
	if not lit:
		return
	_t += delta
	var h := 22.0 + 5.0 * sin(_t * 13.0) + 3.0 * sin(_t * 23.0)
	var sway := 3.0 * sin(_t * 7.0)
	_flame.polygon = PackedVector2Array([Vector2(-8, -4), Vector2(8, -4), Vector2(sway, -4 - h)])
	_inner.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(sway * 0.6, -4 - h * 0.55)])
	if _glow:
		_glow.modulate.a = 0.85 + 0.15 * sin(_t * 11.0)

func _exit_tree() -> void:
	if _glow and is_instance_valid(_glow):
		_glow.queue_free()
