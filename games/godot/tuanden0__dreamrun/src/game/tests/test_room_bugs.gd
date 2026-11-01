## Bugs the user found by playing the real test_room, reproduced with bots on the real scene objects.
extends "res://tests/test_case.gd"


func _room() -> Node2D:
	var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
	tree.root.add_child(room)
	return room


func _hold(action: StringName, count: int) -> void:
	Input.action_press(action)
	await frames(count)
	Input.action_release(action)


func test_rope_hangs_still_until_someone_swings_it() -> void:
	var room := _room()
	var rope := room.get_node("Rope") as Rope
	await frames(300)
	check(absf(rope.angle) < deg_to_rad(1.0), "an untouched rope must hang still, swinging %s deg" % rad_to_deg(rope.angle))
	room.queue_free()
	await frames(2)


func test_holding_a_direction_never_traps_the_player_high_on_the_rope() -> void:
	var room := _room()
	var rope := room.get_node("Rope") as Rope
	var player := room.get_node("Player") as PlayerController
	player.position = rope.bob_position() + Vector2(0, 78)
	await frames(3)
	await _hold(&"interact", 2)
	check(rope.attached, "should be hanging")
	Input.action_press(&"move_right")
	var widest := 0.0
	var frozen := 0
	var longest_frozen := 0
	var last_angle := rope.angle
	for i in 900:
		await frames(1)
		widest = maxf(widest, absf(rope.angle))
		frozen = frozen + 1 if absf(rope.angle - last_angle) < 0.0005 else 0
		longest_frozen = maxi(longest_frozen, frozen)
		last_angle = rope.angle
	check(widest < deg_to_rad(65.0), "pumping must top out below 65 deg, reached %s" % rad_to_deg(widest))
	check(widest > deg_to_rad(20.0), "pumping should still build a real swing, only %s deg" % rad_to_deg(widest))
	check(longest_frozen < 20, "the swing must keep moving, it was frozen for %d frames" % longest_frozen)
	Input.action_release(&"move_right")
	room.queue_free()
	await frames(2)


func test_letting_go_at_speed_flings_the_player_along_the_swing() -> void:
	var room := _room()
	var rope := room.get_node("Rope") as Rope
	var player := room.get_node("Player") as PlayerController
	player.position = rope.bob_position() + Vector2(0, 78)
	await frames(3)
	await _hold(&"interact", 2)
	Input.action_press(&"move_right")
	for i in 600:
		await frames(1)
		if absf(rope.angle) < 0.05 and absf(rope.omega) > 1.5:  # passing the bottom at speed
			break
	Input.action_release(&"move_right")
	var swing := rope.bob_velocity()
	await _hold(&"jump", 2)
	await frames(2)
	check(not rope.attached, "jump lets go")
	check(absf(player.velocity.x) > 150.0 and absf(player.velocity.x) > absf(swing.x) * 0.7, "should fly off with the swing: swing %s, player %s" % [swing, player.velocity])
	room.queue_free()
	await frames(2)


func test_monster_is_not_visible_before_the_chase_starts() -> void:
	var room := _room()
	var monster := room.get_node("Monster") as Monster
	await frames(5)
	check(not monster.visible, "a dormant monster must not be standing around in the level")
	monster.start()
	await frames(2)
	check(monster.visible, "it appears when the chase starts")
	room.queue_free()
	await frames(2)


func test_space_plus_toward_the_platform_gets_onto_it_without_the_up_key() -> void:
	var room := _room()
	var player := room.get_node("Player") as PlayerController
	player.position = Vector2(540, -2)  # just left of the platform edge (x = 580), top at y = -163
	await frames(20)
	Input.action_press(&"move_right")
	await _hold(&"jump", 3)
	await frames(100)
	Input.action_release(&"move_right")
	check(player.position.x > 590.0 and player.position.y < -150.0, "should be standing on the platform, at %s" % player.position)
	room.queue_free()
	await frames(2)


func test_walking_off_the_platform_does_not_pull_you_back_up() -> void:
	var room := _room()
	var player := room.get_node("Player") as PlayerController
	player.position = Vector2(620, -170)  # standing on the platform near its left edge
	await frames(20)
	Input.action_press(&"move_left")
	await frames(90)
	Input.action_release(&"move_left")
	check(player.position.y > -20.0, "stepping off the edge means falling to the floor, at %s" % player.position)
	room.queue_free()
	await frames(2)


func test_can_jump_onto_the_boulder_and_the_crate_with_space_alone() -> void:
	var room := _room()
	var player := room.get_node("Player") as PlayerController
	player.position = Vector2(-400, -2)  # the boulder step sits at x = -300, 70 px high
	await frames(20)
	Input.action_press(&"move_right")
	await _hold(&"jump", 3)
	await frames(17)
	Input.action_release(&"move_right")  # drift to a stop above the boulder
	await frames(90)
	check(player.position.y < -50.0 and player.position.x > -360.0 and player.position.x < -240.0, "should be standing on the boulder, at %s" % player.position)
	room.queue_free()
	await frames(2)


## The ground used to carry random +-0.4 px noise between its vertices. Around x=2360 that left the player sunk 0.001 px into
## a peak, where every motion test reported a collision: standing there, no key moved the player at all.
func test_player_can_walk_off_the_ground_peak_at_x2360() -> void:
	var room := _room()
	var player := room.get_node("Player") as PlayerController
	await frames(5)
	for x in range(2340, 2388, 6):
		for direction in [&"move_left", &"move_right"]:
			player.position = Vector2(x, -3)
			player.velocity = Vector2.ZERO
			await frames(20)  # land and come to rest
			await _hold(direction, 20)
			check(absf(player.position.x - x) > 8.0, "stuck at x=%d pressing %s: moved %s px" % [x, direction, player.position.x - x])
	room.queue_free()
	await frames(2)
