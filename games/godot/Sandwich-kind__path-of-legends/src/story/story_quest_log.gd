class_name StoryQuestLog
extends CanvasLayer
# ---------- Журнал заданий (игра на паузе) ----------
# Слева — список: основные и побочные задания. Справа — описание и шаги.

var mode
var _vs := Vector2.ZERO
var _sel := ""
var _content: Control

func _ready() -> void:
	layer = 20
	_vs = Config.screen(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = _vs
	add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(60, 30)
	panel.size = _vs - Vector2(120, 60)
	panel.add_theme_stylebox_override("panel", StoryHud.box(Color(0.93, 0.86, 0.68, 0.98), Color(0.45, 0.28, 0.14), 14, 4))
	add_child(panel)
	var t := Label.new()
	t.text = "Задания"
	t.position = Vector2(90, 42)
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08))
	t.add_theme_constant_override("outline_size", 0)
	add_child(t)
	var close := Button.new()
	close.text = "Закрыть"
	close.size = Vector2(150, 46)
	close.position = Vector2(_vs.x - 230, 44)
	close.add_theme_font_size_override("font_size", 20)
	close.focus_mode = Control.FOCUS_ALL
	close.pressed.connect(queue_free)
	add_child(close)
	_content = Control.new()
	add_child(_content)
	for qid in StoryQuests.DB:
		if not mode.data["quests"][qid].get("done", false):
			_sel = qid
			break
	if _sel == "":
		_sel = StoryQuests.DB.keys()[0]
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_quests") or event.is_action_pressed("p1_menu") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()

func _ink(parent: Node, text: String, pos: Vector2, size: int, c := Color(0.25, 0.15, 0.08)) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.add_theme_constant_override("outline_size", 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _refresh() -> void:
	for c in _content.get_children():
		c.queue_free()
	var y := 104.0
	for group in [[true, "Основные"], [false, "Побочные"]]:
		_ink(_content, group[1], Vector2(96, y), 20, Color(0.5, 0.25, 0.1))
		y += 32.0
		for qid in StoryQuests.DB:
			var q: Dictionary = StoryQuests.DB[qid]
			if q["main"] != group[0]:
				continue
			var st: Dictionary = mode.data["quests"][qid]
			var b := Button.new()
			b.text = ("✓ " if st.get("done", false) else "") + String(q["name"])
			b.position = Vector2(96, y)
			b.size = Vector2(300, 46)
			b.add_theme_font_size_override("font_size", 18)
		
			b.modulate = Color(1.2, 1.1, 0.8) if qid == _sel else Color(0.85, 0.85, 0.85)
			b.pressed.connect(func():
				_sel = qid
				_refresh())
			_content.add_child(b)
			y += 52.0
		y += 10.0
	# описание выбранного
	var q2: Dictionary = StoryQuests.DB[_sel]
	var st2: Dictionary = mode.data["quests"][_sel]
	var x := 430.0
	var w := _vs.x - x - 100.0
	_ink(_content, String(q2["name"]) + ("  (выполнено)" if st2.get("done", false) else ""), Vector2(x, 104), 26, Color(0.4, 0.15, 0.05))
	_ink(_content, "Основное задание" if q2["main"] else "Побочное задание", Vector2(x, 140), 15, Color(0.45, 0.32, 0.2))
	var d := _ink(_content, String(q2["desc"]), Vector2(x, 170), 17)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.update_minimum_size()
	d.size = Vector2(w, 60)
	var y2 := 240.0
	var steps: Array = q2["steps"]
	for i in steps.size():
		var done: bool = st2.get("done", false) or i < int(st2["step"])
		var cur: bool = not st2.get("done", false) and i == int(st2["step"])
		if i > int(st2["step"]) and not st2.get("done", false):
			_ink(_content, "?  ...", Vector2(x, y2), 18, Color(0.45, 0.35, 0.25, 0.6))     # будущие шаги скрыты
			y2 += 30.0
			continue
		var txt: String = String(steps[i]["text"])
		if cur and steps[i].has("count"):
			txt += "  (%d/%d)" % [int(st2["n"]), int(steps[i]["count"])]
		_ink(_content, ("☑  " if done else "☐  ") + txt, Vector2(x, y2), 18,
				Color(0.35, 0.45, 0.2) if done else Color(0.25, 0.15, 0.08))
		y2 += 30.0
	var r: Dictionary = q2.get("reward", {})
	var rt := "Награда: %d опыта" % int(r.get("xp", 0))
	for id in r.get("items", {}):
		rt += ", " + Items.item_name(String(id)) + " ×%d" % int(r["items"][id])
	_ink(_content, rt, Vector2(x, y2 + 16), 16, Color(0.5, 0.3, 0.05))
