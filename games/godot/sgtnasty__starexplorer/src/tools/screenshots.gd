# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Node
## Renders each screen and saves a PNG of it (needs a display, not --headless):
##
##     godot --path . res://tools/screenshots.tscn -- /output/dir
##
## Used to produce the images in docs/screenshots.

var _out := "res://docs/screenshots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	Game.save_path = "user://screenshot_save.json"
	Game.new_game(2024)
	var g := Game
	g.credits = 1850
	g.ship.cargo.add("iron", 9)
	g.ship.cargo.add("hydrogen", 6)
	g.ship.cargo.add("crystals", 3)
	var sys := g.system()
	for p in sys.planets:
		g.scan_planet(p)

	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	await _shot(main, "title", {}, "01_title")
	await _shot(main, "system", {}, "02_system")
	await _shot(main, "galaxy", {}, "03_galaxy")
	await _shot(main, "starbase", {}, "04_market")
	main.find_child("tab_1", true, false).grab_focus()
	await _capture("05_shipyard")
	main.find_child("tab_2", true, false).grab_focus()
	await _capture("06_crew")
	await _shot(main, "encounter", {"encounter": Encounter.create("pirate", 1, rng)}, "07_encounter")
	await _shot(main, "combat", {"encounter": Encounter.create("monster", 1, rng), "ambush": true}, "08_combat")
	Game.delete_save()
	get_tree().quit()


func _shot(main: Control, screen: String, params: Dictionary, file: String) -> void:
	main.goto(screen, params)
	await _capture(file)


func _capture(file: String) -> void:
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_out.path_join(file + ".png"))
