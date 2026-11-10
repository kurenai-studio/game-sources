class_name ArenaMode
extends Node
# Режим «Арена»: в одиночку или вдвоём (в одной команде) против волн ботов.
#   Волны 1–5   — Лесная тропа,  на 5-й  мини-босс Десятник Гнилозуб;
#   Волны 6–10  — Окраина деревни, на 10-й босс Атаман Чёрный Вепрь;
#   Волны 11–15 — Джунгли днём,  на 15-й мини-босс Вождь гоблинов;
#   Волны 16–20 — Джунгли ночью, на 20-й босс Древний Энт;
#   Волны 21–25 — Пещеры, на 25-й мини-босс Паучья королева;
#   Волны 26–30 — Царство скелетов, на 30-й босс Король скелетов;
#   Волны 31–35 — Драгоценные пещеры, на 35-й мини-босс Барон Грызь;
#   Волны 36–40 — Кристальные пещеры, на 40-й босс Ирида;
#   Волны 41–45 — Колизей днём,  на 45-й мини-босс Гладиатор;
#   Волны 46–50 — Колизей ночью, на 50-й босс Колосс;
#   Волны 51–55 — Жуткий лес, на 55-й мини-босс Ведьма Полынь;
#   Волны 56–60 — Болото, на 60-й босс Трясинный Владыка;
#   Волны 61–65 — Ледяная тропа, на 65-й мини-босс Ётун Стужа;
#   Волны 66–70 — Храм шторма, на 70-й босс Громовник, Владыка Бури;
#   Волны 71–75 — Лавовые просторы, на 75-й мини-босс Цербер;
#   Волны 76–80 — Тронный зал Тёмного лорда, на 80-й — сам Тёмный Лорд.
# У каждой локации (кроме первых двух) своя механика: лианы в джунглях, камнепад
# и шипы в пещерах, ящики с порохом и батуты в шахте, катапульты в Колизее,
# корни-ловушки в Жутком лесу, трясина, газ и тонущие брёвна на Болоте,
# наледь и сосульки на Ледяной тропе, ветер и громоотводы в Храме шторма,
# лава и вулканические бомбы на Лавовых просторах, люстры и пламя бездны в Тронном зале.
# Перед каждым боссом — кат-сцена его появления. В начале — герой поднимается
# на арену из подвала на деревянном подъёмнике.
# После каждой пройденной волны: золото и сохранение (можно продолжить позже
# с начала следующей волны). В начале волны здоровье восстанавливается.

signal finished(victory: bool, waves_done: int, gold: int)

const TOTAL_WAVES := 80
const STAGE_NAMES := ["Лесная тропа", "Окраина деревни", "Джунгли", "Ночные джунгли", "Пещеры", "Царство скелетов",
		"Драгоценные пещеры", "Кристальные пещеры", "Колизей", "Ночной Колизей", "Жуткий лес", "Болото",
		"Ледяная тропа", "Храм шторма", "Лавовые просторы", "Тронный зал"]
const LIVES_SOLO := 3
const LIVES_COOP := 5            # вдвоём жизни общие
const SPAWN_INTERVAL := 1.5      # пауза между выходами ботов
const MAX_ALIVE := 6             # больше одновременно на арене не бывает (без призванных)
const MAX_SUMMONED := 10
const BREAK_TIME := 3.0          # пауза между волнами
const COOP_HP := 1.4             # вдвоём враги прочнее

var world: Node2D
var hud: Hud
var coop := false
var chars := [0, 0]
var start_wave := 1

var players: Array = []
var wave := 0
var lives := LIVES_SOLO
var kills := 0
var gold_earned := 0
var info := {}
var stage := -1
var _queue: Array = []
var _alive: Array = []
var _spawn_t := 0.0
var _gate_i := 0
var _target_t := 0.0
var _state := "intro"            # intro, fight, break, over
var _cam: Node2D
var _lanterns: Array = []
var _arrows: CanvasLayer
var _arrow_pool: Array = []
var _fade: ColorRect
var _boss: Player
var _totems: Array = []
var _hold := 0.0                  # после гибели босса волна «закрывается» не сразу — пусть доиграет сцена
var place_name := ""              # своё название места (бой с Лордом уходит на вершину цитадели)
var stage_cam: Camera2D           # неподвижная камера на всю арену (третья фаза Лорда)

func _mode_key() -> String:
	return "coop" if coop else "solo"

static func stage_for(w: int) -> int:
	return clampi((w - 1) / 5, 0, 15)

func start() -> void:
	add_to_group("persist")
	add_to_group("arena_mode")
	for n in world.get_children():      # счёт и кнопки остаются при перестройке арены
		if n is CanvasLayer:
			n.add_to_group("persist")
	wave = start_wave - 1
	lives = LIVES_COOP if coop else LIVES_SOLO
	var saved := Save.arena_progress(_mode_key())
	if start_wave > 1 and saved.has("lives"):
		lives = maxi(1, int(saved["lives"]))
	_build_stage(stage_for(start_wave))

	var count := 2 if coop else 1
	for i in count:
		var pos: Vector2 = info["center"] + Vector2((i * 2 - 1) * 70.0 if coop else 0.0, 0)
		var outline: Color = Config.NO_OUTLINE
		if coop:
			outline = Config.OUTLINE_P1 if i == 0 else Config.OUTLINE_P2
		var p := Characters.create(chars[i], "p%d" % (i + 1), i, 0, pos, 1 if i == 0 else -1, outline)
		Balance.apply(p, "arena")              # баланс легенд для Арены (core/balance.gd)
		p.team_color = Config.OUTLINE_P1
		p.map_w = Colosseum.W
		p.map_top = 40.0
		p.respawn_protect = 2.0
		p.frozen = true
		p.died.connect(_on_player_died)
		world.add_child(p)
		p.add_to_group("persist")
		players.append(p)
	_build_lanterns()

	# кнопки на экране
	rebuild_controls()

	# камера: в одиночку — за героем, вдвоём — держит обоих в кадре
	if coop:
		var dc := DuelCamera.new()
		dc.bounds = Rect2(0, 0, Colosseum.W, Colosseum.H)
		dc.follow = true
		dc.open_top = false
		dc.targets = players
		dc.margin = Vector2(300, 220)
		_cam = dc
	else:
		var c := Camera2D.new()
		c.limit_left = 0
		c.limit_top = 0
		c.limit_right = int(Colosseum.W)
		c.limit_bottom = int(Colosseum.H + Config.panel())
		c.position_smoothing_enabled = true
		c.position_smoothing_speed = 6.0
		c.position = players[0].position
		_cam = c
	world.add_child(_cam)
	_cam.add_to_group("persist")
	_cam.make_current()
	if _cam is Camera2D and not coop:
		_cam.reset_smoothing()

	_arrows = CanvasLayer.new()
	_arrows.layer = 4
	world.add_child(_arrows)
	_arrows.add_to_group("persist")
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 8
	world.add_child(fade_layer)
	fade_layer.add_to_group("persist")
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Config.screen(world)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)

	hud.show_coins()
	_update_hud()
	_lift_intro()
	var d := 1.9
	hud.show_banner("Арена" if start_wave == 1 else "Продолжение: волна %d" % start_wave)
	_after(d + 1.0, hud.show_banner.bind("3"))
	_after(d + 1.55, hud.show_banner.bind("2"))
	_after(d + 2.1, hud.show_banner.bind("1"))
	_after(d + 2.65, func():
		hud.show_banner("Бой!", Color(1.0, 0.85, 0.3))
		for p in players:
			p.frozen = false)
	_after(d + 3.4, _next_wave)

# ---------- Арена ----------
func _build_stage(s: int) -> void:
	stage = s
	match s:
		0: info = ForestTrail.build(world)
		1: info = VillageEdge.build(world)
		2: info = Jungle.build(world, false)
		3: info = Jungle.build(world, true)
		4: info = Caves.build(world, false)
		5: info = Caves.build(world, true)
		6: info = GemCaves.build(world, false)
		7: info = GemCaves.build(world, true)
		8: info = Colosseum.build(world, 0, false)
		9: info = Colosseum.build(world, 2, true)
		10: info = EerieWoods.build(world, false)
		11: info = EerieWoods.build(world, true)
		_: info = FarStages.build(world, s)
	for sp in info["spawners"]:
		sp.picked.connect(_on_picked)
	# жилы самоцветов: за выбитые камни — немного золота
	for g in info.get("gems", []):
		g.cells_removed.connect(_on_gems_broken)

# Ночью вокруг героев мягкий свет
func _build_lanterns() -> void:
	_lanterns.clear()
	if info["glow"] == null:
		return
	for p in players:
		var l := Torch.make_glow(360.0, Color(1.0, 0.95, 0.85, 0.55))
		info["glow"].add_child(l)
		_lanterns.append(l)

func _rebuild(s: int) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.5)
	t.tween_callback(func():
		for n in world.get_children():
			if not n.is_in_group("persist"):
				world.remove_child(n)
				n.queue_free()
		_build_stage(s)
		_build_lanterns()
		for i in players.size():
			var p: Player = players[i]
			p.position = info["center"] + Vector2((i * 2 - 1) * 70.0 if coop else 0.0, 0)
			p.velocity = Vector2.ZERO
		if _cam is Camera2D and not coop:
			_cam.reset_smoothing())
	t.tween_property(_fade, "color:a", 0.0, 0.6)

# ---------- Смена места посреди боя ----------
# Тёмный Лорд уводит героев из тронного зала на вершину цитадели: затемнение,
# арена строится заново (build(world) -> info), keep — узлы, которые «переезжают»
# вместе с героями (сам Лорд); on_built зовётся сразу после постройки, пока темно.
func relocate(build: Callable, keep: Array, on_built: Callable = Callable(), heroes_x: Array = []) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.55)
	t.tween_callback(func():
		for k in keep:
			if is_instance_valid(k):
				k.add_to_group("persist")
		for n in world.get_children():
			if not n.is_in_group("persist"):
				world.remove_child(n)
				n.queue_free()
		for k in keep:
			if is_instance_valid(k):
				k.remove_from_group("persist")
		info = build.call(world)
		for sp in info["spawners"]:
			sp.picked.connect(_on_picked)
		_build_lanterns()
		for i in players.size():
			var p: Player = players[i]
			var x: float = heroes_x[i] if i < heroes_x.size() else info["center"].x + (i * 2 - 1) * 70.0 * (1.0 if coop else 0.0)
			p.position = Vector2(x, info["floor"] - p.body_size.y / 2 - 2)
			p.velocity = Vector2.ZERO
			p.spawn = info["center"]
		if on_built.is_valid():
			on_built.call()
		if _cam is Camera2D and not coop:
			_cam.position = players[0].position + Vector2(0, -60)
			_cam.reset_smoothing()
		_update_hud())
	t.tween_property(_fade, "color:a", 0.0, 0.8)

