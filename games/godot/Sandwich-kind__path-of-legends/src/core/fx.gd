class_name Fx
# Эффекты для ульт и способностей: кольца, искры, руны, листья, вспышки.
# Всё рисуется простыми полигонами и плавно исчезает само.

# Расходящееся кольцо (ударная волна)
static func ring(parent: Node, pos: Vector2, radius: float, color: Color, time := 0.45, width := 6.0,
		flat := 1.0) -> void:
	var l := Line2D.new()
	var pts := Util.circle(1.0, 32)
	pts.append(pts[0])
	for i in pts.size():
		pts[i].y *= flat
	l.points = pts
	l.width = width / maxf(radius, 1.0)
	l.default_color = color
	l.position = pos
	l.scale = Vector2(radius * 0.2, radius * 0.2)
	l.z_index = 8
	parent.add_child(l)
	var t := l.create_tween()
	t.set_parallel(true)
	t.tween_property(l, "scale", Vector2(radius, radius), time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, time)
	t.chain().tween_callback(l.queue_free)

# Искры, разлетающиеся во все стороны
static func sparks(parent: Node, pos: Vector2, color: Color, n := 12, speed := 260.0, size := 5.0,
		up := false) -> void:
	for i in n:
		var s := Polygon2D.new()
		s.polygon = PackedVector2Array([Vector2(-size, 0), Vector2(0, -size * 0.5), Vector2(size, 0), Vector2(0, size * 0.5)])
		s.color = color.lightened(randf_range(0.0, 0.3))
		s.position = pos
		s.z_index = 9
		parent.add_child(s)
		var a := randf() * TAU
		if up:
			a = -PI / 2 + randf_range(-0.9, 0.9)
		var d := Vector2.from_angle(a) * speed * randf_range(0.4, 1.0)
		s.rotation = a
		var t := s.create_tween()
		t.set_parallel(true)
		t.tween_property(s, "position", pos + d * 0.5, randf_range(0.3, 0.6)).set_ease(Tween.EASE_OUT)
		t.tween_property(s, "modulate:a", 0.0, 0.6)
		t.chain().tween_callback(s.queue_free)

# Вращающийся круг с рунами (на земле — сплющенный)
static func rune_circle(parent: Node, pos: Vector2, radius: float, color: Color, time: float, flat := 0.3) -> Node2D:
	var root := Node2D.new()
	root.position = pos
	root.z_index = 2
	parent.add_child(root)
	var spin := Node2D.new()
	root.add_child(spin)
	for r in [radius, radius * 0.72]:
		var l := Line2D.new()
		var pts := Util.circle(r, 40)
		pts.append(pts[0])
		l.points = pts
		l.width = 3.0
		l.default_color = color
		spin.add_child(l)
	for i in 8:                              # руны по кругу
		var a := TAU * i / 8.0
		var g := Polygon2D.new()
		var c := Vector2.from_angle(a) * radius * 0.86
		g.polygon = PackedVector2Array([c + Vector2(0, -7), c + Vector2(5, 0), c + Vector2(0, 7), c + Vector2(-5, 0)])
		g.color = color.lightened(0.3)
		spin.add_child(g)
	root.scale = Vector2(0.1, 0.1 * flat)
	var t := root.create_tween()
	t.tween_property(root, "scale", Vector2(1.0, flat), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(maxf(0.0, time - 0.55))
	t.tween_property(root, "modulate:a", 0.0, 0.3)
	t.tween_callback(root.queue_free)
	var st := spin.create_tween().set_loops(int(ceil(time / 1.2)) + 1)
	st.tween_property(spin, "rotation", TAU, 1.2).from(0.0)
	return root

# Мягкое свечение (круг, который пульсирует и тает)
static func glow(parent: Node, pos: Vector2, radius: float, color: Color, time: float) -> Polygon2D:
	var g := Polygon2D.new()
	g.polygon = Util.circle(radius, 28)
	g.color = color
	g.position = pos
	g.z_index = 7
	parent.add_child(g)
	g.scale = Vector2(0.2, 0.2)
	var t := g.create_tween()
	t.tween_property(g, "scale", Vector2.ONE, time * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(time * 0.4)
	t.tween_property(g, "modulate:a", 0.0, time * 0.2)
	t.tween_callback(g.queue_free)
	return g

# Звезда-вспышка (на острие копья, в руке)
static func star(parent: Node, pos: Vector2, radius: float, color: Color, time: float) -> Polygon2D:
	var s := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var r := radius if i % 2 == 0 else radius * 0.3
		pts.append(Vector2.from_angle(TAU * i / 16.0) * r)
	s.polygon = pts
	s.color = color
	s.position = pos
	s.z_index = 9
	parent.add_child(s)
	s.scale = Vector2.ZERO
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", Vector2.ONE, time * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "rotation", PI, time)
	t.chain().tween_property(s, "modulate:a", 0.0, time * 0.4)
	t.chain().tween_callback(s.queue_free)
	return s

# Вихрь листьев вокруг героя (превращение Терновника)
static func leaf_swirl(parent: Node, center: Node2D, radius: float, time: float, n := 18) -> void:
	var sw := LeafSwirl.new()
	sw.center = center
	sw.radius = radius
	sw.time = time
	sw.count = n
	parent.add_child(sw)

# Листья, разлетающиеся при превращении
static func leaf_burst(parent: Node, pos: Vector2, n := 24) -> void:
	for i in n:
		var leaf := Polygon2D.new()
		leaf.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(0, -4), Vector2(7, 0), Vector2(0, 4)])
		leaf.color = Color(0.3, 0.7, 0.25).lightened(randf_range(0.0, 0.3))
		leaf.position = pos
		leaf.z_index = 9
		parent.add_child(leaf)
		var d := Vector2.from_angle(randf() * TAU) * randf_range(80, 220)
		var t := leaf.create_tween()
		t.set_parallel(true)
		t.tween_property(leaf, "position", pos + d + Vector2(0, 60), 0.9).set_ease(Tween.EASE_OUT)
		t.tween_property(leaf, "rotation", randf_range(-6, 6), 0.9)
		t.tween_property(leaf, "modulate:a", 0.0, 0.9).set_delay(0.3)
		t.chain().tween_callback(leaf.queue_free)

