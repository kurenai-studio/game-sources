extends SceneTree
func _init():
	var t := Time.get_ticks_msec()
	var img := Maps.preview_image("mountain", Vector2(700, 300))
	print("preview ", img.get_size(), " ms ", Time.get_ticks_msec() - t)
	img.save_png("/tmp/claude-0/prev_mountain.png")
	Maps.preview_image("two_houses", Vector2(700, 300)).save_png("/tmp/claude-0/prev_houses.png")
	Maps.preview_image("test_field", Vector2(700, 300)).save_png("/tmp/claude-0/prev_field.png")
	var w := Node2D.new()
	root.add_child(w)
	t = Time.get_ticks_msec()
	var info := Maps.build(w, "mountain")
	var n := 0
	for c in w.get_children():
		if c is Destructible: n += c.cells.size()
	print("cells ", n, " build ms ", Time.get_ticks_msec() - t, " ", info["size"])
	quit()
