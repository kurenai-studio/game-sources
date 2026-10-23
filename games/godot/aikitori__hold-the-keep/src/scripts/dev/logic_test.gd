extends Node
## Test ohne Fenster: Wegfindung, Bauregeln, Wellen und ein kurzer Spielablauf mit Türmen.
## Start: godot --headless res://scenes/dev/logic_test.tscn

var _failed := false


func _check(ok: bool, text: String) -> void:
	print(("ok:   " if ok else "FAIL: ") + text)
	if not ok:
		_failed = true


func _ready() -> void:
	for id: StringName in Sfx.VOLUME:
		_check(Sfx._streams[id] is AudioStream, "Klang %s geladen" % id)
	Sfx.muted = true  # Wiedergaben, die beim Beenden noch laufen, meldet Godot als hängend.
	var map := MapData.load_map(&"vier_felder")
	_check(map.spawn != Vector2i(-1, -1) and map.keep != Vector2i(-1, -1), "Karte hat Friedhof und Burg")
	var board := Board.new(map)
	var path := board.full_path()
	_check(path.size() > 40 and path[-1] == map.keep, "Weg vom Friedhof zur Burg führt durch alle Felder (%d Schritte)" % path.size())
	var grass_step := Vector2i(-1, -1)
	for cell in path:
		if map.cell(cell) == MapData.Cell.GRASS:
			grass_step = cell
			break
	var preview := board.full_path_with(grass_step)
	_check(not preview.has(grass_step) and preview[-1] == map.keep and board.full_path() == path,
			"Wegvorschau umgeht das geplante Feld und ändert den Weg nicht")
	_check(board.check_build(Vector2i(19, 10)) == Board.BuildCheck.NOT_GRASS, "Auf dem festen Weg kann nicht gebaut werden")
	_check(board.check_build(Vector2i(0, 0)) == Board.BuildCheck.NOT_GRASS, "Im Wald kann nicht gebaut werden")
	# Ausgang von Feld A (x 17, y 2..11) zumauern: der letzte Stein muss abgelehnt werden.
	var refused := -1
	for y in range(2, 12):
		var at := Vector2i(17, y)
		if board.check_build(at) == Board.BuildCheck.OK:
			board.place(at, true)
		else:
			refused = y
	_check(refused >= 0 and board.check_build(Vector2i(17, refused)) == Board.BuildCheck.BLOCKS_PATH,
			"Der Weg lässt sich nicht ganz versperren (abgelehnt bei y=%d)" % refused)
	# Zickzack in Feld A: zwei Riegel mit Lücke unten und oben.
	var maze := Board.new(map)
	for y in range(2, 11):
		maze.place(Vector2i(7, y), true)
	for y in range(3, 12):
		maze.place(Vector2i(13, y), true)
	var longer := maze.full_path()
	_check(maze.path_length(longer) > board.path_length(path) + 10.0,
			"Mauern machen den Weg länger (%.1f statt %.1f)" % [maze.path_length(longer), board.path_length(path)])
	_check(board.check_build(Vector2i(5, 5), [[Vector2i(5, 5), map.keep]]) == Board.BuildCheck.ENEMY_THERE, "Nicht auf Gegnern bauen")
	var flight: Array = maze.flight_legs[-1]
	_check(flight[0] == map.spawn and flight[-1] == map.keep and maze.flight_lengths[-1] > 40.0
			and maze.flight_legs == board.flight_legs,
			"Flieger folgen dem Grundweg durch alle Felder, Türme ändern die Route nicht (%.1f)" % maze.flight_lengths[-1])
	_test_maps()
	var boss_wave := Defs.wave(5)
	_check(boss_wave[0] == &"vampire" and Defs.wave(10)[0] == &"keeper", "Bosse in Welle 5 und 10")
	var seen := {}
	for n in range(1, Defs.WAVES + 1):
		for kind in Defs.wave(n):
			seen[kind] = true
	_check(seen.size() == Defs.ENEMIES.size(), "Alle %d Gegnerarten kommen vor (%d)" % [Defs.ENEMIES.size(), seen.size()])
	var mixed := {}
	for kind in Defs.wave(12):
		mixed[kind] = true
	_check(mixed.size() >= 3 and Defs.wave(12) == Defs.wave(12), "Welle 12 gemischt und immer gleich")
	_check(Defs.upgrade_cost(&"archer", 3) == -1 and Defs.upgrade_cost(&"wall", 1) == -1, "Ausbau endet bei Stufe 3, Mauern nie")
	await _play()
	print("LOGIC-TEST ", "FEHLGESCHLAGEN" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


## Alle Karten: Weg über alle Kontrollpunkte, Hochfläche bebaubar ohne den Weg zu ändern.
func _test_maps() -> void:
	for id: StringName in MapData.ORDER:
		var map := MapData.load_map(id)
		var board := Board.new(map)
		var path := board.full_path()
		var visits := true
		for point in map.waypoints:
			visits = visits and path.has(point)
		_check(map.spawn.x >= 0 and path.size() > 20 and visits and path[-1] == map.keep,
				"Karte %s: Weg über %d Ziele, %d Schritte" % [id, map.waypoints.size(), path.size()])
		var high := Vector2i(-1, -1)
		for y in map.size.y:
			for x in map.size.x:
				if high.x < 0 and map.cell(Vector2i(x, y)) == MapData.Cell.HIGH:
					high = Vector2i(x, y)
		if high.x >= 0:
			var before := board.full_path().size()
			_check(board.check_build(high) == Board.BuildCheck.OK, "Karte %s: Hochfläche bebaubar" % id)
			board.place(high, true)
			_check(board.full_path().size() == before, "Karte %s: Turm auf der Hochfläche ändert den Weg nicht" % id)
	_check(Defs.is_air_wave(4) and Defs.wave(4).all(func(k: StringName) -> bool: return Defs.ENEMIES[k].get("air", false)),
			"Welle 4 ist eine Luftwelle")
	for id: StringName in Defs.SPECS:
		_check((Defs.SPECS[id] as Array).size() == 2, "%s hat zwei Spezialisierungen" % id)


## Ziehen mit einem Finger: der gegriffene Bodenpunkt bleibt unter dem Finger, auch in kleinen Schritten.
## Zwei Finger zoomen, danach zieht der übrige Finger ohne Sprung weiter.
func _test_touch_drag(main: Main) -> void:
	var rig := main.rig
	var start := Vector2(640, 360)
	var grabbed := rig.ground_point(start, 0.0)
	var before := rig.position
	main._unhandled_input(_touch(0, start, true))
	var at := start
	for i in 40:
		at += Vector2(-3, 2)
		main._unhandled_input(_drag_event(0, at))
	var slip := Vector2(rig.ground_point(at, 0.0).x - grabbed.x, rig.ground_point(at, 0.0).z - grabbed.z).length()
	_check(rig.position.distance_to(before) > 1.0 and slip < 0.01,
			"Karte folgt dem Finger (%.2f Felder bewegt, Abweichung %.3f)" % [rig.position.distance_to(before), slip])
	# Weit über den Rand hinaus, dann ein kleines Stück zurück: die Kamera muss sofort folgen.
	for i in 100:
		at += Vector2(-40, -40)
		main._unhandled_input(_drag_event(0, at))
	var corner := rig.position
	at += Vector2(30, 30)
	main._unhandled_input(_drag_event(0, at))
	_check(rig.position.distance_to(corner) > 0.5, "Am Rand festgefahren, zurückziehen geht sofort (%.2f)" % rig.position.distance_to(corner))
	var size: float = rig.camera.size
	main._unhandled_input(_touch(1, at + Vector2(100, 0), true))
	main._unhandled_input(_drag_event(1, at + Vector2(200, 0)))
	_check(rig.camera.size < size, "Zwei Finger auseinander zoomen hinein")
	main._unhandled_input(_touch(1, at + Vector2(200, 0), false))
	var regrab := rig.ground_point(at, 0.0)
	main._unhandled_input(_drag_event(0, at + Vector2(1, 0)))
	main._unhandled_input(_drag_event(0, at))
	_check(rig.ground_point(at, 0.0).distance_to(regrab) < 0.01, "Nach dem Zoomen springt die Karte nicht")
	main._unhandled_input(_touch(0, at, false))
	_check(main.board.towers.is_empty() and not main._dragging, "Ziehen baut nichts")
	rig.camera.size = size


static func _touch(index: int, at: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	return event


static func _drag_event(index: int, at: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	return event


## Kurzer Ablauf: Türme an den Ausgang von Feld A, drei Wellen im Zeitraffer.
func _play() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	_test_touch_drag(main)
	main.gold = 2000
	var built := 0
	for at in [Vector2i(16, 9), Vector2i(16, 12 - 4), Vector2i(15, 10), Vector2i(14, 8), Vector2i(16, 6), Vector2i(13, 10)]:
		for id in [&"archer", &"bowman", &"spearman", &"mage", &"catapult", &"ballista"]:
			if main.board.towers.has(at):
				break
			if main.try_build(id, at) != null:
				built += 1
				break
	_check(built >= 5, "Türme gebaut (%d)" % built)
	var tower: Tower = main.board.towers.values()[0]
	main.select_tower(tower)
	main.upgrade_selected()
	_check(tower.level == 2, "Ausbau auf Stufe 2")
	main.upgrade_selected()
	var options := tower.spec_options()
	_check(tower.level == 3 and options.size() == 2, "Auf Stufe 3 zwei Spezialisierungen")
	main.specialize_selected(options[1]["id"])
	_check(tower.spec_id == options[1]["id"] and tower.spec_options().is_empty(), "Spezialisiert: %s" % tower.title())
	var sky: Tower = main.try_build(&"skyguard", Vector2i(15, 8))
	_check(sky != null and sky.targets() == "air", "Himmelswacht trifft nur Luft")
	Engine.time_scale = 8.0
	main.countdown = 0.1
	var waited := 0.0
	var early := false
	while main.wave < 4 and waited < 300.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		early = early or (main.countdown > 0.0 and not main.enemies.is_empty())
		if main.countdown > 0.0 and main.wave < 4:
			main.call_next_wave()
	for i in 600:
		if main.enemies.is_empty() and main._queue.is_empty():
			break
		await get_tree().process_frame
	Engine.time_scale = 1.0
	_check(main.kills > 10, "Türme töten Gegner (%d, Leben %d)" % [main.kills, main.lives])
	_check(not early, "Pause erst, wenn die Welle besiegt ist")
	_check(main.wave >= 4, "Vier Wellen gespielt, auch eine Luftwelle (%d)" % main.wave)
	var gold_before: int = main.gold
	main.select_tower(tower)
	main.sell_selected()
	_check(main.gold > gold_before and not main.board.towers.has(tower.cell), "Abreißen gibt Gold zurück")
	main.queue_free()
	await get_tree().process_frame