# Трещины в земле после удара
static func cracks(parent: Node, pos: Vector2, color: Color, length := 90.0) -> void:
	for i in 6:
		var l := Line2D.new()
		var a := PI + PI * (i + 0.5) / 6.0 + randf_range(-0.15, 0.15)
		var pts := PackedVector2Array([Vector2.ZERO])
		var p := Vector2.ZERO
		for k in 4:
			p += Vector2.from_angle(a + randf_range(-0.4, 0.4)) * length / 4.0 * Vector2(1.0, 0.25)
			pts.append(p)
		l.points = pts
		l.width = 3.0
		l.default_color = color
		l.position = pos
		l.z_index = 3
		parent.add_child(l)
		var t := l.create_tween()
		t.tween_interval(0.8)
		t.tween_property(l, "modulate:a", 0.0, 0.6)
		t.tween_callback(l.queue_free)

# След удара оружием: светлый полумесяц от угла a0 до a1 (вокруг центра)
static func arc(parent: Node, pos: Vector2, radius: float, a0: float, a1: float, color: Color,
		time := 0.22, thick := 26.0) -> void:
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(Vector2.from_angle(a) * radius)
	for i in range(n, -1, -1):
		var a := lerpf(a0, a1, float(i) / n)
		var k := sin(PI * float(i) / n)            # к краям полумесяц тоньше
		pts.append(Vector2.from_angle(a) * (radius - thick * k))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = color
	poly.position = pos
	poly.z_index = 8
	parent.add_child(poly)
	var t := poly.create_tween()
	t.set_parallel(true)
	t.tween_property(poly, "modulate:a", 0.0, time)
	t.tween_property(poly, "scale", Vector2(1.12, 1.12), time)
	t.chain().tween_callback(poly.queue_free)

