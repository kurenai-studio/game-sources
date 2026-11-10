class_name DuelEvents
extends Node
# События дуэли:
#   • «Подарки с неба» — в случайные точки карты падают сферы здоровья,
#     баффов и МЕГА-баффов (если включены в свитке);
#   • «Мгновенная смерть» — когда таймер раунда истекает, начинается мини-апокалипсис:
#       TEST_FIELD — из стен летят ножи (ранят только героев, сквозь всё);
#       «Два дома» — бомбардировка: бомбы взрываются и поджигают всё вокруг;
#       «Гора»     — извержение: снизу поднимается лава, с неба падают раскалённые камни.
#     Ледяная тропа — сосульки, Храм шторма — молнии, Лавовые просторы — вулканические
#     бомбы, остальные — бомбардировка или обвал. Поверх этого — общий хаос: каждые
#     несколько секунд метеоритный дождь, гроза, землетрясение или ураган; а через
#     20 с тьма начинает понемногу вытягивать жизнь (чем дальше, тем сильнее).
#     «Цитадель во тьме» — из тьмы встаёт Воплощение Тьмы (неуязвимое) и бьёт
#     МЕГА-атаками по обоим игрокам; уворачиваться можно, но всё яростнее.

const HEAL_EVERY := 10.0
const BUFF_EVERY := 14.0
const MEGA_EVERY := 30.0
const MAX_HEAL := 3
const MAX_BUFF := 3
const ORB_LIFE := 30.0

var world: Node2D
var hud: Hud
var map_id := ""
var info := {}
var players: Array = []
var opts := {}
var active := false               # идёт ли бой (во время отсчёта и между раундами — нет)

var time_left := 0.0
var doom := false                 # апокалипсис начался
var lava_y := INF                 # верх лавы (Гора)
var _t := {"heal": 3.0, "buff": 6.0, "mega": 20.0}
var _orbs := {"heal": [], "buff": [], "mega": []}
var _doom_t := 0.0
var _doom_age := 0.0
var _side := 1
var _lava: Node2D
var _lava_top: Polygon2D
var _lava_tick := 0.0
var _chaos_t := 5.0
var _drain_t := 0.0
var _gale_t := 0.0
var _gale_dir := 1.0
var _avatar: DarkAvatar
const DRAIN_AFTER := 20.0

func _ready() -> void:
	time_left = float(opts.get("sd_time", 120))

func _physics_process(delta: float) -> void:
	if not active:
		return
	_drops(delta)
	if opts.get("sd", false):
		if not doom:
			time_left -= delta
			hud.show_timer("%d:%02d" % [int(ceilf(time_left)) / 60, int(ceilf(time_left)) % 60],
					Color(1.0, 0.4, 0.3) if time_left < 10.0 else Color.WHITE)
			if time_left <= 0.0:
				_start_doom()
		else:
			_doom_age += delta
			_doom_step(delta)

# ---------- Сферы с неба ----------
func _drops(delta: float) -> void:
	var kinds := []
	if opts.get("heal", false) and not doom:
		kinds.append(["heal", HEAL_EVERY, MAX_HEAL])
	if opts.get("buffs", false):
		kinds.append(["buff", BUFF_EVERY, MAX_BUFF])
	if opts.get("mega", false):
		kinds.append(["mega", MEGA_EVERY, 1])
	for k in kinds:
		var key: String = k[0]
		_orbs[key] = _orbs[key].filter(func(o): return is_instance_valid(o))
		_t[key] -= delta
		if _t[key] <= 0.0:
			_t[key] = k[1] * randf_range(0.8, 1.2)
			if _orbs[key].size() < k[2]:
				var o := _drop(key)
				if o:
					_orbs[key].append(o)

# Совершенно случайная точка карты: случайное место в воздухе, откуда сфера
# падает до первой поверхности под ней
func _drop(key: String) -> Pickup:
	var size: Vector2 = info["size"]
	var top: float = info.get("top_y", 40.0)
	var space := world.get_world_2d().direct_space_state
	var x_lo: float = info.get("x_lo", 0.0) + 60.0
	var x_hi: float = info.get("x_hi", size.x) - 60.0
	for attempt in 40:
		var start := Vector2(randf_range(x_lo, x_hi), randf_range(top, size.y - 120))
		var pq := PhysicsPointQueryParameters2D.new()
		pq.position = start
		pq.collision_mask = Layer.WORLD
		if not space.intersect_point(pq, 1).is_empty():
			continue                         # внутри стены или блока
		if lava_y < INF and start.y > lava_y - 150:
			continue
		var rq := PhysicsRayQueryParameters2D.create(start, start + Vector2(0, 4000), Layer.WORLD)
		var hit := space.intersect_ray(rq)
		if hit.is_empty():
			continue
		var land: Vector2 = hit["position"] - Vector2(0, 34)
		if lava_y < INF and land.y > lava_y - 60:
			continue
		var p := Pickup.new()
		p.kind = "heal" if key == "heal" else Buffs.random_type()
		p.mega = key == "mega"
		p.allow_mega = opts.get("mega", false)
		p.position = Vector2(land.x, maxf(top, land.y - 500.0))   # падает с высоты
		p.land_y = land.y
		p.life = ORB_LIFE
		p.picked.connect(_on_picked.bind(p))
		world.add_child(p)
		return p
	return null

