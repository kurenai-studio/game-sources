extends SceneTree
var f := 0
var rb
var ch
func _initialize() -> void:
	var w := Node2D.new()
	root.add_child(w)
	ch = CharacterBody2D.new()
	ch.collision_layer = 2
	ch.collision_mask = 1
	var c := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = Vector2(40, 60)
	c.shape = s
	ch.add_child(c)
	ch.position = Vector2(500, 500)
	w.add_child(ch)
	var fl := StaticBody2D.new()
	var c3 := CollisionShape2D.new()
	var s3 := RectangleShape2D.new()
	s3.size = Vector2(1000, 20)
	c3.shape = s3
	fl.add_child(c3)
	fl.position = Vector2(500, 540)
	w.add_child(fl)
	rb = RigidBody2D.new()
	rb.collision_layer = 1
	rb.collision_mask = 3
	var c2 := CollisionShape2D.new()
	var s2 := RectangleShape2D.new()
	s2.size = Vector2(40, 40)
	c2.shape = s2
	rb.add_child(c2)
	rb.position = Vector2(500, 300)
	w.add_child(rb)
func _physics_process(_d: float) -> bool:
	f += 1
	ch.velocity = Vector2(0, 100)
	ch.move_and_slide()
	if f % 10 == 0:
		print(f, " rb y=", int(rb.position.y))
	return f >= 60
