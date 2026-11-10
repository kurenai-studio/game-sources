class_name PrismRay
extends Node2D
# ---------- Ульта Призмы: «Радужный луч» ----------
# Перед героем появляются 7 цветных кристаллов. После подготовки из каждого бьёт
# тонкий луч к точке схождения перед героем — там рождается большой белый луч.
#   • луч мгновенный и упирается в ближайшую цель, нанося непрерывный урон;
#   • сквозь блоки не проходит, но выжигает их — прожигает себе путь;
#   • сквозь врагов не проходит: жжёт ближайшего, когда тот падёт — следующего;
#   • проходя сквозь свою зеркальную стену (или зеркальный кристалл), усиливается:
#     урон больше, цвет переливается радугой.
# Пока луч горит, герой идёт медленно и может только ставить зеркальную стену.
# МЕГА: каждый кристалл ещё и сам бьёт вперёд тонким лучом своего цвета.

var p: Player
var mega := false
var prep := 1.1
var dur := 4.0
var dps := 160.0                 # урон в секунду по врагу (сквозь своё зеркало — ×AMP)
const AMP := 2.6
var _t := 0.0
var _tick := 0.0
var _crystals: Array = []
var _feeds: Array = []
var _side: Array = []
var _laser: Array = []
var _end_glow: Polygon2D
var _hit_info := {}
var _side_info: Array = []
var _amp := false
var _done := false

const COLORS := [Color(1.0, 0.25, 0.3), Color(1.0, 0.6, 0.2), Color(1.0, 0.95, 0.3), Color(0.35, 1.0, 0.45),
		Color(0.3, 0.85, 1.0), Color(0.35, 0.45, 1.0), Color(0.8, 0.4, 1.0)]
const MASK := Layer.WORLD | Layer.FRAME | Layer.PLAYER | Layer.BOT
const TICK := 0.1
const FOCUS := 62.0              # луч сходится совсем рядом с героем — зеркало встаёт дальше (см. PrismKit)
const LEN := 2600.0