func _on_picked(text: String, color: Color, p: Pickup) -> void:
	float_text(text, color, p.global_position)

func float_text(text: String, color: Color, where: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = where + Vector2(-140, -60)
	l.size = Vector2(280, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", color)
	l.z_index = 20
	world.add_child(l)
	var t := l.create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 60.0, 1.2)
	t.tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.4)
	t.chain().tween_callback(l.queue_free)

# ---------- Мгновенная смерть ----------
func _start_doom() -> void:
	doom = true
	hud.show_timer("0:00", Color(1.0, 0.3, 0.25))
	var names := {"test_field": "Ножи из стен!", "two_houses": "Бомбардировка!", "mountain": "Извержение вулкана!",
			"test_buffs": "Бомбардировка!", "arena_colosseum": "Обстрел с трибун!", "arena_colosseum_night": "Обстрел с трибун!",
			"arena_jungle": "Бомбы гоблинов!", "arena_jungle_night": "Бомбы гоблинов!",
			"arena_caves": "Обвал!", "arena_kingdom": "Обвал!",
			"arena_ice": "Ледопад!", "arena_storm": "Гнев бури!", "arena_lava": "Вулкан проснулся!",
			"arena_throne": "Пламя бездны!", "arena_citadel": "Воплощение Тьмы пробуждается!"}
	hud.show_banner("МГНОВЕННАЯ СМЕРТЬ!", Color(1.0, 0.3, 0.25))
	var t := create_tween()
	t.tween_interval(1.3)
	t.tween_callback(hud.show_banner.bind(names.get(map_id, "Апокалипсис!"), Color(1.0, 0.6, 0.3)))
	t.tween_interval(1.4)
	t.tween_callback(hud.hide_banner)
	_doom_t = 1.5
	if map_id == "mountain":
		_make_lava()
	if map_id == "arena_citadel":
		_avatar = DarkAvatar.new()
		_avatar.duel = true
		_avatar.glow_layer = info.get("glow")
		world.add_child(_avatar)

func _doom_step(delta: float) -> void:
	_doom_t -= delta
	if map_id != "arena_citadel":
		_chaos(delta)
		_drain(delta)
	match map_id:
		"arena_citadel":
			pass                                  # всё делает Воплощение Тьмы
		"arena_ice":
			if _doom_t <= 0.0:
				_doom_t = maxf(0.25, 0.7 - _doom_age * 0.01)
				_icicle()
		"arena_storm":
			if _doom_t <= 0.0:
				_doom_t = maxf(0.35, 1.0 - _doom_age * 0.012)
				_lightning(_near_player_x(320.0), 0.9)
		"arena_lava":
			if _doom_t <= 0.0:
				_doom_t = maxf(0.25, 0.7 - _doom_age * 0.01)
				_lava_bomb()
		"test_field":
			if _doom_t <= 0.0:
				_doom_t = 1.5
				_knife_volley()
		"two_houses":
			if _doom_t <= 0.0:
				# чем дольше, тем чаще падают бомбы
				_doom_t = maxf(0.3, 0.8 - _doom_age * 0.01)
				_bomb()
		"mountain":
			_update_lava(delta)
			if _doom_t <= 0.0:
				_doom_t = maxf(0.5, 1.3 - _doom_age * 0.008)
				_rock()
		"arena_caves", "arena_kingdom":
			# обвал: со свода падают раскалённые камни
			if _doom_t <= 0.0:
				_doom_t = maxf(0.2, 0.6 - _doom_age * 0.01)
				_bomb(true)
		_:
			if _doom_t <= 0.0:
				_doom_t = maxf(0.22, 0.7 - _doom_age * 0.012)
				_bomb()