# Камера кат-сцены плавно смотрит в другую точку
func cut_focus(pos: Vector2, zoom: float, time: float) -> void:
	if _cut_cam == null or not is_instance_valid(_cut_cam):
		return
	var ct := _cut_cam.create_tween()
	ct.tween_property(_cut_cam, "position", pos, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ct.parallel().tween_property(_cut_cam, "zoom", Vector2(zoom, zoom), time)

# Камера кат-сцены сразу в точке (пока экран затемнён)
func cut_jump(pos: Vector2) -> void:
	if _cut_cam and is_instance_valid(_cut_cam):
		_cut_cam.position = pos

# Новое тело главного босса (третья фаза Лорда): old уходит без сцены гибели
func adopt_boss(b: Player, old: Player) -> void:
	b.died.connect(_on_bot_died.bind(b))
	_alive.append(b)
	if is_instance_valid(old):
		_alive.erase(old)
		if _boss == old:
			_boss = b
		old.queue_free()
	_boss = b
	_update_hud()

# ---------- Волны ----------
func _next_wave() -> void:
	if wave >= TOTAL_WAVES or _state == "over":
		return
	wave += 1
	_queue = Bots.wave_list(wave)
	_state = "fight"
	_spawn_t = 0.8
	var boss_kinds := _queue.filter(func(k): return Bots.is_boss(k))
	if not boss_kinds.is_empty():
		_queue = _queue.filter(func(k): return not Bots.is_boss(k))
		_state = "cutscene"
		_after(1.4, _boss_intro.bind(boss_kinds[0]))
	for i in players.size():
		var p: Player = players[i]
		if p.is_alive():
			p.heal_full()
		else:
			p.revive(info["center"])      # выбывший напарник возвращается
	var boss_wave: bool = not boss_kinds.is_empty()
	if boss_wave:
		var big := wave % 10 == 0
		hud.show_banner("Волна %d — %s!" % [wave, "БОСС" if big else "мини-босс"], Color(1.0, 0.4, 0.3))
	else:
		hud.show_banner("Волна %d" % wave)
	_after(1.6, hud.hide_banner)
	_update_hud()

func _process(delta: float) -> void:
	if players.is_empty():
		return
	var lead: Player = players[0]
	if not coop and lead.is_alive():
		_cam.position = lead.position + Vector2(0, -60)
	for i in _lanterns.size():
		if is_instance_valid(_lanterns[i]):
			_lanterns[i].position = players[i].position
			_lanterns[i].visible = players[i].is_alive()
	_alive = _alive.filter(func(b): return is_instance_valid(b))
	_totems = _totems.filter(func(b): return is_instance_valid(b))
	_hold = maxf(0.0, _hold - delta)
	_target_t -= delta
	if _target_t <= 0.0:
		_target_t = 0.4
		_retarget()
	if _state == "fight":
		_spawn_t -= delta
		var regular := _alive.filter(func(b): return not b.has_meta("summoned")).size()
		var in_scene := _cut_cam != null and is_instance_valid(_cut_cam)      # пока идёт сцена — новые не выходят
		if _spawn_t <= 0.0 and not _queue.is_empty() and regular < MAX_ALIVE and not in_scene:
			_spawn_t = SPAWN_INTERVAL
			_spawn(_queue.pop_front())
		if _queue.is_empty() and _alive.is_empty() and _hold <= 0.0:
			_wave_cleared()
	_update_treant(delta)
	_update_king()
	_keep_inside(delta)
	_update_arrows()
	_update_boss_bar()
	hud.set_buffs(players[0].buffs)
	if coop:
		hud.set_buffs2(players[1].buffs)

# Каждый бот целится в ближайшего живого героя
func _nearest(pos: Vector2) -> Player:
	var best: Player = null
	var bd := INF
	# враги нападают и на героев, и на призванных союзников (скелеты Мортиса, тотемы, деревца)
	for a in world.get_tree().get_nodes_in_group("allies"):
		if is_instance_valid(a) and a.is_alive() and a.get_meta("kind", "") != "totem":
			var da := pos.distance_squared_to(a.global_position)
			if da < bd:
				bd = da
				best = a
	for p in players:
		if p.is_alive():
			var d := pos.distance_squared_to(p.global_position)
			if d < bd:
				bd = d
				best = p
	return best if best != null else players[0]

func _retarget() -> void:
	for b in _alive + _totems:
		if is_instance_valid(b):
			b.target = _nearest(b.global_position)

func _spawn(kind: String) -> void:
	var gates: Array = info["gates"]
	var g: Vector2 = gates[_gate_i % gates.size()]
	_gate_i += 1
	var size: Vector2 = Bots.TYPES[kind]["size"]
	var pos := Vector2(g.x, g.y - size.y / 2 - 2)
	var b := _make_bot(kind, pos)
	Util.flash(world, pos, size.y * 0.8, Color(0.9, 0.85, 0.7, 0.8))
	if Bots.is_boss(kind):
		_boss = b
		hud.show_banner(Bots.TYPES[kind]["name"] + "!", Color(1.0, 0.3, 0.25))
		_after(1.4, hud.hide_banner)
		if Bots.TYPES[kind].has("hint"):
			_after(1.5, hud.show_hint.bind(Bots.TYPES[kind]["hint"], 10.0))
		if kind == "treant":
			_totem_wave = 0
			b.invulnerable = true
			_grow_totems()
	_update_hud()

func _make_bot(kind: String, pos: Vector2) -> Player:
	var b := Bots.create(kind, wave, pos, _nearest(pos), Colosseum.W)
	b.calm_jumps = true                # на Арене боты реже скачут без дела
	Save.see(kind)                     # запись в бестиарии открыта
	if coop:
		b.max_hp = int(b.max_hp * COOP_HP)
	b.allies = func(): return _alive
	b.summon = _summon
	b.died.connect(_on_bot_died.bind(b))
	if Bots.is_boss(kind) and kind != "totem":
		b.stagger_max = b.max_hp * Balance.STAGGER_SHARE    # босс копит пошатывание → оглушение, урон ×2
	world.add_child(b)
	if b.body_size.y >= 140.0:
		b.ignore_one_way_platforms()       # огромные боссы не застревают в платформах
	if kind != "totem":
		_alive.append(b)
	return b

# Противник появляется прямо в точке (осколки раскола, отражения Ириды)
func spawn_at(kind: String, pos: Vector2) -> Player:
	var size: Vector2 = Bots.TYPES[kind]["size"]
	var p := Vector2(clampf(pos.x, Colosseum.WALL + 50, Colosseum.W - Colosseum.WALL - 50), minf(pos.y, info["floor"] - size.y / 2 - 2))
	var b := _make_bot(kind, p)
	b.set_meta("summoned", true)
	b.velocity = Vector2(randf_range(-200, 200), -350)
	_update_hud()
	return b

# Дополнительное золото (разбитый самоцветный жук)
func bonus_gold(n: int, at: Vector2) -> void:
	Save.add_gold(n)
	gold_earned += n
	hud.show_coins()
	_float_text("+%d" % n, Color(1.0, 0.85, 0.3), at)

# Босс зовёт подмогу: гоблины выпрыгивают из кустов рядом
func _summon(kind: String, count: int, near: Vector2) -> void:
	var summoned := _alive.filter(func(b): return b.has_meta("summoned")).size()
	for i in mini(count, MAX_SUMMONED - summoned):
		var x := clampf(near.x + randf_range(-260, 260), Colosseum.WALL + 60, Colosseum.W - Colosseum.WALL - 60)
		var size: Vector2 = Bots.TYPES[kind]["size"]
		var pos := Vector2(x, info["floor"] - size.y / 2 - 4)
		var b := _make_bot(kind, pos)
		b.set_meta("summoned", true)
		if kind.begins_with("shardling"):
			b.set_meta("no_split", true)          # призванные осколки не раскалываются на мелочь
		b.velocity = Vector2(0, -500)
		Util.flash(world, pos, 40.0, Color(0.4, 0.9, 0.3, 0.8))
	_update_hud()

var _gem_acc := 0

func _on_gems_broken(count: int, attacker, at: Vector2) -> void:
	if attacker == null or not is_instance_valid(attacker) or not (attacker is Player) or attacker.team != 0:
		return
	_gem_acc += count
	if _gem_acc >= 3:
		var g := _gem_acc / 3
		_gem_acc %= 3
		Save.add_gold(g)
		gold_earned += g
		hud.show_coins()
		_float_text("+%d" % g, Color(1.0, 0.85, 0.3), at)

func _on_bot_died(_index: int, b: Player) -> void:
	if b.get_meta("kind") == "totem":
		return
	kills += 1
	_alive.erase(b)
	if Bots.is_boss(b.get_meta("kind")) and b.get_meta("kind") != "totem":
		if wave % 10 == 0 and b == _boss:
			BossFx._slowmo(world, 0.35, 0.7)          # последний удар по главному боссу — замедленно
		var corpse := BossFx.death(world, b)            # у каждого босса своя смерть
		if b == _boss:
			var final_boss: bool = b.get_meta("kind") == "dark_lord"
			_hold = 4.4 if final_boss else 2.6
			if corpse:
				cinematic(corpse, 4.1 if final_boss else 2.3, true)    # камера показывает, как он погибает
	if b == _boss:
		_boss = null
		# победа над главным боссом открывает новую легенду
		var bk: String = b.get_meta("kind")
		if Save.unlock_hero(bk):
			for i in Characters.LIST.size():
				if Characters.LIST[i].get("unlock", "") == bk:
					hud.show_banner("Новая легенда: %s!" % Characters.LIST[i]["name"], Color(1.0, 0.85, 0.3))
					_after(2.2, hud.hide_banner)
		for t in _totems:          # без Энта тотемы рассыпаются
			if is_instance_valid(t):
				t.invulnerable = false
				t.take_damage(99999)
		_totems.clear()
	_update_hud()

# ---------- Древний Энт и Тотемы жизни ----------
# Тотемы вырастают за бой всего 3 раза: в начале — 1, когда у Энта останется
# 2/3 здоровья — 3, а с 1/3 — 4. Пока стоит хоть один тотем, Энт неуязвим;
# сломал все — бей Энта, пока он не дойдёт до следующего порога.
const TOTEM_WAVES := [1, 2, 4]          # тотемы растут трижды: 1, потом 2, потом 4
const TOTEM_AT := [1.01, 0.67, 0.34]
var _totem_wave := 0

func _grow_totems() -> void:
	if _totem_wave >= TOTEM_WAVES.size():
		return
	var count: int = TOTEM_WAVES[_totem_wave]
	_totem_wave += 1
	var spots: Array = (info.get("totems", []) as Array).duplicate()
	var cx := Colosseum.W / 2
	spots.sort_custom(func(a, b): return absf(a.x - cx) < absf(b.x - cx))
	var use: Array = spots.slice(0, count)
	if count >= 4 and spots.size() > count:
		use = spots.slice(spots.size() - count)          # последние — по краям арены, побегать придётся
	for sp in use:
		var size: Vector2 = Bots.TYPES["totem"]["size"]
		var t := _make_bot("totem", sp - Vector2(0, size.y / 2 + 2))
		_totems.append(t)
		Util.flash(world, sp, 60.0, Color(0.5, 1.0, 0.3, 0.8))
	if _boss and is_instance_valid(_boss):
		_boss.invulnerable = true

func _update_treant(_delta: float) -> void:
	if _boss == null or not is_instance_valid(_boss) or _boss.get_meta("kind") != "treant":
		return
	var aura: Node2D = _boss.get_node_or_null("Aura")
	if aura == null:
		aura = Polygon2D.new()
		aura.name = "Aura"
		aura.polygon = Util.circle(_boss.body_size.y * 0.62, 28)
		aura.color = Color(0.4, 1.0, 0.35, 0.22)
		_boss.add_child(aura)
	aura.visible = _boss.invulnerable
	if _boss.invulnerable:
		aura.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.006)
		var standing := _totems.filter(func(t): return is_instance_valid(t) and t.is_alive()).size()
		if standing == 0:
			_boss.invulnerable = false
			_boss.stun(2.0)
			hud.show_banner("Энт уязвим!", Color(0.6, 1.0, 0.4))
			_after(1.4, hud.hide_banner)
	elif _totem_wave < TOTEM_WAVES.size() and float(_boss.hp) / _boss.max_hp <= TOTEM_AT[_totem_wave]:
		_grow_totems()
		if _boss.rig:
			_boss.rig.play("roar")
		hud.show_banner("Тотемы выросли снова!", Color(1.0, 0.6, 0.3))
		_after(1.4, hud.hide_banner)

