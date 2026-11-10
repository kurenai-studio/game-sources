class_name BestiaryScreen
extends CanvasLayer
# Бестиарий: каменная плита с вкладками «Колизей», «Джунгли», «Пещеры».
# Противник, которого ещё не встречали на арене, скрыт за знаком вопроса.
# После первой встречи появляется его фигурка; при нажатии — описание:
# здоровье, урон, скорость, волна первого появления и немного истории.

signal back_pressed

const TABS := [["forest", "Лес"], ["village", "Деревня"], ["jungle", "Джунгли"], ["caves", "Пещеры"],
		["deep", "Самоцветы"], ["colosseum", "Колизей"], ["eerie", "Жуткий лес"], ["swamp", "Болото"],
		["ice", "Ледяная тропа"], ["storm", "Храм шторма"], ["lava", "Лава"], ["throne", "Тронный зал"]]
const TAB_ROW := 6                  # вкладок в ряду (два ряда)
const INK := Color(0.95, 0.88, 0.72)

var _tab := 0
var _sel := 0
var _grid: Control
var _scroll: ScrollContainer   # карточки противников прокручиваются (на некоторых локациях их больше 8)
var _cards: Array = []
var _info: Control
var _tab_btns: Array = []
var _vs := Vector2.ZERO

func _ready() -> void:
	_vs = Config.screen(self)
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.09, 0.11)
	bg.size = _vs
	add_child(bg)
	var title := Label.new()
	title.text = "Бестиарий"
	title.size = Vector2(_vs.x, 60)
	title.position = Vector2(0, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	add_child(title)
	var bw := minf(_vs.x - 80.0, 1100.0)
	var x0 := (_vs.x - bw) / 2
	var tw := (bw - 260.0) / TAB_ROW
	for i in TABS.size():
		var b := MainMenu.make_button(self, TABS[i][1], Vector2(x0 + (i % TAB_ROW) * tw, 76 + (i / TAB_ROW) * 46), Vector2(tw - 6.0, 42), 15)
		b.pressed.connect(func():
			if _tab == i:
				return
			_tab = i
			_sel = 0
			_refresh())
		_tab_btns.append(b)
	var all := MainMenu.make_button(self, "Открыть всё", Vector2(x0 + bw - 250, 76), Vector2(250, 88), 18)
	all.pressed.connect(func():
		Save.see_all()
		_refresh())
	_grid = _panel(Vector2(x0, 174), Vector2(bw * 0.52, _vs.y - 192))
	_info = _panel(Vector2(x0 + bw * 0.54, 174), Vector2(bw * 0.46, _vs.y - 192))
	var back := MainMenu.make_button(self, "Назад", Vector2(20, 20), Vector2(130, 55), 26)
	back.pressed.connect(func(): back_pressed.emit())
	_refresh()

func _panel(pos: Vector2, size: Vector2) -> Control:
	var p := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.22, 0.20, 0.22)
	st.border_color = Color(0.45, 0.40, 0.38)
	st.set_border_width_all(4)
	st.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", st)
	p.position = pos
	p.size = size
	p.clip_contents = true
	add_child(p)
	return p

func _label(parent: Control, text: String, pos: Vector2, size: Vector2, font: int, color := INK,
		center := false) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

# Живая фигурка противника (дышит и шевелится)
static func make_figure(kind: String, box: Vector2) -> Node2D:
	var size: Vector2 = Bots.TYPES[kind]["size"]
	var rig: Node2D
	if kind in CreatureRig.KINDS:
		var cr := CreatureRig.new()
		cr.kind = kind
		cr.size = size
		rig = cr
	elif kind in DeepRig.KINDS:
		var dr := DeepRig.new()
		dr.kind = kind
		dr.size = size
		rig = dr
	elif kind in WildRig.KINDS:
		var wr := WildRig.new()
		wr.kind = kind
		wr.size = size
		rig = wr
	else:
		var br := BotRig.new()
		br.kind = "hunter" if kind == "mirror_double" else kind     # отражение — в облике героя
		br.size = size
		if kind == "mirror_double":
			br.modulate = Color(0.75, 0.95, 1.25, 0.82)
		rig = br
	var extra := 1.4 if kind in ["treant", "colossus", "chief", "gladiator", "skeleton_king", "deadwood", "bog_lord"] else 1.15
	var k := minf(box.x / (size.x * 1.5), box.y / (size.y * extra))
	var holder := Node2D.new()          # масштаб — у держателя: модель сама крутит свой scale.x
	holder.scale = Vector2(k, k)
	holder.add_child(rig)
	return holder

