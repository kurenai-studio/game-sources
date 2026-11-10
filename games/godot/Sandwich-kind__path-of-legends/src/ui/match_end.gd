class_name MatchEnd
extends CanvasLayer
# Экран окончания матча: кто победил и что дальше.

signal again_pressed
signal maps_pressed
signal menu_pressed

var winner := 0              # 0 — игрок 1, 1 — игрок 2
var rounds := [0, 0]
var title_text := ""         # если задано — вместо «Победил Игрок N!»
var title_color := Color.WHITE
var sub_text := ""
var show_maps := true

func _ready() -> void:
	layer = 10
	var vs := Config.screen(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.size = vs
	add_child(dim)
	var c := Config.OUTLINE_P1 if winner == 0 else Config.OUTLINE_P2
	if title_text != "":
		c = title_color
	var title := Label.new()
	title.text = title_text if title_text != "" else "Победил Игрок %d!" % (winner + 1)
	title.size = Vector2(vs.x, 90)
	title.position = Vector2(0, 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", c)
	add_child(title)
	var score := Label.new()
	score.text = sub_text if sub_text != "" else "Раунды  %d : %d" % [rounds[0], rounds[1]]
	score.size = Vector2(vs.x, 50)
	score.position = Vector2(0, 205)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 32)
	add_child(score)
	var bw := 260.0
	var n := 3 if show_maps else 2
	var x := vs.x / 2 - (bw * n + 20 * (n - 1)) / 2
	var b1 := MainMenu.make_button(self, "Ещё раз", Vector2(x, 320), Vector2(bw, 80), 30)
	b1.pressed.connect(func(): again_pressed.emit())
	b1.set_meta("pad_default", true)
	add_to_group("pad_modal")           # бой закончен — кнопки выбираются геймпадом
	x += bw + 20
	if show_maps:
		var b2 := MainMenu.make_button(self, "Другая карта", Vector2(x, 320), Vector2(bw, 80), 30)
		b2.pressed.connect(func(): maps_pressed.emit())
		x += bw + 20
	var b3 := MainMenu.make_button(self, "В меню", Vector2(x, 320), Vector2(bw, 80), 30)
	b3.pressed.connect(func(): menu_pressed.emit())
