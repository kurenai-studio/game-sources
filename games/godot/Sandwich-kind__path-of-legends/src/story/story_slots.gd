class_name StorySlots
extends CanvasLayer
# ---------- История: три ячейки сохранений ----------
# Пустая ячейка — «Новая игра» (откроется создание персонажа).
# Занятая — герой, уровень, время в игре; «Продолжить» или «Удалить».

signal back_pressed
signal new_game(slot: int)
signal continue_game(slot: int, data: Dictionary)

var _vs := Vector2.ZERO
var _cards: Control
var _confirm: Control

func _ready() -> void:
	_vs = Config.screen(self)
	backdrop(self, _vs)
	var t := Label.new()
	t.text = "История"
	t.size = Vector2(_vs.x, 70)
	t.position = Vector2(0, 26)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 52)
	t.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	t.add_theme_constant_override("outline_size", 12)
	t.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.08))
	add_child(t)
	var sub := Label.new()
	sub.text = "Выбери ячейку сохранения"
	sub.size = Vector2(_vs.x, 30)
	sub.position = Vector2(0, 96)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	add_child(sub)
	var back := Button.new()
	back.text = "Назад"
	back.position = Vector2(24, 24)
	back.size = Vector2(150, 54)
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	_cards = Control.new()
	add_child(_cards)
	_build()

static func backdrop(layer: CanvasLayer, vs: Vector2) -> void:
	var img := PixelArt.title_landscape()
	var k := maxf(vs.x / img.get_width(), vs.y / img.get_height())
	var bg := PixelArt.make_sprite(img, k)
	bg.position = (vs - Vector2(img.get_size()) * k) / 2
	layer.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.02, 0.55)
	shade.size = vs
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)

func _build() -> void:
	for c in _cards.get_children():
		c.queue_free()
	var cw := minf(330.0, (_vs.x - 80.0) / 3.0 - 20.0)
	var ch := 430.0
	var total := cw * 3 + 40.0
	for i in StorySave.SLOTS:
		var slot := i + 1
		var x := (_vs.x - total) / 2 + i * (cw + 20.0)
		var card := Panel.new()
		card.position = Vector2(x, 150)
		card.size = Vector2(cw, ch)
		card.add_theme_stylebox_override("panel", StoryHud.box(Color(0.12, 0.09, 0.07, 0.92), Color(0.8, 0.6, 0.3), 14, 3))
		_cards.add_child(card)
		var num := Label.new()
		num.text = "Ячейка %d" % slot
		num.size = Vector2(cw, 30)
		num.position = Vector2(0, 12)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.add_theme_font_size_override("font_size", 20)
		num.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
		card.add_child(num)
		var s := StorySave.summary(slot)
		if s.is_empty():
			var e := Label.new()
			e.text = "Пусто"
			e.size = Vector2(cw, 40)
			e.position = Vector2(0, 150)
			e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			e.add_theme_font_size_override("font_size", 24)
			e.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
			card.add_child(e)
			var b := Button.new()
			b.text = "Новая игра"
			b.size = Vector2(cw - 40, 64)
			b.position = Vector2(20, ch - 90)
			b.add_theme_font_size_override("font_size", 24)
			b.pressed.connect(func(): new_game.emit(slot))
			card.add_child(b)
			continue
		# герой этой ячейки
		var d := StorySave.load_slot(slot)
		var holder := Node2D.new()
		var k := 2.0
		holder.scale = Vector2(k, k)
		holder.position = Vector2(cw / 2, 200 - Player.SIZE.y * k / 2)
		card.add_child(holder)
		var rig := BotRig.new()
		rig.kind = "story"
		rig.size = Player.SIZE
		rig.custom_spec = StoryLook.spec(d.get("look", StoryLook.default_look()), d.get("equipped", {}))
		holder.add_child(rig)
		var info := Label.new()
		info.text = "%s\nУровень %d · в игре %s\n%s" % [s["name"], s["level"], s["time"], String(s["saved"]).replace("T", "  ")]
		info.size = Vector2(cw, 90)
		info.position = Vector2(0, 214)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.add_theme_font_size_override("font_size", 18)
		card.add_child(info)
		var go := Button.new()
		go.text = "Продолжить"
		go.size = Vector2(cw - 40, 58)
		go.position = Vector2(20, ch - 132)
		go.add_theme_font_size_override("font_size", 22)
		go.pressed.connect(func(): continue_game.emit(slot, StorySave.load_slot(slot)))
		card.add_child(go)
		var del := Button.new()
		del.text = "Удалить"
		del.size = Vector2(cw - 40, 44)
		del.position = Vector2(20, ch - 64)
		del.add_theme_font_size_override("font_size", 17)
		del.modulate = Color(1.0, 0.7, 0.65)
		del.pressed.connect(_ask_delete.bind(slot, String(s["name"])))
		card.add_child(del)

func _ask_delete(slot: int, hero_name: String) -> void:
	if _confirm:
		_confirm.queue_free()
	_confirm = Control.new()
	_confirm.size = _vs
	add_child(_confirm)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = _vs
	_confirm.add_child(dim)
	var p := Panel.new()
	p.size = Vector2(480, 220)
	p.position = (_vs - p.size) / 2
	p.add_theme_stylebox_override("panel", StoryHud.box(Color(0.12, 0.09, 0.07, 0.97), Color(0.9, 0.4, 0.3), 14, 3))
	_confirm.add_child(p)
	var l := Label.new()
	l.text = "Удалить сохранение «%s»?\nЭто нельзя отменить." % hero_name
	l.size = Vector2(480, 80)
	l.position = Vector2(0, 26)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 21)
	p.add_child(l)
	var yes := Button.new()
	yes.text = "Удалить"
	yes.size = Vector2(190, 56)
	yes.position = Vector2(40, 136)
	yes.add_theme_font_size_override("font_size", 20)
	yes.modulate = Color(1.0, 0.65, 0.6)
	yes.pressed.connect(func():
		StorySave.delete_slot(slot)
		_confirm.queue_free()
		_confirm = null
		_build())
	p.add_child(yes)
	var no := Button.new()
	no.text = "Отмена"
	no.size = Vector2(190, 56)
	no.position = Vector2(250, 136)
	no.add_theme_font_size_override("font_size", 20)
	no.pressed.connect(func():
		_confirm.queue_free()
		_confirm = null)
	p.add_child(no)
