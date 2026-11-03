extends Node
## Scripted capture used for README screenshots: `godot --path . -- --tour=docs`.
## Walks the menus, plays with the autopilot, forces an upgrade pick, a boss wave and the results screen.

var _dir: String


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dir = GameState.tour_dir
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := _dir.path_join(file_name)
	img.save_png(path)
	print("Saved ", path)


func _run() -> void:
	SaveSystem.path = "user://tour_save.json"
	SaveSystem.data = SaveSystem.default_data()
	SaveSystem.data["coins"] = 1340
	SaveSystem.data["unlocked_characters"] = ["vanguard", "ranger"]
	SaveSystem.data["meta"] = {"vitality": 2, "power": 1, "magnet": 1}
	SaveSystem.data["stats"]["best_score"] = 18450
	SaveSystem.data["achievements"] = ["first_blood", "survivor"]
	EventBus.wallet_changed.emit(SaveSystem.get_coins())
	await _wait(2.5)
	await _shot("01_main_menu.png")
	var menu := get_tree().current_scene
	menu.show_page("play")
	await _wait(1.2)
	menu.show_page("settings")
	await _wait(1.0)
	await _shot("02_settings.png")
	GameState.start_run(&"ranger")
	await _wait(3.0)
	var game := get_tree().current_scene
	game.debug_grant(&"multishot", 2)
	game.debug_grant(&"piercing", 1)
	game.debug_jump_to_wave(8)
	await _wait(4.5)
	await _shot("03_gameplay.png")
	game.debug_force_upgrade()
	await _wait(1.3)
	await _shot("04_upgrade_cards.png")
	while game.phase == game.Phase.CHOOSING:
		game.debug_pick_first()
		await _wait(0.6)
	game.debug_jump_to_wave(5)
	await _wait(8.0)
	await _shot("05_boss_fight.png")
	game.debug_game_over()
	await _wait(3.5)
	await _shot("06_results.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://tour_save.json"))
	get_tree().quit()
