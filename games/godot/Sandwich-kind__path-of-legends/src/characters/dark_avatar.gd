class_name DarkAvatar
extends Node2D
# ---------- Тёмный Лорд, третья фаза: «Воплощение Тьмы» ----------
# Повергнутый во второй раз, Лорд отдаёт себя тьме, которой повелевает:
# фон гаснет, по краям встают стены мрака, сам Лорд растворяется, камень из его
# груди взлетает вверх — и из темноты поднимается его последнее обличье:
# огромная голова и две кисти рук, без тела. Правая рука демона — слева на
# арене, голова — посередине, левая рука — справа (как у Мега Сатаны).
#   Руки: «Кулак» — рука взмывает, по полу ползёт её тень, и кулак падает
#         туда (по полу расходится волна — перепрыгни); «Когти» — три огненных
#         шара с когтей; «Хлопок» — обе руки разлетаются по бокам от героя
#         и схлопываются на его высоте (подпрыгни или спрыгни).
#         У каждой руки своё здоровье: сломанная рука рассыпается и через 15 с
#         отрастает. Сломаны обе — голова опускается к самому полу и открыта
#         для удара (оглушена, урон ×2), потом поднимается, руки отрастают.
#   Голова: «Взгляд» — тонкие лучи-прицелы из глаз ведут героя, вспыхивают
#         белым и бьют залпом (уходи с линии после вспышки); «Пасть тьмы» —
#         столб огня прямо под головой; «Град» — веера тёмных сфер; «Зов» —
#         из тьмы выходят тени.
# Убить нужно голову — тогда рассыпаются и руки.

const HEAD_SIZE := Vector2(300, 270)
const HAND_SIZE := Vector2(190, 150)
const INNER_L := 550.0
const INNER_R := 2050.0
const HAND_REGROW := 15.0
const EXPOSE_T := 7.0
const TITLE := "Тёмный Лорд — Воплощение Тьмы"
const HEAD_RISE := 460.0          # центр головы над полом
const HAND_RISE := 330.0
const HAND_DX := 580.0

var lord: Player
var lord_sky: Node
var duel := false                 # Дуэль: выходит в «Мгновенную смерть», неуязвимо, бьёт МЕГА-атаками
var glow_layer: Node
var head_node: Node2D
var head_rig: AvatarRig
var _rage_t := 0.0                # Дуэль: чем дольше, тем яростнее
const DUEL_TEAM := 2              # в Дуэли — враг обоим игрокам
var am: Node
var world: Node2D
var floor_y := 940.0
var cx := 1300.0
var head: Player
var hands: Array = []
var _state := "intro"             # intro, fight, exposed, dead
var _t := 0.0
var _head_y := 0.0
var _head_act := ""
var _head_t := 0.0
var _head_cd := {"gaze": 3.0, "maw": 8.0, "orbs": 5.0, "call": 14.0, "clap": 10.0}
var _pace := 2.0
var _volley := 0
var _lines: Array = []
var _gaze_dirs: Array = []
var _tick := 0.0
var _maw_fx: Node2D
var _expose_t := 0.0
var _glow: Node2D
var _glows: Array = []
var _dark: Polygon2D
var _walls: Array = []
var _cam: Camera2D

class Hand:
	var p: Player                 # на Арене — бот с полоской здоровья; в Дуэли — нет
	var node: Node2D              # что двигаем (бот или просто узел с моделью)
	var rig: AvatarRig
	var side := -1
	var anchor := Vector2.ZERO
	var pos := Vector2.ZERO
	var state := "idle"
	var t := 0.0
	var cd := 1.5
	var target: Player
	var goal := Vector2.ZERO
	var hit := {}
	var broken := 0.0
	var shadow: Polygon2D
	var shots := 0

func _ready() -> void:
	z_index = 7
	world = get_parent()
	am = get_tree().get_first_node_in_group("arena_mode")
	floor_y = am.info["floor"] if am else 940.0
	cx = Colosseum.W / 2.0
	_head_y = floor_y - HEAD_RISE
	if glow_layer == null and am:
		glow_layer = am.info.get("glow")
	if duel:
		_begin_duel()
	else:
		_begin()

func _after(time: float, fn: Callable) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = time
	add_child(t)
	t.timeout.connect(fn)
	t.timeout.connect(t.queue_free)
	t.start()

func _banner(text: String, c := Color(1.0, 0.55, 0.3), hold := 1.6) -> void:
	if am and am.hud:
		am.hud.show_banner(text, c)
		am._after(hold, am.hud.hide_banner)

func _heroes() -> Array:
	var res := []
	for n in world.get_children():
		if n is Player and (duel or n.team != 1) and n.is_alive() and not n.is_minion:
			res.append(n)
	return res

func _foes_of_avatar() -> Array:
	var res := []
	for n in world.get_children():
		if n is Player and (duel or n.team != 1) and n.is_alive():
			res.append(n)
	return res

# Кто «бьёт» (для зачёта урона): на Арене — сама часть босса, в Дуэли — никто
func _atk_head() -> Player:
	return head if is_instance_valid(head) else null

func _atk(h: Hand) -> Player:
	return h.p if is_instance_valid(h.p) else null

func _bullet_team() -> int:
	return DUEL_TEAM if duel else 1

func _hand_alive(h: Hand) -> bool:
	return h.p.is_alive() if is_instance_valid(h.p) else h.broken <= 0.0

func _head_stunned() -> bool:
	return is_instance_valid(head) and head.is_stunned()

# Ярость: в Дуэли атаки всё чаще
func _rage() -> float:
	return 1.6 + minf(1.4, _rage_t / 35.0) if duel else 1.0

func _nearest_hero(at: Vector2) -> Player:
	var best: Player = null
	var bd := INF
	for h in _heroes():
		var d: float = h.global_position.distance_squared_to(at)
		if d < bd:
			bd = d
			best = h
	return best

