extends SceneTree
var main
var f := 0
var p1
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.start_duel()
	if f == 5:
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()
			if n is Player and n.index == 0: p1 = n
			if n is Player and n.index == 1: n.position = Vector2(1050, 560)
		p1.position = Vector2(300, 565)
		p1.facing = 1
		Maps.add_column(main.world, Rect2(360, 60, 40, 540))
	if f == 15:
		p1._leap()
		Input.action_press("p1_right")
	if f >= 15 and f < 60:
		print(f, " pos=", p1.position.round(), " v=", p1.velocity.round(), " phasing=", p1._phasing, " mask=", p1.collision_mask, " inside=", p1._inside_block())
	if f == 60:
		return true
	return false