# TEST_FIELD: ножи летят из стены рядами. В каждом залпе есть «окно» из двух
# пропущенных рядов — туда и нужно успеть встать. Перед залпом на стене
# загораются отметки — видно, где полетят ножи.
func _knife_volley() -> void:
	var size: Vector2 = info["size"]
	var rows := []
	var y := 45.0
	while y < size.y - 55.0:
		rows.append(y)
		y += 45.0
	var n := rows.size()
	# окно: чаще у земли или на высоте прыжка, иногда где угодно
	var gap := n - 2 - randi() % 3 if randf() < 0.65 else randi() % (n - 1)
	var side := _side
	_side = -_side
	var x := 24.0 if side > 0 else size.x - 24.0
	for i in n:
		if i == gap or i == gap + 1:
			continue
		var mark := Polygon2D.new()
		mark.polygon = PackedVector2Array([Vector2(0, -6), Vector2(14 * side, 0), Vector2(0, 6)])
		mark.color = Color(1.0, 0.25, 0.2, 0.9)
		mark.position = Vector2(x, rows[i])
		mark.z_index = 30
		world.add_child(mark)
		var mt := mark.create_tween().set_loops(4)
		mt.tween_property(mark, "modulate:a", 0.2, 0.1)
		mt.tween_property(mark, "modulate:a", 1.0, 0.1)
		var t := mark.create_tween()
		t.tween_interval(0.85)
		t.tween_callback(mark.queue_free)
		var k := Knife.new()
		k.position = Vector2(x - side * 30.0, rows[i])
		k.dir = side
		k.delay = 0.85 + randf_range(0.0, 0.12)
		k.map_w = size.x
		world.add_child(k)

# «Два дома»: бомба падает в случайную точку; на земле — отметка, куда упадёт
func _bomb(rock := false) -> void:
	var size: Vector2 = info["size"]
	var x := randf_range(info.get("x_lo", 0.0) + 80.0, info.get("x_hi", size.x) - 80.0)
	if randf() < 0.65:          # чаще — рядом с кем-то из героев
		x = _near_player_x(450.0)
	var space := world.get_world_2d().direct_space_state
	# на открытых картах — с неба, под сводом пещеры — прямо из-под потолка
	var top: float = -700.0 if info.get("open_top", true) else info.get("top_y", 40.0) + 10.0
	var rq := PhysicsRayQueryParameters2D.create(Vector2(x, top + 20.0), Vector2(x, size.y + 50), Layer.WORLD)
	var hit := space.intersect_ray(rq)
	var b := SkyBomb.new()
	b.rock = rock
	b.position = Vector2(x, top)
	if not hit.is_empty():
		b.mark_at = hit["position"]
	world.add_child(b)

# ---------- Общий хаос «Мгновенной смерти» ----------
func _alive_players() -> Array:
	return players.filter(func(p): return is_instance_valid(p) and p.is_alive())

# Точка рядом с кем-то из игроков
func _near_player_x(spread: float) -> float:
	var size: Vector2 = info["size"]
	var lo: float = info.get("x_lo", 0.0) + 60.0
	var hi: float = info.get("x_hi", size.x) - 60.0
	var al := _alive_players()
	if al.is_empty():
		return randf_range(lo, hi)
	var p: Player = al.pick_random()
	return clampf(p.global_position.x + randf_range(-spread, spread), lo, hi)

func _ground_y(x: float, from_y: float) -> float:
	var space := world.get_world_2d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, info["size"].y + 50.0), Layer.WORLD | Layer.FRAME))
	return hit["position"].y if not hit.is_empty() else info["size"].y - 48.0

func _chaos_banner(text: String, c: Color) -> void:
	hud.show_banner(text, c)
	var t := create_tween()
	t.tween_interval(1.1)
	t.tween_callback(hud.hide_banner)

