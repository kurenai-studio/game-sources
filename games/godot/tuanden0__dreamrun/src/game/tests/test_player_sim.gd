## Bots that play like a person instead of exercising one feature: they walk, stop, turn round, hop over what
## is in the way and press the use key when something is at their feet, over the whole real test_room, with
## FlightRecorder watching for physics that cannot be right and for being stuck on open ground.
extends "res://tests/test_case.gd"

const WEST := -2900.0
const EAST := 2900.0


## No frame budget may be exceeded: a bot that cannot get anywhere must fail, not hang the whole run.
const MAX_FRAMES := 60000

var _spent := 0


## `monsters` = false removes the chase monster and the boss, for bots that only check the ground.
func _room(monsters: bool = true) -> Node2D:
	var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
	if not monsters:
		room.get_node("Monster").free()
		room.get_node("Boss").free()
	tree.root.add_child(room)
	_spent = 0
	return room


## Walks from `from_x` to `to_x`, stopping for a few frames every `stride` px (people do not hold a key for 6000 px,
## and standing still on a spot is what exposed the ground peak bug). Something it cannot hop over is skipped past,
## because puzzles are for the other bots. Returns where it ended.
func _stop_and_go(player: PlayerController, from_x: float, to_x: float, stride: float, rng: RandomNumberGenerator) -> float:
	var action := &"move_right" if to_x > from_x else &"move_left"
	var sign := 1.0 if to_x > from_x else -1.0
	player.position = Vector2(from_x, -3)
	player.velocity = Vector2.ZERO
	await frames(20)
	while (to_x - player.position.x) * sign > stride and _spent < MAX_FRAMES:
		var start := player.position.x
		Input.action_press(action)
		var waited := 0
		while absf(player.position.x - start) < stride and waited < 100:
			waited += 1
			_spent += 1
			if waited % 25 == 0 and player.is_on_wall():
				Input.action_press(&"jump")  # a person hops what blocks them
			await frames(1)
			Input.action_release(&"jump")
		Input.action_release(action)
		if absf(player.position.x - start) < stride * 0.5:
			player.position.x += sign * 170.0  # a door or a crate: skip it
		var rest := rng.randi_range(4, 12)
		_spent += rest
		await frames(rest)
	return player.position.x


func test_bot_walks_the_whole_ground_stop_and_go_both_ways() -> void:
	var room := _room(false)
	var player := room.get_node("Player") as PlayerController
	await frames(5)
	var rec := FlightRecorder.new(player, tree)
	rec.start()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for stride in [13.0, 29.0]:  # different strides so the stops land on different spots
		await _stop_and_go(player, WEST, EAST, stride, rng)
		await _stop_and_go(player, EAST, WEST, stride, rng)
	rec.stop()
	release_all_inputs()
	check(_spent < MAX_FRAMES, "the bot never got across the room")
	var stuck := rec.violations.filter(func(v: String) -> bool: return v.contains("stuck"))
	check(stuck.is_empty(), "stuck on open ground (%d):\n%s" % [stuck.size(), "\n".join(stuck.slice(0, 5))])
	# the bot's own skips past doors and crates are teleports, not game bugs
	var other := rec.violations.filter(func(v: String) -> bool: return not v.contains("stuck") and not v.contains("teleported"))
	check(other.is_empty(), "other violations:\n%s" % "\n".join(other.slice(0, 5)))
	room.queue_free()
	await frames(2)


