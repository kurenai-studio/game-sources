class_name FallingAnvil
extends Node
# Падающая стена или наковальня Кузнеца.
# Обычная: перед Кузнецом с неба падает железная стена и стоит недолго
#   (свои пули проходят сквозь неё, как сквозь щит).
# МЕГА: огромная наковальня падает с неба, проламывая всё на пути, и остаётся
#   навсегда. Форма ступенчатая — на неё можно запрыгнуть и перейти.
#   Сломать можно, но очень трудно.

var owner_p: Player
var team := 0
var mega := false
var x := 0.0
var land_y := 0.0              # где окажется низ стены
var d: Destructible
var _v := 0.0
var _start_v := true
var _hit := {}
var _done := false
var _shadow: Polygon2D
var life := 8.0               # сколько стоит обычная стена (на Арене — дольше)
var side := 1                 # с какой стороны стоит Кузнец (там выступ)

const ANVIL := [               # МЕГА-наковальня: какие клетки есть в каждом ряду (сверху вниз)
	[0, 10], [1, 9], [3, 7], [3, 7], [2, 8], [1, 9],
]

func _ready() -> void:
	var world := get_parent()
	d = Destructible.new()
	d.mat_kind = "iron"
	if mega:
		d.cell = 22.0
		d.cols = 11
		d.rows = ANVIL.size()
		d.cell_hp = 420
		d.density = 220.0
		d.color = Color(0.17, 0.17, 0.21)          # тёмный чугун — хорошо видно на любом фоне
		for y in ANVIL.size():
			for cx in range(ANVIL[y][0], ANVIL[y][1] + 1):
				var c := Vector2i(cx, y)
				d.cells[c] = d.cell_hp
				d.anchors.append(c)
				if y == 0:
					d.cell_colors[c] = Color(0.70, 0.70, 0.78)      # отполированная рабочая грань
				elif cx <= 1 and y <= 1:
					d.cell_colors[c] = Color(0.32, 0.30, 0.36)      # рог
				elif y == ANVIL.size() - 1:
					d.cell_colors[c] = Color(0.26, 0.22, 0.20)      # основание
	else:
		# высокая железная стена (8 клеток) — через неё не перепрыгнуть;
		# со стороны Кузнеца — выступ-ступенька, по нему он забирается наверх
		d.cell = 25.0
		d.cols = 3
		d.rows = 8
		d.cell_hp = 45
		d.density = 45.0
		d.color = Color(0.42, 0.42, 0.47)
		d.shield_team = team                       # свои пули пролетают сквозь стену
		d.lifetime = life
		var ledge := 0 if side > 0 else 2
		for cx in d.cols:
			for y in d.rows:
				if cx == ledge and y < 4:
					continue                           # выступ — только нижняя половина
				var c2 := Vector2i(cx, y)
				d.cells[c2] = d.cell_hp
				d.anchors.append(c2)
				if y == 0 or (cx == ledge and y == 4):
					d.cell_colors[c2] = Color(0.60, 0.60, 0.66)    # светлая верхняя кромка
				elif (cx + y) % 3 == 0:
					d.cell_colors[c2] = Color(0.36, 0.36, 0.41)    # заклёпки
	d.anchored = true
	var h := d.rows * d.cell
	var start_y := land_y - h / 2.0 - (720.0 if mega else 260.0)
	d.position = Vector2(x, start_y)
	world.add_child(d)
	# тень на земле — видно, куда упадёт
	_shadow = Polygon2D.new()
	var half := d.cols * d.cell / 2.0
	_shadow.polygon = PackedVector2Array([Vector2(-half, -3), Vector2(half, -3), Vector2(half, 3), Vector2(-half, 3)])
	_shadow.color = Color(0, 0, 0, 0.15)
	_shadow.position = Vector2(x, land_y)
	_shadow.z_index = 2
	world.add_child(_shadow)
	if mega:
		Fx.rune_circle(world, Vector2(x, land_y), half + 20.0, Color(1.0, 0.6, 0.2, 0.85), 0.9, 0.25)

func _physics_process(delta: float) -> void:
	if _done or not is_instance_valid(d):
		return
	if _start_v:
		_start_v = false
		_v = 300.0 if mega else 650.0
	_v += (3200.0 if mega else 2600.0) * delta
	d.position.y += _v * delta
	var half_w := d.cols * d.cell / 2.0
	var h := d.rows * d.cell
	var bottom := d.position.y + h / 2.0
	_shadow.color.a = clampf(0.15 + 0.5 * (1.0 - (land_y - bottom) / 700.0), 0.15, 0.6)
	_shadow.scale.x = 0.6 + 0.4 * clampf(1.0 - (land_y - bottom) / 700.0, 0.0, 1.0)
	_smash(half_w, bottom)
	if bottom >= land_y:
		d.position.y = land_y - h / 2.0
		_land(half_w, h)

