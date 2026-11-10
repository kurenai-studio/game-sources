class_name StoryMode
extends Node
# ---------- Режим «История» ----------
# Одиночная РПГ. Пока — «макет»: герой просыпается в поле у сундука.
# Здесь собраны: мир (поле, сундук, табличка, чучело, разбойники, погреб),
# герой с набором StoryKit, рюкзак и экипировка, задания, опыт и уровни,
# сохранение в выбранную ячейку.

signal exit_to_menu

const W := 4200.0
const H := 1300.0
const G := H - 48.0               # верх земли
const SPAWN := Vector2(560, G - 37)
const CHEST_ITEMS := [["iron_helm", 1], ["chainmail", 1], ["guard_greaves", 1], ["leather_boots", 1],
		["leather_gloves", 1], ["traveler_cape", 1], ["copper_ring", 1], ["fang_amulet", 1],
		["short_sword", 1], ["rogue_dagger", 1], ["hunting_bow", 1], ["arrows", 30], ["sling", 1], ["stones", 20],
		["scroll_fireball", 1], ["scroll_dash", 1], ["scroll_heal", 1], ["scroll_rage", 1],
		["potion_hp", 3], ["potion_mana", 1], ["old_key", 1]]
const START_ITEMS := ["leather_shirt", "leather_pants"]

var world: Node2D
var slot := 1
var data: Dictionary
var hero: Player
var kit: StoryKit
var hud: StoryHud
var cam: Camera2D
var props: Array = []
var dummy: Player
# лагерь из двух разбойников у палатки и один дозорный подальше, у погреба
var _bandit_spots := [Vector2(2760, G - 37), Vector2(2900, G - 37), Vector2(3460, G - 37)]
const AGGRO := 420.0               # с какого расстояния разбойник замечает героя
const SHOUT := 330.0               # на каком расстоянии он может позвать своих
var _bandits := {}                # точка -> бот
var _respawn_t := {}              # точка -> через сколько появится снова
var _near: StoryProp
var _overlay: CanvasLayer
var _dummy_t := 0.0
var _show_dmg := true

func _ready() -> void:
	TouchControls._add("p1", {"ranged": KEY_G, "interact": KEY_T, "inv": KEY_I, "quests": KEY_J, "menu": KEY_ESCAPE})
	_show_dmg = bool(StorySettings.get_value("damage_numbers"))
	_build_world()
	_spawn_hero()
	_spawn_enemies()
	hud = StoryHud.new()
	hud.mode = self
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	world.add_child(hud)
	hud.inv_pressed.connect(open_inventory)
	hud.quests_pressed.connect(open_quests)
	hud.menu_pressed.connect(open_menu)
	hud.build_buttons(hero, kit)
	hero.ui = hud.ui
	# контроллер подключили или отключили — показать или спрятать экранные кнопки
	Input.joy_connection_changed.connect(func(_id: int, _c: bool):
		if is_instance_valid(hud):
			hud.build_buttons(hero, kit)
			hero.ui = hud.ui)
	_update_quest_text()
	if int(data.get("playtime", 0.0)) < 1:
		hud.banner("Пробуждение")
		_after(1.4, func(): hud.toast("Рядом стоит сундук. Подойди и открой его."))

