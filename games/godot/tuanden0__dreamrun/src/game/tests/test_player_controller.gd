extends "res://tests/test_case.gd"

const PLAYER := preload("res://scenes/player.tscn")


## Player standing on a 2000 px wide floor whose top is y = 0, both under one "world" node
## (player.get_parent()) so the test can free everything at once. With stub_visual the art node is
## replaced by an empty Node2D: gameplay must not depend on it.
func _world(stub_visual: bool) -> PlayerController:
	var world := Node2D.new()
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 40)
	shape.shape = rect
	shape.position = Vector2(0, 20)
	floor_body.add_child(shape)
	world.add_child(floor_body)
	var player := PLAYER.instantiate() as PlayerController
	if stub_visual:
		var visual := player.get_node("Visual")
		player.remove_child(visual)
		visual.free()
		var stub := Node2D.new()
		stub.name = "Visual"
		player.add_child(stub)
	player.position = Vector2(0, -2)
	world.add_child(player)
	tree.root.add_child(world)
	return player


func _scenarios(stub_visual: bool) -> void:
	var player := _world(stub_visual)
	var label := "[stub=%s] " % stub_visual
	await frames(20)
	check(player.is_on_floor() and player.state == &"idle", label + "should settle idle on floor, state=%s" % player.state)

	Input.action_press(&"move_right")
	await frames(60)
	check(player.position.x > 100.0, label + "should run right, x=%s" % player.position.x)
	check(player.state == &"run", label + "state should be run, got %s" % player.state)
	Input.action_release(&"move_right")
	await frames(30)

	var seen: Array[StringName] = []
	player.state_changed.connect(func(s: StringName) -> void: seen.append(s))
	Input.action_press(&"jump")
	await frames(2)
	Input.action_release(&"jump")
	check(player.velocity.y < 0.0 or seen.has(&"jump"), label + "jump should lift off, vy=%s seen=%s" % [player.velocity.y, seen])
	await frames(90)
	check(seen.has(&"jump") and seen.has(&"fall"), label + "should pass through jump then fall: %s" % [seen])
	check(player.is_on_floor(), label + "should land again")
	player.get_parent().queue_free()
	await frames(1)


func test_controller_with_visual() -> void:
	await _scenarios(false)


func test_controller_with_stub_visual() -> void:
	await _scenarios(true)
