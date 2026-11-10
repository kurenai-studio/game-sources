class_name RootSpike
extends Node2D
# Корни Энта: сначала земля трескается и светится (предупреждение),
# потом из неё вырываются острые корни и подбрасывают всех, кто стоит сверху.

const WARN := 0.9
const HALF := 55.0
const HEIGHT := 160.0

var team := 1
var attacker: Node
var damage := 22
var bone := false            # костяные шипы Короля скелетов
var stone := false           # каменные шипы Кузнеца
var crystal := false         # кристальные шипы Ириды
var half := HALF             # полуширина (МЕГА-корни Терновника шире)
var root_time := 0.0         # обездвиживает вместо подбрасывания (корни Терновника)
var warn := WARN
var _t := 0.0
var _hit := false
var _warn: ColorRect
var _spikes: Polygon2D

func _ready() -> void:
	z_index = 2
	_warn = ColorRect.new()
	_warn.color = Color(0.55, 0.9, 0.3, 0.0)
	_warn.position = Vector2(-half, -8)
	_warn.size = Vector2(half * 2, 10)
	add_child(_warn)
	_spikes = Polygon2D.new()
	var pts := PackedVector2Array([Vector2(-half, 0)])
	var n := 5
	for i in n:
		var x0 := -half + (i + 0.5) * half * 2 / n
		pts.append(Vector2(x0 - 8, 0))
		pts.append(Vector2(x0, -HEIGHT * randf_range(0.75, 1.0)))
		pts.append(Vector2(x0 + 8, 0))
	pts.append(Vector2(half, 0))
	_spikes.polygon = pts
	_spikes.color = Color(0.9, 0.88, 0.8) if bone else Color(0.42, 0.28, 0.15)
	if stone:
		_spikes.color = Color(0.55, 0.52, 0.5)
		_warn.color = Color(1.0, 0.5, 0.15, 0.0)
	if bone:
		_warn.color = Color(0.85, 0.3, 0.3, 0.0)
	if crystal:
		_spikes.color = Color(0.65, 0.85, 1.0, 0.95)
		_warn.color = Color(0.6, 0.8, 1.0, 0.0)
		Shimmer.apply(_spikes, 0.35, 0.9)
	_spikes.scale = Vector2(1, 0)
	add_child(_spikes)

func _process(delta: float) -> void:
	_t += delta
	if _t < warn:
		_warn.color.a = 0.35 + 0.35 * absf(sin(_t * 16.0))
		return
	_warn.visible = false
	var k := clampf((_t - warn) / 0.12, 0.0, 1.0)
	if _t > warn + 0.7:
		k = clampf(1.0 - (_t - warn - 0.7) / 0.3, 0.0, 1.0)
		if k <= 0.0:
			queue_free()
			return
	_spikes.scale.y = k
	if not _hit and k >= 1.0:
		_hit = true
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive():
				var feet: Vector2 = n.global_position + Vector2(0, n.body_size.y / 2)
				if absf(feet.x - global_position.x) < half + n.body_size.x / 2 \
						and feet.y > global_position.y - HEIGHT and feet.y < global_position.y + 12:
					n.take_damage(damage, attacker)
					if root_time > 0.0:
						n.root(root_time)
					else:
						n.velocity.y = -650.0
