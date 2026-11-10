class_name DuelSetup
extends CanvasLayer
# Подготовка дуэли в виде свитка.
#   Вверху — параметры матча (победы в раундах, убийства в раунде).
#   Ниже — места битвы. Нажатие на место «рисует» его эскиз внизу свитка,
#   выбор другого места стирает эскиз и рисует новый.
#   В конце — «Выбрать легенд»: свиток сворачивается, из-под земли поднимаются
#   две каменные колонны с героями. «В БОЙ!» начинает дуэль.

signal start_pressed(map_id: String, wins: int, kills: int, sel: Array, opts: Dictionary)
signal back_pressed

const WINS_RANGE := Vector2i(1, 9)
const KILLS_RANGE := Vector2i(1, 20)
const INK := ScrollPaper.INK

var wins := 3
var kills := 5
# Подарки с неба и «Мгновенная смерть»
var opts := {"heal": false, "buffs": false, "mega": false, "sd": false, "sd_time": 120}
var _toggles := {}
var _sd_lbl: Label
var map_id := ""
var sel := [0, 1]
var start_on_legends := false     # сразу открыть выбор легенд (кнопка «Ещё раз» и т.п.)

var _vs := Vector2.ZERO
var _paper: ScrollPaper
var _wins_lbl: Label
var _kills_lbl: Label
var _map_btns := {}
var _desc: Label
var _preview: TextureRect
var _cover: ColorRect
var _quill: Polygon2D
var _hint: Label
var _legends_btn: Button
var _preview_y := 0.0
var _picker: LegendPicker
var _back: Button
var _draw_tw: Tween

func _ready() -> void:
	_vs = Config.screen(self)
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.11, 0.08)
	bg.size = _vs
	add_child(bg)
	# доски стола
	for i in int(_vs.y / 54.0) + 1:
		var plank := ColorRect.new()
		plank.color = Color(0.2, 0.13, 0.09) if i % 2 == 0 else Color(0.18, 0.12, 0.08)
		plank.position = Vector2(0, i * 54.0)
		plank.size = Vector2(_vs.x, 52)
		add_child(plank)
	_paper = ScrollPaper.new()
	var pw := minf(820.0, _vs.x - 300.0)
	_paper.paper_rect = Rect2((_vs.x - pw) / 2, 34, pw, _vs.y - 68)
	add_child(_paper)
	_fill(_paper.content, pw - 40.0)
	_back = MainMenu.make_button(self, "Назад", Vector2(20, 20), Vector2(130, 55), 26)
	_back.pressed.connect(_on_back)
	CoinBadge.corner(self)
	if map_id != "":
		_choose_map(map_id, false)
	if start_on_legends and map_id != "":
		_paper.visible = false
		_show_picker()

# ---------- Содержимое свитка ----------
func _label(parent: Control, text: String, pos: Vector2, size: Vector2, font: int,
		center := true) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # перенос строк — до размера
	l.text = text
	l.position = pos
	l.size = size
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	parent.add_child(l)
	return l

func _line(parent: Control, y: float, w: float) -> void:
	var r := ColorRect.new()
	r.color = Color(INK, 0.35)
	r.position = Vector2(w * 0.15, y)
	r.size = Vector2(w * 0.7, 2)
	parent.add_child(r)

