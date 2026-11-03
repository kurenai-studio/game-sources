extends RefCounted


static func build() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 70
	particles.lifetime = 1.4
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, 430.0)
	particles.initial_velocity_min = 170.0
	particles.initial_velocity_max = 470.0
	particles.damping_min = 20.0
	particles.damping_max = 70.0
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 12.0
	particles.angular_velocity_min = -720.0
	particles.angular_velocity_max = 720.0

	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.7, Color(1, 1, 1, 1))
	particles.color_ramp = fade

	var hues := Gradient.new()
	hues.set_color(0, Color(1.0, 0.82, 0.25))
	hues.set_color(1, Color(1.0, 0.45, 0.35))
	hues.add_point(0.25, Color(0.45, 0.9, 1.0))
	hues.add_point(0.5, Color(0.55, 1.0, 0.6))
	hues.add_point(0.75, Color(1.0, 0.55, 0.85))
	particles.color_initial_ramp = hues

	return particles
