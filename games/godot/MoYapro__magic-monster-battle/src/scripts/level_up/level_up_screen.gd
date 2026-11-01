extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const HEADER_H := 48.0
const BOTTOM_BAR_H := 38.0

const CARD_W := 340.0
const CARD_H := 210.0
const CARD_GAP := 30.0
const CARD_Y := HEADER_H + (SCREEN_H - HEADER_H - BOTTOM_BAR_H - CARD_H) * 0.5
const CARDS_TOTAL_W := 3.0 * CARD_W + 2.0 * CARD_GAP
const CARD_MARGIN := (SCREEN_W - CARDS_TOTAL_W) * 0.5

const OPTION_H := 50.0
const OPTION_PAD := 12.0
const HP_GAIN := 10
const MANA_GAIN := 1

var _mages: Array[MageData] = []
var _heal_button: Button = null


func _ready() -> void:
	_mages = GameState.mages
	_build_bottom_bar()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), Palette.COLOR_BG, true)
	_draw_header()
	for i in _mages.size():
		_draw_mage_card(i)
	_draw_bottom_bar_bg()


func _draw_header() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, HEADER_H)), Palette.COLOR_HEADER_BG, true)
	draw_rect(Rect2(Vector2(0, HEADER_H - 1), Vector2(SCREEN_W, 1)), Palette.COLOR_BORDER, true)
	draw_string(ThemeDB.fallback_font,
			Vector2(SCREEN_W * 0.5, HEADER_H * 0.5 + 9.0),
			"Level Up", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, Palette.COLOR_TEXT_BRIGHT)


func _card_x(i: int) -> float:
	return CARD_MARGIN + i * (CARD_W + CARD_GAP)


func _option_rect(mage_i: int, stat: String) -> Rect2:
	var x := _card_x(mage_i) + OPTION_PAD
	var w := CARD_W - OPTION_PAD * 2.0
	var y := CARD_Y + 50.0 + (0.0 if stat == "hp" else OPTION_H + 8.0)
	return Rect2(Vector2(x, y), Vector2(w, OPTION_H))


func _draw_mage_card(i: int) -> void:
	var mage := _mages[i]
	var x := _card_x(i)
	draw_rect(Rect2(Vector2(x, CARD_Y), Vector2(CARD_W, CARD_H)), Palette.COLOR_PANEL, true)
	draw_rect(Rect2(Vector2(x, CARD_Y), Vector2(CARD_W, CARD_H)), Palette.COLOR_BORDER, false, 1.0)
	draw_string(ThemeDB.fallback_font,
			Vector2(x + OPTION_PAD, CARD_Y + 26.0),
			mage.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.COLOR_TEXT_BRIGHT)
	var hp_frac := clampf(float(mage.current_hp) / float(mage.max_hp), 0.0, 1.0)
	var hp_color := Palette.COLOR_HP_FULL.lerp(Palette.COLOR_HP_LOW, 1.0 - hp_frac)
	var name_w := ThemeDB.fallback_font.get_string_size(mage.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(ThemeDB.fallback_font,
			Vector2(x + OPTION_PAD + name_w + 8.0, CARD_Y + 24.0),
			"%d / %d HP" % [mage.current_hp, mage.max_hp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, hp_color)
	_draw_option(i, "hp",   "Max HP",    mage.max_hp,          HP_GAIN)
	_draw_option(i, "mana", "Mana / turn", mage.mana_allowance, MANA_GAIN)


func _draw_option(mage_i: int, stat: String, label: String, current: int, gain: int) -> void:
	var r := _option_rect(mage_i, stat)
	draw_rect(r, Palette.COLOR_OPTION_BG, true)
	draw_rect(r, Palette.COLOR_BORDER, false, 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(r.position.x + 8.0, r.position.y + 16.0),
			label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.COLOR_SECTION)
	draw_string(font, Vector2(r.position.x + 8.0, r.position.y + 36.0),
			"%d  →  %d" % [current, current + gain],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.COLOR_TEXT_STAT)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := (event as InputEventMouseButton).position
	for i in _mages.size():
		for stat in ["hp", "mana"]:
			if _option_rect(i, stat).has_point(pos):
				get_viewport().set_input_as_handled()
				_apply_upgrade(i, stat)
				return


func _draw_bottom_bar_bg() -> void:
	var bar_y := SCREEN_H - BOTTOM_BAR_H
	draw_rect(Rect2(Vector2(0, bar_y), Vector2(SCREEN_W, BOTTOM_BAR_H)), Palette.COLOR_HEADER_BG, true)
	draw_rect(Rect2(Vector2(0, bar_y), Vector2(SCREEN_W, 1)), Palette.COLOR_BORDER, true)


func _build_bottom_bar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_heal_button = Button.new()
	_heal_button.text = "Heal All ♥"
	_heal_button.size = Vector2(148, BOTTOM_BAR_H - 10)
	_heal_button.position = Vector2(SCREEN_W - 156.0, SCREEN_H - BOTTOM_BAR_H + 5.0)
	_heal_button.pressed.connect(_on_heal_all_pressed)
	layer.add_child(_heal_button)


func _on_heal_all_pressed() -> void:
	for mage: MageData in _mages:
		if mage.current_hp <= 0:
			mage.current_hp = int(mage.max_hp * 0.3)
		else:
			var heal := int(mage.max_hp * 0.8)
			mage.current_hp = mini(mage.max_hp, mage.current_hp + heal)
	GameState.mages = _mages
	get_tree().change_scene_to_file("res://scenes/world/path_selection_screen.tscn")


func _apply_upgrade(mage_i: int, stat: String) -> void:
	var mage := _mages[mage_i]
	if stat == "hp":
		mage.max_hp += HP_GAIN
		mage.current_hp = mini(mage.max_hp, mage.current_hp + HP_GAIN)
	else:
		mage.mana_allowance += MANA_GAIN
	GameState.mages = _mages
	get_tree().change_scene_to_file("res://scenes/world/path_selection_screen.tscn")
