class_name SwampBits
# ---------- Механики Болота ----------
#   MudPuddle — лужа трясины: кто в ней стоит (герой или враг), тот вязнет и
#               двигается вдвое медленнее; пузыри на поверхности.
#   GasVent   — болотный газ: со дна поднимаются пузыри, потом — вспышка,
#               которая ранит всех рядом. Пузыри растут заранее — видно, куда не стоит лезть.
#   SinkingLog — бревно-плот: если на нём стоять, медленно уходит в трясину,
#               а без седока всплывает обратно.

class MudPuddle extends Node2D:
	var width := 260.0
	var life := 0.0                     # 0 — навсегда; иначе лужица высыхает
	var team := -1                      # -1 — вязнут все; иначе только враги этой команды (лужи Осоки)
	var _t := 0.0
	var _bubbles: Array = []

	func _ready() -> void:
		z_index = 2
		var mud := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 13:
			var x := -width / 2 + width * i / 12.0
			pts.append(Vector2(x, -4.0 - sin(PI * i / 12.0) * 3.0))
		pts.append(Vector2(width / 2, 10))
		pts.append(Vector2(-width / 2, 10))
		mud.polygon = pts
		mud.color = Color(0.13, 0.17, 0.08, 0.95) if team < 0 else Color(0.17, 0.27, 0.12, 0.92)   # лужи Осоки — зеленее
		add_child(mud)
		var rim := Line2D.new()                          # кромка тины по краю лужи
		rim.points = pts.slice(0, 13)
		rim.width = 3.0
		rim.default_color = Color(0.40, 0.52, 0.20, 0.9)
		add_child(rim)
		var shine := Line2D.new()
		shine.points = PackedVector2Array([Vector2(-width * 0.3, -3), Vector2(width * 0.1, -4)])
		shine.width = 2.0
		shine.default_color = Color(0.62, 0.72, 0.42, 0.55)
		add_child(shine)
		for k in 3:                                      # ряска
			var dw := Polygon2D.new()
			dw.polygon = Util.circle(3.0 + k, 8)
			dw.scale = Vector2(1.6, 0.5)
			dw.color = Color(0.45, 0.62, 0.22, 0.85)
			dw.position = Vector2(-width * 0.35 + k * width * 0.3, -2.0)
			add_child(dw)
		for k in 4:
			var b := Polygon2D.new()
			b.polygon = Util.circle(3.0, 8)
			b.color = Color(0.45, 0.52, 0.28, 0.9)
			b.position = Vector2(randf_range(-width / 2 + 10, width / 2 - 10), -4)
			add_child(b)
			_bubbles.append(b)

	func _physics_process(delta: float) -> void:
		_t += delta
		if life > 0.0:
			if _t > life:
				modulate.a -= delta * 2.0
				if modulate.a <= 0.0:
					queue_free()
					return
		for i in _bubbles.size():
			var b: Polygon2D = _bubbles[i]
			var k := fmod(_t * 0.6 + i * 0.27, 1.0)
			b.scale = Vector2.ONE * (0.3 + k * 1.2)
			b.modulate.a = 1.0 - k
		for n in get_parent().get_children():
			if not (n is Player) or not n.is_alive() or n.flying:
				continue
			var feet: float = n.global_position.y + n.body_size.y / 2
			if absf(n.global_position.x - global_position.x) < width / 2 and absf(feet - global_position.y) < 16.0:
				if n.kit is OsokaKit:
					n.kit.in_mud()                        # Осока в трясине не вязнет, а скользит
					continue
				if team >= 0 and n.team == team:
					continue
				n.slow(0.2, 0.5, "mud")                  # вязнет в трясине
				if n.is_on_floor() and absf(n.velocity.x) > 40.0 and randf() < 0.08:
					Fx.sparks(get_parent(), Vector2(n.global_position.x, global_position.y - 4), Color(0.3, 0.34, 0.18), 3, 90.0, 3.0, true)

