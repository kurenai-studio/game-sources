class_name Pad
extends Node
# ---------- Геймпад (Bluetooth-контроллер для телефона) ----------
# Один игрок (Арена в одиночку, История): кнопки можно переназначить —
# у Арены и у Истории свои раскладки (сохраняются в user://settings.json).
# Левый стик всегда ходит (влево/вправо, вниз — спрыгнуть), в Арене и Дуэли вверх — прыжок.
# Двое игроков — раскладка постоянная: у каждого свой контроллер со стандартной
# раскладкой Арены, а если контроллер один — он делится пополам (SPLIT_P1 / SPLIT_P2).
# В меню: крестовина/стик — выбор, A — нажать, B — назад (не переназначаются).
# Узел Pad живёт в main и следит за подключением и за фокусом кнопок меню.
#
# Кнопка записывается строкой: "b0" — кнопка №0 (A), "a4+" — ось 4 (курок LT) вперёд.

const ACTIONS := ["left", "right", "jump", "down", "shoot", "reload", "ranged", "interact",
		"a1", "a2", "a3", "ult", "inv", "menu", "quests"]
# функции, которые можно переназначить: [действие, название]
const FUNCS := {
	"fight": [["left", "Влево"], ["right", "Вправо"], ["jump", "Прыжок"], ["down", "Спрыгнуть вниз"],
			["shoot", "Стрельба / удар"], ["reload", "Перезарядка"], ["a1", "Способность 1"], ["a2", "Способность 2"],
			["a3", "Способность 3"], ["ult", "Ульта"]],
	"story": [["left", "Влево"], ["right", "Вправо"], ["jump", "Прыжок"], ["down", "Спрыгнуть вниз"],
			["shoot", "Удар ближнего боя"], ["ranged", "Дальний бой"], ["interact", "Взаимодействие"],
			["a1", "Способность 1"], ["a2", "Способность 2"], ["a3", "Способность 3"], ["ult", "Ульта"],
			["inv", "Рюкзак"], ["menu", "Меню (пауза)"], ["quests", "Задания"]],
}
const DEFAULTS := {
	"fight": {"left": "b13", "right": "b14", "jump": "b0", "down": "b12", "shoot": "b2", "reload": "b1",
			"a1": "b9", "a2": "b10", "a3": "a4+", "ult": "a5+"},
	"story": {"left": "b13", "right": "b14", "jump": "b0", "down": "b12", "shoot": "b2", "ranged": "b1",
			"interact": "b3", "a1": "b9", "a2": "b10", "a3": "a4+", "ult": "a5+", "inv": "b4", "menu": "b6", "quests": "b8"},
}
const FIXED := {"left": ["a0-"], "right": ["a0+"], "down": ["a1+"]}      # левый стик — всегда ходьба
const FIXED_FIGHT := {"jump": ["a1-"]}     # в Арене и Дуэли левый стик вверх — ещё и прыжок
const SPLIT_P1 := {"left": ["a0-"], "right": ["a0+"], "jump": ["a1-", "b7"], "down": ["a1+"], "shoot": ["a4+"],
		"reload": ["b9"], "a1": ["b13"], "a2": ["b11"], "a3": ["b14"], "ult": ["b12"]}
const SPLIT_P2 := {"left": ["a2-"], "right": ["a2+"], "jump": ["a3-", "b8"], "down": ["a3+"], "shoot": ["a5+"],
		"reload": ["b10"], "a1": ["b2"], "a2": ["b3"], "a3": ["b1"], "ult": ["b0"]}
const BTN_NAME := {0: "A", 1: "B", 2: "X", 3: "Y", 4: "SEL", 6: "STA", 7: "Нажать левый стик", 8: "Нажать правый стик",
		9: "LB", 10: "RB", 11: "Крестовина ↑", 12: "Крестовина ↓", 13: "Крестовина ←", 14: "Крестовина →"}