func _wave_cleared() -> void:
	_state = "break"
	if wave % 5 == 0 and Save.unlock_stage(stage):
		# этап пройден целиком — его арена теперь есть в Дуэли
		var mname := ""
		for m in Maps.DUEL_MAPS:
			if m.get("stage", -1) == stage:
				mname = m["name"]
		_after(BREAK_TIME * 0.5, hud.show_hint.bind("Новая карта для Дуэли: «%s»!" % mname, 4.0))
	var reward := Save.wave_reward(wave)
	Save.add_gold(reward)
	gold_earned += reward
	hud.show_coins()
	_float_text("+%d золотых" % reward, Color(1.0, 0.85, 0.3), _nearest(info["center"]).position)
	if wave >= TOTAL_WAVES:
		if Save.unlock_stage(16):          # победа над Лордом — его цитадель для Дуэли
			_after(BREAK_TIME * 0.5, hud.show_hint.bind("Новая карта для Дуэли: «Цитадель во тьме»!", 4.0))
		_state = "over"
		Save.clear_arena_progress(_mode_key())
		hud.show_banner("Победа!", Color(1.0, 0.85, 0.3))
		_after(2.0, func(): finished.emit(true, wave, gold_earned))
		return
	Save.set_arena_progress(_mode_key(), wave + 1, chars.slice(0, players.size()), maxi(lives, 1))
	hud.show_banner("Волна %d пройдена" % wave, Color(0.6, 1.0, 0.6))
	var next_stage := stage_for(wave + 1)
	if next_stage != stage:
		var texts := ["", "Из-за деревьев поднимается дым… Бандиты напали на деревню!",
				"Деревня спасена. Дорога ведёт дальше — в джунгли гоблинов!",
				"В джунглях темнеет. Зажигаются факелы…", "Под джунглями открылся спуск в пещеры…",
				"Всё глубже… Вы входите в Царство скелетов",
				"За троном — старая шахта. Драгоценные пещеры кобольдов!",
				"Стены начинают светиться… Кристальные пещеры",
				"Из глубин — наверх, к свету… Ворота Колизея открыты!",
				"Ночь опускается на Колизей…",
				"За воротами Колизея — мёртвый лес. Здесь не поют птицы…",
				"Тропа уходит в трясину. Осторожно — болото!",
				"За болотом — горы. Ночь, мороз, северное сияние… Ледяная тропа!",
				"Над перевалом сгущаются тучи. Впереди — Храм шторма…",
				"За храмом земля чернеет и дымится. Лавовые просторы!",
				"Впереди цитадель Тёмного лорда. Ворота тронного зала открыты…"]
		_after(1.4, hud.show_banner.bind(texts[next_stage]))
		_after(2.4, _rebuild.bind(next_stage))
		_after(2.4 + BREAK_TIME, _next_wave)
	else:
		_after(BREAK_TIME, _next_wave)

func _on_player_died(index: int) -> void:
	if _state == "over":
		return
	var p: Player = players[index]
	lives -= 1
	_update_hud()
	if lives > 0:
		p.spawn = info["center"]
		return
	lives = 0
	p.stay_dead = true                    # больше жизней нет — ждёт конца волны
	var anyone := players.any(func(x): return x.is_alive())
	if anyone:
		hud.show_banner("Игрок %d выбыл до конца волны" % (index + 1), Color(1.0, 0.6, 0.4))
		_after(1.6, hud.hide_banner)
		return
	_state = "over"
	hud.show_banner("Поражение", Color(1.0, 0.35, 0.3))
	# прогресс остаётся: можно продолжить с начала этой волны, жизни — заново
	Save.set_arena_progress(_mode_key(), wave, chars.slice(0, players.size()),
			LIVES_COOP if coop else LIVES_SOLO)
	for b in _alive:
		if is_instance_valid(b):
			b.frozen = true
	_after(2.0, func(): finished.emit(false, wave - 1, gold_earned))

# Подобрал сердце или бафф: надпись над местом подбора, МЕГА — крупно на весь экран
func _on_picked(text: String, color: Color, where: Vector2) -> void:
	_float_text(text, color, where)
	if text.begins_with("МЕГА") or text.begins_with("ДВОЙНОЕ"):
		hud.show_banner(text, color)
		_after(1.3, hud.hide_banner)

func _float_text(text: String, color: Color, where: Vector2) -> void:
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

# ---------- Интерфейс ----------
func _update_hud() -> void:
	if hud == null:
		return
	var place: String = STAGE_NAMES[clampi(stage, 0, STAGE_NAMES.size() - 1)].replace("Ночные джунгли", "Джунгли").replace("Ночной Колизей", "Колизей")
	if place_name != "":
		place = place_name
	hud.set_text("%s · Волна %d / %d" % [place, maxi(wave, 1), TOTAL_WAVES])
	var left := _queue.size() + _alive.size()
	hud.set_sub("Врагов: %d   ·   Жизни: %d%s   ·   Убито: %d" % [left, lives, " (общие)" if coop else "", kills])

func _update_boss_bar() -> void:
	if _boss != null and is_instance_valid(_boss) and _boss.is_alive():
		var n: String = _boss.get_meta("title", Bots.TYPES[_boss.get_meta("kind")]["name"])
		if _boss.invulnerable:
			n += "  (неуязвим — сломай тотемы!)"
		elif _boss.get_meta("kind") == "treant" and _totem_wave < TOTEM_WAVES.size():
			n += "  (уязвим — тотемы ещё вырастут)"
		elif _boss.is_stunned():
			n += "  (оглушён! урон ×%s)" % str(_boss.stun_mult).trim_suffix(".0")
		hud.show_boss(n, float(_boss.hp) / _boss.max_hp,
				_boss.stagger / _boss.stagger_max if _boss.stagger_max > 0.0 and _boss._stagger_cd <= 0.0 else -1.0)
	else:
		hud.hide_boss()

# Стрелки у края экрана показывают, где боты, которых не видно
func _update_arrows() -> void:
	var vs := Config.screen(world)
	var ct := world.get_viewport().get_canvas_transform()
	var area := Rect2(Vector2(36, 110), Vector2(vs.x - 72, vs.y - Config.panel() - 150))
	var used := 0
	for b in _alive + _totems:
		if not is_instance_valid(b) or not b.is_alive():
			continue
		var sp: Vector2 = ct * b.global_position
		if Rect2(Vector2.ZERO, vs).grow(-10).has_point(sp):
			continue
		if used >= _arrow_pool.size():
			var a := Polygon2D.new()
			a.polygon = PackedVector2Array([Vector2(18, 0), Vector2(-10, -12), Vector2(-10, 12)])
			_arrows.add_child(a)
			_arrow_pool.append(a)
		var arrow: Polygon2D = _arrow_pool[used]
		used += 1
		var center := area.get_center()
		var dir := (sp - center).normalized()
		arrow.position = Vector2(clampf(sp.x, area.position.x, area.end.x), clampf(sp.y, area.position.y, area.end.y))
		arrow.rotation = dir.angle()
		var totem: bool = b.get_meta("kind") == "totem"
		arrow.color = Color(0.5, 1.0, 0.35) if totem else (Color(1.0, 0.8, 0.2) if b == _boss else Color(1.0, 0.3, 0.3, 0.9))
		arrow.scale = Vector2.ONE * (1.5 if b == _boss or totem else 1.0)
		arrow.visible = true
	for i in range(used, _arrow_pool.size()):
		_arrow_pool[i].visible = false

func _after(time: float, fn: Callable) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = time
	add_child(t)
	t.timeout.connect(fn)
	t.timeout.connect(t.queue_free)
	t.start()


