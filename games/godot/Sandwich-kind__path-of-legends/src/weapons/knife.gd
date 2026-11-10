class_name Knife
extends Area2D
# Нож «Мгновенной смерти» (TEST_FIELD): вылетает из стены и летит насквозь
# через всё — постройки не трогает, ранит только героев (каждого — один раз).

const SPEED := 820.0
const DAMAGE := 15

var dir := 1
var delay := 0.8
var map_w := 1152.0
var _hit := {}
var _vis: Node2D

func _ready() -> void:
	z_index = 25
	collision_layer = 0
	collision_mask = Layer.PLAYER
	monitoring = false
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(30, 8)
	col.shape = rs
	add_child(col)
	_vis = Node2D.new()
	_vis.scale.x = dir
	add_child(_vis)
	var blade := Polygon2D.new()
	blade.polygon = PackedVector2Array([Vector2(-2, -4), Vector2(14, -4), Vector2(24, 0), Vector2(14, 3), Vector2(-2, 3)])
	blade.color = Color(0.85, 0.87, 0.92)
	_vis.add_child(blade)
	var edge := Polygon2D.new()
	edge.polygon = PackedVector2Array([Vector2(-2, -4), Vector2(14, -4), Vector2(24, 0), Vector2(14, -1), Vector2(-2, -1)])
	edge.color = Color(1, 1, 1)
	_vis.add_child(edge)
	var handle := Polygon2D.new()
	handle.polygon = PackedVector2Array([Vector2(-14, -3), Vector2(-2, -3), Vector2(-2, 3), Vector2(-14, 3)])
	handle.color = Color(0.4, 0.22, 0.12)
	_vis.add_child(handle)
	var guard := Polygon2D.new()
	guard.polygon = PackedVector2Array([Vector2(-3, -7), Vector2(0, -7), Vector2(0, 7), Vector2(-3, 7)])
	guard.color = Color(0.75, 0.6, 0.3)
	_vis.add_child(guard)
	visible = false
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		if delay <= 0.0:
			visible = true
			monitoring = true
		return
	position.x += dir * SPEED * delta
	if position.x < -100.0 or position.x > map_w + 100.0:
		queue_free()

func _on_body(b: Node) -> void:
	if b is Player and b.is_alive() and not _hit.has(b):
		_hit[b] = true
		b.take_damage(DAMAGE)
		Util.flash(get_parent(), b.global_position, 18.0, Color(1.0, 0.3, 0.3, 0.8))
