class_name HeroFigure
# Рисует героя крупно (для меню, книги легенд, колонн выбора).

# bottom — точка, где у героя ноги; k — во сколько раз крупнее; face — куда смотрит
static func draw(parent: Node, bottom: Vector2, k: float, char_idx: int, outline := Color(0, 0, 0, 0),
		face := 1, locked := false) -> Control:
	var ch: Dictionary = Characters.LIST[char_idx]
	var size := Player.SIZE * k
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.position = bottom - Vector2(size.x / 2, size.y)
	parent.add_child(root)
	if ch.has("rig"):
		# легенда с моделью из частей — живая фигурка (дышит)
		var holder := Node2D.new()
		holder.scale = Vector2(k, k)
		holder.position = Vector2(size.x / 2, size.y / 2)
		root.add_child(holder)
		var rig := BotRig.new()
		rig.kind = ch["rig"]
		rig.size = Player.SIZE
		rig.puppet_facing = face
		holder.add_child(rig)
		if outline.a > 0.0 and not locked:
			var m := Polygon2D.new()
			m.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(0, 11)])
			m.color = outline
			m.position = Vector2(0, -Player.SIZE.y / 2 - 30)
			holder.add_child(m)
		if locked:
			holder.modulate = Color(0.05, 0.04, 0.06, 0.9)     # силуэт: легенда ещё не открыта
		return root
	if outline.a > 0.0:
		var o := ColorRect.new()
		o.size = size + Vector2(5, 5) * k
		o.position = -Vector2(2.5, 2.5) * k
		o.color = outline
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(o)
	var body := ColorRect.new()
	body.size = size
	body.color = ch["color"]
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(body)
	var shade := ColorRect.new()
	shade.size = Vector2(size.x, size.y * 0.12)
	shade.position = Vector2(0, size.y * 0.88)
	shade.color = Color(ch["color"]).darkened(0.25)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var eye := ColorRect.new()
	eye.size = Vector2(8, 8) * k
	eye.color = Color.BLACK
	eye.position = Vector2(size.x / 2 + (face * 10 - 4) * k, size.y / 2 - 18 * k - 4 * k)
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(eye)
	return root