# ---------- Мир ----------
func _build_world() -> void:
	# рамка поля: трава сверху, под ней толща земли (камера показывает поле выше кнопок), стены по краям
	var bg := ColorRect.new()
	bg.color = Color(0.26, 0.44, 0.78)
	bg.position = Vector2(0, -3000)
	bg.size = Vector2(W, H + 3000)
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(bg)
	Maps.add_block(world, Rect2(0, G, W, 16), Maps.GRASS)
	Maps.add_block(world, Rect2(0, G + 16, W, 450), Jungle.DIRT)
	Maps.add_block(world, Rect2(0, -3000, 20, H + 3000))
	Maps.add_block(world, Rect2(W - 20, -3000, 20, H + 3000))
	var sky := PixelArt.make_sprite(PixelArt.valley_backdrop(W, -1500.0, G), PixelArt.SCALE)
	sky.position = Vector2(0, -1500)
	sky.z_index = -10
	world.add_child(sky)
	for x in [260.0, 1000.0, 1720.0, 2320.0, 3420.0, 3980.0]:
		Maps.add_tree(world, x, G)
	# холм с платформами посередине и ящики у лагеря разбойников
	Maps.add_platform(world, Rect2(1880, G - 130, 260, 20), true)
	Maps.add_platform(world, Rect2(2060, G - 250, 220, 20), true)
	Maps.add_crate(world, Vector2(2600, G - 31))
	Maps.add_crate(world, Vector2(2660, G - 31))
	Maps.add_crate(world, Vector2(2630, G - 92))
	Maps.add_column(world, Rect2(3240, G - 120, 40, 120))
	_tent(Vector2(2920, G))
	# предметы, с которыми можно взаимодействовать
	var opened: Array = data["world"].get("opened", [])
	_prop("campfire", "fire", Vector2(380, G), "")
	_prop("chest", "start_chest", Vector2(680, G), "")
	_prop("sign", "sign_road", Vector2(1180, G), "На восток — Старая тропа. Осторожно: в лощине видели разбойников!\nНа самом краю поля — заброшенный погреб.")
	_prop("door", "cellar", Vector2(3760, G), "")
	for pr in props:
		if pr.id in opened:
			pr.opened = true

func _prop(kind: String, id: String, pos: Vector2, text: String) -> StoryProp:
	var pr := StoryProp.new()
	pr.kind = kind
	pr.id = id
	pr.text = text
	pr.position = pos
	world.add_child(pr)
	props.append(pr)
	return pr

# Палатка разбойников (для вида)
func _tent(base: Vector2) -> void:
	var img := BotRig._img(40, 26)
	for y in 26:
		var hw := int(20.0 * y / 25.0)
		img.fill_rect(Rect2i(20 - hw, y, hw * 2, 1), Color(0.55, 0.42, 0.30) if (y / 3) % 2 == 0 else Color(0.50, 0.38, 0.27))
	img.fill_rect(Rect2i(17, 12, 6, 14), Color(0.12, 0.09, 0.07))
	img.fill_rect(Rect2i(19, 0, 2, 3), Color(0.35, 0.22, 0.12))
	BotRig._volume(img)
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(4, 4)
	s.centered = false
	s.offset = Vector2(-20, -26)
	s.position = base
	s.z_index = -3
	world.add_child(s)

func _spawn_hero() -> void:
	var p := Player.new()
	p.prefix = "p1"
	p.index = 0
	p.team = 0
	p.color = Color(0.6, 0.45, 0.3)
	p.outline = Config.NO_OUTLINE
	p.speed = 340.0
	p.abilities = ["", "", ""]
	p.ability_cds = [1.0, 1.0, 1.0]
	p.ult = ""
	p.clip_size = 1
	p.map_w = W
	p.map_top = -400.0
	var pos: Array = data["world"].get("pos", [])
	p.spawn = SPAWN
	p.position = Vector2(float(pos[0]), float(pos[1])) if pos.size() == 2 else SPAWN
	p.facing = 1
	p.rig_kind = "story"
	p.rig_spec = StoryLook.spec(data["look"], data["equipped"])
	kit = StoryKit.new()
	kit.p = p
	kit.mode = self
	kit.data = data
	p.kit = kit
	hero = p
	world.add_child(p)
	if p._ammo_fill:
		p._ammo_fill.visible = false
		if p._ammo_fill.has_meta("bg"):
			p._ammo_fill.get_meta("bg").visible = false
	kit.refresh()
	p.hp = p.max_hp if int(data.get("hp", -1)) < 0 else mini(int(data["hp"]), p.max_hp)
	kit.mana = kit.max_mana if float(data.get("mana", -1)) < 0.0 else minf(float(data["mana"]), kit.max_mana)
	p.heal(0)
	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_right = int(W)
	cam.limit_bottom = int(H + 230)
	cam.offset.y = Config.panel() / 2.0       # полоса кнопок снизу — герой чуть выше
	cam.limit_top = -1500
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.position = p.position + Vector2(0, -90)
	world.add_child(cam)
	cam.make_current()
	cam.reset_smoothing()