static var using_pad := true  # последнее, чем играли: геймпад (true) или касание экрана (false)
static var layout := ""       # что сейчас включено: fight, story, two (двое, по контроллеру), shared (один на двоих)
var main: Node

static func connected() -> bool:
	return not Input.get_connected_joypads().is_empty()

static func names() -> Array:
	var r := []
	for id in Input.get_connected_joypads():
		r.append(Input.get_joy_name(id))
	return r

# ---------- Раскладки одного игрока ----------
static func binds(profile: String) -> Dictionary:
	var b: Dictionary = (DEFAULTS[profile] as Dictionary).duplicate()
	var saved = StorySettings.get_value("pad_" + profile)
	if saved is Dictionary:
		for k in saved:
			if b.has(k):
				b[k] = String(saved[k])
	return b

# Назначить кнопку функции. Если кнопка занята другой функцией — они меняются.
# Возвращает функцию, с которой поменялись (или "").
static func set_bind(profile: String, fn: String, id: String) -> String:
	var b := binds(profile)
	var other := ""
	for k in b:
		if k != fn and b[k] == id:
			other = k
	if other != "":
		b[other] = b[fn]
	b[fn] = id
	StorySettings.set_value("pad_" + profile, b)
	if layout != "":
		apply_layout(layout)
	return other

static func reset(profile: String) -> void:
	StorySettings.set_value("pad_" + profile, {})
	if layout != "":
		apply_layout(layout)

static func func_name(profile: String, fn: String) -> String:
	for f in FUNCS[profile]:
		if f[0] == fn:
			return f[1]
	return fn

static func id_name(id: String) -> String:
	if id.begins_with("b"):
		return BTN_NAME.get(int(id.substr(1)), "Кнопка " + id.substr(1))
	var ax := int(id.substr(1, id.length() - 2))
	var pos := id.ends_with("+")
	match ax:
		4:
			return "LT"
		5:
			return "RT"
		0:
			return "Левый стик →" if pos else "Левый стик ←"
		1:
			return "Левый стик ↓" if pos else "Левый стик ↑"
		2:
			return "Правый стик →" if pos else "Правый стик ←"
		3:
			return "Правый стик ↓" if pos else "Правый стик ↑"
	return "Ось " + str(ax)

# Строка кнопки из события (для переназначения); "" — не подходит
static func id_of(event: InputEvent) -> String:
	if event is InputEventJoypadButton and event.pressed:
		return "b%d" % event.button_index
	if event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		if event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
			return ""                       # левый стик занят ходьбой
		if event.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT] and event.axis_value < 0.0:
			return ""
		return "a%d%s" % [event.axis, "+" if event.axis_value > 0.0 else "-"]
	return ""

static func _event(id: String, dev: int) -> InputEvent:
	var ev: InputEvent
	if id.begins_with("b"):
		var bt := InputEventJoypadButton.new()
		bt.button_index = int(id.substr(1)) as JoyButton
		ev = bt
	else:
		var mo := InputEventJoypadMotion.new()
		mo.axis = int(id.substr(1, id.length() - 2)) as JoyAxis
		mo.axis_value = 1.0 if id.ends_with("+") else -1.0
		ev = mo
	ev.device = dev
	return ev

