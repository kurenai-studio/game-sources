## Animation contact sheet for visual checks (needs a display, not --headless):
## godot --path game --resolution 1280x720 --script ../tools/filmstrip.gd -- <out.png> <scenario>
## Scenarios: land, climb, rope, push, chase, run. One cell is the area around the player, sampled every few frames.
extends SceneTree

const CELL := Vector2i(420, 300)
const COLUMNS := 4


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var scenario: String = args[1]
	var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var player := room.get_node("Player") as PlayerController
	var plan := await _setup(scenario, player, room)
	var shots: Array[Image] = []
	for i in plan.count:
		for f in plan.every:
			await physics_frame
		await RenderingServer.frame_post_draw
		var screen := root.get_texture().get_image()
		var centre := screen.get_size() / 2
		shots.append(screen.get_region(Rect2i(centre - CELL / 2, CELL)))
	var rows := ceili(shots.size() / float(COLUMNS))
	var sheet := Image.create(CELL.x * mini(shots.size(), COLUMNS), CELL.y * rows, false, Image.FORMAT_RGB8)
	for i in shots.size():
		sheet.blit_rect(shots[i], Rect2i(Vector2i.ZERO, CELL), Vector2i((i % COLUMNS) * CELL.x, (i / COLUMNS) * CELL.y))
	sheet.save_png(out)
	quit()


## Puts the player where the scenario starts, presses what the scenario needs, returns {every, count}.
func _setup(scenario: String, player: PlayerController, room: Node) -> Dictionary:
	match scenario:
		"land":
			player.position = Vector2(0, -260)
			return {"every": 3, "count": 18}
		"climb":
			player.position = Vector2(560, -110)
			player.velocity.y = -50.0
			await physics_frame
			Input.action_press(&"climb_up")
			return {"every": 3, "count": 20}
		"rope":
			var rope := room.get_node("Rope") as Rope
			player.position = rope.bob_position() + Vector2(0, 78)
			await physics_frame
			Input.action_press(&"interact")
			await physics_frame
			Input.action_release(&"interact")
			Input.action_press(&"move_right")
			return {"every": 10, "count": 18}
		"push":
			player.position = Vector2(190, -2)
			for i in 20:
				await physics_frame
			Input.action_press(&"interact")
			Input.action_press(&"move_right")
			return {"every": 6, "count": 18}
		"chase":
			player.position = Vector2(1560, -2)
			room.get_node("Monster").position.x = 1330.0
			room.get_node("Monster").start()
			return {"every": 14, "count": 12}
	Input.action_press(&"move_right")
	return {"every": 4, "count": 18}
