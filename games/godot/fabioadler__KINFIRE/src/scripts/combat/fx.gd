class_name Fx
extends RefCounted
## Fábrica de efeitos: partículas de impacto, explosões, luzes.

static var _light_tex: GradientTexture2D


static func light_texture() -> GradientTexture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.5, Color(1, 1, 1, 0.35))
		_light_tex = GradientTexture2D.new()
		_light_tex.gradient = g
		_light_tex.fill = GradientTexture2D.FILL_RADIAL
		_light_tex.fill_from = Vector2(0.5, 0.5)
		_light_tex.fill_to = Vector2(1.0, 0.5)
		_light_tex.width = 128
		_light_tex.height = 128
	return _light_tex


static func make_light(color: Color, scale: float, energy: float = 1.0,
		flicker := LightFx.Flicker.NONE, shadow := false) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.color = color
	l.texture_scale = scale
	l.energy = energy
	# 7.2: tremulação por fonte + candidatura ao orçamento de sombra (#14.2)
	if flicker != LightFx.Flicker.NONE or shadow:
		LightFx.register(l, flicker, shadow)
	return l


static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 10, speed: float = 60.0, life: float = 0.45, size: float = 2.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = false
	p.one_shot = true
	p.amount = int(maxf(1.0, roundf(amount * Game.particle_mult())))
	p.lifetime = life
	p.explosiveness = 0.95
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 90)
	p.scale_amount_min = size * 0.5
	p.scale_amount_max = size
	p.damping_min = 40.0
	p.damping_max = 80.0
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	p.z_index = 6
	parent.add_child(p)
	p.emitting = true
	p.get_tree().create_timer(life + 0.2).timeout.connect(p.queue_free)


static func explosion(parent: Node, pos: Vector2, color: Color, radius: float) -> void:
	FxShape.spawn(parent, FxShape.Type.RING, pos, color, radius, 0.35)
	burst(parent, pos, color, int(clampf(radius * 0.5, 8, 30)), radius * 2.0, 0.5, 2.5)
	var l := make_light(color, radius / 40.0, 1.5)
	l.position = pos
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, 0.4)
	tw.tween_callback(l.queue_free)
