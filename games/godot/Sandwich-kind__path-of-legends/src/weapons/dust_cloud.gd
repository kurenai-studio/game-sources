class_name DustCloud
extends Node2D
# Сверкающая пыльца хрустальной моли: медленно оседает, в облаке герой замедлен

var team := 1
var radius := 85.0
var _life := 3.2
var _dots: Array = []

func _ready() -> void:
	for i in 22:
		var d := Polygon2D.new()
		d.polygon = Util.circle(randf_range(2.0, 4.0), 6)
		d.color = Color(0.85, 0.8, 1.0, 0.75) if i % 2 == 0 else Color(0.7, 0.9, 1.0, 0.75)
		d.position = Vector2.from_angle(randf() * TAU) * randf() * radius
		add_child(d)
		_dots.append(d)
	Shimmer.apply(self, 0.4, 1.0)

func _physics_process(delta: float) -> void:
	_life -= delta
	position.y += 22.0 * delta
	for d in _dots:
		d.position += Vector2(sin(_life * 3.0 + d.position.y) * 8.0, 4.0) * delta
	modulate.a = clampf(_life / 0.8, 0.0, 1.0)
	for n in get_parent().get_children():
		if n is Player and n.is_alive() and n.team != team and n.global_position.distance_to(global_position) < radius:
			n.slow(0.4, 0.55)
	if _life <= 0.0:
		queue_free()
