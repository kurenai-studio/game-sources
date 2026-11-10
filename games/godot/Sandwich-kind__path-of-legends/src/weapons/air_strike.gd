class_name AirStrike
extends Node2D
# Авиаудар Солдата.
# Обычный: на земле у врага — красная метка с обратным отсчётом. Через ~3,5 с
#   над полем пролетает самолёт и сбрасывает в метку одну мощную бомбу.
# МЕГА: самолёт медленно летит через всё поле и всё время сбрасывает бомбы;
#   каждая при взрыве разлетается на бомбы поменьше.

var team := 0
var attacker: Node
var mega := false
var target := Vector2.ZERO      # метка на земле
var map_w := 1600.0
var sky_y := 80.0
var delay := 3.5
var _t := 0.0
var _plane: Node2D
var _mark: Node2D
var _dir := 1
var _dropped := false
var _drop_acc := 0.0
var _speed := 900.0

func _ready() -> void:
	z_index = 7
	_dir = 1 if randf() < 0.5 else -1
	_mark = Node2D.new()
	_mark.position = target
	add_child(_mark)
	if not mega:
		var ring := Line2D.new()
		var pts := Util.circle(60.0, 32)
		pts.append(pts[0])
		for i in pts.size():
			pts[i].y *= 0.3
		ring.points = pts
		ring.width = 4.0
		ring.default_color = Color(1.0, 0.2, 0.15, 0.9)
		_mark.add_child(ring)
		for a in [0.0, PI / 2]:             # перекрестье
			var l := Line2D.new()
			l.points = PackedVector2Array([Vector2.from_angle(a) * 70.0 * Vector2(1, 0.3), -Vector2.from_angle(a) * 70.0 * Vector2(1, 0.3)])
			l.width = 3.0
			l.default_color = Color(1.0, 0.25, 0.2, 0.9)
			_mark.add_child(l)
		var beam := Polygon2D.new()             # красный луч-наводка в небо
		beam.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(1, -900), Vector2(-1, -900)])
		beam.color = Color(1.0, 0.2, 0.15, 0.25)
		_mark.add_child(beam)
	_plane = _make_plane()
	_plane.visible = false
	add_child(_plane)

func _make_plane() -> Node2D:
	var pl := Node2D.new()
	var k := 1.6 if mega else 1.2
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-60, -6), Vector2(40, -8), Vector2(62, 0), Vector2(40, 8), Vector2(-60, 6)])
	body.color = Color(0.36, 0.42, 0.32)
	pl.add_child(body)
	var wing := Polygon2D.new()
	wing.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(18, 0), Vector2(-15, 34), Vector2(-30, 34)])
	wing.color = Color(0.28, 0.33, 0.25)
	pl.add_child(wing)
	var wing2 := Polygon2D.new()
	wing2.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(18, 0), Vector2(-20, -26), Vector2(-32, -26)])
	wing2.color = Color(0.32, 0.38, 0.29)
	pl.add_child(wing2)
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(-60, -4), Vector2(-46, -4), Vector2(-56, -26), Vector2(-64, -26)])
	tail.color = Color(0.32, 0.38, 0.29)
	pl.add_child(tail)
	var glass := Polygon2D.new()
	glass.polygon = PackedVector2Array([Vector2(28, -8), Vector2(44, -7), Vector2(50, -2), Vector2(28, -2)])
	glass.color = Color(0.6, 0.85, 1.0)
	pl.add_child(glass)
	var star := Polygon2D.new()
	star.polygon = Util.circle(5.0, 5)
	star.color = Color(0.85, 0.15, 0.12)
	star.position = Vector2(-20, 0)
	pl.add_child(star)
	pl.scale = Vector2(k * _dir, k)
	return pl

func _physics_process(delta: float) -> void:
	_t += delta
	if _mark and is_instance_valid(_mark):
		_mark.modulate.a = 0.6 + 0.4 * absf(sin(_t * (6.0 + 6.0 * _t / delay)))
	if mega:
		_mega_tick(delta)
		return
	# самолёт появляется так, чтобы пролететь над меткой, когда отсчёт закончится
	var fly_x := target.x - _dir * _speed * (delay - _t)
	if _t > delay - 1.6:
		_plane.visible = true
		_plane.position = Vector2(fly_x, sky_y)
	var h := maxf(target.y - sky_y - 16.0, 10.0)
	var tf := (-200.0 + sqrt(200.0 * 200.0 + 2.0 * FallingBomb.GRAVITY * h)) / FallingBomb.GRAVITY
	if not _dropped and _t >= delay - 250.0 * tf / _speed:
		_dropped = true
		_drop(Vector2(fly_x, sky_y + 16.0), Vector2(_dir * 250.0, 200.0), true, false)
	if _t > delay + 1.6:
		queue_free()

func _mega_tick(delta: float) -> void:
	if _t < 1.2:
		return
	_plane.visible = true
	_speed = 380.0
	var x0 := -150.0 if _dir > 0 else map_w + 150.0
	var x := x0 + _dir * _speed * (_t - 1.2)
	_plane.position = Vector2(x, sky_y)
	_drop_acc -= delta
	if _drop_acc <= 0.0 and x > 40.0 and x < map_w - 40.0:
		_drop_acc = 0.45
		_drop(_plane.position + Vector2(0, 18), Vector2(_dir * 120.0, 150.0), true, true)
	if (_dir > 0 and x > map_w + 200.0) or (_dir < 0 and x < -200.0):
		queue_free()

func _drop(at: Vector2, vel: Vector2, big: bool, cluster: bool) -> void:
	var b := FallingBomb.new()
	b.team = team
	b.attacker = attacker
	b.big = big
	b.cluster = cluster
	b.velocity = vel
	b.position = at
	get_parent().add_child(b)
