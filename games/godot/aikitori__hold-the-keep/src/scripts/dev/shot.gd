extends Node
## Screenshots (braucht ein Fenster oder Xvfb): godot res://scenes/dev/shot.tscn -- <Ordner> <karte|menu>
## Baut Türme neben den Weg, spielt im Zeitraffer an und speichert Übersicht, Nahansicht und Turm-Karte.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if args.size() > 0 else "user://"
	var what: String = args[1] if args.size() > 1 else "vier_felder"
	if what == "icon":
		await _icon(folder)
		return
	if what == "menu":
		add_child(load("res://scenes/menu.tscn").instantiate())
		await _frames(4)
		get_viewport().get_texture().get_image().save_png(folder + "/menu.png")
		get_tree().quit()
		return
	if what == "gegner":
		await _enemies(folder)
		return
	Main.map_id = StringName(what)
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(2)
	main.gold = 5000
	var path := main.board.full_path()
	var kinds: Array[StringName] = [&"archer", &"bowman", &"mage", &"spearman", &"catapult", &"skyguard", &"ballista", &"trebuchet"]
	var built: Array[Tower] = []
	for i in range(4, path.size(), 3):
		for offset in [Vector2i(1, 1), Vector2i(-1, -1), Vector2i(2, 0), Vector2i(0, 2), Vector2i(-2, 0)]:
			var at: Vector2i = path[i] + offset
			if main.map.buildable(at) and not main.board.towers.has(at) and not path.has(at):
				var tower := main.try_build(kinds[built.size() % kinds.size()], at)
				if tower != null:
					built.append(tower)
					break
		if built.size() >= 22:
			break
	for i in built.size():
		if i % 3 == 0:
			built[i].upgrade()
		if i % 5 == 0:
			built[i].upgrade()
			built[i].upgrade()
			var options := built[i].spec_options()
			if not options.is_empty():
				built[i].specialize(options[i % 2]["id"])
	main.countdown = 0.1
	Engine.time_scale = 30.0
	await _frames(14)
	main.call_next_wave()
	Engine.time_scale = 12.0
	await _frames(6)
	Engine.time_scale = 0.0
	var focus := Board.world_of(path[path.size() / 4])
	main.rig.position = focus
	main.rig.camera.size = 11.0
	await _frames(2)
	get_viewport().get_texture().get_image().save_png("%s/%s_nah.png" % [folder, what])
	main.rig.position = Board.world_of(main.map.size / 2)
	main.rig.camera.size = maxf(main.map.size.x, main.map.size.y) * 0.62
	await _frames(2)
	get_viewport().get_texture().get_image().save_png("%s/%s_karte.png" % [folder, what])
	var special: Tower = built[0]
	for tower in built:
		if tower.level == 3 and tower.spec_id == &"":
			special = tower
	while special.level < 3:
		special.upgrade()
	main.select_tower(special)
	main.rig.position = special.position
	main.rig.camera.size = 8.0
	await _frames(2)
	get_viewport().get_texture().get_image().save_png("%s/%s_turm.png" % [folder, what])
	Engine.time_scale = 1.0
	get_tree().quit()


## Alle Gegnerarten in einer Reihe (zum Vergleich der Varianten).
func _enemies(folder: String) -> void:
	Main.map_id = &"weites_feld"
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(2)
	main.countdown = 1000.0
	var center := Vector3(main.map.size.x / 2.0, 0.0, main.map.size.y / 2.0)
	var i := 0
	for kind: StringName in Defs.ENEMIES:
		var enemy := Enemy.new()
		main.add_child(enemy)
		enemy.setup(kind, 1, main, main.board)
		enemy.set_process(false)
		enemy.position = center + Vector3(i * 1.3 - 7.0, enemy.position.y, -i * 1.3 + 7.0)
		enemy.rotation.y = PI * 0.25
		i += 1
	main.rig.position = center
	main.rig.camera.size = 12.0
	await _frames(4)
	get_viewport().get_texture().get_image().save_png(folder + "/gegner.png")
	get_tree().quit()


## App-Icon: Burgturm mit Fahnen auf einer Graskachel, 512 x 512.
func _icon(folder: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	var tile := Models.make("td/tile")
	tile.scale = Vector3(1.6, 1.0, 1.6)
	root.add_child(tile)
	var y := 0.2
	for key in ["castle/tower-square-base", "castle/tower-square-mid-windows", "castle/tower-square-roof"]:
		var part := Models.make(key)
		part.position.y = y
		root.add_child(part)
		y += Models.height(part)
	var flag := Models.make("castle/flag-banner-long")
	flag.position = Vector3(0.55, 0.2, 0.55)
	root.add_child(flag)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = y + 0.7
	viewport.add_child(cam)
	var center := Vector3(0, y * 0.5, 0)
	cam.look_at_from_position(center + Vector3(1, 0.8, 1).normalized() * 10.0, center, Vector3.UP)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -25, 0)
	viewport.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#3b2a1e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.78, 0.75)
	env.environment.ambient_light_energy = 0.6
	viewport.add_child(env)
	await _frames(4)
	viewport.get_texture().get_image().save_png(folder + "/icon.png")
	get_tree().quit()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
