extends SceneTree
## Full rounds using ordinary movement, collision, capture, growth, and timing.
const Gameplay = preload("res://scripts/gameplay.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := Gameplay.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound_enabled = false
	for candidate in range(3):
		for seed_value in [1, 42, 12345, 7788]:
			game.start_round(candidate, seed_value)
			game.set_demo_mode(true)
			for _tick in range(5401):
				game._physics_process(1.0 / 60.0)
			var stats: Dictionary = game.get_stats()
			print("Playthrough candidate=%d seed=%d absorbed=%d/%d level=%d score=%d" % [candidate, seed_value, stats.absorbed, stats.total, stats.level, stats.score])
			if stats.active or stats.time_left != 0.0 or stats.level < 6 or stats.absorbed < 120:
				failures += 1
				push_error("Round failed to finish or reach expected playable progression")
	game.free()
	print("Playthroughs: 12 rounds, %d failures" % failures)
	quit(1 if failures else 0)
