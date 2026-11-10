class_name ArenaSetup
extends CanvasLayer
# Подготовка Арены (тоже свиток): в одиночку или вдвоём в одной команде,
# новая игра или продолжение с сохранённой волны. Затем — выбор легенд на колоннах.

signal start_pressed(coop: bool, wave: int, sel: Array)
signal back_pressed

const INK := ScrollPaper.INK

var coop := false
var sel := [0, 1]

var _vs := Vector2.ZERO
var _paper: ScrollPaper
var _mode_btns: Array = []
var _cont_btn: Button
var _progress_lbl: Label
var _picker: LegendPicker
var _back: Button
var _wave := 1
var _any_wave := 1
var _any_lbl: Label

func _ready() -> void:
	_vs = Config.screen(self)
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.11, 0.08)
	bg.size = _vs
	add_child(bg)
	for i in int(_vs.y / 54.0) + 1:
		var plank := ColorRect.new()
		plank.color = Color(0.2, 0.13, 0.09) if i % 2 == 0 else Color(0.18, 0.12, 0.08)
		plank.position = Vector2(0, i * 54.0)
		plank.size = Vector2(_vs.x, 52)
		add_child(plank)
	_paper = ScrollPaper.new()
	var pw := minf(780.0, _vs.x - 300.0)
	_paper.paper_rect = Rect2((_vs.x - pw) / 2, 34, pw, _vs.y - 68)
	add_child(_paper)
	_fill(_paper.content, pw - 40.0)
	_back = MainMenu.make_button(self, "Назад", Vector2(20, 20), Vector2(130, 55), 26)
	_back.pressed.connect(_on_back)
	CoinBadge.corner(self)
	_set_coop(coop)

func _label(parent: Control, text: String, pos: Vector2, size: Vector2, font: int) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # перенос строк — до размера
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	parent.add_child(l)
	return l

func _fill(c: Control, w: float) -> void:
	var y := 6.0
	_label(c, "Арена", Vector2(0, y), Vector2(w, 50), 38)
	y += 56.0
	_label(c, "80 волн: лес и деревня, джунгли, пещеры, самоцветы и кристаллы, Колизей, Жуткий лес и Болото, ледяные горы, Храм шторма, лава — и тронный зал Тёмного лорда.\nПрогресс сохраняется после каждой волны. За волны дают золото.",
			Vector2(10, y), Vector2(w - 20, 90), 18)
	y += 98.0
	_label(c, "Кто идёт в бой", Vector2(0, y), Vector2(w, 36), 26)
	y += 44.0
	var names := ["Один", "Вдвоём"]
	for i in 2:
		var b := MainMenu.make_button(c, names[i], Vector2(w / 2 - 250 + i * 260, y), Vector2(240, 70), 28)
		b.pressed.connect(_set_coop.bind(i == 1))
		_mode_btns.append(b)
	y += 82.0
	_label(c, "Вдвоём — на одном телефоне, в одной команде: друг по другу не попадаете.",
			Vector2(10, y), Vector2(w - 20, 30), 16).modulate = Color(1, 1, 1, 0.75)
	y += 44.0
	_progress_lbl = _label(c, "", Vector2(0, y), Vector2(w, 34), 20)
	y += 44.0
	var new_btn := MainMenu.make_button(c, "Новая игра", Vector2(w / 2 - 300, y), Vector2(280, 76), 28)
	new_btn.pressed.connect(_go.bind(false))
	new_btn.set_meta("pad_default", true)
	_cont_btn = MainMenu.make_button(c, "Продолжить", Vector2(w / 2 + 20, y), Vector2(280, 76), 28)
	_cont_btn.pressed.connect(_go.bind(true))
	y += 96.0
	# ВРЕМЕННО (для проверки): начать с любой волны. Потом уберём.
	_label(c, "Проверка: начать с любой волны (временно)", Vector2(0, y), Vector2(w, 30), 18).modulate = Color(1, 1, 1, 0.8)
	y += 36.0
	var bx := w / 2 - 330.0
	for d in [-10, -1]:
		var bd := MainMenu.make_button(c, str(d), Vector2(bx, y), Vector2(70, 60), 24)
		bd.pressed.connect(_step_any.bind(d))
		bx += 78.0
	_any_lbl = _label(c, "", Vector2(bx - 10, y - 2), Vector2(170, 64), 18)
	bx += 158.0
	for d in [1, 10]:
		var bu := MainMenu.make_button(c, "+" + str(d), Vector2(bx, y), Vector2(70, 60), 24)
		bu.pressed.connect(_step_any.bind(d))
		bx += 78.0
	var go_any := MainMenu.make_button(c, "Старт", Vector2(bx + 8, y), Vector2(170, 60), 24)
	go_any.pressed.connect(_go_any)
	_step_any(0)
	y += 80.0
	_paper.content_height = y

func _mode_key() -> String:
	return "coop" if coop else "solo"

func _set_coop(v: bool) -> void:
	coop = v
	for i in 2:
		_mode_btns[i].modulate = Color(1.25, 1.12, 0.75) if (i == 1) == v else Color(0.85, 0.85, 0.85)
	var p := Save.arena_progress(_mode_key())
	if p.is_empty() and Save.stage_unlocked(9) and not Save.stage_unlocked(11):
		# Колизей уже пройден раньше (когда волн было 50) — можно сразу в новые земли
		_progress_lbl.text = "Новые земли открыты: Жуткий лес и Болото"
		_cont_btn.disabled = false
		_cont_btn.text = "С волны 51"
	elif p.is_empty():
		_progress_lbl.text = "Сохранённой игры нет"
		_cont_btn.disabled = true
		_cont_btn.text = "Продолжить"
	else:
		_progress_lbl.text = "Сохранено: начало волны %d" % int(p["wave"])
		_cont_btn.disabled = false
		_cont_btn.text = "С волны %d" % int(p["wave"])

func _step_any(d: int) -> void:
	_any_wave = clampi(_any_wave + d, 1, ArenaMode.TOTAL_WAVES)
	if _any_lbl:
		var place: String = ArenaMode.STAGE_NAMES[ArenaMode.stage_for(_any_wave)]
		_any_lbl.text = "Волна %d\n%s" % [_any_wave, place]

func _go_any() -> void:
	_wave = _any_wave
	_paper.rolled_up.connect(_show_picker, CONNECT_ONE_SHOT)
	_paper.roll_up()

func _go(cont: bool) -> void:
	_wave = 1
	if cont:
		var p := Save.arena_progress(_mode_key())
		_wave = int(p.get("wave", 51 if Save.stage_unlocked(9) else 1))
		var ch: Array = p.get("chars", [])
		for i in mini(ch.size(), 2):
			sel[i] = int(ch[i])
	_paper.rolled_up.connect(_show_picker, CONNECT_ONE_SHOT)
	_paper.roll_up()

func _show_picker() -> void:
	_paper.visible = false
	_picker = LegendPicker.new()
	_picker.count = 2 if coop else 1
	_picker.sel = sel.duplicate()
	_picker.titles = ["Игрок 1", "Игрок 2"] if coop else ["Твоя легенда"]
	_picker.go_text = "НА АРЕНУ!" if _wave == 1 else "ВОЛНА %d!" % _wave
	_picker.style = "lift"
	add_child(_picker)
	_picker.rise()
	var started := [false]
	_picker.go_pressed.connect(func():
		if started[0]:
			return
		started[0] = true
		var chosen: Array = _picker.sel.duplicate()
		# подъёмники уезжают наверх — на арену
		_picker.lift_up(func(): start_pressed.emit(coop, _wave, chosen)))
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
		return
	back_pressed.emit()
