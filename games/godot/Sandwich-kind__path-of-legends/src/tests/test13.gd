extends SceneTree
var main
var f := 0
var p1
var rb
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.map_id = "test_field"
		main.start_duel()
	if f == 5:
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()
			if n is Player and n.index == 0: p1 = n
			if n is Player and n.index == 1: n.position = Vector2(1000, 565)
		p1.position = Vector2(500, 565)
		p1.process_physics_priority = PRIO
		print("p1 layer=", p1.collision_layer, " shape disabled=", p1._col.disabled, " exceptions=", p1.get_collision_exceptions())
		# простой RigidBody2D без наших скриптов
		rb = RigidBody2D.new()
		rb.collision_layer = 1
		rb.collision_mask = 3
		var c := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = Vector2(40, 40)
		c.shape = s
		rb.add_child(c)
		rb.position = Vector2(500, 300)
		main.world.add_child(rb)
	if f > 5 and f < 60 and f % 5 == 0:
		print(f, " plain rb y=", int(rb.position.y))
	if f == 60:
		return true
	return false