class GasVent extends Node2D:
	var _t := 0.0
	var _state := "idle"
	var _bubbles: Array = []

	func _ready() -> void:
		z_index = 2
		_t = randf_range(2.0, 6.0)
		for k in 6:
			var b := Polygon2D.new()
			b.polygon = Util.circle(6.0, 10)
			b.color = Color(0.55, 0.85, 0.35, 0.0)
			b.position = Vector2(randf_range(-30, 30), -randf_range(4, 40))
			add_child(b)
			_bubbles.append(b)

	func _physics_process(delta: float) -> void:
		_t -= delta
		match _state:
			"idle":
				if _t <= 0.0:
					_state = "warn"
					_t = 1.3
			"warn":
				for b in _bubbles:
					b.color.a = 0.75
					b.scale = Vector2.ONE * (0.4 + (1.3 - _t) * 1.0 + 0.2 * sin(_t * 20.0 + b.position.x))
					b.position.y -= delta * 20.0
					if b.position.y < -70.0:
						b.position.y = -6.0
				if _t <= 0.0:
					_boom()
					_state = "idle"
					_t = randf_range(6.0, 9.0)

	func _boom() -> void:
		for b in _bubbles:
			b.color.a = 0.0
		var world := get_parent()
		var at := global_position + Vector2(0, -24)
		Util.explode(world, at, 120.0, 16, 25, -1, null, true)         # вспышка бьёт всех рядом
		Fx.ring(world, at, 130.0, Color(0.6, 1.0, 0.4, 0.9), 0.4, 7.0)
		Fx.sparks(world, at, Color(0.7, 1.0, 0.4), 16, 260.0, 5.0, true)
		SwampBits.puff(world, at, 1.0)

# Лёгкое зелёное облачко газа: поднимается и тает за секунду-полторы, не закрывает обзор
static func puff(world: Node, at: Vector2, size: float) -> void:
	for k in 7:
		var c := Polygon2D.new()
		c.polygon = Util.circle(randf_range(22.0, 38.0) * size, 12)
		c.color = Color(0.55, 0.85, 0.35, 0.38)
		c.position = at + Vector2(randf_range(-50, 50), randf_range(-20, 20)) * size
		c.scale = Vector2(0.3, 0.3)
		c.z_index = 4
		world.add_child(c)
		var t := c.create_tween()
		t.set_parallel(true)
		t.tween_property(c, "scale", Vector2(1.3, 1.3), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(c, "position:y", c.position.y - randf_range(40, 80) * size, 1.4)
		t.tween_property(c, "modulate:a", 0.0, 0.9).set_delay(0.5)
		t.chain().tween_callback(c.queue_free)

class SinkingLog extends AnimatableBody2D:
	var width := 220.0
	var depth := 60.0
	var _rest_y := 0.0
	var _vis: Node2D

	func _ready() -> void:
		collision_layer = Layer.WORLD | Layer.FRAME
		sync_to_physics = true
		_rest_y = position.y
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(width, 20)
		col.shape = rs
		col.one_way_collision = true
		add_child(col)
		_vis = Node2D.new()
		add_child(_vis)
		var log_p := Polygon2D.new()
		log_p.polygon = PackedVector2Array([Vector2(-width / 2, -10), Vector2(width / 2, -10), Vector2(width / 2 + 6, 0),
				Vector2(width / 2, 10), Vector2(-width / 2, 10), Vector2(-width / 2 - 6, 0)])
		Tex.apply(log_p, "mine_wood", Color(0.36, 0.28, 0.18))
		_vis.add_child(log_p)
		for x in [-width / 2, width / 2]:
			var end := Polygon2D.new()
			end.polygon = Util.circle(9.0, 12)
			end.color = Color(0.55, 0.44, 0.28)
			end.position = Vector2(x, 0)
			_vis.add_child(end)
		for k in 3:
			var moss := Polygon2D.new()
			moss.polygon = PackedVector2Array([Vector2(-14, -10), Vector2(14, -10), Vector2(8, -14), Vector2(-8, -15)])
			moss.color = Color(0.32, 0.45, 0.20)
			moss.position = Vector2(-width / 3 + k * width / 3, 0)
			_vis.add_child(moss)

	func _physics_process(delta: float) -> void:
		var riders := 0
		for n in get_parent().get_children():
			if n is Player and n.is_alive() and not n.flying:
				var feet: float = n.global_position.y + n.body_size.y / 2
				if absf(n.global_position.x - global_position.x) < width / 2 + 6.0 and absf(feet - (global_position.y - 10.0)) < 8.0:
					riders += 1
		var goal := _rest_y + (depth if riders > 0 else 0.0)
		position.y = move_toward(position.y, goal, delta * (45.0 if riders > 0 else 30.0))
		_vis.rotation = sin(Time.get_ticks_msec() * 0.002 + _rest_y) * 0.02