func _chaos(delta: float) -> void:
	if _gale_t > 0.0:
		_gale_t -= delta
		for p in _alive_players():
			p.push_wind(_gale_dir * 420.0)
			if randf() < 0.3:
				Fx.sparks(world, p.global_position + Vector2(-_gale_dir * 200.0, randf_range(-60, 60)), Color(0.9, 0.95, 1.0, 0.7), 1, 300.0, 2.5)
	_chaos_t -= delta
	if _chaos_t > 0.0:
		return
	_chaos_t = maxf(4.0, 7.0 - _doom_age * 0.04)
	match ["meteors", "storm", "quake", "gale"].pick_random():
		"meteors":
			_chaos_banner("Метеоритный дождь!", Color(1.0, 0.55, 0.25))
			for k in 7:
				var t := create_tween()
				t.tween_interval(0.2 * k)
				t.tween_callback(_bomb.bind(true))
		"storm":
			_chaos_banner("Гроза!", Color(0.7, 0.85, 1.0))
			for p in _alive_players():
				for k in 3:
					_lightning(clampf(p.global_position.x + (k - 1) * 150.0, 60.0, info["size"].x - 60.0), 0.9 + k * 0.35)
		"quake":
			_chaos_banner("Землетрясение — прыгай!", Color(1.0, 0.75, 0.35))
			for k in 3:
				var t := create_tween()
				t.tween_interval(1.0 + k * 0.7)
				t.tween_callback(_quake_pulse)
		"gale":
			_gale_dir = -1.0 if randf() < 0.5 else 1.0
			_gale_t = 3.0
			_chaos_banner("Ураган!  " + (">>>" if _gale_dir > 0 else "<<<"), Color(0.85, 0.95, 1.0))

# Землетрясение: кто стоит на земле — получает урон и подлетает
func _quake_pulse() -> void:
	if not doom:
		return
	Fx.shake(world, 10.0)
	for p in _alive_players():
		if p.is_on_floor():
			p.take_damage(12)
			p.velocity.y = -520.0
			Fx.sparks(world, p.global_position + Vector2(0, p.body_size.y / 2), Color(0.6, 0.5, 0.4), 8, 220.0, 4.0, true)

# Молния: на земле — метка, через миг бьёт с неба
func _lightning(x: float, delay: float) -> void:
	var al := _alive_players()
	var ref_y: float = al[0].global_position.y - 60.0 if not al.is_empty() else 0.0
	for p in al:
		if absf(p.global_position.x - x) < 400.0:
			ref_y = p.global_position.y - 60.0
	var gy := _ground_y(x, ref_y)
	var at := Vector2(x, gy)
	var mark := Fx.rune_circle(world, at, 60.0, Color(0.65, 0.85, 1.0, 0.9), delay + 0.1, 0.25)
	mark.z_index = 3
	var t := mark.create_tween()
	t.tween_interval(delay)
	t.tween_callback(func():
		if not is_instance_valid(world) or not doom:
			return
		Fx.bolt(world, at + Vector2(randf_range(-60, 60), -900.0), at, Color(0.92, 0.96, 1.0))
		Fx.bolt(world, at + Vector2(randf_range(-60, 60), -900.0), at, Color(0.6, 0.75, 1.0))
		Util.flash(world, at + Vector2(0, -20), 80.0, Color(0.85, 0.92, 1.0, 0.95))
		for p in _alive_players():
			if absf(p.global_position.x - x) < 60.0 + p.body_size.x * 0.3 and absf(p.global_position.y + p.body_size.y / 2 - gy) < 170.0:
				p.take_damage(22)
				p.stun(0.3))

# Ледопад: сосулька над головой
func _icicle() -> void:
	var x := _near_player_x(380.0)
	var al := _alive_players()
	var ref_y: float = al[0].global_position.y - 60.0 if not al.is_empty() else 0.0
	FarBits.drop_icicle(world, x, _ground_y(x, ref_y), 0.8, 16)

# Вулкан: раскалённая бомба по дуге к игроку
func _lava_bomb() -> void:
	var x := _near_player_x(350.0)
	var al := _alive_players()
	var ref_y: float = al[0].global_position.y - 60.0 if not al.is_empty() else 0.0
	var b := FarBits.LavaBomb.new()
	b.goal = Vector2(x, _ground_y(x, ref_y))
	b.position = Vector2(x + randf_range(-500, 500), -200.0)
	b.damage = 18
	world.add_child(b)

# Тьма вытягивает жизнь: через 20 с — всем, и всё сильнее
func _drain(delta: float) -> void:
	if _doom_age < DRAIN_AFTER:
		return
	_drain_t -= delta
	if _drain_t > 0.0:
		return
	_drain_t = 1.0
	var dmg := 1 + int((_doom_age - DRAIN_AFTER) / 8.0)
	if absf(_doom_age - DRAIN_AFTER) < 1.0:
		_chaos_banner("Тьма вытягивает жизнь!", Color(0.8, 0.45, 1.0))
	for p in _alive_players():
		p.take_damage(dmg)
		Util.flash(world, p.global_position, 26.0, Color(0.6, 0.2, 0.9, 0.6))

# «Гора»: лава поднимается снизу и загоняет всех к вершине
const LAVA_SPEED := 20.0
const LAVA_STOP := 1150.0          # выше этого лава не поднимается (вершина остаётся)

