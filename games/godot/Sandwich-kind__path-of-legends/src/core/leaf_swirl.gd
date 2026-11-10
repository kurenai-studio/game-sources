class_name LeafSwirl
extends Node2D
# Листья кружатся вокруг героя, сужаясь к нему (превращение в Энта)

var center: Node2D
var radius := 90.0
var time := 0.9
var count := 18
var _t := 0.0
var _leaves: Array = []

func _ready() -> void:
	z_index = 9
	for i in count:
		var leaf := Polygon2D.new()
		leaf.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(0, -4), Vector2(7, 0), Vector2(0, 4)])
		leaf.color = Color(0.3, 0.7, 0.25) if i % 3 != 0 else Color(0.6, 0.85, 0.3)
		add_child(leaf)
		_leaves.append([leaf, TAU * i / count, randf_range(-1.0, 0.6)])

func _process(delta: float) -> void:
	_t += delta
	var k := _t / time
	if k >= 1.0 or not is_instance_valid(center):
		queue_free()
		return
	for L in _leaves:
		var a: float = L[1] + k * TAU * 2.0
		var r := radius * (1.0 - k * 0.6)
		L[0].position = center.global_position + Vector2(cos(a) * r, sin(a) * r * 0.35 + float(L[2]) * radius * 0.6 - k * 40.0)
		L[0].rotation = a * 2.0
	modulate.a = 1.0 if k < 0.8 else (1.0 - k) * 5.0