## What a person does that a feature test does not: sets a goal, reacts a beat late, hops what is in the way, tries the
## use key and a crate when blocked for a while, gives up and walks away, pauses for no reason. It knows nothing about
## the puzzles: whatever it solves it solves by trying.
class Sim:
	var player: PlayerController
	var room: Node2D
	var rng: RandomNumberGenerator
	var tree: SceneTree
	var frames_played := 0
	var deaths := 0
	var min_x := INF
	var max_x := -INF
	var interacts := 0
	var crate_pushes := 0
	var _blocked := 0
	var _mode := &"travel"
	var _mode_left := 0
	var _crate: Crate
	var _target: Node2D
	var _crate_last := 0.0
	var _crate_still := 0
	var _crate_start := 0.0

	func _init(p_player: PlayerController, p_room: Node2D, p_rng: RandomNumberGenerator, p_tree: SceneTree) -> void:
		player = p_player
		room = p_room
		rng = p_rng
		tree = p_tree
		player.died.connect(func() -> void: deaths += 1)

	func _press(action: StringName, down: bool) -> void:
		if down:
			Input.action_press(action)
		else:
			Input.action_release(action)

	func _walk(dir: int) -> void:
		_press(&"move_left", dir < 0)
		_press(&"move_right", dir > 0)

	func _nearest_crate() -> Crate:
		var best: Crate = null
		for node in tree.get_nodes_in_group(&"grabbable"):
			if node is Crate and (best == null or absf(node.global_position.x - player.global_position.x) < absf(best.global_position.x - player.global_position.x)):
				best = node
		return best

	## Seeing a door open is what tells a person to stop pushing.
	func _a_door_is_open() -> bool:
		for node in tree.get_nodes_in_group(&"resettable"):
			if node is Door and node.is_open and absf(node.global_position.x - player.global_position.x) < 700.0:
				return true
		return false

	func _nearest_usable() -> Node2D:
		var best: Node2D = null
		for node in tree.get_nodes_in_group(&"usable"):
			if best == null or absf(node.global_position.x - player.global_position.x) < absf(best.global_position.x - player.global_position.x):
				best = node
		return best

	## Plays `max_frames` physics frames towards `goal_x`, one decision every few frames.
	func play(goal_x: float, max_frames: int) -> bool:
		var played := 0
		while played < max_frames:
			var think := rng.randi_range(4, 10)  # reaction time
			_decide(goal_x, think)
			for i in think:
				await tree.physics_frame
			played += think
			frames_played += think
			min_x = minf(min_x, player.global_position.x)
			max_x = maxf(max_x, player.global_position.x)
			if absf(player.global_position.x - goal_x) < 60.0:
				_release_all()
				return true
		_release_all()
		return false

	func _release_all() -> void:
		for action in [&"move_left", &"move_right", &"jump", &"interact", &"climb_up"]:
			Input.action_release(action)

	func _tap_pause() -> void:
		for pressed in [true, false]:
			var event := InputEventAction.new()
			event.action = &"pause"
			event.pressed = pressed
			Input.parse_input_event(event)

	func _decide(goal_x: float, think: int) -> void:
		# people stop to think: open the menu now and then, close it a moment later
		if tree.paused:
			if rng.randf() < 0.4:
				_tap_pause()
			return
		if rng.randf() < 0.006 and not player.is_dead:
			_tap_pause()
		if player.is_dead:
			_release_all()
			return
		var dir := 1 if goal_x > player.global_position.x else -1
		_mode_left -= think
		if _mode_left <= 0 and _mode != &"travel":
			_enter(&"travel", 0)
		match _mode:
			&"travel":
				_walk(dir)
				if absf(player.velocity.x) > 20.0:
					_blocked = 0  # getting somewhere
				elif player.grabbed == null and (player.is_on_floor() or player.is_on_wall()):
					_blocked += think  # hopping does not reset it
				if _blocked > 8 and rng.randf() < 0.7:
					_press(&"jump", true)  # hop it
				else:
					_press(&"jump", rng.randf() < 0.03)  # idle hopping
				if rng.randf() < 0.02:
					_enter(&"pause", rng.randi_range(20, 80))
				elif _blocked > 90:
					var roll := rng.randf()
					var crate := _nearest_crate()
					var usable := _nearest_usable()
					if crate != null and roll < 0.45 and absf(crate.global_position.x - player.global_position.x) < 900.0:
						_crate = crate
						_crate_start = crate.global_position.x
						_crate_last = _crate_start
						_crate_still = 0
						_enter(&"fetch", 600)
					elif usable != null and roll < 0.9 and absf(usable.global_position.x - player.global_position.x) < 700.0:
						_target = usable
						_enter(&"use", 500)
					else:
						_press(&"interact", true)  # try it right here
						interacts += 1
						_enter(&"tap", 6)
				elif _blocked > 400:
					_enter(&"retreat", 120)
			&"pause":
				_walk(0)
			&"tap":
				pass
			&"retreat":
				_walk(-dir)
			&"use":
				var gap := _target.global_position.x - player.global_position.x
				if absf(gap) > 14.0:
					_walk(1 if gap > 0.0 else -1)
				else:
					_walk(0)
					_press(&"interact", true)
					interacts += 1
					_enter(&"tap", 8)
			&"fetch":
				# stand on the far side of the crate from the goal, then push it towards the goal
				var spot := _crate.global_position.x - dir * 52.0
				var off := spot - player.global_position.x
				if absf(off) > 14.0:
					_walk(1 if off > 0.0 else -1)
					_press(&"interact", false)
				else:
					_walk(0)
					_press(&"interact", true)
					_enter(&"push", 900)
			&"push":
				_press(&"interact", true)
				_walk(dir)
				if player.grabbed != null:
					crate_pushes += 1
				if absf(_crate.global_position.x - _crate_last) < 0.3:
					_crate_still += think
				else:
					_crate_still = 0
				_crate_last = _crate.global_position.x
				# done when it has stopped (against something) for a second, or we let go of it
				if _crate_still > 60 or _a_door_is_open() or (player.grabbed == null and _mode_left < 560):
					_enter(&"travel", 0)
		if _mode == &"fetch" or _mode == &"use":
			_press(&"jump", player.is_on_wall() and player.grabbed == null)  # hop what is in the way, like a person
		elif _mode != &"travel":
			_press(&"jump", false)  # only walking hops; jumping lets go of a crate
		if _mode != &"tap" and _mode != &"push" and _mode != &"fetch":
			_press(&"interact", false)

	func _enter(mode: StringName, frames_: int) -> void:
		_mode = mode
		_mode_left = frames_
		_blocked = 0 if mode == &"travel" else _blocked


