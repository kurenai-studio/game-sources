extends Node


# Overlays.

@onready var player_overlay := $OverlayCanvasLayer/PlayerOverlay

@onready var health_overlay := $OverlayCanvasLayer/PlayerOverlay/HealthOverlay

@onready var help_overlay := $OverlayCanvasLayer/PlayerOverlay/HelpOverlay

# Main Menu.

@onready var main_menu_base : Control = $MenuCanvasLayer/MainMenu

# Credits Menu.

@onready var credits_menu_base := $MenuCanvasLayer/CreditsMenu

# Help Menu.

@onready var help_menu_base := $MenuCanvasLayer/HelpMenu

# Game Over Menu.

@onready var game_over_menu_base := $MenuCanvasLayer/GameOverMenu


# Virtual methods.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_menu"):
		toggle_menu()
	elif event.is_action_pressed(&"open_help"):
		toggle_help()


func _ready() -> void:
	_ensure_texture_sizing()


# Callbacks.

func _on_help_overlay_help_pressed() -> void:
	open_help()


func _on_main_menu_credits_pressed() -> void:
	open_credits()


func _on_main_menu_help_pressed() -> void:
	open_help()


func _on_main_menu_quit_pressed() -> void:
	do_quit()



func _on_main_menu_continue_pressed() -> void:
	close_main_menu()


func _on_main_menu_restart_pressed() -> void:
	restart_game()


func _on_credits_menu_close_pressed() -> void:
	close_credits()


func _on_help_menu_close_pressed() -> void:
	close_help()


func _on_game_over_menu_quit_pressed() -> void:
	do_quit()


func _on_game_over_menu_restart_pressed() -> void:
	restart_game()


func _ensure_texture_sizing() -> void:
	preload("res://UI/Buttons/CheckRoundGrey.svg").set_size_override(Vector2i(16, 16))
	preload("res://UI/Buttons/CheckRoundGreyCircle.svg").set_size_override(Vector2i(16, 16))
	preload("res://UI/Buttons/CheckSquareGrey.svg").set_size_override(Vector2i(24, 24))
	preload("res://UI/Buttons/CheckSquareGreyCheckmark.svg").set_size_override(Vector2i(24, 24))

	preload("res://UI/Panels/PanelGlass.svg").set_size_override(Vector2i(64, 64))
	preload("res://UI/Panels/PanelGlassScrews.svg").set_size_override(Vector2i(64, 64))
	preload("res://UI/Panels/PanelSquare.svg").set_size_override(Vector2i(64, 64))

	preload("res://UI/Sliders/BarRoundSmall.svg").set_size_override(Vector2i(96, 16))
	preload("res://UI/Sliders/BarRoundSmallSquare.svg").set_size_override(Vector2i(16, 16))
	preload("res://UI/Sliders/BarShadowRoundOutlineSmall.svg").set_size_override(Vector2i(96, 16))


# Helper methods.

func open_main_menu() -> void:
	main_menu_base.visible = true
	player_overlay.visible = false
	get_tree().paused = true

func close_main_menu() -> void:
	main_menu_base.visible = false
	player_overlay.visible = true
	get_tree().paused = false

func toggle_menu() -> void:
	if game_over_menu_base.visible:
		return

	if credits_menu_base.visible:
		close_credits()
	elif help_menu_base.visible:
		close_help()
	elif main_menu_base.visible:
		close_main_menu()
	else:
		open_main_menu()


func toggle_help() -> void:
	if help_menu_base.visible:
		close_help()
	else:
		open_help()


func open_credits() -> void:
	credits_menu_base.visible = true


func close_credits() -> void:
	credits_menu_base.visible = false


func open_help() -> void:
	if not main_menu_base.visible:
		get_tree().paused = true

	help_menu_base.visible = true


func close_help() -> void:
	if not main_menu_base.visible:
		get_tree().paused = false

	help_menu_base.visible = false


func restart_game() -> void:
	# TODO: Move to game state helper.
	get_tree().reload_current_scene()
	main_menu_base.visible = false
	player_overlay.visible = true
	game_over_menu_base.visible = false
	get_tree().paused = false


func do_quit() -> void:
	# TODO: Add confirmation.
	get_tree().quit()


func update_health(lives: int) -> void:
	health_overlay.update_health(lives)


func game_over() -> void:
	game_over_menu_base.visible = true
	get_tree().paused = true
