extends SceneTree
var f := 0
var c: Control
func _initialize() -> void:
	Save.load_game()
	c = Control.new()
	c.size = Vector2(1600, 720)
	var bg := ColorRect.new()
	bg.size = c.size
	bg.color = Color(0.27, 0.26, 0.31)
	c.add_child(bg)
	root.add_child(c)
	HeroFigure.draw(c, Vector2(500, 600), 8.0, 7, Color(0, 0, 0, 0), 1)
	HeroFigure.draw(c, Vector2(1100, 600), 8.0, 7, Color(0, 0, 0, 0), -1)
func _process(_d: float) -> bool:
	f += 1
	if f == 30:
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/helm.png")
		return true
	return false