func _make_lava() -> void:
	var size: Vector2 = info["size"]
	lava_y = size.y - 40.0
	_lava = Node2D.new()
	_lava.z_index = 8
	world.add_child(_lava)
	var body := ColorRect.new()
	body.color = Color(0.95, 0.35, 0.08)
	body.size = Vector2(size.x, size.y + 400)
	body.position = Vector2(0, 0)
	body.name = "Body"
	_lava.add_child(body)
	for i in 30:
		var bubble := ColorRect.new()
		bubble.color = Color(1.0, 0.75, 0.2)
		bubble.size = Vector2(randf_range(8, 22), 6)
		bubble.position = Vector2(randf_range(0, size.x), randf_range(10, 120))
		bubble.set_meta("speed", randf_range(10, 40))
		body.add_child(bubble)
	_lava_top = Polygon2D.new()
	_lava_top.color = Color(1.0, 0.65, 0.15)
	_lava.add_child(_lava_top)
	_lava.position.y = lava_y

func _update_lava(delta: float) -> void:
	lava_y = maxf(LAVA_STOP, lava_y - LAVA_SPEED * delta)
	_lava.position.y = lava_y
	var size: Vector2 = info["size"]
	var pts := PackedVector2Array()
	var t := _doom_age
	var x := 0.0
	while x <= size.x:
		pts.append(Vector2(x, -6.0 + 5.0 * sin(x * 0.02 + t * 3.0) + 3.0 * sin(x * 0.05 - t * 5.0)))
		x += 40.0
	pts.append(Vector2(size.x, 14))
	pts.append(Vector2(0, 14))
	_lava_top.polygon = pts
	for bub in _lava.get_node("Body").get_children():
		bub.position.x += float(bub.get_meta("speed")) * delta
		if bub.position.x > size.x:
			bub.position.x = 0.0
	# жжётся: всех, кто ступил в лаву, обжигает и подбрасывает
	_lava_tick -= delta
	if _lava_tick <= 0.0:
		_lava_tick = 0.25
		for p in players:
			if is_instance_valid(p) and p.is_alive():
				var feet: float = p.global_position.y + p.body_size.y / 2
				if feet > lava_y + 4.0:
					p.take_damage(9)
					p.velocity.y = minf(p.velocity.y, -520.0)
					if p._para != 0:
						p._land()               # в лаве парашют сгорает — герой снова управляем
					Util.flash(world, Vector2(p.global_position.x, lava_y), 30.0, Color(1.0, 0.7, 0.2, 0.8))

func _rock() -> void:
	var size: Vector2 = info["size"]
	var b := SkyBomb.new()
	b.rock = true
	var x := randf_range(Maps.MOUNT_CX - 1500.0, Maps.MOUNT_CX + 1500.0)
	if randf() < 0.5:
		var p: Player = players.pick_random()
		x = p.global_position.x + randf_range(-400, 400)
	b.position = Vector2(x, -600)
	var space := world.get_world_2d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, -500), Vector2(x, size.y), Layer.WORLD))
	if not hit.is_empty():
		b.mark_at = hit["position"]
	world.add_child(b)

# Куда возрождаться, когда снизу лава: в небо над вершиной, на парашюте
func safe_spawn(r: Dictionary, p: Player) -> Dictionary:
	if lava_y == INF:
		return r
	# Пока течёт лава — только на вершину, на твёрдый камень выше лавы, без парашюта.
	var space := world.get_world_2d().direct_space_state
	var side := -1.0 if p.team == 0 else 1.0
	for attempt in 24:
		var x := Maps.MOUNT_CX + side * randf_range(40.0, 320.0)
		if attempt >= 12:
			x = Maps.MOUNT_CX + randf_range(-320.0, 320.0)
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, -600), Vector2(x, info["size"].y), Layer.WORLD))
		if hit.is_empty():
			continue
		var top: Vector2 = hit["position"]
		if top.y > lava_y - 90.0:
			continue
		var pos := Vector2(x, top.y - p.body_size.y / 2 - 4.0)
		var q := PhysicsShapeQueryParameters2D.new()
		var rs := RectangleShape2D.new()
		rs.size = p.body_size - Vector2(4, 4)
		q.shape = rs
		q.transform = Transform2D(0, pos)
		q.collision_mask = Layer.WORLD
		if space.intersect_shape(q, 1).is_empty():
			return {"pos": pos, "parachute": false}
	return {"pos": Vector2(Maps.MOUNT_CX, lava_y - 900.0), "parachute": true}
