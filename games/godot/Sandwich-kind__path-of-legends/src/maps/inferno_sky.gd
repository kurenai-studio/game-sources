class_name InfernoSky
extends Node2D
# ---------- Небо второй фазы Колосса ----------
# Когда Колосс пробуждается, ночной Колизей загорается:
#   • небо и трибуны наливаются красным, луна становится багровой;
#   • по небу на фоне то и дело проносятся огненные кометы;
#   • с арены вверх летят искры, факелы на стенах разгораются втрое;
#   • МЕТЕОРЫ (по-настоящему опасные): на земле загорается круг-предупреждение,
#     через секунду туда падает огненный камень — взрыв и горящая земля.
#     Падают рядом с героями; чем меньше у Колосса здоровья, тем чаще.
# Колосс повержен окончательно — метеоры прекращаются, небо медленно гаснет.

var boss: Player
var floor_y := 940.0
var map_w := 2600.0
var glow: CanvasLayer

var _sky: Polygon2D
var _t := 0.0
var _comet_t := 0.5
var _ember_t := 0.0
var _meteor_t := 2.5
var _ending := false

func _ready() -> void:
	z_index = -9
	# красное зарево поверх фона (под всем остальным)
	_sky = Polygon2D.new()
	_sky.polygon = PackedVector2Array([Vector2(-200, -1200), Vector2(map_w + 200, -1200),
			Vector2(map_w + 200, floor_y), Vector2(-200, floor_y)])
	_sky.color = Color(1.0, 0.28, 0.08, 0.0)
	add_child(_sky)
	var t := create_tween()
	t.tween_property(_sky, "color:a", 0.30, 2.0)
	# багровая луна и разгоревшиеся факелы
	if glow:
		for n in glow.get_children():
			if n is Polygon2D:
				n.create_tween().tween_property(n, "color", Color(1.0, 0.42, 0.25), 2.0)
		var red := Torch.make_glow(900.0, Color(1.0, 0.35, 0.1, 0.0))
		red.position = Vector2(map_w / 2, floor_y - 500)
		glow.add_child(red)
		red.create_tween().tween_property(red, "modulate:a", 0.45, 2.5)
	for n in get_parent().get_children():
		if n is Torch:
			var tt := n.create_tween()
			tt.tween_property(n, "scale", Vector2(1.7, 1.9), 1.2).set_trans(Tween.TRANS_BACK)

func _process(delta: float) -> void:
	_t += delta
	var alive := is_instance_valid(boss) and boss.is_alive()
	if not alive and not _ending:
		_end()
	# кометы на фоне
	_comet_t -= delta
	if _comet_t <= 0.0 and not _ending:
		_comet_t = randf_range(0.5, 1.3)
		_comet()
	# искры летят вверх
	_ember_t -= delta
	if _ember_t <= 0.0:
		_ember_t = 0.07 if not _ending else 0.3
		_ember()

func _physics_process(delta: float) -> void:
	if _ending or not is_instance_valid(boss) or not boss.is_alive():
		return
	if boss.cutscene_shield or boss.frozen:
		return
	_meteor_t -= delta
	if _meteor_t <= 0.0:
		var ratio := float(boss.hp) / maxf(1.0, boss.max_hp)
		_meteor_t = randf_range(3.2, 4.8) if ratio > 0.5 else randf_range(2.2, 3.4)
		var heroes: Array = []
		for n in get_parent().get_children():
			if n is Player and n.team != boss.team and n.is_alive() and not n.is_minion:
				heroes.append(n)
		if heroes.is_empty():
			return
		var count := 2 if ratio > 0.5 else 3
		for k in count:
			var h: Player = heroes[randi() % heroes.size()]
			var x := clampf(h.global_position.x + randf_range(-320.0, 320.0) * (0.3 if k == 0 else 1.0), 90.0, map_w - 90.0)
			var tw := create_tween()            # твин живёт вместе с небом
			tw.tween_interval(k * 0.35 + 0.01)
			tw.tween_callback(_drop_meteor.bind(x))

func _drop_meteor(x: float) -> void:
	if not is_inside_tree() or _ending:
		return
	var m := Meteor.new()
	m.team = boss.team if is_instance_valid(boss) else 1
	m.attacker = boss if is_instance_valid(boss) else null
	m.target_x = x
	m.floor_y = floor_y
	get_parent().add_child(m)

func _comet() -> void:
	var c := Node2D.new()
	c.z_index = -9
	var from := Vector2(randf_range(-100, map_w + 100), randf_range(-500, floor_y - 650))
	var dir := Vector2(randf_range(-1.0, 1.0), randf_range(0.35, 0.8)).normalized()
	c.position = from
	var tail := Line2D.new()
	tail.points = PackedVector2Array([Vector2.ZERO, -dir * randf_range(90, 160)])
	tail.width = 5.0
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.4, 0.95))
	g.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	tail.gradient = g
	c.add_child(tail)
	var head := Polygon2D.new()
	head.polygon = Util.circle(5.0, 10)
	head.color = Color(1.0, 0.95, 0.7)
	c.add_child(head)
	add_child(c)
	var t := c.create_tween()
	t.tween_property(c, "position", from + dir * randf_range(700, 1100), 1.3)
	t.parallel().tween_property(c, "modulate:a", 0.0, 0.5).set_delay(0.8)
	t.tween_callback(c.queue_free)

