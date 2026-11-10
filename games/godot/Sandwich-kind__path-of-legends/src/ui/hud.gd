class_name Hud
extends CanvasLayer
# Счёт вверху экрана, строка с раундом и победами, крупные надписи
# посередине («Раунд 2», «3», «Бой!») и кнопка «Меню».

signal menu_pressed

var _label: Label
var _sub: Label
var _banner: Label
var _boss_box: Control
var _boss_fill: ColorRect
var _boss_name: Label
var _stagger_fill: ColorRect
var _buffs: RichTextLabel
var _buffs2: RichTextLabel
var _hint: Label
var coins: CoinBadge
var _timer: Label

func _ready() -> void:
	layer = 5
	var w := Config.screen(self).x
	_label = _make_label(Vector2(0, 18), Vector2(w, 50), 36)
	_sub = _make_label(Vector2(0, 62), Vector2(w, 30), 18)
	_sub.modulate = Color(1, 1, 1, 0.8)
	_banner = _make_label(Vector2(0, 150), Vector2(w, 100), 64)
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_banner.visible = false
	var menu_btn := MainMenu.make_button(self, "Меню", Vector2(30, 25), Vector2(130, 55), 26)
	menu_btn.pressed.connect(func(): menu_pressed.emit())
	menu_btn.focus_mode = Control.FOCUS_NONE        # иначе кнопка «A» геймпада нажала бы «Меню»
	# полоса здоровья босса
	_boss_box = Control.new()
	_boss_box.position = Vector2(w / 2 - 260, 100)
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	add_child(_boss_box)
	var bb := ColorRect.new()
	bb.color = Color(0, 0, 0, 0.6)
	bb.position = Vector2(0, 28)
	bb.size = Vector2(520, 18)
	_boss_box.add_child(bb)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Color(0.9, 0.2, 0.2)
	_boss_fill.position = Vector2(3, 31)
	_boss_fill.size = Vector2(514, 12)
	_boss_box.add_child(_boss_fill)
	_boss_name = _make_label(Vector2(0, 0), Vector2(520, 28), 22)
	_boss_name.reparent(_boss_box, false)
	_boss_name.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	# активные баффы с таймерами
	_buffs = RichTextLabel.new()
	_buffs.bbcode_enabled = true
	_buffs.fit_content = true
	_buffs.scroll_active = false
	_buffs.position = Vector2(30, 92)
	_buffs.size = Vector2(320, 200)
	_buffs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buffs.add_theme_font_size_override("normal_font_size", 20)
	_buffs.add_theme_constant_override("outline_size", 6)
	_buffs.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	add_child(_buffs)
	# баффы второго игрока — справа (Арена вдвоём)
	_buffs2 = _buffs.duplicate()
	_buffs2.position = Vector2(w - 350, 92)
	add_child(_buffs2)
	# подсказка о боссе
	_hint = _make_label(Vector2(w / 2 - 330, 152), Vector2(660, 60), 19)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.size = Vector2(660, 60)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_hint.visible = false

func _make_label(pos: Vector2, size: Vector2, font: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

func set_text(text: String) -> void:
	_label.text = text

func set_sub(text: String) -> void:
	_sub.text = text

# Крупная надпись посередине экрана
func show_banner(text: String, color := Color.WHITE) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.visible = true
	_banner.pivot_offset = _banner.size / 2
	_banner.scale = Vector2(1.3, 1.3)
	var t := create_tween()
	t.tween_property(_banner, "scale", Vector2.ONE, 0.15)

func hide_banner() -> void:
	_banner.visible = false

func show_boss(boss_name: String, ratio: float, stagger := -1.0) -> void:
	_boss_box.visible = true
	_boss_name.text = boss_name
	_boss_fill.size.x = 514.0 * clampf(ratio, 0.0, 1.0)
	# жёлтая полоска под здоровьем — сколько осталось до оглушения
	if _stagger_fill == null:
		var sb := ColorRect.new()
		sb.color = Color(0, 0, 0, 0.6)
		sb.position = Vector2(0, 46)
		sb.size = Vector2(520, 8)
		_boss_box.add_child(sb)
		_stagger_fill = ColorRect.new()
		_stagger_fill.color = Color(1.0, 0.85, 0.3)
		_stagger_fill.position = Vector2(2, 48)
		_stagger_fill.size = Vector2(0, 4)
		_boss_box.add_child(_stagger_fill)
		_stagger_fill.set_meta("bg", sb)
	_stagger_fill.visible = stagger >= 0.0
	_stagger_fill.get_meta("bg").visible = stagger >= 0.0
	_stagger_fill.size.x = 516.0 * clampf(stagger, 0.0, 1.0)

func hide_boss() -> void:
	_boss_box.visible = false

# Список баффов игрока: обычные — цветом, МЕГА — жирно и с пометкой
func set_buffs(buffs: Dictionary) -> void:
	var t := ""
	for k in buffs:
		var info: Dictionary = Buffs.TYPES[k]
		var c: Color = info["color"]
		var line: String = "%s  %d с" % [Buffs.title(k, buffs[k]["mega"]), ceili(buffs[k]["t"])]
		if buffs[k]["mega"]:
			line = "[b]%s[/b]" % line
		t += "[color=#%s]%s[/color]\n" % [c.to_html(false), line]
	_buffs.text = t

func set_buffs2(buffs: Dictionary) -> void:
	var keep := _buffs
	_buffs = _buffs2
	set_buffs(buffs)
	_buffs = keep

var _hint_tw: Tween

func show_hint(text: String, time := 9.0) -> void:
	if _hint_tw and _hint_tw.is_valid():
		_hint_tw.kill()                  # старая подсказка не прячет новую раньше времени
	_hint.text = text
	_hint.visible = true
	_hint.modulate.a = 1.0
	var t := _hint.create_tween()
	_hint_tw = t
	t.tween_interval(time)
	t.tween_property(_hint, "modulate:a", 0.0, 0.6)
	t.tween_callback(func(): _hint.visible = false)

func hide_hint() -> void:
	if _hint_tw and _hint_tw.is_valid():
		_hint_tw.kill()
	_hint.visible = false

# Монеты в правом верхнем углу (Арена)
func show_coins() -> void:
	if coins == null:
		coins = CoinBadge.corner(self)
	coins.refresh()

# Таймер «Мгновенной смерти» — справа вверху
func show_timer(text: String, color := Color.WHITE) -> void:
	if _timer == null:
		var w := Config.screen(self).x
		_timer = _make_label(Vector2(w - 230, 22), Vector2(200, 50), 36)
		_timer.add_theme_constant_override("outline_size", 8)
		_timer.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_timer.text = text
	_timer.add_theme_color_override("font_color", color)
