class_name SwampWake
extends Node2D
# ---------- Ульта Осоки «Пробуждение топи» ----------
# Осока втыкает посох в землю — земля вокруг (под каждым местом — своя высота)
# на 8 секунд превращается в болото. Враги в нём вдвое медленнее и не могут
# прыгать; каждую секунду из грязи вылезают руки и хватают случайного врага
# (урон и держат 1 с). Сама Осока в этом болоте скользит, а Нырок
# перезаряжается вдвое быстрее.
# МЕГА: за спиной поднимается моховая тень Трясинного Владыки и дважды бьёт
#   огромной лапой перед собой (сильный урон, ломает блоки).
# Арена: 10 с, зона шире, руки хватают чаще.

var team := 0
var owner_p: Player
var mega := false
var arena := false
var dur := 8.0
var half_w := 450.0
var hand_every := 1.0

const COL := 50.0
var _cols: Array = []           # [x, y земли] — где разлилось болото
var _t := 0.0
var _hand_t := 0.6
var _shadow: BotRig
var _slams := []

func _ready() -> void:
	z_index = 2
	if arena:
		dur = 10.0
		half_w = 600.0
		hand_every = 0.6
	var space := get_world_2d().direct_space_state
	var from_y: float = owner_p.global_position.y - 40.0 if is_instance_valid(owner_p) else global_position.y - 40.0
	var map_w: float = owner_p.map_w if is_instance_valid(owner_p) else 2600.0
	var x := global_position.x - half_w
	while x <= global_position.x + half_w:
		if x > 30.0 and x < map_w - 30.0:
			var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, from_y + 700.0), Layer.WORLD | Layer.FRAME))
			if not hit.is_empty():
				_cols.append(Vector2(x, hit["position"].y))
		x += COL
	# болото: по полоске грязи на каждую колонку + пузыри и камыш
	for c in _cols:
		var m := Polygon2D.new()
		m.polygon = PackedVector2Array([Vector2(-COL / 2 - 2, -3 - randf() * 3), Vector2(COL / 2 + 2, -3 - randf() * 3),
				Vector2(COL / 2 + 2, 8), Vector2(-COL / 2 - 2, 8)])
		m.color = Color(0.17, 0.26, 0.11, 0.0)
		m.position = c - global_position
		add_child(m)
		var mt := m.create_tween()
		mt.tween_property(m, "color:a", 0.93, 0.4 + absf(c.x - global_position.x) / half_w * 0.5)
		if randf() < 0.35:
			var reed := Line2D.new()
			reed.points = PackedVector2Array([Vector2(0, 0), Vector2(randf_range(-4, 4), -randf_range(18, 34))])
			reed.width = 2.0
			reed.default_color = Color(0.36, 0.52, 0.24)
			reed.position = c - global_position + Vector2(randf_range(-20, 20), -2)
			reed.scale = Vector2(1, 0)
			add_child(reed)
			reed.create_tween().tween_property(reed, "scale", Vector2.ONE, 0.6).set_delay(0.3)
	Fx.ring(get_parent(), global_position, 160.0, Color(0.55, 0.85, 0.35, 0.9), 0.5, 8.0)
	if mega:
		_summon_shadow()

func _col_at(x: float) -> int:
	for i in _cols.size():
		if absf(_cols[i].x - x) <= COL / 2 + 0.5:
			return i
	return -1

# Стоит ли этот боец в болоте (ногами на земле зоны)
func is_in(n: Player) -> bool:
	var i := _col_at(n.global_position.x)
	if i < 0:
		return false
	var feet: float = n.global_position.y + n.body_size.y / 2
	return absf(feet - _cols[i].y) < 26.0

func _physics_process(delta: float) -> void:
	_t += delta
	var world := get_parent()
	var victims: Array = []
	for n in world.get_children():
		if not (n is Player) or not n.is_alive():
			continue
		if not is_in(n):
			continue
		if n.team == team:
			if n.kit is OsokaKit:
				n.kit.in_mud()
			continue
		if n.flying:
			continue
		n.slow(0.2, 0.5, "mud")
		n._no_jump_t = maxf(n._no_jump_t, 0.2)
		victims.append(n)
	# пузыри на болоте
	if randf() < delta * 8.0 and not _cols.is_empty():
		var c: Vector2 = _cols[randi() % _cols.size()]
		Fx.sparks(world, c + Vector2(randf_range(-20, 20), -4), Color(0.4, 0.55, 0.25), 2, 60.0, 3.0, true)
	_hand_t -= delta
	if _hand_t <= 0.0 and _t < dur - 0.3:
		_hand_t = hand_every
		if not victims.is_empty():
			_hand(victims[randi() % victims.size()])
	for s in _slams.duplicate():
		if _t >= s:
			_slams.erase(s)
			_slam()
	if _t >= dur:
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.5)
		t.tween_callback(queue_free)
		if is_instance_valid(_shadow):
			var st := _shadow.create_tween()
			st.tween_property(_shadow, "modulate:a", 0.0, 0.5)
			st.tween_callback(_shadow.queue_free)
		set_physics_process(false)

