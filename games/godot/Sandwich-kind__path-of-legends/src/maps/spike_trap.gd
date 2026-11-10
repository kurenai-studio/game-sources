class_name SpikeTrap
extends Node2D
# ---------- Ловушка с шипами (Царство скелетов) ----------
# Решётка в полу. Раз в несколько секунд в щелях загорается красный свет —
# и из пола выстреливают костяные шипы. Ранят всех, кто стоит сверху:
# и героя, и скелетов. Ритм у каждой ловушки свой.

var width := 140.0
var _t := 0.0
var _state := "idle"
var _spikes: Polygon2D
var _glow: Polygon2D
var _hit := {}

const IDLE := 3.6
const WARN := 0.8
const UP := 0.9

func _ready() -> void:
	z_index = 1
	_t = randf_range(1.0, IDLE)
	var grate := Polygon2D.new()
	grate.polygon = PackedVector2Array([Vector2(-width / 2, -4), Vector2(width / 2, -4), Vector2(width / 2, 4), Vector2(-width / 2, 4)])
	grate.color = Color(0.20, 0.18, 0.22)
	add_child(grate)
	var k := -width / 2 + 8.0
	while k < width / 2:
		var slot := Polygon2D.new()
		slot.polygon = PackedVector2Array([Vector2(k, -3), Vector2(k + 6, -3), Vector2(k + 6, 2), Vector2(k, 2)])
		slot.color = Color(0.05, 0.04, 0.06)
		add_child(slot)
		k += 14.0
	_glow = Polygon2D.new()
	_glow.polygon = PackedVector2Array([Vector2(-width / 2, -2), Vector2(width / 2, -2), Vector2(width / 2 - 10, -26), Vector2(-width / 2 + 10, -26)])
	_glow.color = Color(1.0, 0.25, 0.15, 0.0)
	add_child(_glow)
	_spikes = Polygon2D.new()
	var pts := PackedVector2Array([Vector2(-width / 2, 0)])
	var x := -width / 2
	while x < width / 2:
		pts.append(Vector2(x + 5, -46))
		pts.append(Vector2(x + 10, 0))
		x += 10.0
	pts.append(Vector2(width / 2, 0))
	_spikes.polygon = pts
	_spikes.color = Color(0.90, 0.88, 0.80)
	_spikes.scale.y = 0.0
	add_child(_spikes)

func _physics_process(delta: float) -> void:
	_t -= delta
	match _state:
		"idle":
			if _t <= 0.0:
				_state = "warn"
				_t = WARN
		"warn":
			_glow.color.a = 0.25 + 0.25 * sin(_t * 30.0)
			_spikes.scale.y = 0.12
			if _t <= 0.0:
				_state = "up"
				_t = UP
				_hit.clear()
				Fx.sparks(get_parent(), global_position + Vector2(0, -20), Color(0.95, 0.9, 0.8), 8, 200.0, 3.0, true)
		"up":
			_spikes.scale.y = minf(1.0, _spikes.scale.y + delta * 14.0)
			_glow.color.a = 0.0
			for n in get_parent().get_children():
				if n is Player and n.is_alive() and not _hit.has(n):
					var d: Vector2 = n.global_position - global_position
					if absf(d.x) < width / 2 + n.body_size.x * 0.3 and d.y < 0.0 and d.y > -n.body_size.y / 2 - 40.0:
						_hit[n] = true
						n.take_damage(14)                 # шипы бьют всех — и героя, и врагов
						n.velocity.y = -420.0
			if _t <= 0.0:
				_state = "idle"
				_t = IDLE + randf_range(-0.6, 0.6)
		_:
			pass
	if _state == "idle":
		_spikes.scale.y = maxf(0.0, _spikes.scale.y - delta * 4.0)
