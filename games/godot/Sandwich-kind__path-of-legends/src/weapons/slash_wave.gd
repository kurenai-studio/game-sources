class_name SlashWave
extends Node2D
# Дальний взмах Самурая: светлый полумесяц летит вперёд и пронзает всех на пути.
# Слегка режет блоки, но не останавливается о них. В МЕГА-ульте замораживает.

var team := 0
var attacker: Node
var dir := 1
var speed := 1300.0
var damage := 22
var range_px := 650.0
var color := Color(0.95, 0.97, 1.0, 0.85)
var burn := 0.0               # поджог (ульта)
var freeze := 0.0             # заморозка (МЕГА-ульта)
var _travel := 0.0
var _hit := {}
var _poly: Polygon2D

func _ready() -> void:
	z_index = 7
	_poly = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 13:
		var a := lerpf(-1.25, 1.25, i / 12.0)
		pts.append(Vector2.from_angle(a) * 46.0)
	for i in range(12, -1, -1):
		var a := lerpf(-1.25, 1.25, i / 12.0)
		pts.append(Vector2.from_angle(a) * (46.0 - 16.0 * sin(PI * i / 12.0)))
	_poly.polygon = pts
	_poly.color = color
	_poly.scale = Vector2(dir, 1)
	add_child(_poly)
	var core := Polygon2D.new()
	core.polygon = pts
	core.color = Color(1, 1, 1, 0.9)
	core.scale = Vector2(dir * 0.9, 0.7)
	add_child(core)

func _physics_process(delta: float) -> void:
	var step := speed * delta
	position.x += dir * step
	_travel += step
	modulate.a = clampf(1.0 - (_travel - range_px * 0.7) / (range_px * 0.3), 0.0, 1.0)
	var parent := get_parent()
	for n in parent.get_children():
		if n is Player and n.team != team and n.is_alive() and not _hit.has(n):
			var d: Vector2 = n.global_position - global_position
			if absf(d.x) < 40.0 + n.body_size.x / 2 and absf(d.y) < 50.0 + n.body_size.y / 2:
				_hit[n] = true
				n.take_damage(damage, attacker)
				if burn > 0.0:
					n.burn(3.0, burn, attacker)
				if freeze > 0.0:
					n.stun(freeze)
					Fx.ice(n, n.body_size, freeze)
				Fx.sparks(parent, n.global_position, Color(1, 1, 1), 8, 220.0, 4.0)
		elif n is Destructible and n.shield_team != team and not n.background \
				and absf(n.global_position.x - global_position.x) < 300.0 and absf(n.global_position.y - global_position.y) < 300.0:
			for y in [-30.0, 0.0, 30.0]:
				n.hit(global_position + Vector2(dir * 20.0, y), Vector2(dir, 0), 12, 4.0, team,
						{"strict": true, "attacker": attacker, "power": 0.4})
	if _travel >= range_px:
		queue_free()
