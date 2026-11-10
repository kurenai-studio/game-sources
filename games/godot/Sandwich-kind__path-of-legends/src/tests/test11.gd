extends SceneTree
# Урон от падающего ящика и от летящих осколков
var main
var f := 0
var p1
var p2
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
			if n is Player and n.index == 1: p2 = n
	if f == 7:
		p1.position = Vector2(500, 565)
		p2.position = Vector2(1000, 565)
	if f == 8:
		Maps.add_crate(main.world, Vector2(500, 150))
	if f == 70:
		print("TEST falling crate: p1 hp 100 -> ", p1.hp)
		p1.hp = 100
		p1.position = Vector2(300, 565)
	if f == 75:
		# противник стреляет тяжёлым снарядом в колонну, за которой стоит p1
		Maps.add_column(main.world, Rect2(360, 440, 40, 160))
		p2.position = Vector2(700, 565)
		p2.facing = -1
	if f == 80:
		for k in 3:
			p2._shoot_bullet(900.0, 40, 22.0, 16.0, 0.0)
	if f == 100:
		p1.hp = 100
		for k in 3:
			var fr := Fragment.new()
			fr.size = Vector2(20, 20)
			fr.team = 1
			fr.hurt = 6
			fr.position = Vector2(420 + k * 30, 560)
			fr.linear_velocity = Vector2(-600, 0)
			main.world.add_child(fr)
	if f == 160:
		print("TEST fragments through column: p1 hp 100 -> ", p1.hp)
		return true
	return false
