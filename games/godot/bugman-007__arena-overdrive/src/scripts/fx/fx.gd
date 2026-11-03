class_name Fx
extends RefCounted
## Particle bursts, shockwave rings and the shared additive glow texture.

static var _glow: Texture2D
static var _additive: CanvasItemMaterial


static func glow_texture() -> Texture2D:
	if _glow == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.35))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_glow = t
	return _glow


static func additive() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive


## Additive glow sprite used under entities and projectiles.
static func make_glow(color: Color, radius: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = glow_texture()
	s.material = additive()
	s.modulate = color
	s.scale = Vector2.ONE * (radius * 2.0 / 128.0)
	s.show_behind_parent = true
	return s


static func burst(parent: Node, at: Vector2, color: Color, amount: int = 16, speed: float = 260.0,
		lifetime: float = 0.5, size: float = 4.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = lifetime
	p.direction = Vector2.RIGHT
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.damping_min = speed * 0.8
	p.damping_max = speed * 1.6
	p.scale_amount_min = size * 0.5
	p.scale_amount_max = size
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.lightened(0.4), 1.0))
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	p.material = additive()
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func ring(parent: Node, at: Vector2, color: Color, radius: float, duration: float = 0.35, width: float = 6.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var r := ShockRing.new()
	r.position = at
	r.color = color
	r.max_radius = radius
	r.width = width
	r.material = additive()
	parent.add_child(r)
	var tw := r.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "t", 1.0, duration)
	tw.tween_callback(r.queue_free)