# Проламывает блоки под собой и бьёт тех, на кого падает
func _smash(half_w: float, bottom: float) -> void:
	var world := get_parent()
	for n in world.get_children():
		if n is Destructible and n != d and not n.background and n.shield_team != team \
				and absf(n.global_position.x - x) < half_w + 400.0 and absf(n.global_position.y - bottom) < 400.0:
			var px := -half_w + 10.0
			while px < half_w:
				n.hit(Vector2(x + px, bottom - 6.0), Vector2.DOWN, 999 if mega else 60, 4.0, team,
						{"strict": true, "attacker": owner_p, "power": 0.6})
				px += 20.0
		elif n is Player and n.is_alive() and not mega and absf(n.global_position.x - x) < half_w + n.body_size.x / 2 \
				and n.global_position.y + n.body_size.y / 2 > bottom - 20.0 and n.global_position.y - n.body_size.y / 2 < bottom + 40.0 \
				and n.global_position.y - n.body_size.y / 2 > bottom - d.rows * d.cell:
			# стена вот-вот накроет — отодвигаем вбок (враги — от Кузнеца, свои — к нему),
			# а не даём физике выдавить его наверх стены или под карту
			if n.team != team and not _hit.has(n):
				_hit[n] = true
				n.take_damage(15, owner_p)
			_shove(n, half_w, side if n.team != team else -side)
		elif n is Player and n.team != team and n.is_alive() and not _hit.has(n):
			if absf(n.global_position.x - x) < half_w + n.body_size.x / 2 \
					and n.global_position.y - n.body_size.y / 2 < bottom and n.global_position.y + n.body_size.y / 2 > bottom - 40.0:
				_hit[n] = true
				n.take_damage(45 if mega else 15, owner_p)
				var side := signf(n.global_position.x - x)
				if side == 0.0:
					side = 1.0
				n.velocity = Vector2(side * 500.0, -350.0)
				if mega:
					n.stun(0.8)

# Отодвинуть героя из-под стены в сторону dir (если там стена карты — в другую)
func _shove(n: Player, half_w: float, dir: int) -> void:
	var space := n.get_world_2d().direct_space_state
	var ex: Array[RID] = [n.get_rid(), d.get_rid()]
	for dd in [dir, -dir]:
		var tx: float = x + dd * (half_w + n.body_size.x / 2 + 6.0)
		var q := PhysicsRayQueryParameters2D.create(n.global_position, Vector2(tx + dd * n.body_size.x / 2, n.global_position.y),
				Layer.WORLD | Layer.FRAME, ex)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			n.global_position.x = tx
			n.velocity = Vector2(dd * 260.0, -80.0)
			return

func _land(half_w: float, h: float) -> void:
	_done = true
	var world := get_parent()
	var ground := Vector2(x, land_y)
	_shadow.queue_free()
	Fx.ring(world, ground, half_w + (90.0 if mega else 30.0), Color(0.85, 0.85, 0.9, 0.9), 0.45, 7.0 if mega else 4.0, 0.3)
	Fx.sparks(world, ground, Color(1.0, 0.8, 0.4), 22 if mega else 8, 300.0, 5.0, true)
	if mega:
		Fx.cracks(world, ground + Vector2(-half_w, 0), Color(0.25, 0.2, 0.18), 120.0)
		Fx.cracks(world, ground + Vector2(half_w, 0), Color(0.25, 0.2, 0.18), 120.0)
		Util.explode(world, ground, half_w + 40.0, 0, 0, team, owner_p)
	# никто не остаётся замурованным внутри — выталкиваем наверх
	for n in world.get_children():
		if n is Player and n.is_alive():
			if absf(n.global_position.x - x) < half_w + n.body_size.x / 2 - 4.0 \
					and absf(n.global_position.y - d.position.y) < h / 2 + n.body_size.y / 2 - 4.0:
				if mega:
					n.global_position.y = d.position.y - h / 2 - n.body_size.y / 2 - 2.0
					n.velocity.y = 0.0
				else:
					_shove(n, half_w, side if n.team != team else -side)
	queue_free()
