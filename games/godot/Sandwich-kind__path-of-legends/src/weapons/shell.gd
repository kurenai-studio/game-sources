class_name Shell
extends Area2D
# ---------- Массивный снаряд (UBER_TESTIK_2, способность 1) ----------

var size := 36.0
var mega := false            # МЕГА: крупнее, летит дальше, пробивает больше
const CARVE_DAMAGE := 45     # урон клеткам за кадр: ящики, платформы и камень рвёт сразу, дома — нет
var shooter: Node
var team := 0
var direction := Vector2.RIGHT
var speed := 650.0
var damage := 45
var pierce := 120.0          # запас пробития
var _life := 2.2
var _hit := {}
var _done := false

func _ready() -> void:
	if mega:
		size = 62.0
		_life = 3.6
		pierce = 320.0
		damage = 70
	collision_layer = 0
	collision_mask = Layer.WORLD | Layer.PLAYER | Layer.BOT | Layer.BACK   # фон тоже прорывает
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = size / 2
	col.shape = cs
	add_child(col)
	var outer := Polygon2D.new()
	outer.polygon = Util.circle(size / 2, 20)
	outer.color = Color(0.45, 0.25, 0.85)
	add_child(outer)
	var inner := Polygon2D.new()
	inner.polygon = Util.circle(size / 4, 14)
	inner.color = Color(0.85, 0.75, 1.0)
	add_child(inner)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _done:
		return
	position += direction * speed * delta
	for b in get_overlapping_bodies():
		if b.has_method("hit") and b.shield_team != team:
			b.hit(global_position, direction, CARVE_DAMAGE, size * 0.65, team,
					{"strict": true, "attacker": shooter})
	_life -= delta
	if _life <= 0.0:
		_end()

func _on_body_entered(body: Node) -> void:
	if _done or body == shooter or body.get("shield_team") == team:
		return
	if body.has_method("take_damage"):
		if body.team != team and not _hit.has(body):
			_hit[body] = true
			body.take_damage(damage, shooter)
		return
	if body.has_method("hit"):
		var fam = body.family
		if _hit.has(fam):
			return
		_hit[fam] = true
		pierce -= body.density
		if pierce <= 0.0:
			body.hit(global_position, direction, CARVE_DAMAGE, size * 0.65, team,
					{"strict": true, "attacker": shooter})
			_end()
		return
	_end()   # неразрушаемая рамка арены

func _end() -> void:
	if _done:
		return
	_done = true
	Util.flash(get_parent(), global_position, 45.0, Color(0.7, 0.5, 1.0))
	queue_free()
