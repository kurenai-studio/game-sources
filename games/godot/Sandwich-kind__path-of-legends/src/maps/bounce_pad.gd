class_name BouncePad
extends StaticBody2D
# ---------- Поющий кристалл (Кристальные пещеры) ----------
# Плоская друза в полу. Кто на неё наступит — герой или противник, — того
# подбрасывает высоко вверх с переливчатым звоном. Удобно, чтобы быстро
# забраться к алтарю баффов или перелететь через опасность.

var width := 90.0
var power := 1350.0
var _cd := {}
var _vis: Node2D
var _t := 0.0

func _ready() -> void:
	collision_layer = Layer.WORLD | Layer.FRAME
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(width, 14)
	col.shape = rs
	col.position = Vector2(0, -7)
	add_child(col)
	_vis = Node2D.new()
	add_child(_vis)
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-width / 2, 0), Vector2(-width / 2 + 8, -14), Vector2(width / 2 - 8, -14), Vector2(width / 2, 0)])
	base.color = Color(0.45, 0.55, 0.95)
	_vis.add_child(base)
	for k in 5:
		var cr := Polygon2D.new()
		var x := -width / 2 + 12 + k * (width - 24) / 4.0
		var h := 14.0 + (k % 2) * 8.0
		cr.polygon = PackedVector2Array([Vector2(x - 6, -12), Vector2(x, -12 - h), Vector2(x + 6, -12)])
		cr.color = [Color(0.6, 0.85, 1.0), Color(0.8, 0.6, 1.0), Color(0.6, 1.0, 0.85)][k % 3]
		_vis.add_child(cr)
	Shimmer.apply(_vis, 0.35, 0.8)

func _physics_process(delta: float) -> void:
	_t += delta
	_vis.modulate = Color(1, 1, 1).lerp(Color(1.4, 1.4, 1.6), 0.5 + 0.5 * sin(_t * 3.0))
	for k in _cd.keys():
		_cd[k] -= delta
		if _cd[k] <= 0.0:
			_cd.erase(k)
	for n in get_parent().get_children():
		if not (n is Player) or not n.is_alive() or _cd.has(n) or n.flying:
			continue
		var feet: float = n.global_position.y + n.body_size.y / 2
		if absf(n.global_position.x - global_position.x) < width / 2 + n.body_size.x * 0.2 \
				and absf(feet - (global_position.y - 14.0)) < 10.0 and n.velocity.y >= -10.0:
			_cd[n] = 0.5
			n.velocity.y = -power
			Fx.ring(get_parent(), global_position + Vector2(0, -10), 70.0, Color(0.7, 0.85, 1.0, 0.9), 0.35, 5.0, 0.4)
			Fx.sparks(get_parent(), global_position + Vector2(0, -12), Color(0.8, 0.9, 1.0), 10, 260.0, 3.0, true)
			_vis.scale = Vector2(1.2, 0.6)
			create_tween().tween_property(_vis, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