func _spawn_enemies() -> void:
	dummy = Bots.create("dummy", 1, Vector2(1420, G - 37), hero, W)
	dummy.respawn = false
	world.add_child(dummy)
	for spot in _bandit_spots:
		_spawn_bandit(spot)

func _spawn_bandit(spot: Vector2) -> void:
	var b := Bots.create("bandit", 1, spot, hero, W)
	b.position = spot
	b.aware = false
	b.aggro_radius = AGGRO
	b.facing = -1 if randf() < 0.5 else 1
	b.alert_cb = _on_bandit_alert
	b.died.connect(_on_bandit_died.bind(spot))
	world.add_child(b)
	_bandits[spot] = b

# Разбойник заметил героя: «!» над головой, и он зовёт тех, кто рядом
func _on_bandit_alert(b: Player) -> void:
	float_text(b.global_position + Vector2(0, -70), "!", Color(1.0, 0.35, 0.25))
	for spot in _bandits:
		var o: Player = _bandits[spot]
		if is_instance_valid(o) and o != b and o.is_alive() and not o.aware \
				and o.global_position.distance_to(b.global_position) < SHOUT:
			o.become_aware()

func _on_bandit_died(_i: int, spot: Vector2) -> void:
	var b: Player = _bandits.get(spot)
	gain_xp(25)
	_quest_event("bandits")
	if b and is_instance_valid(b):
		_after(1.0, b.queue_free)
	_bandits.erase(spot)
	_respawn_t[spot] = 40.0

# ---------- Каждый кадр ----------
func _process(delta: float) -> void:
	if hero == null:
		return
	data["playtime"] = float(data.get("playtime", 0.0)) + delta
	cam.position = hero.position + Vector2(0, -90)
	hud.refresh(hero, kit, data)
	for spot in _respawn_t.keys():
		_respawn_t[spot] -= delta
		if _respawn_t[spot] <= 0.0:
			_respawn_t.erase(spot)
			_spawn_bandit(spot)
	# чучело никогда не ломается: восстанавливается
	if dummy and dummy.hp < dummy.max_hp:
		_dummy_t += delta
		if _dummy_t > 1.5:
			_dummy_t = 0.0
			dummy.hp = dummy.max_hp
	# ближайший предмет для взаимодействия
	_near = null
	var best := INF
	if hero.is_alive() and not hud.is_dialog_open():
		for pr in props:
			var d: float = pr.global_position.distance_to(hero.global_position + Vector2(0, 37))
			if d < pr.radius and d < best and pr.prompt() != "":
				best = d
				_near = pr
	if _near:
		var sp := world.get_viewport().get_canvas_transform() * (_near.global_position + Vector2(0, -95))
		hud.show_prompt(sp, _near.prompt())
	else:
		hud.show_prompt(Vector2.ZERO, "")
	if hud.ui.has("interact"):
		TouchControls.set_state(hud.ui["interact"], 1.0 if _near else 0.0, false)
	if Input.is_action_just_pressed("p1_interact"):
		if hud.is_dialog_open():
			hud.close_dialog()
		elif _near:
			_interact(_near)
	if Input.is_action_just_pressed("p1_inv"):
		open_inventory()
	elif Input.is_action_just_pressed("p1_quests"):
		open_quests()
	elif Input.is_action_just_pressed("p1_menu"):
		open_menu()

