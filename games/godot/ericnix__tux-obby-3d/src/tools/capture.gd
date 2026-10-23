extends Node
## Ferramenta de desenvolvimento: abre o jogo, percorre o nível e salva capturas.
## Uso: godot --path . --scene res://tools/capture.tscn

const OUT_DIR := "/tmp/opencode/tux_shots/"

var main: Node3D


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	main = load("res://scenes/main.tscn").instantiate()
	main.auto_pause_enabled = false
	add_child(main)
	await get_tree().create_timer(1.2).timeout
	await _shot("01_menu")

	main.start_game()
	await get_tree().create_timer(1.0).timeout
	await _shot("02_start")

	# Close-up do Tux, sem HUD
	main.hud.visible = false
	main.player.set_frozen(true)
	var closeup := Camera3D.new()
	main.add_child(closeup)
	closeup.fov = 40.0
	closeup.global_position = main.player.global_position + Vector3(2.3, 1.65, -3.1)
	closeup.look_at(main.player.global_position + Vector3(0, 0.95, 0))
	closeup.current = true
	var closeup_fill := OmniLight3D.new()
	closeup_fill.light_color = Color("ffe6c4")
	closeup_fill.light_energy = 11.0
	closeup_fill.omni_range = 12.0
	closeup_fill.omni_attenuation = 1.7
	closeup_fill.light_cull_mask = 2
	closeup.add_child(closeup_fill)
	await get_tree().create_timer(0.4).timeout
	await _shot("03_tux")
	main.hud.visible = true
	main.player.camera_rig.activate()

	main.hud.hint_label.visible = false
	for i in range(1, main.level.checkpoint_spawns.size()):
		var pos: Vector3 = main.level.checkpoint_spawns[i]
		main.player.respawn(pos, 0.0)
		main.player.set_frozen(true)
		await get_tree().create_timer(0.6).timeout
		await _shot("%02d_cp%d" % [i + 3, i])

	# Chegada
	main.player.respawn(Vector3(2.0, 16.45, -164.5), 0.0)
	main.player.set_frozen(true)
	await get_tree().create_timer(0.6).timeout
	await _shot("09_finish")

	# Vista aérea do percurso
	var overview := Camera3D.new()
	main.add_child(overview)
	overview.fov = 70.0
	overview.far = 500.0
	overview.global_position = Vector3(38, 34, 22)
	overview.look_at(Vector3(0, 4, -80))
	overview.current = true
	await get_tree().create_timer(0.5).timeout
	await _shot("10_overview")

	overview.global_position = Vector3(20, 40, -120)
	overview.look_at(Vector3(0, 12, -155))
	await get_tree().create_timer(0.3).timeout
	await _shot("11_overview_final")

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("CAPTURAS CONCLUIDAS")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := OUT_DIR + name + ".png"
	image.save_png(path)
	print("shot: ", path, " ", image.get_size())