func _fill(c: Control, w: float) -> void:
	var y := 6.0
	_label(c, "Свиток дуэли", Vector2(0, y), Vector2(w, 50), 38)
	y += 60.0
	_line(c, y, w)
	y += 14.0
	_label(c, "Условия поединка", Vector2(0, y), Vector2(w, 36), 26)
	y += 44.0
	_wins_lbl = _stepper(c, "Побед в раундах для победы в матче", y, w, _change_wins)
	y += 64.0
	_kills_lbl = _stepper(c, "Убийств для победы в раунде", y, w, _change_kills)
	y += 76.0
	_line(c, y, w)
	y += 14.0
	_label(c, "Подарки с неба", Vector2(0, y), Vector2(w, 36), 26)
	y += 40.0
	_label(c, "Сферы падают в случайные места карты", Vector2(0, y), Vector2(w, 26), 16).modulate.a = 0.75
	y += 32.0
	for row in [["heal", "Станции здоровья"], ["buffs", "Баффы"], ["mega", "МЕГА-баффы"]]:
		_toggle(c, row[0], row[1], y, w)
		y += 62.0
	_line(c, y + 6, w)
	y += 20.0
	_label(c, "Мгновенная смерть", Vector2(0, y), Vector2(w, 36), 26)
	y += 40.0
	_label(c, "Когда время раунда выйдет — начнётся апокалипсис", Vector2(0, y), Vector2(w, 26), 16).modulate.a = 0.75
	y += 32.0
	_toggle(c, "sd", "Включить", y, w)
	y += 62.0
	_label(c, "Время раунда", Vector2(20, y + 10), Vector2(w - 420, 40), 21, false)
	var bm := MainMenu.make_button(c, "−мин", Vector2(w - 410, y), Vector2(80, 56), 20)
	bm.pressed.connect(_change_sd.bind(-60))
	var bs := MainMenu.make_button(c, "−10с", Vector2(w - 325, y), Vector2(80, 56), 20)
	bs.pressed.connect(_change_sd.bind(-10))
	_sd_lbl = _label(c, "", Vector2(w - 245, y + 6), Vector2(80, 44), 30)
	var ps := MainMenu.make_button(c, "+10с", Vector2(w - 165, y), Vector2(80, 56), 20)
	ps.pressed.connect(_change_sd.bind(10))
	var pm := MainMenu.make_button(c, "+мин", Vector2(w - 80, y), Vector2(80, 56), 20)
	pm.pressed.connect(_change_sd.bind(60))
	y += 76.0
	_line(c, y, w)
	y += 14.0
	_label(c, "Место битвы", Vector2(0, y), Vector2(w, 36), 26)
	y += 46.0
	# карты — по три в ряд; скрытые появляются после прохождения этапов Арены
	var maps: Array = Maps.visible_duel_maps()
	var gap := 16.0
	var per_row := 3
	var bw := (w - 40.0 - gap * (per_row - 1)) / per_row
	for i in maps.size():
		var m: Dictionary = maps[i]
		var pos := Vector2(20 + (i % per_row) * (bw + gap), y + (i / per_row) * 82.0)
		var b := MainMenu.make_button(c, m["name"], pos, Vector2(bw, 70), 24 if m["name"].length() < 12 else 20)
		b.pressed.connect(_choose_map.bind(m["id"], true))
		if m.has("stage"):
			b.modulate = Color(1.0, 0.9, 0.75)
		_map_btns[m["id"]] = b
	y += 82.0 * ceili(maps.size() / float(per_row))
	_desc = _label(c, "", Vector2(30, y), Vector2(w - 60, 56), 18)
	y += 62.0
	# эскиз карты
	_preview_y = y
	var frame := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.9, 0.8, 0.6)
	st.border_color = Color(INK, 0.6)
	st.set_border_width_all(2)
	frame.add_theme_stylebox_override("panel", st)
	frame.position = Vector2(20, y)
	frame.size = Vector2(w - 40, 270)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(frame)
	_hint = _label(frame, "Выберите место битвы —\nего эскиз появится здесь", Vector2(0, 100), Vector2(w - 40, 70), 20)
	_hint.modulate = Color(1, 1, 1, 0.6)
	_preview = TextureRect.new()
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_preview.position = Vector2(8, 8)
	_preview.size = frame.size - Vector2(16, 16)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_preview)
	# «бумага», которая сдвигается, открывая рисунок
	_cover = ColorRect.new()
	_cover.color = st.bg_color
	_cover.position = Vector2(8, 4)
	_cover.size = Vector2(0, frame.size.y - 8)
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_cover)
	_quill = Polygon2D.new()
	_quill.polygon = PackedVector2Array([Vector2(0, 0), Vector2(10, -60), Vector2(26, -70), Vector2(8, -6)])
	_quill.color = Color(0.95, 0.95, 0.9)
	_quill.visible = false
	frame.add_child(_quill)
	y += 290.0
	_legends_btn = MainMenu.make_button(c, "Выбрать легенд", Vector2(w / 2 - 170, y), Vector2(340, 80), 32)
	_legends_btn.pressed.connect(_on_legends)
	_legends_btn.disabled = true
	y += 100.0
	_paper.content_height = y
	_update_steppers()

func _stepper(c: Control, text: String, y: float, w: float, fn: Callable) -> Label:
	_label(c, text, Vector2(20, y + 10), Vector2(w - 260, 40), 21, false)
	var minus := MainMenu.make_button(c, "−", Vector2(w - 230, y), Vector2(60, 56), 30)
	minus.pressed.connect(fn.bind(-1))
	var val := _label(c, "", Vector2(w - 165, y + 6), Vector2(90, 44), 32)
	var plus := MainMenu.make_button(c, "+", Vector2(w - 70, y), Vector2(60, 56), 30)
	plus.pressed.connect(fn.bind(1))
	return val