func _ember() -> void:
	var parent: Node = glow if glow else self
	var e: Node2D = Torch.make_glow(randf_range(12.0, 22.0), Color(1.0, randf_range(0.4, 0.7), 0.15, 0.9)) if glow else Polygon2D.new()
	if e is Polygon2D:
		(e as Polygon2D).polygon = Util.circle(2.5, 6)
		(e as Polygon2D).color = Color(1.0, 0.6, 0.2)
	e.position = Vector2(randf_range(60.0, map_w - 60.0), floor_y - randf_range(0.0, 40.0))
	parent.add_child(e)
	var t := e.create_tween()
	t.tween_property(e, "position", e.position + Vector2(randf_range(-80, 80), -randf_range(250, 520)), randf_range(2.0, 3.2))
	t.parallel().tween_property(e, "modulate:a", 0.0, 1.0).set_delay(1.4)
	t.tween_callback(e.queue_free)

# Колосс повержен — небо гаснет, факелы стихают
func _end() -> void:
	_ending = true
	var t := create_tween()
	t.tween_property(_sky, "color:a", 0.0, 3.0)
	for n in get_parent().get_children():
		if n is Torch:
			n.create_tween().tween_property(n, "scale", Vector2.ONE, 2.0)
	t.tween_interval(1.5)
	t.tween_callback(queue_free)

# ---------- Метеор ----------
class Meteor extends Node2D:
	var team := 1
	var attacker: Player
	var target_x := 0.0
	var floor_y := 940.0
	const WARN := 1.2
	var _t := 0.0
	var _ground := Vector2.ZERO
	var _mark: Node2D
	var _rock: Node2D
	var _from := Vector2.ZERO

	func _ready() -> void:
		z_index = 6
		var space := get_world_2d().direct_space_state
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(target_x, floor_y - 900.0),
				Vector2(target_x, floor_y + 30.0), Layer.WORLD | Layer.FRAME))
		_ground = Vector2(target_x, hit["position"].y if not hit.is_empty() else floor_y)
		# круг-предупреждение на земле
		_mark = Node2D.new()
		_mark.position = _ground
		var ring := Line2D.new()
		var pts := Util.circle(80.0, 28)
		for i in pts.size():
			pts[i].y *= 0.28
		pts.append(pts[0])
		ring.points = pts
		ring.width = 3.0
		ring.default_color = Color(1.0, 0.35, 0.15, 0.9)
		_mark.add_child(ring)
		var fill := Polygon2D.new()
		fill.polygon = pts
		fill.color = Color(1.0, 0.3, 0.1, 0.18)
		_mark.add_child(fill)
		_mark.scale = Vector2(0.3, 0.3)
		add_child(_mark)
		_mark.create_tween().tween_property(_mark, "scale", Vector2.ONE, WARN)
		# сам камень — сверху наискосок
		_from = _ground + Vector2(randf_range(-260.0, 260.0), -1100.0)
		_rock = Node2D.new()
		var tail := Line2D.new()
		tail.points = PackedVector2Array([Vector2.ZERO, (_from - _ground).normalized() * 150.0])
		tail.width = 16.0
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.8, 0.3, 0.95))
		g.set_color(1, Color(1.0, 0.25, 0.05, 0.0))
		tail.gradient = g
		_rock.add_child(tail)
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([Vector2(-16, -6), Vector2(-6, -17), Vector2(10, -14), Vector2(17, 0),
				Vector2(9, 14), Vector2(-9, 15), Vector2(-17, 4)])
		body.color = Color(0.35, 0.18, 0.12)
		_rock.add_child(body)
		var core := Polygon2D.new()
		core.polygon = Util.circle(8.0, 10)
		core.color = Color(1.0, 0.6, 0.2)
		_rock.add_child(core)
		_rock.position = _from
		_rock.visible = false
		add_child(_rock)

	func _physics_process(delta: float) -> void:
		_t += delta
		var fall := 0.45
		if _t >= WARN - fall:
			_rock.visible = true
			var k := clampf((_t - (WARN - fall)) / fall, 0.0, 1.0)
			_rock.position = _from.lerp(_ground, k * k)
			_rock.rotation += delta * 6.0
		if _t >= WARN:
			_impact()

	func _impact() -> void:
		var world := get_parent()
		Util.explode(world, _ground + Vector2(0, -12), 95.0, 13, 40, team, attacker if is_instance_valid(attacker) else null, true)
		Fx.ring(world, _ground, 110.0, Color(1.0, 0.55, 0.2, 0.95), 0.35, 7.0, 0.3)
		Fx.sparks(world, _ground + Vector2(0, -6), Color(1.0, 0.6, 0.2), 16, 300.0, 5.0, true)
		Fx.cracks(world, _ground, Color(0.25, 0.12, 0.08), 70.0)
		var fz := FireZone.new()
		fz.team = team
		fz.attacker = attacker if is_instance_valid(attacker) else null
		fz._life = 2.5
		fz.position = _ground + Vector2(0, -6)
		world.add_child(fz)
		queue_free()
