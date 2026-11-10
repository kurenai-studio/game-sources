extends SceneTree
var main
var f := 0
var t0 := 0
var acc := 0
var n := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.start_duel()
	if f > 10 and f < 400 and f % 20 == 0:
		for nd in main.world.get_children():
			if nd.has_method("hit"):
				nd.hit(nd.global_position + Vector2(randf_range(-20,20), randf_range(-20,20)), Vector2.RIGHT, 30, 25.0, 0)
		if f % 100 == 0:
			Maps.build_test_field(main.world)   # подкидываем новые объекты, чтобы набрать 200 обломков
	if f >= 420 and f < 720:
		var t := Time.get_ticks_usec()
		if t0 != 0:
			acc += t - t0
			n += 1
		t0 = t
	if f == 720:
		print("debris=", Fragment.all.size(), " avg frame us=", acc / max(n, 1))
		return true
	return false
