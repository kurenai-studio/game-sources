class_name InventoryScreen
extends CanvasLayer
# Инвентарь в виде раскрытой «Книги легенд» с закладками-вкладками.
# «Легенды»: список героев слева, выбранный герой и его способности справа.
# Остальные вкладки пока пустые.

signal back_pressed

const TABS := ["Легенды", "Снаряжение", "Трофеи", "Свитки"]
const PAGE := Color(0.95, 0.89, 0.74)
const INK := Color(0.25, 0.16, 0.10)

var _tab := 0
var _hero := 0
var _left: Control
var _right: Control
var _tab_btns: Array = []
var _lsc: ScrollContainer         # список легенд (его прокрутка сохраняется при выборе)

func _ready() -> void:
	var vs := Config.screen(self)
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.10, 0.09)
	bg.size = vs
	add_child(bg)
	# обложка книги
	var bw := minf(vs.x - 220.0, 1060.0)
	var bh := vs.y - 110.0
	var bx := (vs.x - bw) / 2 - 40.0
	var by := 80.0
	var cover := Panel.new()
	cover.position = Vector2(bx - 16, by - 14)
	cover.size = Vector2(bw + 32, bh + 28)
	cover.add_theme_stylebox_override("panel", _box(Color(0.42, 0.20, 0.12), Color(0.75, 0.55, 0.25), 18, 4))
	add_child(cover)
	# две страницы и корешок
	_left = _page(Vector2(bx, by), Vector2(bw / 2 - 6, bh))
	_right = _page(Vector2(bx + bw / 2 + 6, by), Vector2(bw / 2 - 6, bh))
	var spine := ColorRect.new()
	spine.color = Color(0.55, 0.42, 0.28)
	spine.position = Vector2(bx + bw / 2 - 6, by)
	spine.size = Vector2(12, bh)
	add_child(spine)
	# закладки справа
	for i in TABS.size():
		var b := Button.new()
		b.text = TABS[i]
		b.position = Vector2(bx + bw + 22, by + 10 + i * 78)
		b.size = Vector2(170, 64)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_select_tab.bind(i))
		add_child(b)
		_tab_btns.append(b)
	var title := Label.new()
	title.text = "Книга легенд"
	title.size = Vector2(vs.x, 60)
	title.position = Vector2(0, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	add_child(title)
	CoinBadge.corner(self)
	var back := MainMenu.make_button(self, "Назад", Vector2(20, 20), Vector2(130, 55), 26)
	back.pressed.connect(func(): back_pressed.emit())
	_refresh()

func _box(bg: Color, border: Color, radius: int, bw: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(radius)
	st.border_color = border
	st.set_border_width_all(bw)
	return st

func _page(pos: Vector2, size: Vector2) -> Control:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.add_theme_stylebox_override("panel", _box(PAGE, Color(0.8, 0.7, 0.5), 6, 2))
	p.clip_contents = true
	add_child(p)
	return p

func _select_tab(i: int) -> void:
	_tab = i
	_refresh()

func _select_hero(i: int) -> void:
	_hero = i
	_refresh()

func _clear(c: Control) -> void:
	for n in c.get_children():
		n.queue_free()

func _ink_label(parent: Control, text: String, pos: Vector2, size: Vector2, font: int,
		center := false) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # перенос строк — до размера
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

func _refresh() -> void:
	# выбор легенды не сбрасывает прокрутку списка и выбор геймпадом
	var keep_v := _lsc.scroll_vertical if _lsc and is_instance_valid(_lsc) else 0
	var fo := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var list_focus := fo != null and _left.is_ancestor_of(fo)
	for i in _tab_btns.size():
		_tab_btns[i].modulate = Color(1.25, 1.15, 0.8) if i == _tab else Color(0.8, 0.8, 0.8)
	_clear(_left)
	_clear(_right)
	if _tab != 0:
		_ink_label(_left, TABS[_tab], Vector2(20, 20), Vector2(_left.size.x - 40, 50), 32, true)
		_ink_label(_left, "Здесь пока пусто.\nСкоро тут что-то появится.", Vector2(30, 120),
				Vector2(_left.size.x - 60, 120), 22, true)
		return
	# левая страница: список легенд
	_ink_label(_left, "Легенды", Vector2(20, 14), Vector2(_left.size.x - 40, 44), 30, true)
	var lsc := ScrollContainer.new()            # легенд много — список прокручивается
	lsc.position = Vector2(14, 64)
	lsc.size = Vector2(_left.size.x - 28, _left.size.y - 74)
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_left.add_child(lsc)
	_lsc = lsc
	var list := Control.new()
	list.custom_minimum_size = Vector2(_left.size.x - 48, Characters.LIST.size() * 76 + 6)
	lsc.add_child(list)
	var order := Characters.display_order()
	for row in order.size():
		var i: int = order[row]
		var ch: Dictionary = Characters.LIST[i]
		var open := Characters.unlocked(i)
		var b := Button.new()
		b.text = "          " + (ch["name"] if open else "???")
		b.position = Vector2(10, 6 + row * 76)
		b.size = Vector2(_left.size.x - 48, 66)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_select_hero.bind(i))
		if i == _hero:
			b.modulate = Color(1.2, 1.1, 0.75)
		list.add_child(b)
		HeroFigure.draw(b, Vector2(32, 60), 0.75, i, Color(0, 0, 0, 0), 1, not open)
		if i == _hero and list_focus:
			b.grab_focus.call_deferred()
	TouchList.attach(lsc)                       # пальцем — листать, коротким касанием — выбрать
	(func(): if is_instance_valid(lsc): lsc.scroll_vertical = keep_v).call_deferred()
	# правая страница: выбранный герой
	var h: Dictionary = Characters.LIST[_hero]
	var w := _right.size.x
	if not Characters.unlocked(_hero):
		HeroFigure.draw(_right, Vector2(90, 200), 2.4, _hero, Color(0, 0, 0, 0), 1, true)
		_ink_label(_right, "???", Vector2(170, 20), Vector2(w - 190, 44), 30)
		_ink_label(_right, "Эта легенда ещё не открыта.\n" + Characters.unlock_text(_hero) + ", чтобы узнать о ней всё.",
				Vector2(170, 80), Vector2(w - 190, 120), 18)
		return
	HeroFigure.draw(_right, Vector2(90, 200), 2.4, _hero)
	_ink_label(_right, h["name"], Vector2(170, 20), Vector2(w - 190, 44), 30)
	_ink_label(_right, h["role"], Vector2(170, 62), Vector2(w - 190, 30), 20)
	_ink_label(_right, "Здоровье: %d     Скорость: %d" % [h["hp"], int(h["speed"])],
			Vector2(170, 98), Vector2(w - 190, 30), 18)
	var wl := _ink_label(_right, h["weapon"], Vector2(170, 130), Vector2(w - 190, 70), 17)
	var y := maxf(215.0, 130.0 + wl.get_line_count() * wl.get_line_height() + 12.0)
	# способности — в прокручиваемом списке (описания бывают длинными)
	var sc := ScrollContainer.new()
	sc.position = Vector2(14, y)
	sc.size = Vector2(w - 28, _right.size.y - y - 10)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_right.add_child(sc)
	TouchList.attach(sc)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(w - 48, 0)
	box.add_theme_constant_override("separation", 2)
	sc.add_child(box)
	for sk in h["skills"]:
		var parts := [[sk[0], 20, 1.0], [sk[1], 16, 0.85]]
		if sk.size() > 2:
			parts.append(["На Арене: " + sk[2], 15, 0.95])      # усиленный вариант для Арены
		for part in parts:
			var l := Label.new()
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(w - 48, 0)
			l.text = part[0]
			l.add_theme_font_size_override("font_size", part[1])
			l.add_theme_color_override("font_color", INK if not str(part[0]).begins_with("На Арене") else Color(0.50, 0.16, 0.10))
			l.add_theme_constant_override("outline_size", 0)
			l.modulate = Color(1, 1, 1, part[2])
			box.add_child(l)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 6)
		box.add_child(gap)