func test_bot_plays_the_room_like_a_person_east_then_west() -> void:
	for seed_value in [1, 2, 3, 4, 5]:
		var room := _room()
		var player := room.get_node("Player") as PlayerController
		await frames(10)
		var rec := FlightRecorder.new(player, tree)
		rec.start()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var sim := Sim.new(player, room, rng, tree)
		var east := await sim.play(2800.0, 60 * 120)
		var west := await sim.play(-1450.0, 60 * 120)  # up to the boss pen: that fight is the boss bot's
		rec.stop()
		release_all_inputs()
		print("sim seed %d: east=%s west=%s x=%d..%d deaths=%d interacts=%d pushes=%d frames=%d violations=%d" % [seed_value, east, west, sim.min_x, sim.max_x, sim.deaths, sim.interacts, sim.crate_pushes, sim.frames_played, rec.violations.size()])
		check(rec.violations.is_empty(), "seed %d violations (%d):
%s" % [seed_value, rec.violations.size(), rec.report(6)])
		check(sim.max_x - sim.min_x > 800.0, "seed %d barely moved: x=%d..%d" % [seed_value, sim.min_x, sim.max_x])
		room.queue_free()
		await frames(3)


## The back half of the room (chase, boulder trap, electric trap) where the doors no longer gate the bot.
func test_bot_plays_the_back_of_the_room_there_and_back() -> void:
	for seed_value in [1, 2, 3, 4, 5]:
		var room := _room()
		var player := room.get_node("Player") as PlayerController
		player.position = Vector2(1560.0, -3)
		await frames(10)
		var rec := FlightRecorder.new(player, tree)
		rec.start()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var sim := Sim.new(player, room, rng, tree)
		var east := await sim.play(2800.0, 60 * 90)
		var west := await sim.play(1500.0, 60 * 90)
		rec.stop()
		release_all_inputs()
		print("sim-back seed %d: east=%s west=%s x=%d..%d deaths=%d interacts=%d pushes=%d frames=%d violations=%d" % [seed_value, east, west, sim.min_x, sim.max_x, sim.deaths, sim.interacts, sim.crate_pushes, sim.frames_played, rec.violations.size()])
		check(rec.violations.is_empty(), "seed %d violations (%d):\n%s" % [seed_value, rec.violations.size(), rec.report(6)])
		room.queue_free()
		await frames(3)