# Действия игроков и кнопки меню (вызывается один раз при запуске)
static func add_actions() -> void:
	for prefix in ["p1", "p2"]:
		for a in ACTIONS:
			var action: String = prefix + "_" + a
			if not InputMap.has_action(action):
				InputMap.add_action(action)
			InputMap.action_set_deadzone(action, 0.5)   # стик и курки — больше чем наполовину
		# прыжок стиком — только если стик заметно поднят вверх (чтобы не прыгать, просто идя наискосок)
		InputMap.action_set_deadzone(prefix + "_jump", 0.65)
	# в меню выбор кнопок — и крестовиной, и левым стиком
	for ui in [["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0],
			["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var mo2 := InputEventJoypadMotion.new()
		mo2.axis = ui[1]
		mo2.axis_value = ui[2]
		mo2.device = -1
		InputMap.action_add_event(ui[0], mo2)
	for ui2 in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["ui_up", JOY_BUTTON_DPAD_UP],
			["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT]]:
		var has := false
		for e in InputMap.action_get_events(ui2[0]):
			if e is InputEventJoypadButton and e.button_index == ui2[1]:
				has = true
		if not has:
			var bt2 := InputEventJoypadButton.new()
			bt2.button_index = ui2[1]
			bt2.device = -1
			InputMap.action_add_event(ui2[0], bt2)
	apply_layout("fight")

# Перестроить кнопки контроллера у действий игроков
static func apply_layout(kind: String) -> void:
	layout = kind
	var ids := Input.get_connected_joypads()
	for prefix in ["p1", "p2"]:
		var idx := 0 if prefix == "p1" or kind == "shared" else 1
		var dev: int = ids[idx] if ids.size() > idx else idx
		var lay := {}                         # действие -> список кнопок
		if kind == "shared":
			lay = SPLIT_P1 if prefix == "p1" else SPLIT_P2
		else:
			var prof := kind if prefix == "p1" and kind in ["fight", "story"] else "fight"
			var b: Dictionary = binds(prof) if prefix == "p1" and kind in ["fight", "story"] else DEFAULTS["fight"]
			for a in b:
				lay[a] = [b[a]] + FIXED.get(a, []) + (FIXED_FIGHT.get(a, []) if prof == "fight" else [])
		for a in ACTIONS:
			var action: String = prefix + "_" + a
			for ev in InputMap.action_get_events(action):
				if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
					InputMap.action_erase_event(action, ev)
			for id in lay.get(a, []):
				InputMap.action_add_event(action, _event(String(id), dev))

# Какая раскладка нужна сейчас
func _want_layout() -> String:
	if main == null:
		return "fight"
	if main.mode == "duel" or (main.mode == "arena" and main.arena_coop):
		return "shared" if Input.get_connected_joypads().size() == 1 else "two"
	if main.mode == "story":
		return "story"
	return "fight"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy)

func _on_joy(_id: int, _connected: bool) -> void:
	apply_layout(_want_layout())

# С подключённым геймпадом в меню всегда выбрана какая-то кнопка
func _process(_d: float) -> void:
	# экранные кнопки и значки перезарядки для геймпада — показываем то, чем сейчас играют
	var t := Config.touch()
	for n in get_tree().get_nodes_in_group("touch_ui"):
		n.visible = t
	for n in get_tree().get_nodes_in_group("pad_ui"):
		n.visible = not t
	# стик держат наклонённым — выбор шагает дальше
	if _axis_dir != Vector2.ZERO and not _playing():
		_repeat_t -= _d
		if _repeat_t <= 0.0:
			_repeat_t = 0.2
			var ow := get_viewport().gui_get_focus_owner()
			if ow and ow.is_visible_in_tree() and not (ow is Range and _axis_dir.y == 0.0):
				navigate(main, ow, _axis_dir)
	var want := _want_layout()
	if want != layout:
		apply_layout(want)
	if not connected() or _playing() or main == null:
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner == null or not owner.is_visible_in_tree():
		focus_first(main)

# Игра идёт (не меню и не пауза) — фокус кнопкам не нужен: A — это прыжок
# Игра идёт (не меню, не пауза, не экран итогов) — фокус кнопкам не нужен: A — это прыжок
func _playing() -> bool:
	return main != null and main.mode in ["duel", "arena", "story"] and not get_tree().paused \
			and get_tree().get_nodes_in_group("pad_modal").is_empty()

var _axis_dir := Vector2.ZERO      # куда сейчас наклонён левый стик (для меню)
var _repeat_t := 0.0

func _input(event: InputEvent) -> void:
	# чем сейчас играют: касание — показать экранные кнопки, геймпад — спрятать
	if event is InputEventScreenTouch and event.pressed:
		using_pad = false
	elif (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		using_pad = true
	var key_dir := Vector2.ZERO
	if event is InputEventKey and event.pressed:
		key_dir = {KEY_UP: Vector2.UP, KEY_DOWN: Vector2.DOWN, KEY_LEFT: Vector2.LEFT, KEY_RIGHT: Vector2.RIGHT}.get(event.keycode, Vector2.ZERO)
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion or key_dir != Vector2.ZERO):
		return
	if _playing():
		return
	var vp := get_viewport()
	# ---- выбор кнопки крестовиной или стиком ----
	var dir := key_dir
	if event is InputEventKey:
		pass
	elif event is InputEventJoypadMotion:
		if event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
			var v := Vector2(Input.get_joy_axis(event.device, JOY_AXIS_LEFT_X), Input.get_joy_axis(event.device, JOY_AXIS_LEFT_Y))
			var nd := Vector2.ZERO
			if v.length() > 0.6:
				nd = Vector2(signf(v.x), 0) if absf(v.x) > absf(v.y) else Vector2(0, signf(v.y))
			if nd != _axis_dir:
				_axis_dir = nd
				_repeat_t = 0.45
				dir = nd
			vp.set_input_as_handled()
	elif event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				dir = Vector2.UP
			JOY_BUTTON_DPAD_DOWN:
				dir = Vector2.DOWN
			JOY_BUTTON_DPAD_LEFT:
				dir = Vector2.LEFT
			JOY_BUTTON_DPAD_RIGHT:
				dir = Vector2.RIGHT
	if dir != Vector2.ZERO:
		var owner := vp.gui_get_focus_owner()
		# ползунок громкости и т. п. сам меняется влево-вправо
		if owner is Range and dir.y == 0.0 and owner.is_visible_in_tree():
			return
		vp.set_input_as_handled()
		if owner == null or not owner.is_visible_in_tree() or owner.is_queued_for_deletion():
			focus_first(main)
		else:
			navigate(main, owner, dir)
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		var ow := vp.gui_get_focus_owner()
		if ow == null or not ow.is_visible_in_tree():
			if focus_first(main):
				vp.set_input_as_handled()
			return
	# B — «Назад» на экранах меню (окошко поверх экрана закрывается первым)
	if event.is_action_pressed("ui_cancel") and not get_tree().paused and main and main.world:
		for c in main.world.get_children():
			if c.has_signal("back_pressed") and c is CanvasLayer:
				vp.set_input_as_handled()
				if c.has_method("handle_back") and c.handle_back():
					return
				c.emit_signal("back_pressed")
				return

# Все кнопки верхнего слоя, которые можно выбрать
static func _candidates(root: Node) -> Array:
	var best_layer := -100000
	var res := []
	# открыто окошко поверх экрана (карточка товара и т. п.) — выбираем только в нём
	if root and root.is_inside_tree():
		var scopes := root.get_tree().get_nodes_in_group("pad_scope").filter(
				func(n): return is_instance_valid(n) and not n.is_queued_for_deletion() and n.is_visible_in_tree())
		if not scopes.is_empty():
			root = scopes[scopes.size() - 1]
	var stack := [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.is_queued_for_deletion():
			continue                       # окно закрывается — его кнопки не выбираем
		for c in n.get_children():
			stack.append(c)
		if (n is BaseButton or n is Range or n is LineEdit) and n.is_visible_in_tree() \
				and n.focus_mode != Control.FOCUS_NONE and not (n is BaseButton and n.disabled):
			var lay := _layer_of(n)
			if lay > best_layer:
				best_layer = lay
				res = []
			if lay == best_layer:
				res.append(n)
	return res

# Поставить фокус на кнопку по умолчанию (meta "pad_default") или на первую
# сверху-слева. Если открыто окно поверх (пауза, рюкзак) — ищем в нём.
static func focus_first(root: Node) -> bool:
	if root == null:
		return false
	var best: Control = null
	for b in _candidates(root):
		if b.has_meta("pad_default"):
			best = b
			break
		if b is BaseButton and (best == null or _before(b, best)):
			best = b
	if best:
		best.grab_focus()
		_show(best)
		return true
	return false

# Перейти к ближайшей кнопке в нужную сторону (по всему экрану, а не только
# внутри одного блока — встроенный переход Godot туда не ходит).
# Сначала ищем кнопки, которые стоят прямо по ходу (перекрываются с текущей
# поперёк направления: для «влево» — та же строка), и берём ближайшую по краям.
# Только если таких нет — смотрим наискосок. Так из «Арены» влево — «Дуэль»,
# а не широкая «История» над ними.
static func navigate(root: Node, from: Control, dir: Vector2) -> bool:
	var fr := from.get_global_rect()
	var fc := fr.get_center()
	var horiz := dir.x != 0.0
	var best: Control = null
	var best_score := INF
	for c in _candidates(root):
		if c == from:
			continue
		var r: Rect2 = c.get_global_rect()
		# зазор от края текущей кнопки до ближнего края кандидата
		var gap := 0.0
		if dir.x > 0.0:
			gap = r.position.x - fr.end.x
		elif dir.x < 0.0:
			gap = fr.position.x - r.end.x
		elif dir.y > 0.0:
			gap = r.position.y - fr.end.y
		else:
			gap = fr.position.y - r.end.y
		if gap < -10.0:
			continue                            # не впереди (или почти целиком перекрывает)
		if (r.get_center() - fc).dot(dir) <= 0.0:
			continue
		# перекрытие поперёк направления
		var overlap := 0.0
		if horiz:
			overlap = minf(fr.end.y, r.end.y) - maxf(fr.position.y, r.position.y)
		else:
			overlap = minf(fr.end.x, r.end.x) - maxf(fr.position.x, r.position.x)
		var side := absf((r.get_center() - fc).dot(Vector2(-dir.y, dir.x)))   # смещение центров вбок
		var score := maxf(gap, 0.0) + side * 0.25
		if overlap <= 0.0:
			# слишком вбок — это уже не «туда». По строке (влево-вправо) строже,
			# по столбцу (вверх-вниз) мягче: столбцы на экранах часто не ровные
			var limit := maxf(gap, 0.0) + 20.0 if horiz else maxf(gap, 0.0) * 1.3 + 60.0
			if -overlap > limit:
				continue
			score += 100000.0 + (-overlap) * 2.0 + side * 0.3     # наискосок — только если по ходу никого
		score += (r.position.x + r.position.y) * 0.0001           # при равенстве — левая/верхняя
		if score < best_score:
			best_score = score
			best = c
	if best:
		best.grab_focus()
		_show(best)
		return true
	return false

# Кнопка в прокручиваемом свитке — прокрутить, чтобы её было видно
static func _show(c: Control) -> void:
	var p := c.get_parent()
	while p:
		if p is ScrollContainer:
			(p as ScrollContainer).ensure_control_visible(c)       # список прокручивается к кнопке
			return
		if p is ScrollPaper:
			var sp := p as ScrollPaper
			var top := c.global_position.y - sp.content.global_position.y
			var vis := sp.paper_rect.size.y - 60.0
			if top < sp._scroll + 20.0 or top + c.size.y > sp._scroll + vis:
				sp.scroll_to(top - vis * 0.4)
			return
		p = p.get_parent()

static func _layer_of(n: Node) -> int:
	var p := n.get_parent()
	while p:
		if p is CanvasLayer:
			return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0

static func _before(a: Control, b: Control) -> bool:
	var pa := a.global_position
	var pb := b.global_position
	if absf(pa.y - pb.y) > 8.0:
		return pa.y < pb.y
	return pa.x < pb.x
