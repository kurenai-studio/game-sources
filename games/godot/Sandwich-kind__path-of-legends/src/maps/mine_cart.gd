class_name MineCart
extends AnimatableBody2D
# Вагонетка на рельсах (Драгоценные пещеры): ездит туда-обратно по своему
# участку пути. На неё можно запрыгнуть и прокатиться, а всех, кто стоит у неё
# на пути, она сбивает (и героев, и противников).

var x_min := 0.0
var x_max := 400.0
var floor_y := 940.0
var speed := 300.0
var damage := 12
var _dir := 1.0
var _wait := 1.0
var _hit_cd := {}
var _wheels: Array = []
var _spr: Sprite2D

const K := 3.6
const SIZE := Vector2(26, 16) * K

func _ready() -> void:
	collision_layer = Layer.WORLD | Layer.FRAME
	collision_mask = 0
	sync_to_physics = true
	position = Vector2(x_min, floor_y - SIZE.y / 2)
	# стоять можно только сверху — сквозь бока вагонетки герои проходят (их сбивает)
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(SIZE.x - 8, 10)
	col.shape = rs
	col.position = Vector2(0, -SIZE.y / 2 + 9)
	col.one_way_collision = true
	add_child(col)
	var img := DeepArt.cart_image()
	BotRig._volume(img)
	_spr = Sprite2D.new()
	_spr.texture = ImageTexture.create_from_image(img)
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.scale = Vector2(K, K)
	add_child(_spr)
	Shimmer.apply(_spr, 0.14)
	var sh := Polygon2D.new()
	var pts := Util.circle(1.0, 16)
	for i in pts.size():
		pts[i] *= Vector2(SIZE.x * 0.5, 6.0)
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.3)
	sh.position = Vector2(0, SIZE.y / 2)
	sh.z_index = -1
	add_child(sh)

func _physics_process(delta: float) -> void:
	for k in _hit_cd.keys():
		_hit_cd[k] -= delta
		if _hit_cd[k] <= 0.0:
			_hit_cd.erase(k)
	if _wait > 0.0:
		_wait -= delta
		return
	position.x += _dir * speed * delta
	_spr.rotation = sin(Time.get_ticks_msec() * 0.03) * 0.015
	if position.x >= x_max or position.x <= x_min:
		position.x = clampf(position.x, x_min, x_max)
		_dir = -_dir
		_wait = 1.4
		return
	# сбивает тех, кто стоит перед ней (а не едет сверху)
	for n in get_parent().get_children():
		if n is Player and n.is_alive() and not _hit_cd.has(n):
			var to: Vector2 = n.global_position - global_position
			if absf(to.x) < SIZE.x / 2 + n.body_size.x / 2 and signf(to.x) == _dir \
					and n.global_position.y + n.body_size.y / 2 > global_position.y - SIZE.y / 2 + 14:
				_hit_cd[n] = 1.0
				n.take_damage(damage)
				n.velocity = Vector2(_dir * 620.0, -380.0)
				Fx.sparks(get_parent(), n.global_position, Color(1.0, 0.8, 0.4), 8, 200.0, 4.0)
