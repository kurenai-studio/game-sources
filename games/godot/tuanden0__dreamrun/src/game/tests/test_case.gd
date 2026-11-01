## Base for test scripts. Runner calls every `test_*` method (may await), `check` records failures.
extends RefCounted

var failures: Array[String] = []
var tree: SceneTree


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


## A "world" node holding a 4000 px wide floor whose top is y = 0 (x from -1500 to 2500); free the
## world to clean up everything added under it.
func make_world() -> Node2D:
	var world := Node2D.new()
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(4000, 40)
	shape.position = Vector2(500, 20)
	floor_body.add_child(shape)
	world.add_child(floor_body)
	tree.root.add_child(world)
	return world


func spawn_player(world: Node2D, x: float) -> PlayerController:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate() as PlayerController
	player.position = Vector2(x, -2)
	world.add_child(player)
	return player


## World with a platform (top at y = -163, left edge x = 180) and a ledge zone on its left edge;
## the climb ends at (200, -168).
func make_ledge_world() -> Node2D:
	var world := make_world()
	var platform := SolidProp.new()
	platform.position = Vector2(300, -150)
	platform.size = Vector2(240, 26)
	world.add_child(platform)
	var ledge := Ledge.new()
	ledge.position = Vector2(170, -120)
	world.add_child(ledge)
	return world


func release_all_inputs() -> void:
	for action in [&"move_left", &"move_right", &"jump", &"interact", &"climb_up"]:
		Input.action_release(action)
