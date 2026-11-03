extends SceneTree
## Headless smoke test: plays a scripted run through every enemy type,
## power-up and level-up, then checks the run ended in a clean game over.
## Run: godot --headless --fixed-fps 60 --path . -s res://tests/smoke_test.gd

const MAX_FRAMES := 7000

var game: Node
var frame := 0
var splitters_killed := 0
var pickups_seen := {}


func _initialize() -> void:
	game = load("res://main.tscn").instantiate()
	game.persist = false
	root.add_child(game)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 30:
		game.best = 0
		game._start()
		game.elapsed = 58.0  # skip ahead so darts and splitters spawn quickly
		game.invuln = 999.0
		game.pickup_timer = 0.0
	if frame > 30 and game.state == game.State.PLAYING:
		_drive()
	if frame > 30 and game.state == game.State.OVER:
		_finish()
	elif frame >= MAX_FRAMES:
		_fail("run never reached game over")
	return false


func _drive() -> void:
	if frame % 45 == 0:
		game._try_dash()
	if frame % 150 == 0:
		game.pickup_timer = 0.0
	for p in game.pickups:
		pickups_seen[p.kind] = true
	if frame % 120 == 0:
		for h in game.hunters:
			if h.kind == game.Kind.SPLITTER:
				game._kill(h, true)
				splitters_killed += 1
				break
	if frame % 7 == 0 and game.sparks.size() > 0:
		game.player = game.sparks[0].pos
	if frame == 2400:
		game.invuln = 0.0


func _finish() -> void:
	var checks := {
		"reached level 4": game.level >= 4,
		"scored points": game.score > 0,
		"built a combo": game.max_combo > 1,
		"killed a splitter": splitters_killed > 0,
		"spawned power-ups": pickups_seen.size() > 0,
		"loaded all sounds": game.sfx.size() == 9,
		"synthesized the music loop": game.music_stream != null and game.music_stream.data.size() > 0,
		"recorded the cause of death": game.killed_by != "",
	}
	var failed: Array[String] = []
	for name in checks:
		if not checks[name]:
			failed.append(name)
	print("level=%d score=%d kills=%d grazes=%d max_combo=%d splitters=%d killed_by=%s" % [game.level, game.score, game.kills, game.grazes, game.max_combo, splitters_killed, game.killed_by])
	if failed.is_empty():
		print("SMOKE OK")
		_quit(0)
	else:
		_fail(", ".join(failed))


func _fail(reason: String) -> void:
	printerr("SMOKE FAILED: " + reason)
	_quit(1)


func _quit(code: int) -> void:
	game.free()
	quit(code)