# Огненное кольцо вокруг героя (МЕГА-ульта Кузнеца) — следует за ним
static func flame_ring(target: Node2D, radius: float, time: float) -> Node2D:
	var root := Node2D.new()
	root.z_index = 3
	target.add_child(root)
	for i in 16:
		var f := Polygon2D.new()
		f.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(0, -22), Vector2(7, 0), Vector2(0, 5)])
		f.color = Color(1.0, 0.45 + 0.3 * (i % 2), 0.1, 0.8)
		f.position = Vector2.from_angle(TAU * i / 16.0) * Vector2(radius, radius * 0.2)
		root.add_child(f)
	var ring := Line2D.new()
	var pts := Util.circle(radius, 40)
	pts.append(pts[0])
	for i in pts.size():
		pts[i].y *= 0.2
	ring.points = pts
	ring.width = 5.0
	ring.default_color = Color(1.0, 0.55, 0.15, 0.7)
	root.add_child(ring)
	root.position = Vector2(0, 22)
	root.scale = Vector2(0.2, 0.2)
	var t := root.create_tween()
	t.tween_property(root, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(maxf(0.0, time - 0.6))
	t.tween_property(root, "modulate:a", 0.0, 0.3)
	t.tween_callback(root.queue_free)
	return root

# Электрический разряд вокруг точки (ломаные искры)
static func zap(parent: Node, pos: Vector2, color: Color, r := 26.0) -> void:
	for i in 5:
		var l := Line2D.new()
		var a := randf() * TAU
		var pts := PackedVector2Array([Vector2.ZERO])
		var q := Vector2.ZERO
		for k in 4:
			q += Vector2.from_angle(a + randf_range(-0.8, 0.8)) * r / 4.0
			pts.append(q)
		l.points = pts
		l.width = 2.0
		l.default_color = color
		l.position = pos
		l.z_index = 9
		parent.add_child(l)
		var t := l.create_tween()
		t.tween_property(l, "modulate:a", 0.0, 0.25)
		t.tween_callback(l.queue_free)

# Молния от точки к точке
static func bolt(parent: Node, a: Vector2, b: Vector2, color: Color) -> void:
	var l := Line2D.new()
	var pts := PackedVector2Array([a])
	var n := 7
	for i in range(1, n):
		var q := a.lerp(b, float(i) / n)
		pts.append(q + (b - a).orthogonal().normalized() * randf_range(-14.0, 14.0))
	pts.append(b)
	l.points = pts
	l.width = 3.0
	l.default_color = color
	l.z_index = 9
	parent.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "modulate:a", 0.0, 0.3)
	t.tween_callback(l.queue_free)

# Ледяная корка на замороженном враге (тает сама)
static func ice(target: Node2D, size: Vector2, time: float) -> void:
	var root := Node2D.new()
	root.z_index = 6
	target.add_child(root)
	var block := Polygon2D.new()
	var hw := size.x * 0.65
	var hh := size.y * 0.6
	block.polygon = PackedVector2Array([Vector2(-hw, -hh), Vector2(hw * 0.6, -hh * 1.1), Vector2(hw, -hh * 0.2),
			Vector2(hw * 0.9, hh), Vector2(-hw * 0.8, hh), Vector2(-hw * 1.05, 0)])
	block.color = Color(0.6, 0.85, 1.0, 0.45)
	root.add_child(block)
	for k in 3:
		var sh := Line2D.new()
		sh.points = PackedVector2Array([Vector2(-hw * 0.5 + k * hw * 0.4, -hh * 0.7), Vector2(-hw * 0.3 + k * hw * 0.4, -hh * 0.2)])
		sh.width = 2.0
		sh.default_color = Color(1, 1, 1, 0.7)
		root.add_child(sh)
	var t := root.create_tween()
	t.tween_interval(maxf(0.0, time - 0.25))
	t.tween_property(root, "modulate:a", 0.0, 0.25)
	t.tween_callback(root.queue_free)

# Тряска экрана (если не выключена в настройках): камера дрожит и успокаивается
static var _shake_until := 0
static func shake(node: Node, strength: float) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	if not bool(StorySettings.get_value("screen_shake")):
		return
	var now := Time.get_ticks_msec()
	if now < _shake_until - 120:
		return                          # уже трясётся — не наслаиваем
	var cam := node.get_viewport().get_camera_2d()
	if cam == null:
		return
	_shake_until = now + 260
	var t := cam.create_tween()
	for i in 6:
		var k := 1.0 - i / 6.0
		t.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, 0.04)
	t.tween_property(cam, "offset", Vector2.ZERO, 0.04)