# Вкладка (локация) целиком: сетка карточек в прокручиваемом окне
func _refresh() -> void:
	for i in _tab_btns.size():
		_tab_btns[i].modulate = Color(1.3, 1.15, 0.7) if i == _tab else Color(0.85, 0.85, 0.85)
	for n in _grid.get_children():
		n.queue_free()
	_cards.clear()
	var kinds: Array = Bots.LOCATIONS[TABS[_tab][0]]
	var cols := 4
	var gap := 10.0
	var cw := (_grid.size.x - 20.0 - 16.0 - gap * (cols - 1)) / cols
	var ch := (_grid.size.y - 20.0 - gap) / 2.0           # видно два ряда, остальные — ниже, прокруткой
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(4, 4)
	_scroll.size = _grid.size - Vector2(8, 8)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid.add_child(_scroll)
	var content := Control.new()
	var rows := ceili(kinds.size() / float(cols))
	content.custom_minimum_size = Vector2(_scroll.size.x - 16.0, 6 + rows * (ch + gap) + 6)
	_scroll.add_child(content)
	for i in kinds.size():
		var kind: String = kinds[i]
		var known := Save.seen(kind)
		var card := Button.new()
		card.position = Vector2(6 + (i % cols) * (cw + gap), 6 + (i / cols) * (ch + gap))
		card.size = Vector2(cw, ch)
		card.pressed.connect(_select.bind(i))
		content.add_child(card)
		_cards.append(card)
		if known:
			var fig := make_figure(kind, Vector2(cw, ch - 30))
			fig.position = Vector2(cw / 2, (ch - 30) / 2 + 6)
			card.add_child(fig)
			var boss: bool = Bots.TYPES[kind].get("boss", false)
			_label(card, Bots.TYPES[kind]["name"], Vector2(4, ch - 30), Vector2(cw - 8, 26), 14,
					Color(1.0, 0.75, 0.4) if boss else INK, true)
		else:
			_label(card, "?", Vector2(0, ch / 2 - 40), Vector2(cw, 70), 56, Color(0.6, 0.55, 0.5), true)
	if rows > 2:
		# подсказка: внизу есть ещё противники
		var more := _label(_grid, "▼ листай — ещё %d" % (kinds.size() - cols * 2), Vector2(0, _grid.size.y - 26),
				Vector2(_grid.size.x - 16, 22), 14, Color(1.0, 0.85, 0.5, 0.85), true)
		more.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sc := _scroll
		_scroll.get_v_scroll_bar().value_changed.connect(func(v: float):
			if is_instance_valid(more):
				more.visible = v < sc.get_v_scroll_bar().max_value - sc.get_v_scroll_bar().page - 4.0)
	TouchList.attach(_scroll)                   # пальцем — листать, коротким касанием — выбрать
	_select(_sel)

# Выбранный противник: подсветка карточки и описание справа (сетка не перестраивается)
func _select(i: int) -> void:
	var kinds: Array = Bots.LOCATIONS[TABS[_tab][0]]
	_sel = clampi(i, 0, kinds.size() - 1)
	for k in _cards.size():
		_cards[k].modulate = Color(1.25, 1.15, 0.8) if k == _sel else Color.WHITE
	for n in _info.get_children():
		n.queue_free()
	_show_info(kinds[_sel])

func _show_info(kind: String) -> void:
	var w := _info.size.x
	var t: Dictionary = Bots.TYPES[kind]
	if not Save.seen(kind):
		_label(_info, "???", Vector2(0, 30), Vector2(w, 60), 48, Color(0.6, 0.55, 0.5), true)
		_label(_info, "Встреться с этим противником на арене, чтобы узнать о нём больше.",
				Vector2(30, 120), Vector2(w - 60, 100), 20, INK, true)
		return
	var fig := make_figure(kind, Vector2(w * 0.45, 190))
	fig.position = Vector2(w * 0.25, 120)
	_info.add_child(fig)
	var boss: bool = t.get("boss", false)
	var name_fs := 28 if t["name"].length() <= 14 else 22
	_label(_info, t["name"], Vector2(w * 0.48, 16), Vector2(w * 0.5, 70), name_fs, Color(1.0, 0.75, 0.4) if boss else Color(1.0, 0.9, 0.6))
	if boss:
		_label(_info, "Босс арены" if Bots.first_wave(kind) % 10 == 0 else "Мини-босс", Vector2(w * 0.48, 84), Vector2(w * 0.5, 26), 16, Color(1.0, 0.5, 0.4))
	var stats := "Здоровье: %d\nУрон: %d\nСкорость: %d\nВпервые: волна %d" % [
			t["hp"], Bots.damage_of(kind), int(t["speed"]), Bots.first_wave(kind)]
	_label(_info, stats, Vector2(w * 0.48, 112), Vector2(w * 0.5, 110), 18)
	_label(_info, Bots.LORE.get(kind, ""), Vector2(20, 236), Vector2(w - 40, _info.size.y - 250), 17,
			Color(0.85, 0.82, 0.75))