func _ready() -> void:
	z_index = 6
	for i in 7:
		var c := Node2D.new()
		var glow := Polygon2D.new()
		glow.polygon = Util.circle(16.0, 12)
		glow.color = Color(COLORS[i], 0.35)
		c.add_child(glow)
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([Vector2(0, -16), Vector2(7, -4), Vector2(5, 12), Vector2(0, 16), Vector2(-5, 12), Vector2(-7, -4)])
		body.color = COLORS[i]
		c.add_child(body)
		var face := Polygon2D.new()
		face.polygon = PackedVector2Array([Vector2(0, -14), Vector2(5, -4), Vector2(0, 2), Vector2(-3, -4)])
		face.color = Color(COLORS[i].lightened(0.55), 0.95)
		c.add_child(face)
		c.scale = Vector2.ZERO
		add_child(c)
		_crystals.append(c)
		var t := c.create_tween()
		t.tween_interval(i * 0.1)
		t.tween_property(c, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var f := _line(4.0, Color(COLORS[i], 0.9))
		f.visible = false
		_feeds.append(f)
		if mega:
			var sb := [_line(10.0, Color(COLORS[i], 0.3)), _line(4.0, COLORS[i]), _line(1.5, Color(1, 1, 1, 0.9))]
			for l in sb:
				l.visible = false
			_side.append(sb)
			_side_info.append({})
	for w in [[36.0, Color(1, 1, 1, 0.28)], [18.0, Color(0.95, 0.97, 1.0, 0.9)], [7.0, Color(1, 1, 1, 1)]]:
		var l := _line(w[0], w[1])
		l.visible = false
		_laser.append(l)
	_end_glow = Polygon2D.new()
	_end_glow.polygon = Util.circle(26.0, 14)
	_end_glow.color = Color(1, 1, 1, 0.8)
	_end_glow.visible = false
	add_child(_end_glow)
	Shimmer.apply(self, 0.25, 0.8)
	_place()

func _line(w: float, c: Color) -> Line2D:
	var l := Line2D.new()
	l.width = w
	l.default_color = c
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.use_parent_material = true
	add_child(l)
	return l

func _dir() -> Vector2:
	return Vector2(p.facing, 0)

func focus() -> Vector2:
	return p.global_position + Vector2(0, -14) + _dir() * FOCUS

func _crystal_pos(i: int) -> Vector2:
	var back := PI if p.facing > 0 else 0.0
	var a := back + lerpf(-1.3, 1.3, i / 6.0) * (1.0 if p.facing > 0 else -1.0)
	var bob := sin(_t * 4.0 + i) * 4.0
	return focus() + Vector2.from_angle(a) * 66.0 + Vector2(0, bob)

func _place() -> void:
	for i in 7:
		_crystals[i].global_position = _crystal_pos(i)
		_crystals[i].rotation = sin(_t * 3.0 + i * 0.7) * 0.25

func firing() -> bool:
	return _t >= prep and not _done

func _physics_process(delta: float) -> void:
	if _done:
		return
	if not is_instance_valid(p) or not p.is_alive():
		finish()
		return
	_t += delta
	_place()
	if _t < prep:
		# подготовка: кристаллы собираются, в точке схождения копится свет
		if fmod(_t, 0.12) < delta:
			var i := randi() % 7
			Fx.sparks(get_parent(), _crystals[i].global_position, COLORS[i], 2, 90.0, 3.0)
		return
	if _t >= prep + dur:
		finish()
		return
	var f := focus()
	var dir := _dir()
	for i in 7:
		_feeds[i].visible = true
		_feeds[i].points = PackedVector2Array([_crystals[i].global_position, f])
		_feeds[i].width = 3.0 + 1.5 * absf(sin(_t * 20.0 + i))
	# главный луч
	_hit_info = _cast(f, dir)
	var end: Vector2 = _hit_info.get("position", f + dir * LEN)
	_amp = _hit_info.get("amp", false)
	for w in get_tree().get_nodes_in_group("mirror_walls"):
		if is_instance_valid(w) and w.team == p.team and w.crosses(f, end):
			_amp = true
	var c := Color.from_hsv(fmod(_t * 1.4, 1.0), 0.65, 1.0) if _amp else Color(0.95, 0.97, 1.0)
	var k := 1.35 if _amp else 1.0
	var widths := [36.0, 18.0, 7.0]
	var cols := [Color(c, 0.3), Color(c, 0.92), Color(1, 1, 1, 1)]
	for i in 3:
		_laser[i].visible = true
		_laser[i].points = PackedVector2Array([f, end])
		_laser[i].width = widths[i] * k * (1.0 + 0.08 * sin(_t * 40.0 + i))
		_laser[i].default_color = cols[i]
	_end_glow.visible = true
	_end_glow.global_position = end
	_end_glow.color = Color(c, 0.8)
	_end_glow.scale = Vector2.ONE * (1.0 + 0.2 * sin(_t * 30.0)) * k
	# МЕГА: тонкие лучи кристаллов
	if mega:
		for i in 7:
			var from: Vector2 = _crystals[i].global_position
			_side_info[i] = _cast(from, dir)
			var e2: Vector2 = _side_info[i].get("position", from + dir * LEN)
			for l in _side[i]:
				l.visible = true
				l.points = PackedVector2Array([from, e2])
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		_burn(_hit_info, end, dir, int(round(dps * TICK * (AMP if _amp else 1.0))), 90, 16.0, c)
		if mega:
			for i in 7:
				var from2: Vector2 = _crystals[i].global_position
				_burn(_side_info[i], _side_info[i].get("position", from2 + dir * LEN), dir, 4, 26, 8.0, COLORS[i])

# Урон тому, во что упёрся луч
func _burn(info: Dictionary, at: Vector2, dir: Vector2, dmg: int, cell_dmg: int, radius: float, c: Color) -> void:
	if info.is_empty():
		return
	var world := get_parent()
	var body = info["collider"]
	if body is Player:
		body.take_damage(dmg, p)
		if randf() < 0.5:
			Fx.sparks(world, at, c, 4, 200.0, 3.0)
	elif body is Destructible:
		body.hit(at + dir * 4.0, dir, cell_dmg, radius, p.team, {"attacker": p, "strict": true})
		Fx.sparks(world, at, Color(1.0, 0.85, 0.5), 3, 180.0, 3.0)
	else:
		Fx.sparks(world, at, c, 2, 150.0, 2.5)

# Первое, во что упирается луч. Зеркальные кристаллы пропускают и усиливают.
func _cast(a: Vector2, dir: Vector2) -> Dictionary:
	var space := get_world_2d().direct_space_state
	var b := a + dir * LEN
	var ex: Array[RID] = [p.get_rid()]
	var amp := false
	for i in 14:
		var q := PhysicsRayQueryParameters2D.create(a, b, MASK, ex)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return {"amp": amp} if amp else {}
		var c = hit["collider"]
		var skip := false
		if c is Player:
			skip = not c.is_alive() or c.team == p.team or c.cutscene_shield
		elif c is Destructible:
			skip = c.background or c.shield_team == p.team or c.one_way
		elif c is Node and c.has_meta("mirror"):
			skip = true
			amp = true
		elif Util.is_one_way(c):
			skip = true
		if not skip:
			hit["amp"] = amp
			return hit
		ex.append(hit["rid"])
	return {}

func finish() -> void:
	if _done:
		return
	_done = true
	var world := get_parent()
	for i in _crystals.size():
		if is_instance_valid(_crystals[i]):
			Fx.sparks(world, _crystals[i].global_position, COLORS[i], 6, 200.0, 3.0)
	if is_instance_valid(p) and p.kit and p.kit.has_method("ult_ended"):
		p.kit.ult_ended()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)
