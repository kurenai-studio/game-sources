extends SceneTree
var main
var f := 0
var cam
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func ps() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Player:
			r.append(n)
	return r
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.map_id = "two_houses"
		main.start_duel()
	if f == 5:
		for n in main.world.get_children():
			if n is DuelCamera:
				cam = n
		ps()[0].position = Vector2(1900, 1215)
		ps()[1].position = Vector2(2100, 1215)
	if f > 5 and f % 40 == 0 and f < 400:
		print(f, " p1=", ps()[0].position.round(), " p2=", ps()[1].position.round(), " zoom=", snappedf(cam.zoom.x,0.01), " cam=", cam.position.round(), " center=", cam._center.round())
	if f == 400:
		return true
	return false
