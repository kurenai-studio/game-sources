extends SceneTree
## Exercise the real Node2D simulation with deterministic input and fixture props.
## This tests gameplay behavior; it is not a physical-device performance claim.

const Gameplay = preload("res://scripts/gameplay.gd")
const Rules = preload("res://scripts/game_rules.gd")
var game: Node2D
var failures := 0
var checks := 0
var completions := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	game = Gameplay.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound_enabled = false
	game.round_finished.connect(func(_stats: Dictionary) -> void: completions += 1)
	game.start_round(0, 12345)
	var first_world: Array = game.objects.duplicate(true)
	game.start_round(0, 12345)
	_check(game.objects == first_world, "Fixed seed reproduces the entire world")
	_check(game.objects.size() > 150, "Round contains a full playable world")

	_fixture()
	var origin: Vector2 = game.player_position
	_touch_start(2, Vector2(200, 500))
	_touch_drag(2, Vector2(258, 500))
	_step(30)
	_check(game.player_position.x > origin.x + 80.0, "Touch drag moves through real acceleration")
	_check(absf(game.player_position.y - origin.y) < 0.1, "Horizontal drag stays horizontal")
	_touch_end(7)
	_check(game._touch_id == 2, "Other finger cannot release movement pointer")
	_touch_end(2)
	_step(20)
	var stopped: Vector2 = game.player_position
	_step(20)
	_check(game.player_position.distance_to(stopped) < 0.01, "Release over UI clears movement and stops drift")
	_touch_start(3, Vector2(200, 500))
	_touch_drag(3, Vector2(258, 500))
	var cancelled := InputEventScreenTouch.new()
	cancelled.index = 3
	cancelled.pressed = false
	cancelled.canceled = true
	game._input(cancelled)
	_check(game._touch_id == -1, "Cancelled touch clears ownership")
	_touch_start(4, Vector2(200, 500))
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(game._touch_id == -1 and game.velocity == Vector2.ZERO, "Focus loss clears touch and velocity")

	_fixture()
	game._add_prop(0, game.player_position)
	_step(1)
	_check(game.score == 10 and game.absorbed == 1, "Small prop scores exactly once on capture")
	_check(game.radius > Rules.START_RADIUS and game.objects[0].state == 1, "Capture starts sink animation and growth")
	var frozen_time: float = game.time_left
	var frozen_sink: float = game.objects[0].sink
	var frozen_radius: float = game.shown_radius
	game.set_paused(true)
	_step(60)
	_check(game.time_left == frozen_time and game.objects[0].sink == frozen_sink, "Pause freezes timer and absorption animation")
	_check(game.shown_radius == frozen_radius and game.score == 10, "Pause freezes growth visuals and score")
	game.set_paused(false)
	_step(60)
	_check(game.objects[0].state == 2 and game.score == 10, "Sink finishes without scoring twice")

	_fixture()
	var obstacle: Vector2 = game.player_position + Vector2(75, 0)
	game._add_prop(4, obstacle)
	_touch_start(1, Vector2(200, 500))
	_touch_drag(1, Vector2(258, 500))
	_step(120)
	var clearance: float = float(Rules.PROP_TYPES[4].radius) * 0.70 + Rules.START_RADIUS * 0.40
	_check(game.player_position.distance_to(obstacle) >= clearance - 0.01, "Oversized prop prevents physical overlap")
	_check(game.player_position.x < obstacle.x, "Continuous movement cannot pass through oversized prop")
	_check(game.score == 0 and game.radius == Rules.START_RADIUS and game.objects[0].state == 0, "Oversized prop gives no score or growth")
	_touch_end(1)

	_fixture()
	game.player_position = Vector2(43, 100)
	_touch_start(1, Vector2(200, 500))
	_touch_drag(1, Vector2(142, 500))
	_step(60)
	_check(game.player_position.x >= Rules.START_RADIUS + 12.0, "Hole stays within world bounds")
	_touch_end(1)

	_fixture()
	game._add_prop(0, game.player_position)
	_step(1)
	game.time_left = 0.01
	_step(2)
	_check(completions == 1 and not game.active and game.time_left == 0.0, "Timer emits one terminal result")
	var final_score: int = game.score
	_step(120)
	game._finish_round()
	_check(completions == 1 and game.score == final_score, "Finished round is immutable and cannot emit twice")
	game.start_round(2, 12345)
	_check(game.active and not game.paused and game.time_left == Rules.ROUND_SECONDS, "Replay restarts timer and simulation")
	_check(game.score == 0 and game.mass == 0.0 and game.combo == 0 and game.absorbed == 0, "Replay clears prior progression")
	_check(game.radius == Rules.START_RADIUS and game._touch_id == -1 and game.candidate == 2, "Replay resets size/input and applies chosen candidate")
	game.free()
	await process_frame
	await process_frame
	print("Integration: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _fixture() -> void:
	game.start_round(0, 42)
	game.objects.clear()
	game._grid.clear()
	game.set_physics_process(false)

func _step(count: int) -> void:
	for _i in range(count):
		game._physics_process(1.0 / 60.0)

func _touch_start(index: int, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = true
	game._unhandled_input(event)

func _touch_drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	game._input(event)

func _touch_end(index: int) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = Vector2(510, 20)
	event.pressed = false
	game._input(event)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
