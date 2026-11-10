class_name Shuriken
extends Area2D
# ---------- Сюрикен (TESTIK_1, способность 3) ----------

var shooter: Node
var team := 0
var direction := Vector2.RIGHT
var speed := 950.0
var damage := 12
var pierce := 50.0           # ~2 ящика, или платформа + ящик, или 1 колонна
var _life := 1.0
var max_targets := 99        # сколько врагов пробьёт (сюрикены Самурая — 1, МЕГА — 3)
var chain := false           # электрический: перескакивает на ближайшего врага
var _targets := 0
var color := Color(0.85, 0.9, 0.95)
var detailed := false        # прорисованный сюрикен Самурая
var _hit := {}
var _done := false
var _vis: Polygon2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = Layer.WORLD | Layer.PLAYER | Layer.BOT
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 7.0
	col.shape = cs
	add_child(col)
	_vis = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var r := 10.0 if i % 2 == 0 else 3.5
		var a := TAU * i / 8
		pts.append(Vector2(cos(a), sin(a)) * r)
	_vis.polygon = pts
	_vis.color = color
	add_child(_vis)
	if detailed:
		# сюрикен Самурая: тёмная сталь, светлые режущие кромки, отверстие в центре
		_vis.color = color.darkened(0.35)
		for i in 4:
			var edge := Polygon2D.new()
			var a2 := TAU * i / 4.0
			edge.polygon = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a2) * 11.0, Vector2.from_angle(a2 + 0.45) * 3.5])
			edge.color = color.lightened(0.2)
			_vis.add_child(edge)
		var hole := Polygon2D.new()
		hole.polygon = Util.circle(1.8, 8)
		hole.color = Color(0.08, 0.07, 0.09)
		_vis.add_child(hole)
		var blur := Line2D.new()                 # след вращения
		var bp := Util.circle(11.0, 16)
		bp.append(bp[0])
		blur.points = bp
		blur.width = 1.5
		blur.default_color = Color(color, 0.25)
		add_child(blur)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _done:
		return
	position += direction * speed * delta
	_vis.rotation += 25.0 * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _done or body == shooter or body.get("shield_team") == team:
		return
	if body.has_method("take_damage"):
		if body.team != team and not _hit.has(body):
			_hit[body] = true
			body.take_damage(damage, shooter)
			if has_meta("burn") and body.is_alive():
				body.burn(3.0, get_meta("burn"), shooter)
			if chain:
				_chain_from(body)
			_targets += 1
			if _targets >= max_targets:
				_done = true
				queue_free()
		return
	if body.has_method("hit"):
		var fam = body.family
		if _hit.has(fam):
			return
		_hit[fam] = true
		# пролетает насквозь, лишь слегка повреждая блок в месте входа
		body.hit(global_position, direction, 10, 0.0, team, {"attacker": shooter})
		pierce -= body.density
		if pierce <= 0.0:
			_done = true
			queue_free()
		return
	_done = true
	queue_free()

# Электрический сюрикен: разряд перескакивает на ближайшего другого врага
func _chain_from(first: Node) -> void:
	var best = null
	var bd := 380.0
	for n in get_parent().get_children():
		if n is Player and n != first and n.team != team and n.is_alive():
			var d: float = n.global_position.distance_to(first.global_position)
			if d < bd:
				bd = d
				best = n
	if best:
		best.take_damage(damage, shooter)
		Fx.bolt(get_parent(), first.global_position, best.global_position, Color(0.55, 0.85, 1.0))
	Fx.zap(get_parent(), first.global_position, Color(0.55, 0.85, 1.0))
