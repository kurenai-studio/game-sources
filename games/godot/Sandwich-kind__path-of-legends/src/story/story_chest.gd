class_name StoryChest
extends CanvasLayer
# ---------- Сундук: обмен вещами (игра на паузе) ----------
# Слева — рюкзак героя, справа — сундук. Нажми на вещь (или A на геймпаде) —
# она перекладывается на другую сторону. «Взять всё» (Y) — забрать всё из сундука.
# Надетое положить в сундук нельзя — сначала сними.

var mode
var chest_id := ""
var title_text := "Сундук"
var _vs := Vector2.ZERO
var _content: Control
var _info: Label
var _focus := ""              # "h_3" / "c_0" — какую вещь выбрать геймпадом после перестройки

const CELL := 62.0
const TRIM := Color(0.80, 0.60, 0.30)

func _ready() -> void:
	layer = 20
	_vs = Config.screen(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = _vs
	add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(14, 12)
	panel.size = _vs - Vector2(28, 24)
	panel.add_theme_stylebox_override("panel", StoryHud.box(Color(0.10, 0.08, 0.07, 0.97), TRIM, 14, 3))
	add_child(panel)
	var t := _lbl(self, title_text, Vector2(34, 18), 28, Color(1.0, 0.85, 0.45))
	t.size = Vector2(300, 40)
	var close := Button.new()
	close.text = "Закрыть"
	close.size = Vector2(150, 46)
	close.position = Vector2(_vs.x - 180, 20)
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(queue_free)
	add_child(close)
	PadGlyph.attach(close, "B", -1)
	var all := Button.new()
	all.text = "Взять всё"
	all.size = Vector2(190, 46)
	all.position = Vector2(_vs.x - 400, 20)
	all.add_theme_font_size_override("font_size", 20)
	all.pressed.connect(_take_all)
	add_child(all)
	PadGlyph.attach(all, "Y", -1)
	_content = Control.new()
	_content.size = _vs
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_info = _lbl(self, "", Vector2(40, _vs.y - 74), 16, Color(0.95, 0.88, 0.72))
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.update_minimum_size()
	_info.size = Vector2(_vs.x - 80, 44)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		get_viewport().set_input_as_handled()
		_take_all()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_inv") or event.is_action_pressed("p1_menu"):
		get_viewport().set_input_as_handled()
		queue_free()

func _lbl(parent: Node, t: String, pos: Vector2, size: int, c := Color(1, 0.95, 0.85)) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _chest() -> Array:
	return mode.chest_items(chest_id)

func _refresh() -> void:
	for c in _content.get_children():
		c.queue_free()
	var half := (_vs.x - 90.0) / 2.0
	_side(Rect2(36, 76, half, _vs.y - 170), "Рюкзак", mode.data["inventory"], "h")
	_side(Rect2(54 + half, 76, half, _vs.y - 170), "Сундук", _chest(), "c")
	_restore.call_deferred()

func _side(r: Rect2, title: String, items: Array, side: String) -> void:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", StoryHud.box(Color(0.16, 0.12, 0.09, 0.9), TRIM.darkened(0.3), 10, 2))
	_content.add_child(p)
	_lbl(_content, title + ("  (пусто)" if items.is_empty() else ""), r.position + Vector2(14, 8), 19, Color(1.0, 0.85, 0.5))
	var cols := maxi(1, int((r.size.x - 20) / (CELL + 6)))
	for i in items.size():
		var id: String = items[i]["id"]
		var pos := r.position + Vector2(12 + (i % cols) * (CELL + 6), 42 + (i / cols) * (CELL + 6))
		_cell(pos, id, int(items[i]["n"]), side, i)

func _cell(pos: Vector2, id: String, n: int, side: String, i: int) -> void:
	var d := Items.get_def(id)
	var rc: Color = Items.RARITY.get(d.get("rarity", "common"), Color.WHITE)
	var b := Button.new()
	b.position = pos
	b.size = Vector2(CELL, CELL)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, StoryHud.box(Color(0.22, 0.17, 0.12), rc, 8, 2))
	var key := "%s_%d" % [side, i]
	b.set_meta("fk", key)
	b.pressed.connect(_move.bind(side, i))
	b.focus_entered.connect(_show_info.bind(id, n))
	b.mouse_entered.connect(_show_info.bind(id, n))
	_content.add_child(b)
	var ic := AbilityIcons.make(id, CELL * 0.72)
	if ic:
		ic.position = Vector2(CELL / 2, CELL / 2)
		b.add_child(ic)
	if n > 1:
		var l := _lbl(b, str(n), Vector2(4, CELL - 22), 15)
		l.size = Vector2(CELL - 8, 20)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if side == "h" and mode.is_equipped(id):
		var e := _lbl(b, "Надето", Vector2(2, 1), 11, Color(0.6, 1.0, 0.55))
		e.size = Vector2(CELL - 4, 14)

func _show_info(id: String, n: int) -> void:
	var d := Items.get_def(id)
	var st: Dictionary = d.get("stats", {})
	var parts := []
	if d.has("dmg"):
		parts.append("урон %d" % int(d["dmg"]))
	for k in st:
		var num := ("+%d%% " % int(round(float(st[k]) * 100))) if k == "crit" else ("+%d " % int(st[k]))
		parts.append(num + String(Items.STAT_NAME.get(k, k)).to_lower())
	_info.text = Items.item_name(id) + (" ×%d" % n if n > 1 else "") + ("  ·  " + ", ".join(parts) if not parts.is_empty() else "") \
			+ "\n" + String(d.get("desc", ""))
	_info.add_theme_color_override("font_color", Items.RARITY.get(d.get("rarity", "common"), Color.WHITE).lerp(Color(0.95, 0.88, 0.72), 0.4))

func _move(side: String, i: int) -> void:
	var from: Array = mode.data["inventory"] if side == "h" else _chest()
	if i >= from.size():
		return
	var it: Dictionary = from[i]
	var id: String = it["id"]
	if side == "h" and mode.is_equipped(id):
		mode.hud.toast("Сначала сними эту вещь")
		return
	from.remove_at(i)
	if side == "h":
		_put(_chest(), id, int(it["n"]))
	else:
		mode.add_item(id, int(it["n"]))
	# фокус остаётся на той же стороне (на соседней вещи)
	var left := from.size()
	_focus = "%s_%d" % [side, mini(i, left - 1)] if left > 0 else ("c_0" if side == "h" else "h_0")
	_refresh()

func _put(arr: Array, id: String, n: int) -> void:
	if Items.is_stack(id) or Items.get_def(id).get("kind", "") in ["potion", "ammo"]:
		for it in arr:
			if it["id"] == id:
				it["n"] = int(it["n"]) + n
				return
	arr.append({"id": id, "n": n})

func _take_all() -> void:
	var c := _chest()
	for it in c:
		mode.add_item(String(it["id"]), int(it["n"]))
	c.clear()
	_focus = "h_0"
	_refresh()

func _restore() -> void:
	if not (Pad.connected() or PadGlyph.force):
		return
	var fallback: Button = null
	for n in _content.get_children():
		if n is Button and not n.is_queued_for_deletion():
			if n.get_meta("fk", "") == _focus:
				n.grab_focus()
				return
			if fallback == null or (String(n.get_meta("fk", "")).begins_with("c_") and not String(fallback.get_meta("fk", "")).begins_with("c_")):
				fallback = n
	if fallback:
		fallback.grab_focus()
