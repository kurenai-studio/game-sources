extends SceneTree
var f := 0
func _initialize() -> void:
	Save.load_game()
	var c := Control.new()
	c.size = Vector2(1600, 720)
	var bg := ColorRect.new()
	bg.size = c.size
	bg.color = Color(0.27, 0.26, 0.31)
	c.add_child(bg)
	root.add_child(c)
	var ids := [0, 1, 4, 5, 6, 7, 8]
	for i in ids.size():
		HeroFigure.draw(c, Vector2(120 + i * 225, 680), 4.5, ids[i], Color(0, 0, 0, 0), 1)
func _process(_d: float) -> bool:
	f += 1
	if f == 30:
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/legends.png")
		return true
	return false
