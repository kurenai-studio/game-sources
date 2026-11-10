class_name MirrorCrystal
extends StaticBody2D
# Зеркальный кристалл (Кристальные пещеры): прочный, не ломается.
# Пули, стрелы и лучи света отскакивают от него — можно стрелять рикошетом.

var size := Vector2(46, 150)

func _ready() -> void:
	collision_layer = Layer.WORLD | Layer.FRAME
	set_meta("mirror", true)
	add_to_group("mirrors")
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size
	col.shape = rs
	add_child(col)
	var img := DeepArt.mirror_image(int(size.x / 3.0), int(size.y / 3.0))
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(3, 3)
	add_child(s)
	Shimmer.apply(s, 0.22, 0.6)
	var glow := Torch.make_glow(size.y * 1.4, Color(0.5, 0.75, 1.0, 0.25))
	glow.z_index = -1
	add_child(glow)
	var sh := Polygon2D.new()
	var pts := Util.circle(1.0, 16)
	for i in pts.size():
		pts[i] *= Vector2(size.x * 0.75, 7.0)
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.35)
	sh.position = Vector2(0, size.y / 2)
	sh.z_index = -1
	add_child(sh)

# Нормаль поверхности в точке (для отражения)
func normal_at(p: Vector2) -> Vector2:
	var l := to_local(p)
	if absf(l.x) / (size.x / 2) >= absf(l.y) / (size.y / 2):
		return Vector2(signf(l.x) if l.x != 0.0 else 1.0, 0)
	return Vector2(0, signf(l.y) if l.y != 0.0 else -1.0)
