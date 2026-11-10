extends SceneTree
var main
var f := 0
var p1
var crate
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
	if f == 8:
		Maps.add_crate(main.world, Vector2(500, 150))
	if f == 9:
		for n in main.world.get_children():
			if n is Destructible: crate = n
		crate.body_entered.connect(func(b): print("  body_entered ", b.get_class(), " last_speed=", crate._last_speed, " mass=", crate.mass, " freeze=", crate.freeze, " hurt_cd=", crate._hurt_cd))
		print("crate monitor=", crate.contact_monitor, " max=", crate.max_contacts_reported, " layer=", crate.collision_layer, " mask=", crate.collision_mask)
	if f > 9 and f < 90 and f % 2 == 0 and f > 50:
		print(f, " crate y=", int(crate.position.y), " v=", int(crate.linear_velocity.y), " colliding=", crate.get_colliding_bodies().size(), " p1 y=", int(p1.position.y), " hp=", p1.hp)
	if f == 90:
		return true
	return false