# ---------- Безопасность: никто не застревает за пределами арены ----------
var _guard_t := 0.0
func _keep_inside(delta: float) -> void:
	_guard_t -= delta
	if _guard_t > 0.0:
		return
	_guard_t = 0.5
	var lo := Colosseum.WALL + 10.0
	var hi := Colosseum.W - Colosseum.WALL - 10.0
	for b in _alive + _totems:
		if not is_instance_valid(b) or not b.is_alive():
			continue
		# босс в сцене (поднимается из трясины, нырнул, спускается с потолка) — это не «выпал с арены»
		if b.cutscene_shield or b.frozen or not b.is_physics_processing():
			continue
		var p: Vector2 = b.global_position
		var out: bool = p.x < lo or p.x > hi or p.y > info["floor"] + 30.0 or p.y < -300.0
		if out:
			var g: Vector2 = info["gates"][randi() % info["gates"].size()]
			b.global_position = Vector2(g.x, g.y - b.body_size.y / 2 - 4)
			b.velocity = Vector2.ZERO
	for p in players:
		if p.is_alive() and (p.global_position.y > info["floor"] + 60.0 or p.global_position.x < lo - 20 or p.global_position.x > hi + 20):
			p.global_position = info["center"]
			p.velocity = Vector2.ZERO

