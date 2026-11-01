extends Node2D

var color: Color = Color.WHITE
var lifetime: float = 0.35
var age: float = 0.0
var radius: float = 8.0
var particles: Array[Dictionary] = []

static func spawn(parent: Node, at: Vector2, tint: Color, amount: int = 8, size: float = 8.0) -> Node2D:
	var burst := preload("res://scripts/effects/EffectBurst.gd").new()
	burst.global_position = at
	burst.color = tint
	burst.radius = size
	for i in amount:
		var angle := TAU * float(i) / amount + randf_range(-0.18, 0.18)
		burst.particles.append({"p": Vector2.ZERO, "v": Vector2.from_angle(angle) * randf_range(45.0, 150.0)})
	parent.add_child(burst)
	return burst

func _process(delta: float) -> void:
	age += delta
	for particle in particles:
		particle.p += particle.v * delta
		particle.v *= 0.93
	queue_redraw()
	if age >= lifetime:
		queue_free()

func _draw() -> void:
	var alpha := 1.0 - age / lifetime
	draw_circle(Vector2.ZERO, radius * (1.0 + age * 4.0), Color(color, alpha * 0.18))
	for particle in particles:
		draw_circle(particle.p, maxf(1.0, 3.0 * alpha), Color(color, alpha))