# Рука из грязи хватает врага
func _hand(e: Player) -> void:
	var world := get_parent()
	var feet := Vector2(e.global_position.x, e.global_position.y + e.body_size.y / 2)
	var h := Node2D.new()
	h.position = feet + Vector2(0, 10)
	h.z_index = 4
	var palm := Polygon2D.new()
	palm.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-14, -26), Vector2(-9, -40), Vector2(-6, -28), Vector2(-3, -44),
			Vector2(0, -28), Vector2(4, -42), Vector2(6, -27), Vector2(11, -36), Vector2(13, -22), Vector2(12, 0)])
	palm.color = Color(0.34, 0.42, 0.26)
	h.add_child(palm)
	var drip := Polygon2D.new()
	drip.polygon = PackedVector2Array([Vector2(-12, -6), Vector2(12, -6), Vector2(10, 0), Vector2(-10, 0)])
	drip.color = Color(0.22, 0.28, 0.14)
	h.add_child(drip)
	world.add_child(h)
	var t := h.create_tween()
	t.tween_property(h, "position:y", feet.y - 14.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.85)
	t.tween_property(h, "position:y", feet.y + 40.0, 0.3)
	t.tween_callback(h.queue_free)
	e.root(1.0)
	e.take_damage(10, owner_p if is_instance_valid(owner_p) else null)
	Fx.sparks(world, feet, Color(0.3, 0.36, 0.2), 8, 160.0, 4.0, true)

# ---------- МЕГА: тень Трясинного Владыки ----------
func _summon_shadow() -> void:
	if not is_instance_valid(owner_p):
		return
	var world := get_parent()
	_shadow = BotRig.new()
	_shadow.kind = "bog_lord"
	_shadow.size = Bots.TYPES["bog_lord"]["size"]
	_shadow.puppet_facing = owner_p.facing
	_shadow.z_index = -2
	_shadow.modulate = Color(0.55, 0.85, 0.50, 0.0)
	var ground := owner_p.global_position.y + owner_p.body_size.y / 2
	_shadow.position = Vector2(owner_p.global_position.x - owner_p.facing * 90.0, ground - _shadow.size.y / 2 + 60.0)
	world.add_child(_shadow)
	var t := _shadow.create_tween()
	t.set_parallel(true)
	t.tween_property(_shadow, "modulate:a", 0.55, 0.8)
	t.tween_property(_shadow, "position:y", ground - _shadow.size.y / 2, 0.9).set_trans(Tween.TRANS_SINE)
	_slams = [1.4, 3.2]

func _slam() -> void:
	if not is_instance_valid(_shadow) or not is_instance_valid(owner_p):
		return
	var world := get_parent()
	var f := float(_shadow.puppet_facing)
	_shadow.play("slam")
	var lunge := _shadow.create_tween()
	lunge.tween_property(_shadow, "position:x", _shadow.position.x + f * 60.0, 0.15)
	lunge.tween_property(_shadow, "position:x", _shadow.position.x, 0.4)
	var ground := _shadow.position.y + _shadow.size.y / 2
	var cx := _shadow.position.x + f * 300.0
	for e in world.get_children():
		if e is Player and e.team != team and e.is_alive() and absf(e.global_position.x - cx) < 230.0 \
				and absf(e.global_position.y + e.body_size.y / 2 - ground) < 160.0:
			e.take_damage(30, owner_p)
			e.velocity = Vector2(f * 420.0, -700.0)
	# лапа ломает блоки перед собой (без огненной вспышки — это грязь, а не взрыв)
	for n in world.get_children():
		if n is Destructible and n.shield_team != team and not n.background and absf(n.global_position.x - cx) < 500.0:
			var hx := -200.0
			while hx <= 200.0:
				n.hit(Vector2(cx + hx, ground - 20.0), Vector2.DOWN, 60, 40.0, team, {"strict": true, "attacker": owner_p, "power": 0.8})
				hx += 40.0
	Fx.ring(world, Vector2(cx, ground), 240.0, Color(0.5, 0.75, 0.35, 0.95), 0.45, 9.0)
	Fx.cracks(world, Vector2(cx, ground), Color(0.22, 0.2, 0.14), 160.0)
	Fx.sparks(world, Vector2(cx, ground - 10), Color(0.32, 0.36, 0.2), 20, 360.0, 5.0, true)
	Fx.shake(world, 8.0)