# ======================= Переход ко второй фазе =======================
func _begin() -> void:
	var lp := lord.global_position
	lord.cutscene_shield = true
	lord.frozen = true
	lord.velocity = Vector2.ZERO
	lord._forced_time = 0.0
	lord.stagger = 0.0
	lord._stun_t = 0.0
	if lord._stun_fx:
		lord._stun_fx.visible = false
	if am:
		for b in am._alive.duplicate():
			if is_instance_valid(b) and b != lord and b.is_alive():
				FarAbilities._dark_smoke(world, b.global_position, b.body_size)
				b.take_damage(99999)
	for n in world.get_children():                 # чужие снаряды гаснут
		if n is Bullet and n.team == 1:
			n.queue_free()
	if is_instance_valid(lord_sky) and lord_sky.has_method("_end"):
		lord_sky._end()
	Engine.time_scale = 0.3
	get_tree().create_timer(0.8, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	Util.flash(world, lp, 260.0, Color(0.9, 0.4, 0.6, 0.9))
	Fx.shake(world, 8.0)
	if am:
		am.cinematic(lord, 7.6, true)
	_banner("Тёмный Лорд повержен… снова", Color(1.0, 0.55, 0.3), 1.2)
	if lord._rig_root:
		var kt := lord._rig_root.create_tween()
		kt.tween_property(lord._rig_root, "rotation", 0.2 * lord.facing, 0.6).set_trans(Tween.TRANS_SINE)
		kt.parallel().tween_property(lord._rig_root, "position:y", lord._rig_root.position.y + 34.0, 0.6)
	_after(1.4, _banner.bind("«Тьма… возьми меня целиком!»", Color(0.85, 0.5, 1.0), 1.3))
	_after(2.1, _darken)
	_after(2.7, _lord_dissolve)
	_after(3.9, _eyes_open)
	_after(4.7, _rise)
	_after(6.0, func():
		if am:
			am._name_card("dark_lord", TITLE, "ТРЕТЬЯ ФАЗА"))
	_after(7.4, _fight)

# ======================= Дуэль: «Мгновенная смерть» в Цитадели во тьме =======================
func _begin_duel() -> void:
	_after(0.3, _eyes_open)
	_after(1.1, _rise_duel)
	_after(2.6, _fight)

func _rise_duel() -> void:
	head_node = Node2D.new()
	head_node.z_index = -2                          # позади игроков — так их лучше видно
	world.add_child(head_node)
	head_rig = AvatarRig.new()
	head_rig.part = "head"
	head_rig.size = HEAD_SIZE
	head_node.add_child(head_rig)
	_head_y = floor_y - HEAD_RISE + 90.0
	head_node.global_position = Vector2(cx, _head_y)
	var ht := create_tween()
	ht.tween_method(func(v: float): _head_y = v, floor_y - HEAD_RISE + 90.0, floor_y - HEAD_RISE, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	head_rig.play("roar")
	for s in [-1, 1]:
		var h := Hand.new()
		h.side = s
		h.anchor = Vector2(cx + s * HAND_DX, floor_y - HAND_RISE)
		h.pos = h.anchor + Vector2(0, 220)
		h.node = Node2D.new()
		h.node.z_index = -2
		world.add_child(h.node)
		h.rig = AvatarRig.new()
		h.rig.part = "hand"
		h.rig.side = s
		h.rig.size = HAND_SIZE
		h.node.add_child(h.rig)
		h.node.global_position = h.pos
		h.cd = 0.8 + (0.0 if s < 0 else 0.7)
		h.state = "back"
		hands.append(h)
		FarAbilities._dark_smoke(world, h.anchor, HAND_SIZE)
	for n in [head_node] + hands.map(func(x): return x.node):
		var nn: Node2D = n
		nn.modulate.a = 0.0
		nn.create_tween().tween_property(nn, "modulate:a", 1.0, 1.0)
	Fx.shake(world, 14.0)
	Util.flash(world, Vector2(cx, floor_y - HEAD_RISE), 300.0, Color(0.6, 0.15, 0.35, 0.8))
	Fx.ring(world, Vector2(cx, floor_y - HEAD_RISE), 520.0, Color(0.55, 0.1, 0.3, 0.9), 0.7, 12.0)

# Столб огня из пола (МЕГА «Пасти тьмы» в Дуэли): метка, потом пламя
func _geyser(x: float, delay: float) -> void:
	x = clampf(x, INNER_L + 40.0, INNER_R - 40.0)
	var at := Vector2(x, floor_y)
	var mark := Fx.rune_circle(world, at, 60.0, Color(1.0, 0.35, 0.15, 0.9), delay + 0.1, 0.25)
	mark.z_index = 3
	var t := mark.create_tween()
	t.tween_interval(delay)
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		var pil := Polygon2D.new()
		pil.polygon = PackedVector2Array([Vector2(-34, 0), Vector2(-22, -240), Vector2(0, -320), Vector2(22, -240), Vector2(34, 0)])
		pil.color = Color(1.0, 0.45, 0.12, 0.85)
		pil.position = at
		pil.z_index = 6
		world.add_child(pil)
		var pt := pil.create_tween()
		pt.tween_property(pil, "scale", Vector2(1.2, 1.1), 0.15)
		pt.tween_property(pil, "modulate:a", 0.0, 0.45)
		pt.tween_callback(pil.queue_free)
		Fx.sparks(world, at, Color(1.0, 0.55, 0.2), 14, 300.0, 4.0, true)
		for p in _foes_of_avatar():
			if absf(p.global_position.x - x) < 40.0 + p.body_size.x * 0.4 and p.global_position.y > floor_y - 340.0:
				p.take_damage(18, _atk_head())
				p.velocity.y = -520.0)

# Тёмная сцена третьей фазы сразу, без перехода (карта Дуэли «Цитадель во тьме»)
static func dark_stage(world: Node, floor_y: float) -> void:
	for n in world.get_children():
		if n is Sprite2D and n.z_index == -10:
			n.modulate = Color(0.24, 0.11, 0.13)
		if n is Weather:
			n.queue_free()
		if n is CanvasLayer and n.layer == 1:            # свет за стенами мрака не виден
			for g in n.get_children():
				if g is Node2D and (g.global_position.x < INNER_L or g.global_position.x > INNER_R):
					g.visible = false
	var dark := Polygon2D.new()
	dark.polygon = PackedVector2Array([Vector2(-300, -1400), Vector2(Colosseum.W + 300, -1400), Vector2(Colosseum.W + 300, floor_y), Vector2(-300, floor_y)])
	dark.color = Color(0.02, 0.0, 0.03, 0.62)
	dark.z_index = -9
	world.add_child(dark)
	for s in [-1, 1]:
		var w := DarkWall.new()
		w.side = s
		w.edge = INNER_L if s < 0 else INNER_R
		w.floor_y = floor_y
		w.instant = true
		world.add_child(w)
	var rects: Array = FarStages.CITADEL_PLATS.duplicate()
	rects.append(Rect2(INNER_L, floor_y, INNER_R - INNER_L, 8))
	for r: Rect2 in rects:
		var l := Line2D.new()
		l.points = PackedVector2Array([r.position + Vector2(4, 1), Vector2(r.end.x - 4, r.position.y + 1)])
		l.width = 3.0
		l.default_color = Color(0.85, 0.30, 0.55, 0.75)
		l.z_index = 3
		world.add_child(l)

# Камера на всю арену третьей фазы
func _framing() -> Array:
	var vs: Vector2 = Config.screen(world)
	var pan: float = Config.panel()
	var top := floor_y - 800.0                  # сверху — место под надписи и полосу здоровья босса
	var bottom := floor_y + 30.0
	var z := minf(vs.x / (INNER_R - INNER_L + 90.0), (vs.y - pan) / (bottom - top))
	var view := vs / z
	return [Vector2(cx, bottom + pan / z - view.y / 2.0), z]

# Фон гаснет, по краям встают стены мрака
func _darken() -> void:
	for n in world.get_children():
		if n is Sprite2D and n.z_index == -10:
			n.create_tween().tween_property(n, "modulate", Color(0.24, 0.11, 0.13), 1.6)
		if n is Weather:
			n.queue_free()
	var gl: Node = am.info.get("glow") if am else null
	if gl:
		for g in gl.get_children():                   # свет за стенами мрака гаснет
			if g is Node2D and not (g in am._lanterns) and (g.global_position.x < INNER_L or g.global_position.x > INNER_R):
				g.create_tween().tween_property(g, "modulate:a", 0.0, 1.2)
	_dark = Polygon2D.new()
	_dark.polygon = PackedVector2Array([Vector2(-300, -1400), Vector2(Colosseum.W + 300, -1400), Vector2(Colosseum.W + 300, floor_y), Vector2(-300, floor_y)])
	_dark.color = Color(0.02, 0.0, 0.03, 0.0)
	_dark.z_index = -9
	world.add_child(_dark)
	_dark.create_tween().tween_property(_dark, "color:a", 0.62, 1.6)
	_runes()
	for s in [-1, 1]:
		var w := DarkWall.new()
		w.side = s
		w.edge = INNER_L if s < 0 else INNER_R
		w.floor_y = floor_y
		world.add_child(w)
		_walls.append(w)
	Fx.shake(world, 6.0)
	var fr := _framing()
	if am:
		am.cut_focus(fr[0], float(fr[1]), 1.4)
	# неподвижная камера на всю арену — на неё вернётся бой после сцены
	_cam = Camera2D.new()
	_cam.position = fr[0]
	_cam.zoom = Vector2(fr[1], fr[1])
	world.add_child(_cam)
	if am:
		am.stage_cam = _cam

# Плиты третьей фазы светятся тлеющими рунами — во тьме их видно
func _runes() -> void:
	var rects: Array = FarStages.CITADEL_PLATS.duplicate()
	rects.append(Rect2(INNER_L, floor_y, INNER_R - INNER_L, 8))
	for r: Rect2 in rects:
		var l := Line2D.new()
		l.points = PackedVector2Array([r.position + Vector2(4, 1), Vector2(r.end.x - 4, r.position.y + 1)])
		l.width = 3.0
		l.default_color = Color(0.85, 0.30, 0.55, 0.0)
		l.z_index = 3
		world.add_child(l)
		l.create_tween().tween_property(l, "default_color:a", 0.75, 1.4)
		_walls.append(l)

# Лорд растворяется во тьме, камень из груди взлетает на место головы
func _lord_dissolve() -> void:
	if not is_instance_valid(lord):
		return
	var lp := lord.global_position
	var t := lord.create_tween()                  # весь Лорд — с крыльями и камнем — уходит во тьму
	t.tween_property(lord, "modulate", Color(0.05, 0.02, 0.06, 1.0), 0.6)
	t.tween_property(lord, "modulate:a", 0.0, 0.8)
	for k in 26:                                  # тьма стекает с него вверх
		var s := Polygon2D.new()
		s.polygon = Util.circle(randf_range(8, 18), 8)
		s.color = Color(0.04, 0.01, 0.06, 0.85)
		s.position = lp + Vector2(randf_range(-50, 50), randf_range(-90, 90))
		s.z_index = 6
		world.add_child(s)
		var goal := Vector2(cx + randf_range(-120, 120), _head_y + randf_range(-80, 80))
		var st := s.create_tween()
		st.tween_interval(k * 0.04)
		st.tween_property(s, "position", goal, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		st.parallel().tween_property(s, "scale", Vector2(2.2, 2.2), 1.0)
		st.tween_property(s, "modulate:a", 0.0, 0.4)
		st.tween_callback(s.queue_free)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([Vector2(0, -12), Vector2(9, 0), Vector2(0, 12), Vector2(-9, 0)])
	gem.color = Color(1.0, 0.45, 0.15)
	gem.position = lp + Vector2(0, -lord.body_size.y * 0.18)
	gem.z_index = 9
	world.add_child(gem)
	var gl := Torch.make_glow(120.0, Color(1.0, 0.5, 0.2, 0.9))
	gem.add_child(gl)
	var gt := gem.create_tween()
	gt.tween_property(gem, "position", Vector2(cx, _head_y - HEAD_SIZE.y * 0.2), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	gt.parallel().tween_property(gem, "rotation", TAU * 2.0, 1.2)
	gt.tween_property(gem, "scale", Vector2(2.4, 2.4), 0.25)
	gt.tween_property(gem, "modulate:a", 0.0, 0.5)
	gt.tween_callback(gem.queue_free)

func _eyes_open() -> void:
	_make_glows()
	for g in _glows:
		(g as Node2D).modulate.a = 0.0
		g.create_tween().tween_property(g, "modulate:a", 1.0, 0.6)
	_glow.global_position = Vector2(cx, _head_y)
	Fx.shake(world, 5.0)

# Голова и руки поднимаются из тьмы
func _rise() -> void:
	var factor := 1.0
	var t: Dictionary = Bots.TYPES["dark_lord"]
	if is_instance_valid(lord):
		factor = float(lord.max_hp) / float(t["phase2_hp"])
	head = _make_part(Vector2(cx, _head_y), HEAD_SIZE, int(t["phase3_hp"] * factor), "head", 0)
	head.stagger_max = head.max_hp * Balance.STAGGER_SHARE
	head.set_meta("title", TITLE)
	head_node = head
	head_rig = head.rig
	head._hp_fill.visible = false
	(head._hp_fill.get_meta("bg") as Node).visible = false
	for s in [-1, 1]:
		var h := Hand.new()
		h.side = s
		h.anchor = Vector2(cx + s * HAND_DX, floor_y - HAND_RISE)
		h.pos = h.anchor + Vector2(0, 220)
		h.p = _make_part(h.pos, HAND_SIZE, int(t["phase3_hand_hp"] * factor), "hand", s)
		h.node = h.p
		h.rig = h.p.rig
		h.p.on_lethal = func() -> bool:
			_break_hand(h)
			return true
		h.cd = 1.2 + (0.0 if s < 0 else 1.4)
		h.state = "back"
		h.t = 0.0
		hands.append(h)
	for part in [head] + hands.map(func(x): return x.p):
		var pp: Player = part
		pp.cutscene_shield = true
		if pp._rig_root:
			pp._rig_root.modulate.a = 0.0
			pp._rig_root.create_tween().tween_property(pp._rig_root, "modulate:a", 1.0, 1.0)
	head.global_position = Vector2(cx, _head_y + 90.0)
	var ht := create_tween()
	ht.tween_method(func(v: float): _head_y = v, floor_y - HEAD_RISE + 90.0, floor_y - HEAD_RISE, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_head_y = floor_y - HEAD_RISE + 90.0
	if head_rig:
		head_rig.play("roar")
	Fx.shake(world, 14.0)
	Util.flash(world, Vector2(cx, floor_y - HEAD_RISE), 300.0, Color(0.6, 0.15, 0.35, 0.8))
	Fx.ring(world, Vector2(cx, floor_y - HEAD_RISE), 520.0, Color(0.55, 0.1, 0.3, 0.9), 0.7, 12.0)
	for hh in hands:
		FarAbilities._dark_smoke(world, hh.anchor, HAND_SIZE)
	# все герои — внутри стен мрака
	for p in _heroes():
		if p.global_position.x < INNER_L + 50.0 or p.global_position.x > INNER_R - 50.0:
			FarAbilities._dark_smoke(world, p.global_position, p.body_size)
			p.global_position = Vector2(clampf(p.global_position.x, INNER_L + 120.0, INNER_R - 120.0), floor_y - p.body_size.y / 2 - 2)
			p.velocity = Vector2.ZERO
	if am:
		am.adopt_boss(head, lord)
	lord = null

func _make_part(pos: Vector2, size: Vector2, hp: int, part: String, side: int) -> Player:
	var b := Player.new()
	b.prefix = "bot"
	b.index = 1
	b.team = 1
	b.is_bot = true
	b.respawn = false
	b.spawn = pos
	b.body_size = size
	b.color = Color(0.10, 0.08, 0.11)
	b.team_color = Color(1.0, 0.3, 0.3)
	b.max_hp = maxi(hp, 1)
	b.speed = 0.0
	b.jump_force = 0.0
	b.abilities = ["", "", ""]
	b.ult = ""
	b.bot_abilities = {}
	b.anchored = true
	b.map_w = Colosseum.W
	b.target = _nearest_hero(pos)
	b.bar_lift = -size.y * 0.15 if part == "hand" else 0.0
	world.add_child(b)
	b.collision_mask = 0
	b._body.visible = false
	b._eye.visible = false
	b._ammo_fill.visible = false
	(b._ammo_fill.get_meta("bg") as Node).visible = false
	b._rig_root = Node2D.new()
	b._rig_root.position = Vector2(0, size.y / 2)
	b.add_child(b._rig_root)
	var r := AvatarRig.new()
	r.part = part
	r.side = side
	r.size = size
	r.bot = b
	r.position = Vector2(0, -size.y / 2)
	b._rig_root.add_child(r)
	b.rig = r
	b.set_meta("kind", "dark_lord")
	b.set_meta("avatar", part)
	b.set_meta("fireproof", true)
	if am:
		b.allies = func(): return am._alive
	return b

func _fight() -> void:
	if _state != "intro":
		return
	_state = "fight"
	if is_instance_valid(head):
		head.cutscene_shield = false
	for h in hands:
		if is_instance_valid(h.p):
			h.p.cutscene_shield = false
	if am:
		am._after(0.8, am.hud.show_hint.bind(String(Bots.TYPES["dark_lord"]["hint3"]), 11.0))

# ======================= Каждый кадр =======================
func _physics_process(delta: float) -> void:
	_t += delta
	if _state == "intro":
		if head_node and is_instance_valid(head_node):
			_place_head()
			for h in hands:
				_hand_back(h, delta, 0.9)
				_place_hand(h)
		_update_glows()
		return
	if _state == "dead":
		return
	if not duel and (not is_instance_valid(head) or not head.is_alive()):
		_die()
		return
	if am and am._state == "over":
		return
	if duel:
		_rage_t += delta
	_place_head()
	var paused := _head_stunned() or _state == "exposed"
	if _state == "exposed":
		_expose_t -= delta
		if _expose_t <= 0.0:
			_recover()
	elif not paused:
		_head_brain(delta)
	if _head_act != "":
		_head_tick(delta)
	for h in hands:
		_update_hand(h, delta, paused)
	_update_glows()

func _place_head() -> void:
	head_node.global_position = Vector2(cx + sin(_t * 0.7) * 14.0, _head_y + sin(_t * 1.3) * 8.0)
	if is_instance_valid(head):
		head.target = _nearest_hero(head_node.global_position)

func _place_hand(h: Hand) -> void:
	h.node.global_position = h.pos
	if h.shadow:
		h.shadow.visible = h.state == "slam_up" or h.state == "slam_down"
		h.shadow.position = Vector2(h.pos.x, floor_y)

# ---------- Свечение глаз, камня и пасти (поверх тьмы) ----------
func _make_glows() -> void:
	var layer: Node = glow_layer
	_glow = Node2D.new()
	if layer:
		layer.add_child(_glow)
	else:
		world.add_child(_glow)
	for k in 2:
		var e := Torch.make_glow(130.0, Color(1.0, 0.5, 0.15, 0.9))
		_glow.add_child(e)
		_glows.append(e)
	var g := Torch.make_glow(110.0, Color(1.0, 0.35, 0.1, 0.8))
	_glow.add_child(g)
	_glows.append(g)
	var m := Torch.make_glow(260.0, Color(1.0, 0.25, 0.08, 0.0))
	_glow.add_child(m)
	_glows.append(m)
	var halo := Torch.make_glow(900.0, Color(0.45, 0.08, 0.20, 0.35))      # тёмно-багровый ореол за головой
	_glow.add_child(halo)
	_glows.append(halo)

func _update_glows() -> void:
	if _glow == null or not is_instance_valid(_glow):
		return
	_glow.global_position = Vector2.ZERO
	if head_rig == null or not is_instance_valid(head_rig):
		var pos := Vector2(cx, _head_y)
		var eye_off := [Vector2(-44, -10), Vector2(44, -10)]
		for k in 2:
			(_glows[k] as Node2D).global_position = pos + eye_off[k]
		(_glows[2] as Node2D).global_position = pos + Vector2(0, -58)
		(_glows[3] as Node2D).global_position = pos + Vector2(0, 80)
		(_glows[4] as Node2D).global_position = pos
		return
	var rig: AvatarRig = head_rig
	var eyes := rig.eye_points()
	var lit := 1.0 - rig.dim
	for k in 2:
		var e: Sprite2D = _glows[k]
		e.global_position = eyes[k]
		e.modulate.a = lit * (0.85 + 0.15 * sin(_t * 6.0 + k))
	var gm: Sprite2D = _glows[2]
	gm.global_position = rig.gem_point()
	gm.modulate.a = lit * (0.7 + 0.3 * sin(_t * 3.0))
	var mw: Sprite2D = _glows[3]
	mw.global_position = rig.mouth_point()
	mw.modulate.a = rig.jaw_open * 0.9
	var halo: Sprite2D = _glows[4]
	halo.global_position = head_node.global_position
	halo.modulate.a = 0.35 + 0.08 * sin(_t * 1.5)

# ======================= Голова =======================
func _head_brain(delta: float) -> void:
	for k in _head_cd.keys():
		_head_cd[k] -= delta * _rage()
	if _head_act != "":
		return
	_pace -= delta * _rage()
	if _pace > 0.0:
		return
	var heroes := _heroes()
	if heroes.is_empty():
		return
	var opts: Array = []
	for k in ["gaze", "maw", "orbs", "call", "clap"]:
		if _head_cd[k] > 0.0:
			continue
		if k == "clap" and not (_hand_ok(hands[0]) and _hand_ok(hands[1])):
			continue
		if k == "call" and (duel or am and am._alive.filter(func(b): return is_instance_valid(b) and b.has_meta("summoned")).size() >= 2):
			continue
		opts.append(k)
	if opts.is_empty():
		return
	var pick: String = opts[randi() % opts.size()]
	if "clap" in opts and randf() < 0.45:
		pick = "clap"                                   # хлопок — редкий момент, когда обе руки свободны
	_pace = 1.6 + randf() * 0.8
	match pick:
		"gaze": _start_gaze()
		"maw": _start_maw()
		"orbs": _start_orbs()
		"call": _start_call()
		"clap": _start_clap()

func _start_head(act: String, cd: float) -> void:
	_head_act = act
	_head_t = 0.0
	_head_cd[act] = cd
	_tick = 0.0

func _end_head_act() -> void:
	_head_act = ""
	for l in _lines:
		if is_instance_valid(l):
			l.queue_free()
	_lines.clear()
	if is_instance_valid(_maw_fx):
		_maw_fx.queue_free()
	_maw_fx = null
	if head_rig and is_instance_valid(head_rig):
		head_rig.play("close")

func _head_tick(delta: float) -> void:
	_head_t += delta
	match _head_act:
		"gaze": _gaze_tick(delta)
		"maw": _maw_tick(delta)
		"orbs": _orbs_tick()
		"call":
			if _head_t > 1.0:
				_end_head_act()
		"clap":
			if _head_t > 3.2:
				_end_head_act()

# ----- «Взгляд»: лучи из глаз -----
func _gaze_target(k: int) -> Player:
	if duel:
		var hs := _heroes()
		if hs.size() >= 2:
			return hs[k % hs.size()]                  # Дуэль: каждый глаз — на своего игрока
	return _nearest_hero(head_node.global_position)

func _start_gaze() -> void:
	_start_head("gaze", 7.0)
	var eyes: Array = head_rig.eye_points()
	_gaze_dirs.clear()
	for k in 2:
		var l := Line2D.new()
		l.width = 2.0
		l.default_color = Color(1.0, 0.25, 0.15, 0.6)
		l.z_index = 8
		world.add_child(l)
		_lines.append(l)
		var t := _gaze_target(k)
		var aim: Vector2 = t.hurt_center() if t else Vector2(cx, floor_y)
		_gaze_dirs.append((aim - eyes[k]).normalized())

func _gaze_end_point(from: Vector2, dir: Vector2) -> Vector2:
	if dir.y > 0.05:
		var len := (floor_y - from.y) / dir.y
		return from + dir * minf(len, 2400.0)
	return from + dir * 2400.0

func _gaze_tick(delta: float) -> void:
	var eyes: Array = head_rig.eye_points()
	if _head_t < 1.1:
		# прицел ведёт героя (с небольшим отставанием)
		for k in 2:
			var t := _gaze_target(k)
			if t:
				var want: Vector2 = (t.hurt_center() + Vector2((k * 2 - 1) * 18.0, 0) - eyes[k]).normalized()
				_gaze_dirs[k] = (_gaze_dirs[k] as Vector2).slerp(want, minf(1.0, delta * 5.0))
			var l: Line2D = _lines[k]
			l.points = PackedVector2Array([eyes[k], _gaze_end_point(eyes[k], _gaze_dirs[k])])
			l.default_color.a = 0.35 + 0.4 * (_head_t / 1.1)
	elif _head_t < 1.45:
		for k in 2:                                           # вспышка — прицел замер
			var l: Line2D = _lines[k]
			l.points = PackedVector2Array([eyes[k], _gaze_end_point(eyes[k], _gaze_dirs[k])])
			l.width = 3.0
			l.default_color = Color(1, 1, 1, 0.9) if int(_head_t * 20.0) % 2 == 0 else Color(1.0, 0.4, 0.2, 0.9)
	elif _head_t < 2.1:
		if _tick <= 0.0 and _head_t < 1.5:
			Fx.shake(world, 5.0)
		for k in 2:
			var l: Line2D = _lines[k]
			var end := _gaze_end_point(eyes[k], _gaze_dirs[k])
			l.points = PackedVector2Array([eyes[k], end])
			l.width = 24.0 + 6.0 * sin(_t * 40.0)
			l.default_color = Color(1.0, 0.55, 0.25, 0.95)
			if randf() < 0.5:
				Fx.sparks(world, end, Color(1.0, 0.5, 0.2), 2, 160.0, 3.0, true)
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.2
			for p in _foes_of_avatar():
				var c: Vector2 = p.hurt_center()
				for k in 2:
					var q := Geometry2D.get_closest_point_to_segment(c, eyes[k], _gaze_end_point(eyes[k], _gaze_dirs[k]))
					if q.distance_to(c) < 22.0 + p.body_size.x * 0.35:
						p.take_damage(12, _atk_head())
						break
	else:
		_end_head_act()

# ----- «Пасть тьмы»: столб огня под головой -----
func _start_maw() -> void:
	_start_head("maw", 11.0)
	head_rig.play("open")
	_maw_fx = Node2D.new()
	_maw_fx.z_index = 6
	var warn := Polygon2D.new()
	warn.polygon = PackedVector2Array([Vector2(-65, 0), Vector2(65, 0), Vector2(65, 1), Vector2(-65, 1)])
	warn.color = Color(1.0, 0.2, 0.1, 0.18)
	_maw_fx.add_child(warn)
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([Vector2(-55, 0), Vector2(55, 0), Vector2(55, 1), Vector2(-55, 1)])
	beam.color = Color(0.20, 0.0, 0.06, 0.92)
	beam.visible = false
	_maw_fx.add_child(beam)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(-20, 0), Vector2(20, 0), Vector2(20, 1), Vector2(-20, 1)])
	core.color = Color(1.0, 0.45, 0.15, 0.95)
	core.visible = false
	_maw_fx.add_child(core)
	world.add_child(_maw_fx)
	if duel:
		for t in _heroes():                         # МЕГА: из пола под игроками бьют столбы огня
			_geyser(t.global_position.x, 0.5)
			_geyser(t.global_position.x + randf_range(-260, 260), 1.1)
	else:
		_banner("Пасть тьмы! Уходи из-под головы!", Color(1.0, 0.45, 0.3), 1.2)

func _maw_tick(delta: float) -> void:
	if not is_instance_valid(_maw_fx):
		_end_head_act()
		return
	var m: Vector2 = head_rig.mouth_point()
	_maw_fx.global_position = m
	var h := floor_y - m.y
	var warn: Polygon2D = _maw_fx.get_child(0)
	var beam: Polygon2D = _maw_fx.get_child(1)
	var core: Polygon2D = _maw_fx.get_child(2)
	for poly in [warn, beam, core]:
		var pts: PackedVector2Array = (poly as Polygon2D).polygon
		pts[2] = Vector2(pts[2].x, h)
		pts[3] = Vector2(pts[3].x, h)
		(poly as Polygon2D).polygon = pts
	if _head_t < 0.9:
		warn.color.a = 0.12 + 0.18 * absf(sin(_head_t * 14.0))
	elif _head_t < 2.7:
		warn.visible = false
		beam.visible = true
		core.visible = true
		beam.scale.x = 1.0 + 0.12 * sin(_t * 30.0)
		core.scale.x = 1.0 + 0.3 * sin(_t * 45.0)
		if _head_t < 0.95:
			Fx.shake(world, 8.0)
		if randf() < 0.7:
			Fx.sparks(world, Vector2(m.x + randf_range(-50, 50), floor_y - 4), Color(1.0, 0.45, 0.15), 2, 260.0, 4.0, true)
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.25
			for p in _foes_of_avatar():
				if absf(p.global_position.x - m.x) < 55.0 + p.body_size.x * 0.35 and p.global_position.y > m.y:
					p.take_damage(14, _atk_head())
	else:
		_end_head_act()

# ----- «Град»: веера тёмных сфер -----
func _start_orbs() -> void:
	_start_head("orbs", 6.0)
	_volley = 0
	head_rig.play("open")

func _orbs_tick() -> void:
	var times := [0.35, 0.8, 1.25, 1.7, 2.15] if duel else [0.35, 0.8, 1.25]
	if _volley < times.size() and _head_t >= times[_volley]:
		var t := _gaze_target(_volley)
		var from: Vector2 = head_rig.mouth_point()
		var base_dir := (t.hurt_center() - from).normalized() if t else Vector2.DOWN
		var off := 0.09 if _volley % 2 == 1 else 0.0              # каждый второй веер сдвинут — щели между сферами
		for k in 7:
			var b := Bullet.new()
			b.shooter = _atk_head()
			b.team = _bullet_team()
			b.direction = base_dir.rotated((k - 3) * 0.19 + off)
			b.speed = 380.0
			b.damage = 10
			b.size = 16.0
			b.style = "dark"
			b.color = Color(0.5, 0.15, 0.6)
			b.position = from
			world.add_child(b)
		Fx.sparks(world, from, Color(0.7, 0.3, 0.9), 8, 180.0, 4.0)
		_volley += 1
	if _head_t > (2.5 if duel else 1.6):
		_end_head_act()

# ----- «Зов»: из тьмы выходят тени -----
func _start_call() -> void:
	_start_head("call", 18.0)
	head_rig.play("roar")
	Fx.shake(world, 6.0)
	if am:
		am._summon("shade", 2, Vector2(cx, floor_y))
	_banner("Из тьмы выходят тени!", Color(0.8, 0.55, 1.0), 1.2)

# ======================= Руки =======================
func _hand_ok(h: Hand) -> bool:
	return h.broken <= 0.0 and h.state == "idle" and _hand_alive(h)

func _hand_busy() -> bool:
	for h in hands:
		if h.state.begins_with("slam") or h.state.begins_with("clap"):
			return true
	return false

func _update_hand(h: Hand, delta: float, paused: bool) -> void:
	if h.broken > 0.0:
		if _state == "fight":
			h.broken -= delta
			if h.broken <= 0.0:
				_regrow(h)
		return
	h.t += delta
	var rig: AvatarRig = h.rig
	match h.state:
		"idle":
			rig.fist = false
			rig.flat = false
			var bob := Vector2(sin(_t * 1.1 + h.side) * 12.0, sin(_t * 1.7 + h.side) * 10.0)
			h.pos = h.pos.lerp(h.anchor + bob, minf(1.0, delta * 3.0))
			if not paused:
				h.cd -= delta * _rage()
				if h.cd <= 0.0:
					_hand_choose(h)
		"back":
			_hand_back(h, delta, 0.7)
		"slam_up":
			rig.fist = true
			var gx := h.goal.x
			if is_instance_valid(h.target) and h.t < 0.8:
				gx = clampf(h.target.global_position.x, INNER_L + 90.0, INNER_R - 90.0)      # тень ползёт за героем
				h.goal.x = gx
			h.pos.x = move_toward(h.pos.x, gx, delta * 900.0)
			h.pos.y = move_toward(h.pos.y, floor_y - 560.0, delta * 900.0)
			if h.shadow:
				var k := clampf(h.t / 1.0, 0.2, 1.0)
				h.shadow.scale = Vector2(k, k)
				h.shadow.color.a = 0.25 + 0.35 * k
			if h.t >= 1.0:
				h.state = "slam_down"
				h.t = 0.0
		"slam_down":
			h.pos.y += delta * 2600.0
			var bottom := floor_y - HAND_SIZE.y / 2.0
			if h.pos.y >= bottom:
				h.pos.y = bottom
				_slam_impact(h)
				h.state = "slam_hold"
				h.t = 0.0
		"slam_hold":
			if h.t >= 0.85:
				h.state = "back"
				h.t = 0.0
		"aim":
			rig.fist = false
			if is_instance_valid(h.target):
				var to: Vector2 = h.target.hurt_center() - h.pos
				rig.rotation = lerp_angle(rig.rotation, clampf(-to.angle_to(Vector2.DOWN), -0.6, 0.6), minf(1.0, delta * 8.0))
			if h.t >= 0.45 + h.shots * 0.14 and h.shots < 3:
				_hand_shoot(h, h.shots)
				h.shots += 1
			if h.t >= 1.3:
				rig.rotation = 0.0
				h.state = "idle"
				h.cd = randf_range(1.6, 2.6)
		"clap_wind":
			rig.fist = false
			var y := h.goal.y
			if is_instance_valid(h.target) and h.t < 0.8:
				y = clampf(h.target.hurt_center().y, floor_y - 420.0, floor_y - HAND_SIZE.y * 0.32)
				h.goal = Vector2(h.target.global_position.x, y)
			var want := Vector2(h.goal.x + h.side * 440.0, h.goal.y)
			h.pos = h.pos.move_toward(want, delta * 1300.0)
			rig.rotation = lerp_angle(rig.rotation, 0.6 * h.side, minf(1.0, delta * 6.0))     # когти — к герою
			if h.t >= 1.0:
				h.state = "clap_go"
				h.t = 0.0
				h.hit.clear()
		"clap_go":
			h.pos.x = move_toward(h.pos.x, h.goal.x + h.side * HAND_SIZE.x * 0.42, delta * 1900.0)
			for p in _foes_of_avatar():
				if h.hit.has(p):
					continue
				var c: Vector2 = p.hurt_center()
				if absf(c.x - h.pos.x) < HAND_SIZE.x * 0.4 + p.body_size.x * 0.3 and absf(c.y - h.pos.y) < HAND_SIZE.y * 0.32 + p.body_size.y * 0.3:
					h.hit[p] = true
					p.take_damage(24, _atk(h))
					p.velocity = Vector2(-h.side * 300.0, -380.0)
			if absf(h.pos.x - (h.goal.x + h.side * HAND_SIZE.x * 0.42)) < 2.0:
				if h.side < 0:
					_clap_impact(h.goal)
				h.state = "clap_hold"
				h.t = 0.0
		"clap_hold":
			if h.t >= 0.45:
				rig.rotation = 0.0
				h.state = "back"
				h.t = 0.0
	_place_hand(h)

func _hand_back(h: Hand, delta: float, dur: float) -> void:
	h.rig.fist = false
	h.pos = h.pos.lerp(h.anchor, minf(1.0, delta * 4.0 / dur))
	h.rig.rotation = lerp_angle(h.rig.rotation, 0.0, minf(1.0, delta * 6.0))
	if h.state == "back" and (h.t >= dur or h.pos.distance_to(h.anchor) < 6.0):
		h.state = "idle"
		h.cd = randf_range(1.4, 2.4)

func _hand_choose(h: Hand) -> void:
	var t := _nearest_hero(h.pos)
	if t == null:
		h.cd = 1.0
		return
	h.target = t
	h.t = 0.0
	var tx: float = t.global_position.x
	var reach := tx > INNER_L and tx < cx + 260.0 if h.side < 0 else tx > cx - 260.0 and tx < INNER_R
	if duel:
		reach = true
	if (_hand_busy() and not duel) or not reach or randf() < (0.3 if duel else 0.35):
		h.state = "aim"
		h.shots = 0
		return
	h.state = "slam_up"
	h.goal = Vector2(tx, floor_y)
	if h.shadow == null:
		h.shadow = Polygon2D.new()
		var pts := Util.circle(1.0, 20)
		for i in pts.size():
			pts[i] = pts[i] * Vector2(HAND_SIZE.x * 0.55, 14.0)
		h.shadow.polygon = pts
		h.shadow.color = Color(1.0, 0.25, 0.10, 0.4)          # тень-предупреждение: сюда упадёт кулак
		h.shadow.z_index = 2
		var rim := Line2D.new()
		var rp := pts.duplicate()
		rp.append(rp[0])
		rim.points = rp
		rim.width = 3.0
		rim.default_color = Color(1.0, 0.55, 0.3, 0.9)
		h.shadow.add_child(rim)
		world.add_child(h.shadow)

func _slam_impact(h: Hand) -> void:
	var at := Vector2(h.pos.x, floor_y)
	Fx.shake(world, 11.0)
	Fx.ring(world, at, 170.0, Color(0.6, 0.15, 0.3, 0.9), 0.4, 8.0, 0.3)
	Fx.cracks(world, at, Color(0.9, 0.3, 0.15), 110.0)
	Fx.sparks(world, at + Vector2(0, -6), Color(0.35, 0.28, 0.32), 16, 300.0, 5.0, true)
	for p in _foes_of_avatar():
		var c: Vector2 = p.hurt_center()
		if absf(c.x - h.pos.x) < HAND_SIZE.x * 0.5 + p.body_size.x * 0.3 and c.y > h.pos.y - HAND_SIZE.y * 0.5 - 20.0:
			p.take_damage(28, _atk(h))
			p.velocity = Vector2(signf(c.x - h.pos.x + 0.01) * 520.0, -420.0)
	for d in [-1.0, 1.0]:
		var w := FloorWave.new()
		w.dir = d
		w.attacker = _atk(h)
		w.position = at + Vector2(d * HAND_SIZE.x * 0.4, 0)
		w.lo = INNER_L
		w.hi = INNER_R
		w.hit_all = duel
		world.add_child(w)

func _hand_shoot(h: Hand, k: int) -> void:
	if not is_instance_valid(h.target):
		return
	var fp: Array = h.rig.finger_points()
	var from: Vector2 = fp[(k + 1) % fp.size()]
	var b := Bullet.new()
	b.shooter = _atk(h)
	b.team = _bullet_team()
	b.direction = (h.target.hurt_center() - from).normalized().rotated((k - 1) * 0.13)
	b.speed = 560.0
	b.damage = 12
	b.size = 18.0
	b.style = "ember"
	b.burn_t = 1.5
	b.color = Color(1.0, 0.5, 0.2)
	b.position = from
	world.add_child(b)
	Fx.sparks(world, from, Color(1.0, 0.55, 0.2), 4, 140.0, 3.0)

# ----- «Хлопок»: обе руки схлопываются на высоте героя -----
var _clap_n := 0
func _start_clap() -> void:
	_start_head("clap", 12.0)
	_clap_n += 1
	var t := _gaze_target(_clap_n)
	if t == null:
		return
	for h in hands:
		h.state = "clap_wind"
		h.t = 0.0
		h.target = t
		h.goal = Vector2(t.global_position.x, t.hurt_center().y)
	head_rig.play("roar")
	if not duel:
		_banner("Хлопок! Прыгай!", Color(1.0, 0.6, 0.3), 1.0)

func _clap_impact(at: Vector2) -> void:
	Fx.shake(world, 12.0)
	Util.flash(world, at, 160.0, Color(1.0, 0.6, 0.35, 0.9))
	Fx.ring(world, at, 220.0, Color(1.0, 0.5, 0.25, 0.9), 0.35, 8.0)
	for p in _foes_of_avatar():
		var c: Vector2 = p.hurt_center()
		if absf(c.x - at.x) < 100.0 and absf(c.y - at.y) < 70.0:
			p.take_damage(30, _atk_head())
			p.stun(0.6)

# ----- Сломанная рука рассыпается -----
func _break_hand(h: Hand) -> void:
	var p := h.p
	h.broken = HAND_REGROW
	h.state = "idle"
	p.rig.rotation = 0.0
	p.hp = p.max_hp
	p._alive = false
	p.visible = false
	p.collision_layer = 0
	if h.shadow:
		h.shadow.visible = false
	_crumble(h.pos, HAND_SIZE)
	if am:
		am._float_text("Рука сломана!", Color(1.0, 0.8, 0.4), h.pos)
	var both := true
	for o in hands:
		if o.broken <= 0.0:
			both = false
	if both and _state == "fight":
		_expose()

func _crumble(at: Vector2, size: Vector2) -> void:
	Fx.shake(world, 7.0)
	FarAbilities._dark_smoke(world, at, size)
	Fx.sparks(world, at, Color(1.0, 0.45, 0.15), 14, 260.0, 4.0)
	for k in 14:
		var s := Polygon2D.new()
		s.polygon = PackedVector2Array([Vector2(-6, -4), Vector2(5, -6), Vector2(7, 4), Vector2(-4, 6)])
		s.color = Color(0.12, 0.09, 0.13) if k % 3 else Color(1.0, 0.4, 0.12)
		s.position = at + Vector2(randf_range(-size.x * 0.4, size.x * 0.4), randf_range(-size.y * 0.4, size.y * 0.4))
		s.z_index = 6
		world.add_child(s)
		var t := s.create_tween()
		var goal := Vector2(s.position.x + randf_range(-140, 140), floor_y - 4.0)
		t.tween_property(s, "position", goal, randf_range(0.5, 0.9)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(s, "rotation", randf_range(-8, 8), 0.8)
		t.tween_interval(1.5)
		t.tween_property(s, "modulate:a", 0.0, 0.6)
		t.tween_callback(s.queue_free)

func _regrow(h: Hand) -> void:
	var p := h.p
	h.broken = 0.0
	p._alive = true
	p.visible = true
	p.collision_layer = Layer.BOT
	p.heal_full()
	h.pos = h.anchor + Vector2(0, 120.0)
	h.state = "back"
	h.t = 0.0
	h.cd = 1.5
	_place_hand(h)
	if p._rig_root:
		p._rig_root.modulate.a = 0.0
		p._rig_root.create_tween().tween_property(p._rig_root, "modulate:a", 1.0, 0.7)
	for k in 14:                                         # тьма стягивается в новую руку
		var s := Polygon2D.new()
		s.polygon = Util.circle(randf_range(6, 14), 8)
		s.color = Color(0.05, 0.01, 0.07, 0.8)
		s.position = h.anchor + Vector2.from_angle(randf() * TAU) * randf_range(140, 260)
		s.z_index = 6
		world.add_child(s)
		var t := s.create_tween()
		t.tween_property(s, "position", h.anchor, 0.6).set_ease(Tween.EASE_IN)
		t.tween_callback(s.queue_free)

# ----- Обе руки сломаны: голова у самого пола -----
func _expose() -> void:
	_state = "exposed"
	_expose_t = EXPOSE_T
	_end_head_act()
	var tw := create_tween()
	tw.tween_method(func(v: float): _head_y = v, _head_y, floor_y - 175.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	head.stun(EXPOSE_T)
	head_rig.play("open")
	head_rig.dim = 0.6
	Fx.shake(world, 12.0)
	_banner("Обе руки сломаны — голова открыта! Бей!", Color(1.0, 0.85, 0.3), 1.8)
	_after(0.8, func():
		if _state == "exposed":
			Fx.ring(world, Vector2(cx, floor_y), 360.0, Color(0.6, 0.15, 0.3, 0.8), 0.5, 10.0, 0.3)
			Fx.sparks(world, Vector2(cx, floor_y - 6), Color(0.35, 0.28, 0.32), 20, 320.0, 5.0, true))

func _recover() -> void:
	_state = "fight"
	head_rig.dim = 0.0
	head_rig.play("roar")
	var tw := create_tween()
	tw.tween_method(func(v: float): _head_y = v, _head_y, floor_y - HEAD_RISE, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pace = 2.0
	for h in hands:
		h.broken = 0.0001                             # отрастают сразу
	_after(0.5, func():
		for h in hands:
			if h.broken > 0.0 and _state != "dead":
				_regrow(h))

# ======================= Гибель =======================
func _die() -> void:
	if _state == "dead":
		return
	_state = "dead"
	_end_head_act()
	for h in hands:
		if is_instance_valid(h.shadow):
			h.shadow.queue_free()
		if is_instance_valid(h.p):
			if h.broken <= 0.0:
				_crumble(h.pos, HAND_SIZE)
			h.p.queue_free()
	if am:
		for b in am._alive.duplicate():
			if is_instance_valid(b) and b.is_alive() and b != head:
				FarAbilities._dark_smoke(world, b.global_position, b.body_size)
				b.take_damage(99999)
	if is_instance_valid(_glow):
		_glow.create_tween().tween_property(_glow, "modulate:a", 0.0, 0.8)
	# тьма рассеивается
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		for w in _walls:
			if is_instance_valid(w):
				if w.has_method("fade"):
					w.fade()
				else:
					w.create_tween().tween_property(w, "modulate:a", 0.0, 2.0)
		if is_instance_valid(_dark):
			_dark.create_tween().tween_property(_dark, "color:a", 0.0, 3.0)
		for n in world.get_children():
			if n is Sprite2D and n.z_index == -10:
				n.create_tween().tween_property(n, "modulate", Color(0.85, 0.75, 0.75), 3.0))

# Гибель головы (BossFx): трещины света, челюсть отваливается, камень во лбу
# раскалывается — и голова рассыпается пеплом
static func death_fx(world: Node, c: Node2D, feet: Vector2, bs: Vector2) -> void:
	var mid := feet + Vector2(0, -bs.y * 0.5)
	var rig: AvatarRig = null
	var stack: Array = [c]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is AvatarRig:
			rig = n
			break
		stack.append_array(n.get_children())
	if rig:
		rig.play("open")
		rig.dim = 0.0
	var t := c.create_tween()
	for k in 10:                                                  # дрожит
		t.tween_property(c, "position:x", c.position.x + (6.0 if k % 2 == 0 else -6.0), 0.06)
	t.tween_property(c, "position:x", c.position.x, 0.06)
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		Fx.shake(world, 10.0)
		for k in 14:                                              # сквозь трещины бьёт свет
			var l := Line2D.new()
			var a := randf() * TAU
			var o := mid + Vector2(randf_range(-bs.x * 0.3, bs.x * 0.3), randf_range(-bs.y * 0.3, bs.y * 0.25))
			l.points = PackedVector2Array([o, o + Vector2.from_angle(a) * randf_range(200, 480)])
			l.width = 6.0
			l.default_color = Color(1.0, 0.75, 0.45, 0.0)
			l.z_index = 9
			world.add_child(l)
			var lt := l.create_tween()
			lt.tween_property(l, "default_color:a", 0.9, 0.25).set_delay(k * 0.07)
			lt.tween_interval(0.7)
			lt.tween_property(l, "default_color:a", 0.0, 0.4)
			lt.tween_callback(l.queue_free))
	t.tween_property(c, "modulate", Color(2.6, 1.8, 1.4), 1.4)
	t.tween_callback(func():
		c.visible = false
		if not is_instance_valid(world):
			return
		Util.flash(world, mid, 520.0, Color(1.0, 0.85, 0.6, 1.0))
		Fx.ring(world, mid, 640.0, Color(1.0, 0.55, 0.3, 0.95), 0.7, 14.0)
		Fx.ring(world, mid, 340.0, Color(1.0, 0.95, 0.8, 0.9), 0.5, 9.0)
		Fx.shake(world, 20.0)
		var fy := feet.y + 200.0
		var am2 := world.get_tree().get_first_node_in_group("arena_mode") if world.is_inside_tree() else null
		if am2:
			fy = am2.info["floor"]
		for k in 26:                                              # осколки шлема-черепа
			var s := Polygon2D.new()
			var r := randf_range(6, 16)
			s.polygon = PackedVector2Array([Vector2(-r, -r * 0.6), Vector2(r * 0.8, -r), Vector2(r, r * 0.5), Vector2(-r * 0.5, r)])
			s.color = Color(0.12, 0.09, 0.13) if k % 4 else Color(1.0, 0.4, 0.12)
			s.position = mid + Vector2(randf_range(-bs.x * 0.4, bs.x * 0.4), randf_range(-bs.y * 0.4, bs.y * 0.3))
			s.z_index = 6
			world.add_child(s)
			var st := s.create_tween()
			st.tween_property(s, "position", Vector2(s.position.x + randf_range(-300, 300), fy - 4.0), randf_range(0.7, 1.2)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			st.parallel().tween_property(s, "rotation", randf_range(-10, 10), 1.0)
			st.tween_interval(2.0)
			st.tween_property(s, "modulate:a", 0.0, 0.8)
			st.tween_callback(s.queue_free)
		for k in 80:                                              # пепел уносит вверх
			var a := Polygon2D.new()
			a.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(2, 2), Vector2(-2, 2)])
			a.color = Color(0.10, 0.08, 0.10) if k % 4 else Color(1.0, 0.5, 0.2)
			a.position = mid + Vector2(randf_range(-bs.x * 0.5, bs.x * 0.5), randf_range(-bs.y * 0.5, bs.y * 0.45))
			a.z_index = 6
			world.add_child(a)
			var at2 := a.create_tween()
			at2.tween_property(a, "position", a.position + Vector2(randf_range(-160, 160), -randf_range(300, 640)), randf_range(1.6, 2.8)).set_trans(Tween.TRANS_SINE)
			at2.parallel().tween_property(a, "modulate:a", 0.0, 2.4)
			at2.tween_callback(a.queue_free)
		# камень падает на пол и гаснет
		var gem := Polygon2D.new()
		gem.polygon = PackedVector2Array([Vector2(0, -10), Vector2(8, 0), Vector2(0, 10), Vector2(-8, 0)])
		gem.color = Color(1.0, 0.45, 0.15)
		gem.position = mid + Vector2(0, -bs.y * 0.3)
		gem.z_index = 7
		world.add_child(gem)
		var gt := gem.create_tween()
		gt.tween_property(gem, "position:y", fy - 10.0, 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		gt.parallel().tween_property(gem, "rotation", TAU, 0.9)
		gt.tween_property(gem, "color", Color(0.25, 0.10, 0.08), 2.0)
		gt.tween_interval(3.0)
		gt.tween_property(gem, "modulate:a", 0.0, 1.0)
		gt.tween_callback(gem.queue_free))
	t.tween_interval(0.3)
	t.tween_callback(c.queue_free)


# =====================================================================
# Волна по полу от удара кулаком — перепрыгни
class FloorWave extends Node2D:
	var dir := 1.0
	var hit_all := false
	var attacker: Player
	var lo := 0.0
	var hi := 2600.0
	var life := 0.8
	var _hit := {}
	var _t := 0.0

	func _ready() -> void:
		z_index = 5
		var w := Polygon2D.new()
		w.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(-10, -26), Vector2(4, -34), Vector2(16, -20), Vector2(28, 0)])
		w.color = Color(0.40, 0.12, 0.30, 0.85)
		w.scale.x = dir
		add_child(w)
		var c := Polygon2D.new()
		c.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(0, -20), Vector2(14, 0)])
		c.color = Color(1.0, 0.45, 0.2, 0.9)
		add_child(c)

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		position.x += dir * 720.0 * delta
		scale = Vector2.ONE * (1.0 + 0.15 * sin(_t * 30.0))
		if randf() < 0.6:
			Fx.sparks(get_parent(), global_position + Vector2(0, -4), Color(0.4, 0.3, 0.35), 1, 120.0, 3.0, true)
		for n in get_parent().get_children():
			if n is Player and (hit_all or n.team != 1) and n.is_alive() and not _hit.has(n):
				var feet: float = n.global_position.y + n.body_size.y / 2
				if absf(n.global_position.x - global_position.x) < 26.0 + n.body_size.x * 0.4 and feet > global_position.y - 30.0:
					_hit[n] = true
					n.take_damage(12, attacker if is_instance_valid(attacker) else null)
					n.velocity.y = -380.0
		if life <= 0.0 or global_position.x < lo or global_position.x > hi:
			queue_free()