func _change_wins(d: int) -> void:
	wins = clampi(wins + d, WINS_RANGE.x, WINS_RANGE.y)
	_update_steppers()

func _change_kills(d: int) -> void:
	kills = clampi(kills + d, KILLS_RANGE.x, KILLS_RANGE.y)
	_update_steppers()

func _toggle(c: Control, key: String, text: String, y: float, w: float) -> void:
	_label(c, text, Vector2(20, y + 10), Vector2(w - 260, 40), 21, false)
	var b := MainMenu.make_button(c, "", Vector2(w - 190, y), Vector2(180, 54), 22)
	b.pressed.connect(func():
		opts[key] = not opts[key]
		_update_steppers())
	_toggles[key] = b

func _change_sd(d: int) -> void:
	opts["sd_time"] = clampi(int(opts["sd_time"]) + d, 10, 15 * 60)
	_update_steppers()

func _update_steppers() -> void:
	for k in _toggles:
		var on: bool = opts[k]
		_toggles[k].text = "Вкл" if on else "Выкл"
		_toggles[k].modulate = Color(0.75, 1.25, 0.75) if on else Color(0.9, 0.8, 0.8)
	if _sd_lbl:
		_sd_lbl.text = "%d:%02d" % [int(opts["sd_time"]) / 60, int(opts["sd_time"]) % 60]
		_sd_lbl.modulate.a = 1.0 if opts["sd"] else 0.45
	_wins_lbl.text = str(wins)
	_kills_lbl.text = str(kills)

# ---------- Эскиз карты ----------
func _choose_map(id: String, animate: bool) -> void:
	var first := map_id == "" or not animate
	map_id = id
	for k in _map_btns:
		_map_btns[k].modulate = Color(1.25, 1.12, 0.75) if k == id else Color(0.85, 0.85, 0.85)
	for m in Maps.DUEL_MAPS:
		if m["id"] == id:
			_desc.text = m["desc"]
	_legends_btn.disabled = false
	_hint.visible = false
	if _draw_tw:
		_draw_tw.kill()
	var img := Maps.preview_image(id, _preview.size)
	var full: float = (_cover.get_parent() as Control).size.x - 16.0
	_draw_tw = create_tween()
	if not first:
		# стираем старый рисунок: бумага наезжает справа налево
		_draw_tw.tween_property(_cover, "size:x", full, 0.25)
	_draw_tw.tween_callback(func():
		_preview.texture = ImageTexture.create_from_image(img)
		_quill.visible = animate)
	# рисуем новый: бумага уходит, за ней — перо
	if animate:
		_draw_tw.tween_method(_reveal.bind(full), 0.0, 1.0, 1.1)
		_draw_tw.tween_callback(func(): _quill.visible = false)
		_paper.scroll_to(_preview_y - 40.0)
	else:
		_draw_tw.tween_callback(_reveal.bind(1.0, full))
		_quill.visible = false

func _reveal(t: float, full: float) -> void:
	_cover.position.x = 8.0 + full * t
	_cover.size.x = full * (1.0 - t)
	_quill.position = Vector2(_cover.position.x, 60.0 + 150.0 * absf(sin(t * 18.0)) * 0.6 + 40.0)

# ---------- Выбор легенд ----------
func _on_legends() -> void:
	if map_id == "":
		return
	_legends_btn.disabled = true
	_paper.rolled_up.connect(_show_picker, CONNECT_ONE_SHOT)
	_paper.roll_up()

func _show_picker() -> void:
	_paper.visible = false
	_picker = LegendPicker.new()
	_picker.count = 2
	_picker.sel = sel.duplicate()
	add_child(_picker)
	_picker.rise()
	_picker.go_pressed.connect(func(): start_pressed.emit(map_id, wins, kills, _picker.sel.duplicate(), opts.duplicate()))
	_picker.back_pressed.connect(_on_back)
	_back.visible = false

func _on_back() -> void:
	if _picker:
		sel = _picker.sel.duplicate()
		_picker.queue_free()
		_picker = null
		_back.visible = true
		_paper.visible = true
		_paper.unroll()
		_legends_btn.disabled = false
		return
	back_pressed.emit()