# ---------- Взаимодействие ----------
func _interact(pr: StoryProp) -> void:
	match pr.kind:
		"chest":
			chest_items(pr.id)                 # содержимое — до отметки «открыт»
			if not pr.opened:
				pr.open_lid()
			_mark_opened(pr.id)
			_quest_event("chest")
			var ch := StoryChest.new()
			ch.mode = self
			ch.chest_id = pr.id
			_open_overlay(ch)
		"sign":
			hud.show_dialog("Табличка", pr.text)
		"campfire":
			hero.heal(hero.max_hp)
			kit.mana = kit.max_mana
			save_game()
			hud.toast("Ты отдохнул у костра. Игра сохранена.", Color(0.6, 1.0, 0.6))
		"door":
			if pr.opened:
				hud.show_dialog("Погреб", "Внизу темно и пахнет сыростью. Ступени уходят глубоко под землю...\n(Продолжение следует)")
			elif count("old_key") > 0:
				pr.open_door()
				_mark_opened(pr.id)
				hud.show_dialog("Погреб", "Старый ключ со скрипом поворачивается в замке. Дверь открыта!")
				_quest_event("cellar")
			else:
				hud.show_dialog("Погреб", "Дверь заперта. На замке выбито: «Погреб». Нужен ключ.")

# Что лежит в сундуке (при первом открытии — начальная добыча)
func chest_items(id: String) -> Array:
	var w: Dictionary = data["world"]
	if not w.has("chests"):
		w["chests"] = {}
	if not w["chests"].has(id):
		var arr := []
		# в старых сохранениях сундук уже высыпал всё в рюкзак — тогда он пустой
		if id == "start_chest" and not id in w.get("opened", []):
			for it in CHEST_ITEMS:
				arr.append({"id": String(it[0]), "n": int(it[1])})
		w["chests"][id] = arr
	return w["chests"][id]

func _mark_opened(id: String) -> void:
	var op: Array = data["world"].get("opened", [])
	if not id in op:
		op.append(id)
	data["world"]["opened"] = op

# ---------- Рюкзак ----------
func count(id: String) -> int:
	for it in data["inventory"]:
		if it["id"] == id:
			return int(it["n"])
	return 0

func add_item(id: String, n := 1) -> void:
	if Items.is_stack(id) or Items.get_def(id).get("kind", "") in ["potion", "ammo"]:
		for it in data["inventory"]:
			if it["id"] == id:
				it["n"] = int(it["n"]) + n
				return
		data["inventory"].append({"id": id, "n": n})
		return
	for i in n:
		data["inventory"].append({"id": id, "n": 1})

func remove_item(id: String, n := 1) -> void:
	var inv: Array = data["inventory"]
	for i in inv.size():
		if inv[i]["id"] == id:
			inv[i]["n"] = int(inv[i]["n"]) - n
			if int(inv[i]["n"]) <= 0:
				inv.remove_at(i)
			return

# Куда надевается вещь: ячейка брони или «melee» / «ranged»
static func equip_slot(id: String) -> String:
	var d := Items.get_def(id)
	match String(d.get("kind", "")):
		"armor":
			return String(d["slot"])
		"melee":
			return "melee"
		"ranged":
			return "ranged"
	return ""

func is_equipped(id: String) -> bool:
	return id in data["equipped"].values()

func equip(id: String) -> void:
	var s := equip_slot(id)
	if s == "":
		return
	data["equipped"][s] = id
	_after_gear_change()
	if not id in START_ITEMS:
		_quest_event("equip")

func unequip(slot_name: String) -> void:
	data["equipped"].erase(slot_name)
	_after_gear_change()

func _after_gear_change() -> void:
	hero.rig_spec = StoryLook.spec(data["look"], data["equipped"])
	hero.set_rig("story")
	kit.refresh()
	hud.build_buttons(hero, kit)
	hero.ui = hud.ui

