class_name Eruptor
extends Node2D
# ---------- Ульта UBER_TESTIK_2: взрывы из-под земли ----------

const STEP := 200.0          # шаг 10 клеток
var half_w := 70.0           # ширина взрыва 7 клеток
var height := 240.0
var damage := 35
var cell_chance := 1.0       # шанс задеть клетку блока
var mega := false            # МЕГА: шире, выше, сильнее, блоки задевает с шансом 35%
const INTERVAL := 0.5
const MAX_COUNT := 10
var team := 0
var attacker = null
var dir := 1
var feet := Vector2.ZERO
var map_w := 1152.0
var _n := 0
var _t := INTERVAL
var _marker: ColorRect

func _ready() -> void:
	if mega:
		half_w = 110.0
		height = 320.0
		damage = 55
		cell_chance = 0.35
	_marker = ColorRect.new()          # трещина там, где будет следующий взрыв
	_marker.color = Color(1.0, 0.2, 0.1, 0.7)
	_marker.size = Vector2(half_w * 2, 6)
	add_child(_marker)
	_place_marker()

func _x(n: int) -> float:
	return feet.x + dir * (150.0 + n * STEP)

func _inside(x: float) -> bool:
	return _n < MAX_COUNT and x > 20.0 and x < map_w - 20.0

func _place_marker() -> void:
	var x := _x(_n)
	_marker.visible = _inside(x)
	_marker.position = Vector2(x - half_w, feet.y - 3)

func _physics_process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = INTERVAL
	var x := _x(_n)
	if not _inside(x):
		queue_free()
		return
	_erupt(x)
	_n += 1
	_place_marker()

func _erupt(x: float) -> void:
	var parent := get_parent()
	var top := feet.y - height
	for n in parent.get_children():
		if n.has_method("take_damage"):
			if n.team != team and n.is_alive():
				var p: Vector2 = n.global_position
				if absf(p.x - x) <= half_w + 20.0 and p.y >= top and p.y <= feet.y + 10.0:
					n.take_damage(damage, attacker)
		elif n.has_method("hit") and n.shield_team != team:
			var opts := {"strict": true, "radial": true, "attacker": attacker,
					"origin": Vector2(x, feet.y + 80.0), "chance": cell_chance}
			n.hit(Vector2(x, feet.y - 50.0), Vector2.UP, 60, half_w, team, opts)
			n.hit(Vector2(x, feet.y - 170.0), Vector2.UP, 60, half_w, team, opts)
			if mega:
				n.hit(Vector2(x, feet.y - 290.0), Vector2.UP, 60, half_w, team, opts)
	var pillar := ColorRect.new()
	pillar.color = Color(1.0, 0.55, 0.15, 0.75)
	pillar.size = Vector2(half_w * 2, height)
	pillar.position = Vector2(x - half_w, top)
	pillar.pivot_offset = Vector2(half_w, height)
	pillar.scale = Vector2(1, 0.05)
	parent.add_child(pillar)
	var t := pillar.create_tween()
	t.tween_property(pillar, "scale", Vector2.ONE, 0.12)
	t.tween_property(pillar, "modulate:a", 0.0, 0.3)
	t.tween_callback(pillar.queue_free)
	Util.flash(parent, Vector2(x, feet.y - 20.0), half_w, Color(1.0, 0.7, 0.3))