# Стена мрака на краю арены третьей фазы
class DarkWall extends Node2D:
	var side := -1
	var instant := false
	var edge := 550.0
	var floor_y := 940.0
	var _body: StaticBody2D
	var _tendrils: Array = []
	var _t := 0.0

	func _ready() -> void:
		z_index = 5
		var far := -400.0 if side < 0 else 3000.0
		var black := Polygon2D.new()
		black.polygon = PackedVector2Array([Vector2(far, -1400), Vector2(edge, -1400), Vector2(edge, floor_y + 400), Vector2(far, floor_y + 400)])
		black.color = Color(0.02, 0.0, 0.03, 0.97)
		add_child(black)
		for k in 3:                                         # мягкий край
			var band := Polygon2D.new()
			var x0 := edge - side * k * 24.0
			var x1 := edge - side * (k + 1) * 24.0
			band.polygon = PackedVector2Array([Vector2(x0, -1400), Vector2(x1, -1400), Vector2(x1, floor_y + 400), Vector2(x0, floor_y + 400)])
			band.color = Color(0.03, 0.0, 0.05, 0.6 - k * 0.18)
			add_child(band)
		for k in 16:                                        # щупальца тьмы у края
			var t := Polygon2D.new()
			var y := floor_y - 60.0 - k * 70.0
			t.polygon = PackedVector2Array([Vector2(0, -18), Vector2(-side * 46.0, -4), Vector2(-side * 60.0, 4), Vector2(0, 18)])
			t.color = Color(0.06, 0.01, 0.09, 0.85)
			t.position = Vector2(edge, y)
			add_child(t)
			_tendrils.append(t)
		_body = StaticBody2D.new()
		_body.collision_layer = Layer.WORLD
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(80, floor_y + 900)
		col.shape = rs
		_body.position = Vector2(edge + side * 40.0, (floor_y - 900) / 2.0)
		_body.add_child(col)
		add_child(_body)
		if not instant:
			modulate.a = 0.0
			create_tween().tween_property(self, "modulate:a", 1.0, 1.2)

	func _process(delta: float) -> void:
		_t += delta
		for k in _tendrils.size():
			var t: Polygon2D = _tendrils[k]
			t.scale.x = 1.0 + 0.45 * sin(_t * 2.2 + k * 1.3)
			t.rotation = sin(_t * 1.5 + k) * 0.25

	func fade() -> void:
		if is_instance_valid(_body):
			_body.queue_free()
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 2.5)
		t.tween_callback(queue_free)
