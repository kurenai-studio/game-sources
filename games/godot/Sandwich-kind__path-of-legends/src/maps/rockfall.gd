class_name Rockfall
extends Node2D
# ---------- Камнепад (Пещеры) ----------
# Время от времени со свода срываются камни. Сначала с потолка сыплется пыль,
# а на земле видна тень — есть секунда, чтобы отбежать. Камень бьёт всех,
# в кого попал: и героя, и противников (заманивай врагов под тень!), и ломает блоки.

var ceiling := 30.0
var floor_y := 940.0
var map_w := 2600.0
var _t := 5.0

func _physics_process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = randf_range(3.5, 6.5)
	var world := get_parent()
	# чаще — рядом с кем-нибудь из бойцов, иногда — где попало
	var who: Array = []
	for n in world.get_children():
		if n is Player and n.is_alive() and not n.is_minion:
			who.append(n)
	var x := randf_range(150.0, map_w - 150.0)
	if not who.is_empty() and randf() < 0.75:
		var w: Player = who[randi() % who.size()]
		x = clampf(w.global_position.x + randf_range(-120.0, 120.0), 150.0, map_w - 150.0)
	_drop(x)

func _drop(x: float) -> void:
	var world := get_parent()
	var space := get_world_2d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, ceiling + 40.0), Vector2(x, floor_y + 20.0),
			Layer.WORLD | Layer.FRAME))
	var land: float = hit["position"].y if not hit.is_empty() else floor_y
	# предупреждение: пыль со свода и тень на земле
	Fx.sparks(world, Vector2(x, ceiling + 30.0), Color(0.55, 0.5, 0.45), 8, 90.0, 3.0)
	Fx.cracks(world, Vector2(x, ceiling + 34.0), Color(0.18, 0.16, 0.16), 40.0)
	var shadow := Polygon2D.new()
	var pts := Util.circle(34.0, 16)
	for i in pts.size():
		pts[i].y *= 0.25
	shadow.polygon = pts
	shadow.color = Color(0, 0, 0, 0.0)
	shadow.position = Vector2(x, land - 2.0)
	shadow.scale = Vector2(0.3, 0.3)
	shadow.z_index = 3
	world.add_child(shadow)
	var st := shadow.create_tween()
	st.set_parallel(true)
	st.tween_property(shadow, "scale", Vector2.ONE, 1.1)
	st.tween_property(shadow, "color:a", 0.5, 1.1)
	# камень появляется, когда тень «созрела»; твин живёт на тени — пропадёт вместе с ареной
	var top := ceiling + 20.0
	st.chain().tween_callback(func():
		var rock := FallingRock.new()
		rock.position = Vector2(x, top)
		rock.land_y = land
		rock.shadow = shadow
		shadow.get_parent().add_child(rock))

class FallingRock extends Node2D:
	var land_y := 900.0
	var shadow: Node2D
	var _v := 200.0
	var _hit := {}
	var _vis: Polygon2D

	func _ready() -> void:
		z_index = 4
		_vis = Polygon2D.new()
		_vis.polygon = PackedVector2Array([Vector2(-22, -10), Vector2(-8, -26), Vector2(14, -22), Vector2(24, -2),
				Vector2(16, 18), Vector2(-10, 20), Vector2(-24, 6)])
		Tex.apply(_vis, "rock", Color(0.44, 0.40, 0.40))
		add_child(_vis)

	func _physics_process(delta: float) -> void:
		_v += 2400.0 * delta
		position.y += _v * delta
		_vis.rotation += delta * 3.0
		for n in get_parent().get_children():
			if n is Player and n.is_alive() and not _hit.has(n):
				var d: Vector2 = n.global_position - global_position
				if absf(d.x) < n.body_size.x / 2 + 20.0 and absf(d.y) < n.body_size.y / 2 + 20.0:
					_hit[n] = true
					n.take_damage(20)                       # камень бьёт всех — и своих, и чужих
					n.stun(0.5)
		if position.y >= land_y - 16.0:
			var world := get_parent()
			Util.explode(world, Vector2(position.x, land_y - 6.0), 60.0, 0, 30, -1, null)
			Fx.sparks(world, Vector2(position.x, land_y - 6.0), Color(0.5, 0.46, 0.44), 14, 260.0, 5.0, true)
			Fx.ring(world, Vector2(position.x, land_y), 70.0, Color(0.6, 0.55, 0.5, 0.8), 0.3, 5.0, 0.3)
			if is_instance_valid(shadow):
				shadow.queue_free()
			queue_free()
