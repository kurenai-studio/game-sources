extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var btn := Button.new()
	btn.text = "Play Again"
	btn.size = Vector2(160, 44)
	btn.position = Vector2((SCREEN_W - 160.0) * 0.5, SCREEN_H * 0.5 + 60.0)
	btn.pressed.connect(_on_play_again)
	layer.add_child(btn)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), Palette.COLOR_GAME_OVER_BG, true)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(SCREEN_W * 0.5 - 200.0, SCREEN_H * 0.5 - 40.0),
			"GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 72, Palette.COLOR_GAME_OVER_TITLE)
	draw_string(font, Vector2(SCREEN_W * 0.5 - 200.0, SCREEN_H * 0.5 + 20.0),
			"All mages have fallen.", HORIZONTAL_ALIGNMENT_CENTER, 400.0, 20, Palette.COLOR_GAME_OVER_SUB)
	draw_string(font, Vector2(SCREEN_W * 0.5 - 200.0, SCREEN_H * 0.5 + 48.0),
			"Battles won: %d" % GameState.battle_count,
			HORIZONTAL_ALIGNMENT_CENTER, 400.0, 18, Palette.COLOR_GAME_OVER_SUB)


func _on_play_again() -> void:
	GameState.reset_to_new_game()
	get_tree().change_scene_to_file("res://scenes/loot/loot_screen.tscn")
