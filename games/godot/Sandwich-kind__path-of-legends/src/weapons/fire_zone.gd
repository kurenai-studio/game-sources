class_name FireZone
extends Node2D
# ---------- Огонь после взрыва гранаты ----------

const RADIUS := 65.0
const DURATION := 4.0
const TICK := 0.5
var team := 0
var attacker = null
var _life := DURATION
var _tick := 0.0
var _flames: Array = []
var _base: Array = []

func _ready() -> void:
	var glow := Polygon2D.new()
	glow.polygon = Util.circle(RADIUS, 24)
	glow.color = Color(1.0, 0.35, 0.05, 0.25)
	add_child(glow)
	for i in 8:
		var f := ColorRect.new()
		f.color = Color(1.0, randf_range(0.3, 0.7), 0.1, 0.85)
		add_child(f)
		_flames.append(f)
		_base.append(Vector2(randf_range(-RADIUS * 0.7, RADIUS * 0.7), randf_range(-15, 25)))

func _process(_delta: float) -> void:
	for i in _flames.size():
		var h := randf_range(12.0, 34.0)
		_flames[i].size = Vector2(10, h)
		_flames[i].position = _base[i] - Vector2(5, h)

func _physics_process(delta: float) -> void:
	_life -= delta
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		_burn()
	modulate.a = clampf(_life, 0.0, 1.0)
	if _life <= 0.0:
		queue_free()

func _burn() -> void:
	for n in get_parent().get_children():
		if n.has_method("take_damage"):
			if n.team != team and n.is_alive() \
					and n.global_position.distance_to(global_position) <= RADIUS + 20.0:
				n.take_damage(5, attacker)
		elif n.has_method("hit") and n.shield_team != team:
			n.hit(global_position, Vector2.UP, 6, RADIUS, team,
					{"strict": true, "radial": true, "power": 0.35, "push": 0.0,
					"attacker": attacker, "fire": true})