# Выпить зелье / прочитать свиток
func use_item(id: String) -> String:
	var d := Items.get_def(id)
	match String(d.get("kind", "")):
		"potion":
			if d.has("heal"):
				hero.heal(int(d["heal"]))
			if d.has("mana"):
				kit.mana = minf(kit.max_mana, kit.mana + float(d["mana"]))
			remove_item(id, 1)
			return "Выпито: " + Items.item_name(id)
		"scroll":
			var ab: String = d["teach"]
			if ab in data["learned"]:
				return "Эта способность уже изучена"
			data["learned"].append(ab)
			remove_item(id, 1)
			# сразу ставим в свободную ячейку
			var def := StoryAbilities.get_def(ab)
			if def.get("ult", false):
				if String(data["ult"]) == "":
					data["ult"] = ab
			else:
				var slots: Array = data["slots"]
				for i in 3:
					if String(slots[i]) == "":
						slots[i] = ab
						break
			kit.refresh()
			hud.build_buttons(hero, kit)
			hero.ui = hud.ui
			_quest_event("learn")
			return "Изучено: " + String(def["name"])
	return ""

# Поставить способность в ячейку (0..2 — обычные, 3 — ульта). Без повторов.
func assign_ability(ab: String, cell: int) -> void:
	var def := StoryAbilities.get_def(ab)
	var slots: Array = data["slots"]
	if cell == 3:
		if def.get("ult", false):
			data["ult"] = ab
	elif not def.get("ult", false):
		for i in 3:
			if String(slots[i]) == ab:
				slots[i] = ""
		slots[cell] = ab
	kit.refresh()
	hud.build_buttons(hero, kit)
	hero.ui = hud.ui

func clear_ability(cell: int) -> void:
	if cell == 3:
		data["ult"] = ""
	else:
		data["slots"][cell] = ""
	kit.refresh()
	hud.build_buttons(hero, kit)
	hero.ui = hud.ui

# ---------- Опыт ----------
func on_dealt(victim: Node, amount: int, skill: String, crit: bool) -> void:
	if victim is Player and _show_dmg:
		float_text(victim.global_position + Vector2(randf_range(-12, 12), -victim.body_size.y / 2 - 20),
				str(amount) + ("!" if crit else ""), Color(1.0, 0.85, 0.3) if crit else Color(1, 1, 1))
	skill_xp(skill, 3)
	if victim == dummy:
		_quest_event("dummy")

func skill_xp(skill: String, amount: int) -> void:
	if StoryStats.add_skill_xp(data, skill, amount):
		var lvl := StoryStats.skill_lvl(data, skill)
		hud.toast("Навык «%s» вырос до %d" % [StoryStats.SKILL_NAME.get(skill, skill), lvl], Color(0.6, 0.9, 1.0))
		kit.refresh()

func gain_xp(amount: int) -> void:
	float_text(hero.global_position + Vector2(0, -80), "+%d опыта" % amount, Color(1.0, 0.8, 0.3))
	var ups := StoryStats.add_xp(data, amount)
	if ups > 0:
		kit.refresh()
		hero.heal(hero.max_hp)
		kit.mana = kit.max_mana
		hud.banner("Уровень %d!" % int(data["level"]))
		Fx.ring(world, hero.global_position, 110.0, Color(1.0, 0.85, 0.3, 0.9), 0.6, 8.0)
		Fx.sparks(world, hero.global_position, Color(1.0, 0.9, 0.5), 20, 260.0, 4.0, true)

func on_hero_died() -> void:
	hud.banner("Ты пал...", Color(1.0, 0.4, 0.35))
	hero.spawn = SPAWN

func float_text(pos: Vector2, t: String, c: Color) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", c)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.position = pos - Vector2(40, 0)
	l.size = Vector2(80, 30)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 20
	world.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", pos.y - 50.0, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.tween_callback(l.queue_free)

func toast(t: String) -> void:
	hud.toast(t)

