extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const HEADER_H := 48.0

const CARD_W := 500.0
const CARD_H := 360.0
const CARD_GAP := 40.0
const CARDS_TOTAL_W := 2.0 * CARD_W + CARD_GAP
const CARD_X_LEFT  := (SCREEN_W - CARDS_TOTAL_W) * 0.5
const CARD_X_RIGHT := CARD_X_LEFT + CARD_W + CARD_GAP
const CARD_Y := HEADER_H + (SCREEN_H - HEADER_H - CARD_H) * 0.5

var _choices: Array[BiomeData] = []


func _ready() -> void:
	_pick_choices()


func _pick_choices() -> void:
	var pool := BiomesData.unlocked(GameState.battle_count_by_biome)
	pool.shuffle()
	_choices = [pool[0], pool[1]]


func _card_x(i: int) -> float:
	return CARD_X_LEFT if i == 0 else CARD_X_RIGHT


func _card_rect(i: int) -> Rect2:
	return Rect2(Vector2(_card_x(i), CARD_Y), Vector2(CARD_W, CARD_H))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), Palette.COLOR_BG, true)
	_draw_header()
	for i in _choices.size():
		_draw_card(i)


func _draw_header() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, HEADER_H)), Palette.COLOR_HEADER_BG, true)
	draw_rect(Rect2(Vector2(0, HEADER_H - 1), Vector2(SCREEN_W, 1)), Palette.COLOR_BORDER, true)
	draw_string(ThemeDB.fallback_font,
			Vector2(SCREEN_W * 0.5, HEADER_H * 0.5 + 9.0),
			"Choose your path", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Palette.COLOR_TEXT_BRIGHT)


func _draw_card(i: int) -> void:
	var biome := _choices[i]
	var r := _card_rect(i)

	# Background with biome colour tint
	var tint := biome.color
	tint.a = 0.08
	draw_rect(r, Palette.COLOR_PANEL, true)
	draw_rect(r, tint, true)

	draw_rect(r, Color(biome.color, 0.35), false, 1.5)

	var font := ThemeDB.fallback_font
	var lx := r.position.x

	# Biome name
	var name_color := Color(biome.color.r * 1.4, biome.color.g * 1.4, biome.color.b * 1.4).clamp()
	draw_string(font,
			Vector2(lx, r.position.y + CARD_H * 0.42),
			biome.name, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 32, name_color)

	# Tagline
	draw_string(font,
			Vector2(lx + 20.0, r.position.y + CARD_H * 0.42 + 38.0),
			biome.tagline, HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 40.0, 13, Palette.COLOR_TEXT_DIM)

	# Level
	var level: int = GameState.battle_count_by_biome.get(biome.name, 0) + 1
	draw_string(font,
			Vector2(lx, r.position.y + CARD_H * 0.42 + 66.0),
			"Level %d" % level, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 12, Palette.COLOR_TEXT_DIM)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := (event as InputEventMouseButton).position
	for i in _choices.size():
		if _card_rect(i).has_point(pos):
			get_viewport().set_input_as_handled()
			GameState.current_biome = _choices[i]
			get_tree().change_scene_to_file("res://scenes/loot/loot_screen.tscn")
			return