# ---------- Подъёмник: герой поднимается на арену из подвала ----------
func _lift_intro() -> void:
	var floor_y: float = info["floor"]
	for i in players.size():
		var p: Player = players[i]
		p.visible = false
		var x: float = p.position.x
		# люк в полу открывается
		var hole := ColorRect.new()
		hole.color = Color(0.05, 0.04, 0.04)
		hole.size = Vector2(130, 10)
		hole.position = Vector2(x - 65, floor_y)
		hole.scale.x = 0.0
		hole.pivot_offset = Vector2(65, 0)
		hole.z_index = 0                   # люк поверх песка, подъёмник — под ним
		world.add_child(hole)
		var lift := Node2D.new()
		lift.position = Vector2(x, floor_y + 160.0)
		lift.z_index = -1                  # пока под полом — не видно
		world.add_child(lift)
		var plank := ColorRect.new()
		plank.color = Color(0.52, 0.34, 0.18)
		plank.size = Vector2(120, 14)
		plank.position = Vector2(-60, 0)
		lift.add_child(plank)
		for k in 4:
			var line := ColorRect.new()
			line.color = Color(0.38, 0.24, 0.12)
			line.size = Vector2(2, 14)
			line.position = Vector2(-45 + k * 30, 0)
			lift.add_child(line)
		for side in [-1.0, 1.0]:
			var rope := ColorRect.new()
			rope.color = Color(0.7, 0.6, 0.4)
			rope.size = Vector2(3, 160)
			rope.position = Vector2(side * 55 - 1.5, 14)
			lift.add_child(rope)
		HeroFigure.draw(lift, Vector2(0, 0), 1.0, chars[i], p.outline)
		var t := lift.create_tween()
		t.tween_interval(0.35)
		t.tween_property(lift, "position:y", floor_y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_callback(func():
			p.visible = true
			p.position = Vector2(x, floor_y - p.body_size.y / 2 - 1)
			p.velocity = Vector2.ZERO
			Util.flash(world, Vector2(x, floor_y), 60.0, Color(1.0, 0.9, 0.6, 0.6)))
		t.tween_interval(0.3)
		t.tween_property(lift, "modulate:a", 0.0, 0.4)
		t.tween_callback(lift.queue_free)
		var ht := hole.create_tween()
		ht.tween_property(hole, "scale:x", 1.0, 0.3)
		ht.tween_interval(1.3)
		ht.tween_property(hole, "modulate:a", 0.0, 0.4)
		ht.tween_callback(hole.queue_free)

# ---------- Кат-сцены появления боссов ----------
var _cut_cam: Camera2D
var _bars: CanvasLayer
var _foes_held: Array = []

# Место на полу для появления босса — не вплотную к героям
func _clear_x(want: float, dist: float) -> float:
	var lo := Colosseum.WALL + 170.0
	var hi := Colosseum.W - Colosseum.WALL - 170.0
	var best := clampf(want, lo, hi)
	var best_d := -1.0
	for k in [0.0, -1.0, 1.0, -1.6, 1.6, -2.4, 2.4]:
		var x := clampf(want + k * dist, lo, hi)
		var d := INF
		for p in players:
			if is_instance_valid(p):
				d = minf(d, absf(p.position.x - x))
		if d >= dist:
			return x
		if d > best_d:
			best_d = d
			best = x
	return best

func _boss_intro(kind: String) -> void:
	if _state == "over":
		return
	for p in players:
		p.frozen = true
		p.velocity.x = 0.0
	for m in world.get_tree().get_nodes_in_group("allies"):
		if is_instance_valid(m):
			m.frozen = true                 # призванные (скелеты, саженцы) ждут конца сцены
			m.velocity = Vector2.ZERO
	hud.hide_banner()
	# кинорамка
	_bars = CanvasLayer.new()
	_bars.layer = 7
	world.add_child(_bars)
	_bars.add_to_group("persist")
	var vs := Config.screen(world)
	for top in [true, false]:
		var r := ColorRect.new()
		r.color = Color.BLACK
		r.size = Vector2(vs.x, 70)
		r.position = Vector2(0, -70 if top else vs.y)
		_bars.add_child(r)
		r.create_tween().tween_property(r, "position:y", 0.0 if top else vs.y - 70, 0.4)
	# своя камера для сцены
	var cur := world.get_viewport().get_camera_2d()
	_cut_cam = Camera2D.new()
	_cut_cam.position = cur.get_screen_center_position() if cur else info["center"]
	_cut_cam.zoom = cur.zoom if cur else Vector2.ONE
	world.add_child(_cut_cam)
	_cut_cam.add_to_group("persist")
	_cut_cam.make_current()
	var floor_y: float = info["floor"]
	var focus := Vector2(info["center"].x, floor_y - 200)
	var dur := 4.6
	match kind:
		"sergeant":
			# Десятник Гнилозуб: посреди тропы открывается тёмный портал — и он выходит из него
			var px: float = _clear_x(info["center"].x + 140.0, 260.0)
			focus = Vector2(px, floor_y - 170)
			var size_s: Vector2 = Bots.TYPES[kind]["size"]
			var portal := Node2D.new()
			portal.position = Vector2(px, floor_y - size_s.y * 0.55)
			portal.z_index = -1
			var ring_pts := Util.circle(size_s.y * 0.7, 28)
			for i in ring_pts.size():
				ring_pts[i].x *= 0.6
			var hole := Polygon2D.new()
			hole.polygon = ring_pts
			hole.color = Color(0.06, 0.02, 0.10, 0.95)
			portal.add_child(hole)
			var rim := Line2D.new()
			var rp := ring_pts.duplicate()
			rp.append(rp[0])
			rim.points = rp
			rim.width = 6.0
			rim.default_color = Color(0.6, 0.25, 0.95, 0.95)
			portal.add_child(rim)
			portal.scale = Vector2.ZERO
			world.add_child(portal)
			var pt := portal.create_tween()
			pt.tween_interval(0.5)
			pt.tween_property(portal, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pt.tween_property(rim, "rotation", TAU, 2.2)
			pt.tween_property(portal, "scale", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			pt.tween_callback(portal.queue_free)
			for k in 8:
				_after(0.6 + k * 0.2, func():
					BossFx._smoke(world, Vector2(px, floor_y - size_s.y * 0.5), Color(0.25, 0.08, 0.35, 0.6), 2, size_s.x * 0.5))
			_after(1.4, func():
				var b := _make_boss(kind, Vector2(px, floor_y - size_s.y / 2 - 2))
				if b._rig_root:
					b._rig_root.scale = Vector2(0.3, 0.0)
					b._rig_root.modulate = Color(0.2, 0.1, 0.3)
					var bt := b._rig_root.create_tween()
					bt.tween_property(b._rig_root, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					bt.parallel().tween_property(b._rig_root, "modulate", Color.WHITE, 1.0)
				Util.flash(world, Vector2(px, floor_y - size_s.y * 0.5), 90.0, Color(0.6, 0.3, 0.9, 0.9))
				_after(1.1, func():
					if is_instance_valid(b) and b.rig:
						b.rig.play("roar")
					_name_card(kind)))
		"ataman":
			# Атаман Чёрный Вепрь: дымовые бомбы — и он прыгает с крыши прямо в центр
			var land := Vector2(_clear_x(info["center"].x - 80.0, 320.0), floor_y)
			var side := 1.0 if land.x > players[0].position.x else -1.0     # прилетает с дальней от героя стороны
			focus = Vector2(land.x, floor_y - 200)
			var size_a: Vector2 = Bots.TYPES[kind]["size"]
			for k in 3:
				_after(0.5 + k * 0.18, func():
					var at := land + Vector2(randf_range(-160, 160), -20)
					Util.flash(world, at, 50.0, Color(1.0, 0.9, 0.7, 0.8))
					BossFx._smoke(world, at, Color(0.55, 0.55, 0.55, 0.7), 4, 40.0))
			_after(1.1, func():
				var from := Vector2(land.x + side * 650.0, floor_y - 780.0)
				var to := Vector2(land.x, floor_y - size_a.y / 2 - 2)
				var b := _make_boss(kind, from)
				b.set_physics_process(false)
				var tw := b.create_tween()
				tw.tween_method(func(k: float):
					if is_instance_valid(b):
						b.global_position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 260.0), 0.0, 1.0, 0.9)
				if b._rig_root:
					var rt := b._rig_root.create_tween()
					rt.tween_property(b._rig_root, "rotation", -TAU * side, 0.8).set_trans(Tween.TRANS_SINE)
					rt.tween_property(b._rig_root, "rotation", 0.0, 0.0)
				tw.tween_callback(func():
					if not is_instance_valid(b):
						return
					b.set_physics_process(true)
					Fx.ring(world, land, 200.0, Color(0.8, 0.7, 0.5, 0.9), 0.4, 8.0, 0.3)
					Fx.cracks(world, land, Color(0.3, 0.24, 0.18), 120.0)
					Fx.sparks(world, land + Vector2(0, -6), Color(0.7, 0.6, 0.45), 20, 300.0, 5.0, true)
					Fx.shake(world, 10.0)
					_after(0.4, func():
						if is_instance_valid(b) and b.rig:
							b.rig.play("roar")
						_name_card(kind))))
		"chief":
			# Вождь гоблинов: влетает на лиане с крон джунглей
			var anchor := Vector2(info["center"].x - 60.0, floor_y - 820.0)
			var vlen := 700.0
			focus = Vector2(info["center"].x, floor_y - 220)
			var size_c: Vector2 = Bots.TYPES[kind]["size"]
			var a0 := -1.15
			var a1 := 0.32
			_after(0.8, func():
				var vine := Line2D.new()
				vine.width = 6.0
				vine.default_color = Color(0.25, 0.5, 0.18)
				vine.z_index = 3
				world.add_child(vine)
				var hold := func(a: float) -> Vector2:
					return anchor + Vector2(sin(a), cos(a)) * vlen
				var b := _make_boss(kind, hold.call(a0) + Vector2(0, size_c.y * 0.4))
				b.set_physics_process(false)
				var tw := b.create_tween()
				tw.tween_method(func(a: float):
					if is_instance_valid(b):
						var hp: Vector2 = hold.call(a)
						b.global_position = hp + Vector2(0, size_c.y * 0.4)
						vine.points = PackedVector2Array([anchor, hp]), a0, a1, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				var rel: Vector2 = hold.call(a1)
				var land_c := Vector2(rel.x + 140.0, floor_y - size_c.y / 2 - 2)
				tw.tween_property(b, "global_position", land_c, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw.tween_callback(func():
					if is_instance_valid(vine):
						var vt := vine.create_tween()
						vt.tween_property(vine, "modulate:a", 0.0, 0.6)
						vt.tween_callback(vine.queue_free)
					if not is_instance_valid(b):
						return
					b.set_physics_process(true)
					var feet := Vector2(land_c.x, floor_y)
					Fx.ring(world, feet, 150.0, Color(0.5, 0.8, 0.35, 0.9), 0.35, 6.0, 0.3)
					Fx.sparks(world, feet + Vector2(0, -6), Color(0.35, 0.65, 0.25), 18, 260.0, 4.0, true)
					Fx.shake(world, 6.0)
					_after(0.4, func():
						if is_instance_valid(b) and b.rig:
							b.rig.play("roar")
						_name_card(kind))))
		"gladiator":
			# Гладиатор: выбегает из ворот, сальто в центр арены, луч прожектора и конфетти с трибун
			var g: Vector2 = info["gates"][0]
			var dirx := 1.0 if g.x < Colosseum.W / 2 else -1.0
			focus = g + Vector2(dirx * 380.0, -150.0)
			dur = 5.2
			var gate_node: Node2D = info["gate_nodes"][0] if info.has("gate_nodes") else null
			var size_g: Vector2 = Bots.TYPES[kind]["size"]
			_after(0.8, func():
				var b := _make_boss(kind, Vector2(g.x, floor_y - size_g.y / 2 - 2))
				b.z_index = -9
				if gate_node:
					var bars: Node2D = gate_node.get_node("Bars")
					bars.z_index = 2
					bars.create_tween().tween_property(bars, "position:y", -150.0, 0.7).set_trans(Tween.TRANS_SINE)
				_after(0.7, func():
					if is_instance_valid(b):
						b.cutscene_walk = dirx
						b.z_index = 0)
				_after(1.4, func():
					if not is_instance_valid(b):
						return
					b.cutscene_walk = 0.0
					var from: Vector2 = b.global_position
					var to := Vector2(g.x + dirx * 520.0, floor_y - size_g.y / 2 - 2)
					b.set_physics_process(false)
					var tw := b.create_tween()
					tw.tween_method(func(k: float):
						if is_instance_valid(b):
							b.global_position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 220.0), 0.0, 1.0, 0.75)
					if b._rig_root:
						var rt := b._rig_root.create_tween()
						rt.tween_property(b._rig_root, "rotation", TAU * dirx, 0.7)
						rt.tween_property(b._rig_root, "rotation", 0.0, 0.0)
					tw.tween_callback(func():
						if not is_instance_valid(b):
							return
						b.set_physics_process(true)
						var feet := Vector2(to.x, floor_y)
						Fx.ring(world, feet, 160.0, Color(0.95, 0.8, 0.5, 0.9), 0.35, 6.0, 0.3)
						Fx.sparks(world, feet + Vector2(0, -6), Color(0.85, 0.75, 0.55), 14, 240.0, 4.0, true)
						# луч прожектора и конфетти
						var cone := Polygon2D.new()
						cone.polygon = PackedVector2Array([Vector2(-30, -900), Vector2(30, -900), Vector2(110, 0), Vector2(-110, 0)])
						cone.color = Color(1.0, 0.95, 0.7, 0.0)
						cone.position = feet
						cone.z_index = 5
						world.add_child(cone)
						var ctw := cone.create_tween()
						ctw.tween_property(cone, "color:a", 0.22, 0.3)
						ctw.tween_interval(1.6)
						ctw.tween_property(cone, "color:a", 0.0, 0.6)
						ctw.tween_callback(cone.queue_free)
						var cols := [Color(1.0, 0.85, 0.3), Color(0.9, 0.3, 0.3), Color(0.4, 0.7, 1.0), Color(0.6, 1.0, 0.5)]
						for k in 40:
							var cf := Polygon2D.new()
							cf.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(3, 2), Vector2(-3, 2)])
							cf.color = cols[k % cols.size()]
							cf.position = feet + Vector2(randf_range(-600, 600), -randf_range(500, 750))
							cf.z_index = 6
							world.add_child(cf)
							var cft := cf.create_tween()
							cft.tween_property(cf, "position", Vector2(cf.position.x + randf_range(-60, 60), feet.y - 2), randf_range(1.3, 2.2)).set_trans(Tween.TRANS_SINE)
							cft.parallel().tween_property(cf, "rotation", randf_range(-8, 8), 2.0)
							cft.tween_property(cf, "modulate:a", 0.0, 0.5)
							cft.tween_callback(cf.queue_free)
						if b.rig:
							b.rig.play("roar")
						_name_card(kind))))
		"colossus":
			# Колосс: земля дрожит от его шагов за воротами — и он выносит ворота целиком
			var g2: Vector2 = info["gates"][1]
			var dirx2 := 1.0 if g2.x < Colosseum.W / 2 else -1.0
			focus = g2 + Vector2(dirx2 * 260.0, -140.0)
			dur = 5.6
			var gate2: Node2D = info["gate_nodes"][1] if info.has("gate_nodes") else null
			var size_k: Vector2 = Bots.TYPES[kind]["size"]
			for k in 3:
				_after(0.5 + k * 0.55, func():
					Fx.shake(world, 6.0 + k * 3.0)
					Fx.cracks(world, Vector2(g2.x + dirx2 * 40.0, floor_y), Color(0.3, 0.24, 0.2), 50.0 + k * 30.0)
					for d in 6:
						Fx.sparks(world, Vector2(g2.x + randf_range(-120, 120), floor_y - randf_range(280, 360)), Color(0.75, 0.68, 0.55), 2, 60.0, 3.0, true))
			_after(1.9, func():
				var b := _make_boss(kind, Vector2(g2.x, floor_y - size_k.y / 2 - 2))
				b.z_index = -9
				if gate2:
					var bars2: Node2D = gate2.get_node("Bars")
					bars2.z_index = 3
					var bt := bars2.create_tween()
					bt.set_parallel(true)
					bt.tween_property(bars2, "position", bars2.position + Vector2(dirx2 * 360.0, -160.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					bt.tween_property(bars2, "rotation", 1.4 * dirx2, 0.6)
					bt.tween_property(bars2, "modulate:a", 0.0, 0.5).set_delay(0.5)
				Util.flash(world, Vector2(g2.x, floor_y - 120), 160.0, Color(1.0, 0.85, 0.6, 0.9))
				Fx.shake(world, 14.0)
				for d in 10:
					Fx.sparks(world, Vector2(g2.x + randf_range(-60, 60), floor_y - randf_range(20, 220)), Color(0.6, 0.55, 0.5), 3, 380.0, 5.0)
				_after(0.4, func():
					if is_instance_valid(b):
						b.cutscene_walk = dirx2
						b.z_index = 0)
				_after(2.4, func():
					if is_instance_valid(b):
						b.cutscene_walk = 0.0
						if b.rig:
							b.rig.play("roar")
						Fx.shake(world, 8.0)
						_name_card(kind)))
		"treant":
			focus = Vector2(info["center"].x, floor_y - 160)
			_after(0.9, func():
				# росток пробивается из земли и вырастает в Энта
				var sprout := Polygon2D.new()
				sprout.polygon = PackedVector2Array([Vector2(-4, 0), Vector2(4, 0), Vector2(3, -30), Vector2(14, -42), Vector2(2, -36), Vector2(0, -50),
						Vector2(-2, -36), Vector2(-14, -42), Vector2(-3, -30)])
				sprout.color = Color(0.35, 0.75, 0.3)
				sprout.position = Vector2(info["center"].x, floor_y)
				sprout.scale = Vector2(0.1, 0.1)
				sprout.z_index = 3
				world.add_child(sprout)
				var st := sprout.create_tween()
				st.tween_property(sprout, "scale", Vector2(1.6, 1.6), 0.8).set_trans(Tween.TRANS_BACK)
				st.tween_interval(0.2)
				st.tween_callback(func():
					var size: Vector2 = Bots.TYPES["treant"]["size"]
					var b := _make_boss("treant", Vector2(info["center"].x, floor_y - size.y / 2 - 2))
					b.scale = Vector2(0.08, 0.08)
					var bt := b.create_tween()
					bt.tween_property(b, "scale", Vector2.ONE, 1.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
					for k in 6:
						Util.flash(world, Vector2(info["center"].x + randf_range(-90, 90), floor_y - randf_range(20, 180)), 22.0, Color(0.4, 0.9, 0.3, 0.8))
					sprout.queue_free()
					_after(1.4, func():
						if is_instance_valid(b) and b.rig:
							b.rig.play("roar")
						_name_card("treant"))))
		"spider_queen":
			focus = Vector2(info["center"].x, floor_y - 150)
			_after(0.8, func():
				var size: Vector2 = Bots.TYPES["spider_queen"]["size"]
				var start := Vector2(info["center"].x, info.get("ceiling", 30.0) + 60.0)
				var end := Vector2(info["center"].x, floor_y - size.y / 2 - 2)
				var b := _make_boss("spider_queen", start)
				b.set_physics_process(false)
				var thread := Line2D.new()
				thread.width = 2.0
				thread.default_color = Color(0.95, 0.95, 1.0, 0.8)
				thread.z_index = -1
				world.add_child(thread)
				var bt := b.create_tween()
				bt.tween_method(_queen_drop.bind(b, thread, start.x), start.y, end.y, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				bt.tween_callback(func():
					if is_instance_valid(b):
						b.set_physics_process(true)
						if b.rig:
							b.rig.play("roar")
					var tt := thread.create_tween()
					tt.tween_property(thread, "modulate:a", 0.0, 0.6)
					tt.tween_callback(thread.queue_free)
					_name_card("spider_queen")))
		"baron_gryz":
			# пол трескается — и из-под земли вырывается буровая машина
			focus = Vector2(info["center"].x, floor_y - 170)
			var size_b: Vector2 = Bots.TYPES[kind]["size"]
			for k in 4:
				_after(0.5 + k * 0.25, func():
					Fx.cracks(world, Vector2(info["center"].x + randf_range(-80, 80), floor_y), Color(0.25, 0.2, 0.18), 90.0)
					Fx.sparks(world, Vector2(info["center"].x, floor_y - 4), Color(0.6, 0.5, 0.4), 8, 220.0, 4.0))
			_after(1.6, func():
				var b := _make_boss(kind, Vector2(info["center"].x, floor_y - size_b.y / 2 - 2))
				b.velocity = Vector2(0, -600)
				Fx.ring(world, Vector2(info["center"].x, floor_y), 200.0, Color(0.9, 0.75, 0.5, 0.9), 0.5, 8.0)
				Fx.cracks(world, Vector2(info["center"].x, floor_y), Color(0.25, 0.2, 0.18), 160.0)
				_after(0.9, func():
					if is_instance_valid(b) and b.rig:
						b.rig.play("roar")
					_name_card(kind)))
		"irida":
			# осколки со всего зала слетаются в центр и собираются в Ириду
			focus = Vector2(info["center"].x, floor_y - 200)
			var size_i: Vector2 = Bots.TYPES[kind]["size"]
			var center := Vector2(info["center"].x, floor_y - size_i.y / 2)
			for k in 18:
				var sh := Polygon2D.new()
				sh.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -4), Vector2(12, 0), Vector2(0, 4)])
				sh.color = Color(0.75, 0.85, 1.0, 0.9)
				sh.position = center + Vector2.from_angle(TAU * k / 18.0) * randf_range(500, 800)
				world.add_child(sh)
				Shimmer.apply(sh, 0.4, 1.0)
				var st := sh.create_tween()
				st.tween_interval(0.6 + k * 0.04)
				st.tween_property(sh, "position", center, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				st.tween_callback(sh.queue_free)
			_after(2.3, func():
				var b := _make_boss(kind, Vector2(center.x, floor_y - size_i.y / 2 - 2))
				Shards.burst(world, center, 1, b, 0, 0, Color(0.85, 0.85, 1.0))
				Util.flash(world, center, 160.0, Color(0.85, 0.9, 1.0, 0.9))
				_after(0.8, func():
					if is_instance_valid(b) and b.rig:
						b.rig.play("roar")
					_name_card(kind)))
		"skeleton_king":
			var th: Dictionary = info.get("throne", {})
			focus = Vector2(info["center"].x, floor_y - 160)
			if not th.is_empty():
				focus.x = th["pos"].x - 150.0
			dur = 6.2
			if th.is_empty():
				_after(1.0, func():
					_make_boss(kind, Vector2(info["center"].x, floor_y - 90))
					_name_card(kind))
			else:
				var rig: BotRig = th["rig"]
				_after(0.8, func():
					rig.eyes_lit = true                         # глаза вспыхивают
					Util.flash(world, rig.global_position + Vector2(0, -60), 40.0, Color(1.0, 0.3, 0.2, 0.8)))
				_after(1.6, func():
					var t := rig.create_tween()
					t.tween_property(rig, "sit", 0.0, 1.0).set_trans(Tween.TRANS_SINE)   # встаёт с трона
					t.parallel().tween_property(rig, "position:y", info["floor"] - rig.size.y / 2, 1.0))
				_after(2.7, func():
					rig.puppet_vx = -140.0                          # идёт вперёд, из тени — к герою
					var t2 := rig.create_tween()
					t2.tween_property(rig, "modulate", Color.WHITE, 1.3)
					t2.parallel().tween_property(rig, "position:x", rig.position.x - 180.0, 1.3)
					t2.parallel().tween_property(rig, "scale:y", 1.06, 1.3))       # только рост: scale.x — это направление взгляда
				_after(4.0, func():
					rig.visible = false
					var b := _make_boss(kind, Vector2(rig.global_position.x, floor_y - Bots.TYPES[kind]["size"].y / 2 - 2))
					if b.rig:
						b.rig.play("roar")
					_name_card(kind))
		"witch":
			# стая воронов кружит над тропой, сбивается в клубок — и из него выходит ведьма
			focus = Vector2(info["center"].x, floor_y - 200)
			var size_w: Vector2 = Bots.TYPES[kind]["size"]
			var wc := Vector2(info["center"].x, floor_y - size_w.y / 2 - 2)
			for k in 14:
				var cr := WildRig.new()
				cr.kind = "crow"
				cr.size = Vector2(30, 22)
				cr.puppet_facing = 1 if k % 2 == 0 else -1
				var a0 := TAU * k / 14.0
				cr.position = wc + Vector2(cos(a0) * 700.0, -260.0 + sin(a0) * 200.0)
				cr.z_index = 4
				world.add_child(cr)
				var ct2 := cr.create_tween()
				ct2.tween_property(cr, "position", wc + Vector2(cos(a0 * 2.0) * 160.0, -120.0 + sin(a0) * 60.0), 1.0 + k * 0.04)
				ct2.tween_property(cr, "position", wc + Vector2(randf_range(-20, 20), randf_range(-30, 10)), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				ct2.tween_callback(cr.queue_free)
			_after(2.0, func():
				var b := _make_boss(kind, wc)
				Util.flash(world, wc, 140.0, Color(0.7, 0.35, 0.9, 0.9))
				Fx.ring(world, wc, 180.0, Color(0.6, 0.3, 0.8, 0.9), 0.5, 7.0)
				for k in 10:
					Fx.sparks(world, wc + Vector2(randf_range(-40, 40), randf_range(-50, 20)), Color(0.08, 0.08, 0.1), 2, 300.0, 5.0)
				_after(0.8, func():
					if is_instance_valid(b) and b.rig:
						b.rig.play("roar")
					_name_card(kind)))
		"bog_lord":
			# трясина вскипает пузырями — и из неё медленно поднимается Владыка
			var bx: float = _clear_x(info["center"].x + 120.0, 300.0)     # не прямо под героем
			focus = Vector2(bx, floor_y - 180)
			dur = 5.4
			var size_l: Vector2 = Bots.TYPES[kind]["size"]
			for k in 10:
				_after(0.3 + k * 0.12, func():
					var bub := Polygon2D.new()
					bub.polygon = Util.circle(randf_range(8, 16), 10)
					bub.color = Color(0.40, 0.48, 0.24, 0.9)
					bub.position = Vector2(bx + randf_range(-110, 110), floor_y - 4)
					bub.z_index = 3
					world.add_child(bub)
					var bt2 := bub.create_tween()
					bt2.tween_property(bub, "scale", Vector2(1.6, 1.6), 0.5)
					bt2.parallel().tween_property(bub, "modulate:a", 0.0, 0.5)
					bt2.tween_callback(bub.queue_free)
					Fx.sparks(world, Vector2(bx + randf_range(-80, 80), floor_y - 4), Color(0.25, 0.28, 0.16), 3, 160.0, 4.0, true))
			_after(1.6, func():
				var end_y := floor_y - size_l.y / 2 - 2
				var b := _make_boss(kind, Vector2(bx, end_y + size_l.y + 10.0))
				b.set_physics_process(false)
				b.z_index = -1
				var bt3 := b.create_tween()
				bt3.tween_property(b, "position:y", end_y, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				bt3.tween_callback(func():
					if is_instance_valid(b):
						b.set_physics_process(true)
						b.z_index = 0
						if b.rig:
							b.rig.play("roar")
					Fx.ring(world, Vector2(bx, floor_y), 260.0, Color(0.45, 0.55, 0.25, 0.9), 0.5, 9.0)
					_name_card(kind)))
		"jotun":
			# Ётун Стужа: с гор срывается глыба льда, трескается — внутри великан
			var jx: float = _clear_x(info["center"].x + 100.0, 320.0)
			focus = Vector2(jx, floor_y - 200)
			dur = 5.6
			var size_j: Vector2 = Bots.TYPES[kind]["size"]
			var blk := Node2D.new()
			blk.z_index = 3
			var bw := size_j.x + 80.0
			var bh := size_j.y + 60.0
			var ice := Polygon2D.new()
			ice.polygon = PackedVector2Array([Vector2(-bw / 2, 0), Vector2(-bw / 2 - 12, -bh * 0.45), Vector2(-bw / 2 + 10, -bh), Vector2(bw * 0.1, -bh - 18),
					Vector2(bw / 2, -bh + 6), Vector2(bw / 2 + 14, -bh * 0.4), Vector2(bw / 2, 0)])
			ice.color = Color(0.68, 0.86, 1.0, 0.92)
			blk.add_child(ice)
			var ghost := Polygon2D.new()                         # тёмный силуэт великана внутри
			ghost.polygon = PackedVector2Array([Vector2(-size_j.x * 0.35, -6), Vector2(-size_j.x * 0.45, -size_j.y * 0.6), Vector2(-size_j.x * 0.2, -size_j.y * 0.75),
					Vector2(-size_j.x * 0.15, -size_j.y), Vector2(size_j.x * 0.2, -size_j.y), Vector2(size_j.x * 0.25, -size_j.y * 0.75),
					Vector2(size_j.x * 0.45, -size_j.y * 0.6), Vector2(size_j.x * 0.35, -6)])
			ghost.color = Color(0.22, 0.30, 0.48, 0.55)
			blk.add_child(ghost)
			for k in 4:                                          # блики на гранях
				var gl := Line2D.new()
				gl.points = PackedVector2Array([Vector2(-bw * 0.35 + k * bw * 0.22, -bh * 0.85), Vector2(-bw * 0.28 + k * bw * 0.22, -bh * 0.55)])
				gl.width = 4.0
				gl.default_color = Color(1, 1, 1, 0.6)
				blk.add_child(gl)
			blk.position = Vector2(jx, -bh - 200.0)
			world.add_child(blk)
			var bt2 := blk.create_tween()
			bt2.tween_interval(0.6)
			bt2.tween_property(blk, "position:y", floor_y + 2.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			bt2.tween_callback(func():
				Fx.shake(world, 14.0)
				Fx.ring(world, Vector2(jx, floor_y), 260.0, Color(0.85, 0.95, 1.0, 0.9), 0.5, 9.0, 0.3)
				Fx.cracks(world, Vector2(jx, floor_y), Color(0.45, 0.6, 0.8), 160.0)
				for d in 4:
					Fx.sparks(world, Vector2(jx + randf_range(-bw / 2, bw / 2), floor_y - 6), Color(0.9, 0.97, 1.0), 6, 300.0, 5.0, true))
			for k in 6:                                          # глыба трескается, сквозь трещины — свет
				_after(1.6 + k * 0.18, func():
					if not is_instance_valid(blk):
						return
					var cr := Line2D.new()
					var p0 := Vector2(randf_range(-bw * 0.35, bw * 0.35), -randf_range(bh * 0.2, bh * 0.9))
					cr.points = PackedVector2Array([p0, p0 + Vector2(randf_range(-30, 30), randf_range(20, 50)), p0 + Vector2(randf_range(-40, 40), randf_range(50, 90))])
					cr.width = 3.0
					cr.default_color = Color(0.9, 1.0, 1.0)
					blk.add_child(cr)
					Fx.sparks(world, blk.position + p0, Color(0.9, 0.97, 1.0), 4, 120.0, 3.0))
			_after(2.9, func():
				if is_instance_valid(blk):
					var c0: Vector2 = blk.position + Vector2(0, -bh / 2)
					Util.flash(world, c0, 200.0, Color(0.85, 0.95, 1.0, 0.95))
					Fx.shake(world, 10.0)
					for k in 16:                                    # осколки разлетаются
						var sh := Polygon2D.new()
						var r := randf_range(10, 26)
						sh.polygon = PackedVector2Array([Vector2(-r, -r * 0.4), Vector2(r * 0.3, -r), Vector2(r, r * 0.2), Vector2(-r * 0.2, r * 0.8)])
						sh.color = Color(0.72, 0.88, 1.0, 0.95)
						sh.position = c0 + Vector2(randf_range(-bw * 0.4, bw * 0.4), randf_range(-bh * 0.4, bh * 0.4))
						sh.z_index = 5
						world.add_child(sh)
						var dir := (sh.position - c0).normalized()
						var st2 := sh.create_tween()
						st2.tween_property(sh, "position", sh.position + dir * randf_range(160, 360) + Vector2(0, -120), 0.35).set_ease(Tween.EASE_OUT)
						st2.tween_property(sh, "position:y", floor_y - 6, 0.35).set_ease(Tween.EASE_IN)
						st2.parallel().tween_property(sh, "rotation", randf_range(-5, 5), 0.7)
						st2.tween_interval(1.2)
						st2.tween_property(sh, "modulate:a", 0.0, 0.5)
						st2.tween_callback(sh.queue_free)
					blk.queue_free()
				var b := _make_boss(kind, Vector2(jx, floor_y - size_j.y / 2 - 2))
				if b.rig:
					b.rig.play("roar")
				_after(0.5, func():
					if is_instance_valid(b):
						var mouth: Vector2 = b.global_position + Vector2(b.facing * 30.0, -size_j.y * 0.36)
						for k in 5:                               # выдох морозом в небо
							Fx.sparks(world, mouth, Color(0.85, 0.96, 1.0), 6, 260.0, 5.0, true)
					_name_card(kind)))
		"storm_lord":
			# Громовник: громоотводы загораются, в одну точку бьют три молнии — и в свете появляется Владыка
			var sx: float = _clear_x(info["center"].x, 320.0)
			focus = Vector2(sx, floor_y - 220)
			dur = 5.2
			var size_s2: Vector2 = Bots.TYPES[kind]["size"]
			var rods: Array = info.get("rods", [])
			for r in rods:
				if is_instance_valid(r):
					r.glow(true)
			for k in 3:
				_after(0.8 + k * 0.4, func():
					var at := Vector2(sx + randf_range(-30, 30), floor_y)
					Fx.bolt(world, at + Vector2(randf_range(-120, 120), -1100.0), at, Color(0.9, 0.96, 1.0))
					Fx.bolt(world, at + Vector2(randf_range(-120, 120), -1100.0), at, Color(0.6, 0.75, 1.0))
					Util.flash(world, at + Vector2(0, -30), 90.0 + k * 30.0, Color(0.85, 0.92, 1.0, 0.95))
					Fx.ring(world, at, 120.0 + k * 50.0, Color(0.75, 0.88, 1.0, 0.9), 0.4, 6.0, 0.3)
					Fx.shake(world, 5.0 + k * 3.0))
			_after(2.2, func():
				var at := Vector2(sx, floor_y)
				for k in 4:
					Fx.bolt(world, at + Vector2(randf_range(-200, 200), -1100.0), at + Vector2(0, -size_s2.y * 0.5), Color(1, 1, 1))
				Util.flash(world, at + Vector2(0, -size_s2.y * 0.5), 260.0, Color(0.9, 0.95, 1.0, 1.0))
				Fx.shake(world, 12.0)
				var b := _make_boss(kind, Vector2(sx, floor_y - size_s2.y / 2 - 2))
				if b._rig_root:
					b._rig_root.modulate = Color(3.0, 3.0, 3.4)
					b._rig_root.create_tween().tween_property(b._rig_root, "modulate", Color.WHITE, 1.0)
				for r in rods:
					if is_instance_valid(r):
						r.glow(false)
				_after(0.9, func():
					if is_instance_valid(b) and b.rig:
						b.rig.play("roar")
					for k in 6:
						Fx.zap(world, at + Vector2(randf_range(-80, 80), -randf_range(40, size_s2.y)), Color(0.85, 0.95, 1.0), 40.0)
					_name_card(kind)))
		"cerberus":
			# Цербер: лава в озере вскипает — и пёс выпрыгивает из неё, стряхивая огонь
			var land_x: float = _clear_x(info["center"].x + 260.0, 300.0)
			var lx: float = info["center"].x + (330.0 if land_x > info["center"].x else -330.0)    # ближнее лавовое озеро
			focus = Vector2((lx + land_x) / 2.0, floor_y - 170)
			dur = 5.0
			var size_c2: Vector2 = Bots.TYPES[kind]["size"]
			for k in 8:
				_after(0.4 + k * 0.15, func():
					Fx.sparks(world, Vector2(lx + randf_range(-120, 120), floor_y - 4), Color(1.0, 0.55, 0.15), 6, 260.0, 4.0, true)
					if k % 3 == 0:
						Fx.shake(world, 4.0))
			_after(1.7, func():
				var from := Vector2(lx, floor_y + size_c2.y * 0.3)
				var to := Vector2(land_x, floor_y - size_c2.y / 2 - 2)
				var b := _make_boss(kind, from)
				b.set_physics_process(false)
				Util.flash(world, Vector2(lx, floor_y - 30), 140.0, Color(1.0, 0.6, 0.2, 0.9))
				for k in 14:
					Fx.sparks(world, Vector2(lx + randf_range(-60, 60), floor_y - 10), Color(1.0, 0.5, 0.15), 3, 420.0, 6.0, true)
				var tw := b.create_tween()
				tw.tween_method(func(k: float):
					if is_instance_valid(b):
						b.global_position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 280.0), 0.0, 1.0, 0.85)
				tw.tween_callback(func():
					if not is_instance_valid(b):
						return
					b.set_physics_process(true)
					Fx.shake(world, 12.0)
					Fx.ring(world, Vector2(land_x, floor_y), 240.0, Color(1.0, 0.5, 0.2, 0.9), 0.45, 8.0, 0.3)
					Fx.cracks(world, Vector2(land_x, floor_y), Color(0.9, 0.35, 0.1), 130.0)
					for k in 3:                                  # три головы рычат по очереди
						_after(0.5 + k * 0.28, func():
							if is_instance_valid(b) and b.rig:
								b.rig.play("roar")
								var pts: Array = b.rig.head_points() if b.rig.has_method("head_points") else []
								if k < pts.size():
									Fx.ring(world, pts[k], 70.0, Color(1.0, 0.6, 0.2, 0.9), 0.35, 5.0)
									Fx.sparks(world, pts[k], Color(1.0, 0.6, 0.2), 8, 200.0, 4.0))
					_after(1.4, _name_card.bind(kind))))
		"dark_lord":
			# Тёмный Лорд: зал гаснет, на троне загораются глаза — и он встаёт из столба чёрного пламени
			var dx: float = _clear_x(info["center"].x, 300.0)
			focus = Vector2(info["center"].x, floor_y - 260)
			dur = 6.0
			var size_d2: Vector2 = Bots.TYPES[kind]["size"]
			var cm: CanvasModulate = null
			for n in world.get_children():
				if n is CanvasModulate:
					cm = n
			var cm_col: Color = cm.color if cm else Color.WHITE
			if cm:
				cm.create_tween().tween_property(cm, "color", Color(0.18, 0.13, 0.16), 0.9)
			var gl: CanvasLayer = info.get("glow")
			var eyes := Node2D.new()
			for s in [-1, 1]:
				var e := Torch.make_glow(60.0, Color(1.0, 0.45, 0.12, 0.0))
				e.position = Vector2(s * 9.0, 0)
				eyes.add_child(e)
			eyes.position = Vector2(info["center"].x, floor_y - 330.0)
			if gl:
				gl.add_child(eyes)
			else:
				world.add_child(eyes)
			for e in eyes.get_children():
				var et := e.create_tween()
				et.tween_interval(1.0)
				et.tween_property(e, "modulate:a", 1.0, 0.5)
				et.tween_interval(0.9)
				et.tween_property(e, "modulate:a", 0.0, 0.3)
			_after(1.6, func():
				_banner_text("Ты дошёл до моего трона…", Color(1.0, 0.45, 0.3)))
			_after(2.7, func():
				eyes.queue_free()
				var at := Vector2(dx, floor_y)
				FarAbilities._dark_smoke(world, at + Vector2(0, -size_d2.y * 0.5), size_d2)
				var pil := FarAbilities.FirePillar.new()
				pil.harmless = true
				pil.position = at
				pil.scale = Vector2(2.2, 1.6)
				world.add_child(pil))
			_after(3.2, func():
				var b := _make_boss(kind, Vector2(dx, floor_y - size_d2.y / 2 - 2))
				if b._rig_root:
					b._rig_root.modulate = Color(0.1, 0.05, 0.1)
					b._rig_root.create_tween().tween_property(b._rig_root, "modulate", Color.WHITE, 0.9)
				if cm:
					cm.create_tween().tween_property(cm, "color", cm_col, 1.0)
				Fx.shake(world, 12.0)
				Fx.ring(world, Vector2(dx, floor_y), 320.0, Color(0.7, 0.15, 0.25, 0.9), 0.6, 10.0, 0.3)
				Util.flash(world, Vector2(dx, floor_y - size_d2.y * 0.5), 220.0, Color(1.0, 0.45, 0.3, 0.8))
				_after(0.9, func():
					if is_instance_valid(b) and b.rig:
						b.rig.play("roar")
					Fx.sparks(world, Vector2(dx, floor_y - size_d2.y * 0.6), Color(1.0, 0.5, 0.2), 20, 300.0, 5.0)
					_name_card(kind, "", "ПОВЕЛИТЕЛЬ ТЬМЫ")))
		_:
			# запасной вариант: босс просто выходит в центре
			_after(1.0, func():
				var size_d: Vector2 = Bots.TYPES[kind]["size"]
				var b := _make_boss(kind, Vector2(info["center"].x, floor_y - size_d.y / 2 - 2))
				Util.flash(world, b.position, 120.0, Color(1.0, 0.9, 0.7, 0.8))
				_after(0.6, func():
					if is_instance_valid(b) and b.rig:
						b.rig.play("roar")
					_name_card(kind)))
	# камера не заглядывает за стены арены
	var half := Config.screen(world) / 1.05 / 2.0
	focus.x = clampf(focus.x, half.x, Colosseum.W - half.x)
	focus.y = clampf(focus.y, half.y, Colosseum.H + Config.panel() - half.y)
	var ct := _cut_cam.create_tween()
	ct.tween_property(_cut_cam, "position", focus, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ct.parallel().tween_property(_cut_cam, "zoom", Vector2(1.05, 1.05), 1.0)
	_after(dur, _end_intro)

# Королева спускается с потолка на нити паутины
func _queen_drop(y: float, b: Player, thread: Line2D, x: float) -> void:
	if is_instance_valid(b):
		b.position.y = y
		thread.points = PackedVector2Array([Vector2(x, 20), Vector2(x, y)])

func _make_boss(kind: String, pos: Vector2) -> Player:
	var b := _make_bot(kind, pos)
	b.frozen = true
	b.cutscene_shield = true             # пока идёт кат-сцена — неуязвим, призванные его не трогают
	_boss = b
	if kind == "treant":
		_totem_wave = 0
		b.invulnerable = true
		_grow_totems()
	return b

# Короткая надпись посреди сцены (реплика босса)
func _banner_text(text: String, c: Color) -> void:
	hud.show_banner(text, c)
	_after(1.4, hud.hide_banner)

# Табличка с именем босса
func _name_card(kind: String, title := "", sub_text := "") -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	world.add_child(layer)
	var vs := Config.screen(world)
	var big := wave % 10 == 0
	var sub := Label.new()
	sub.text = sub_text if sub_text != "" else ("БОСС АРЕНЫ" if big else "МИНИ-БОСС")
	sub.size = Vector2(vs.x, 40)
	sub.position = Vector2(0, 160)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	layer.add_child(sub)
	var name_l := Label.new()
	name_l.text = title if title != "" else Bots.TYPES[kind]["name"]
	name_l.size = Vector2(vs.x, 80)
	name_l.position = Vector2(-vs.x, 190)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 64)
	name_l.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25) if big else Color(1.0, 0.85, 0.4))
	name_l.add_theme_constant_override("outline_size", 12)
	name_l.add_theme_color_override("font_outline_color", Color(0.1, 0.02, 0.02))
	layer.add_child(name_l)
	var t := name_l.create_tween()
	t.tween_property(name_l, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.6)
	t.tween_property(layer, "offset:y", -400.0, 0.4)
	t.tween_callback(layer.queue_free)

# Камера, к которой возвращаются после кат-сцены
func _main_cam() -> Camera2D:
	if stage_cam and is_instance_valid(stage_cam):
		return stage_cam
	return _cam as Camera2D

func _end_intro() -> void:
	if _state == "over":
		return
	var main_cam := _main_cam() as Node2D
	var ct := _cut_cam.create_tween()
	var back_pos: Vector2 = players[0].position + Vector2(0, -60)
	if coop:
		back_pos = (players[0].position + players[1].position) / 2.0
	ct.tween_property(_cut_cam, "position", back_pos, 0.7).set_trans(Tween.TRANS_SINE)
	ct.parallel().tween_property(_cut_cam, "zoom", (main_cam as Camera2D).zoom, 0.7)
	ct.tween_callback(func():
		(main_cam as Camera2D).make_current()
		_cut_cam.queue_free()
		for r in _bars.get_children():
			r.create_tween().tween_property(r, "modulate:a", 0.0, 0.3)
		var bl := _bars
		_after(0.4, bl.queue_free)
		for p in players:
			p.frozen = false
		for m in world.get_tree().get_nodes_in_group("allies"):
			if is_instance_valid(m):
				m.frozen = false
		if _boss and is_instance_valid(_boss):
			_boss.frozen = false
			_boss.cutscene_shield = false
			_boss.cutscene_walk = 0.0
			var kind: String = _boss.get_meta("kind")
			if Bots.TYPES[kind].has("hint"):
				hud.show_hint(Bots.TYPES[kind]["hint"], 10.0)
		_state = "fight"
		_spawn_t = 1.5)

# Экранные кнопки (и значки перезарядки для геймпада); после «Настроек» из паузы — заново
func rebuild_controls() -> void:
	TouchControls.build_panel(world, coop)
	if coop:
		players[0].ui = TouchControls.build(world, "p1", "left", players[0])
		players[1].ui = TouchControls.build(world, "p2", "right", players[1])
	else:
		players[0].ui = TouchControls.build(world, "p1", "solo", players[0])
	for n in world.get_children():
		if n is CanvasLayer and (n.is_in_group("touch_ui") or n.is_in_group("pad_ui")):
			n.add_to_group("persist")

# ---------- Кинорамка посреди боя (пробуждение Колосса) ----------
# Камера летит к цели и держит её hold секунд, герои и призванные ждут.
func cinematic(target: Node2D, hold: float, stop_foes := false) -> void:
	if _state == "over" or _cut_cam != null and is_instance_valid(_cut_cam):
		return
	for p in players:
		p.frozen = true
		p.velocity.x = 0.0
	_foes_held.clear()
	if stop_foes:                       # оставшиеся враги тоже замирают, пока идёт сцена
		for b in _alive:
			if is_instance_valid(b) and b.is_alive() and not b.frozen:
				b.frozen = true
				b.velocity = Vector2.ZERO
				_foes_held.append(b)
	for m in world.get_tree().get_nodes_in_group("allies"):
		if is_instance_valid(m):
			m.frozen = true
			m.velocity = Vector2.ZERO
	hud.hide_hint()
	_bars = CanvasLayer.new()
	_bars.layer = 7
	world.add_child(_bars)
	_bars.add_to_group("persist")
	var vs := Config.screen(world)
	for top in [true, false]:
		var r := ColorRect.new()
		r.color = Color.BLACK
		r.size = Vector2(vs.x, 70)
		r.position = Vector2(0, -70 if top else vs.y)
		_bars.add_child(r)
		r.create_tween().tween_property(r, "position:y", 0.0 if top else vs.y - 70, 0.4)
	var cur := world.get_viewport().get_camera_2d()
	_cut_cam = Camera2D.new()
	_cut_cam.position = cur.get_screen_center_position() if cur else info["center"]
	_cut_cam.zoom = cur.zoom if cur else Vector2.ONE
	world.add_child(_cut_cam)
	_cut_cam.add_to_group("persist")
	_cut_cam.make_current()
	var focus: Vector2 = target.global_position + Vector2(0, -60) if is_instance_valid(target) else info["center"]
	var half := Config.screen(world) / 1.1 / 2.0
	focus.x = clampf(focus.x, half.x, Colosseum.W - half.x)
	focus.y = clampf(focus.y, half.y, Colosseum.H + Config.panel() - half.y)
	var ct := _cut_cam.create_tween()
	ct.tween_property(_cut_cam, "position", focus, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ct.parallel().tween_property(_cut_cam, "zoom", Vector2(1.1, 1.1), 0.8)
	_after(hold, _end_cinematic)

func _end_cinematic() -> void:
	if _cut_cam == null or not is_instance_valid(_cut_cam):
		return
	var main_cam := _main_cam()
	var ct := _cut_cam.create_tween()
	var back_pos: Vector2 = players[0].position + Vector2(0, -60)
	if coop:
		back_pos = (players[0].position + players[1].position) / 2.0
	if main_cam == stage_cam:
		back_pos = stage_cam.position
	ct.tween_property(_cut_cam, "position", back_pos, 0.6).set_trans(Tween.TRANS_SINE)
	ct.parallel().tween_property(_cut_cam, "zoom", main_cam.zoom, 0.6)
	ct.tween_callback(func():
		main_cam.make_current()
		_cut_cam.queue_free()
		_cut_cam = null
		for r in _bars.get_children():
			r.create_tween().tween_property(r, "modulate:a", 0.0, 0.3)
		var bl := _bars
		_after(0.4, bl.queue_free)
		for p in players:
			p.frozen = false
		for b in _foes_held:
			if is_instance_valid(b) and _state != "over":
				b.frozen = false
		_foes_held.clear()
		for m in world.get_tree().get_nodes_in_group("allies"):
			if is_instance_valid(m):
				m.frozen = false)

# ---------- Король скелетов: теряя треть здоровья, зовёт стражу ----------
var _king_phase := 0
var _king_shield := 0.0
func _update_king() -> void:
	if _boss == null or not is_instance_valid(_boss) or _boss.get_meta("kind") != "skeleton_king":
		return
	var ratio := float(_boss.hp) / _boss.max_hp
	if _king_shield > 0.0:
		_king_shield -= get_process_delta_time()
		if _king_shield <= 0.0:
			_boss.invulnerable = false
			var a := _boss.get_node_or_null("Aura")
			if a:
				a.queue_free()
		return
	var want := 1 if ratio < 0.67 else 0
	if ratio < 0.34:
		want = 2
	if want > _king_phase:
		_king_phase = want
		_king_shield = 5.0
		_boss.invulnerable = true
		if _boss.rig:
			_boss.rig.play("roar")
		var aura := Polygon2D.new()
		aura.name = "Aura"
		aura.polygon = Util.circle(_boss.body_size.y * 0.6, 28)
		aura.color = Color(0.6, 0.3, 1.0, 0.25)
		_boss.add_child(aura)
		hud.show_banner("Стража, ко мне!", Color(0.8, 0.6, 1.0))
		_after(1.4, hud.hide_banner)
		_summon("skel_sword", 3, _boss.global_position)