# ---------- Задания ----------
# Основное задание идёт по шагам; шаги проверяются по состоянию мира,
# поэтому порядок действий игрока не важен.
func _quest_event(ev: String) -> void:
	var before: Dictionary = (data["quests"] as Dictionary).duplicate(true)
	match ev:
		"dummy":
			_reward("warmup", StoryQuests.advance(data, "warmup", 0))
		"bandits":
			_reward("bandits", StoryQuests.advance(data, "bandits", 0))
	_check_main()
	if before != data["quests"]:
		_update_quest_text()

func _check_main() -> void:
	var conds := [
		"start_chest" in data["world"].get("opened", []),
		_has_gear(),
		not (data["learned"] as Array).is_empty(),
		"cellar" in data["world"].get("opened", []),
	]
	for i in 8:
		var st: Dictionary = data["quests"]["awakening"]
		if st.get("done", false) or not conds[int(st["step"])]:
			return
		var r := StoryQuests.advance(data, "awakening", int(st["step"]))
		_reward("awakening", r)
		if not r.get("done", false):
			hud.toast("Задание обновлено: " + StoryQuests.step_text("awakening", data["quests"]["awakening"]), Color(1.0, 0.9, 0.55))

func _has_gear() -> bool:
	for s in data["equipped"]:
		if not String(data["equipped"][s]) in START_ITEMS:
			return true
	return false

func _reward(qid: String, r: Dictionary) -> void:
	if not r.get("done", false):
		return
	hud.banner("Задание выполнено: " + String(StoryQuests.DB[qid]["name"]), Color(0.6, 1.0, 0.55))
	if r.has("xp"):
		_after(0.6, gain_xp.bind(int(r["xp"])))
	var items: Dictionary = r.get("items", {})
	for id in items:
		add_item(String(id), int(items[id]))

func _update_quest_text() -> void:
	var lines := []
	for qid in StoryQuests.DB:
		var st: Dictionary = data["quests"][qid]
		if st.get("done", false):
			continue
		var q: Dictionary = StoryQuests.DB[qid]
		lines.append(("◆ " if q["main"] else "◇ ") + String(q["name"]) + ": " + StoryQuests.step_text(qid, st))
		if lines.size() >= 3:
			break
	hud.set_quest_text("\n".join(lines))

# ---------- Окна поверх игры (игра на паузе) ----------
func _open_overlay(o: CanvasLayer) -> void:
	if _overlay and is_instance_valid(_overlay) and not _overlay.is_queued_for_deletion():
		return
	hud.close_dialog(false)
	_overlay = o
	o.process_mode = Node.PROCESS_MODE_ALWAYS
	world.get_tree().paused = true
	world.add_child(o)
	o.tree_exited.connect(func():
		if _overlay != o:
			return                     # уже открыто другое окно (из паузы — в задания)
		_overlay = null
		if is_instance_valid(world) and world.is_inside_tree():
			# снимаем паузу после удаления окна (во время удаления менять паузу нельзя)
			var tree := world.get_tree()
			tree.process_frame.connect(func():
				if _overlay == null or not is_instance_valid(_overlay):
					tree.paused = false, CONNECT_ONE_SHOT))

func open_inventory() -> void:
	var inv := StoryInventory.new()
	inv.mode = self
	_open_overlay(inv)

func open_quests() -> void:
	var q := StoryQuestLog.new()
	q.mode = self
	_open_overlay(q)

func open_menu() -> void:
	var m := StoryPause.new()
	m.mode = self
	_open_overlay(m)

func save_game() -> void:
	data["hp"] = hero.hp if hero.is_alive() else -1
	data["mana"] = kit.mana
	data["world"]["pos"] = [hero.position.x, hero.position.y] if hero.is_alive() and hero.is_on_floor() else []
	StorySave.save_slot(slot, data)

func quit_to_menu() -> void:
	world.get_tree().paused = false
	exit_to_menu.emit()

func _after(time: float, fn: Callable) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = time
	add_child(t)
	t.timeout.connect(fn)
	t.timeout.connect(t.queue_free)
	t.start()
