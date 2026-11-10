class_name Grenade
extends RigidBody2D
# ---------- Граната (TESTIK_1, способность 1) ----------

const RADIUS := 90.0
const MINI_RADIUS := 55.0
var team := 0
var attacker = null
var fuse := 1.4
var split := 0               # на сколько мини-гранат раскалывается при взрыве
var mini := false
var style := ""               # frag — прорисованная граната Солдата            # мини-граната: меньше, быстрее взрывается, без огня

func _ready() -> void:
	collision_layer = Layer.GREN
	collision_mask = Layer.WORLD | Layer.PLAYER | Layer.BOT
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.35
	mat.friction = 0.8
	physics_material_override = mat
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 8.0
	col.shape = cs
	add_child(col)
	if mini:
		fuse = randf_range(0.45, 0.7)
		cs.radius = 5.0
	var vis := Polygon2D.new()
	vis.polygon = Util.circle(6.0 if mini else 9.0, 12)
	vis.color = Color(0.45, 0.55, 0.2) if mini else Color(0.25, 0.45, 0.2)
	add_child(vis)
	if style == "frag":
		# осколочная граната: насечки-«ананас», запал, чека с кольцом, блик
		vis.color = Color(0.28, 0.34, 0.2)
		for y in [-4.0, 0.0, 4.0]:
			var l := Line2D.new()
			l.points = PackedVector2Array([Vector2(-8, y), Vector2(8, y)])
			l.width = 1.0
			l.default_color = Color(0.18, 0.22, 0.12)
			add_child(l)
		for x in [-4.0, 0.0, 4.0]:
			var l2 := Line2D.new()
			l2.points = PackedVector2Array([Vector2(x, -8), Vector2(x, 8)])
			l2.width = 1.0
			l2.default_color = Color(0.18, 0.22, 0.12)
			add_child(l2)
		var fuse_top := Polygon2D.new()
		fuse_top.polygon = PackedVector2Array([Vector2(-3, -8), Vector2(3, -8), Vector2(3, -12), Vector2(-3, -12)])
		fuse_top.color = Color(0.55, 0.55, 0.58)
		add_child(fuse_top)
		var lever := Line2D.new()
		lever.points = PackedVector2Array([Vector2(3, -11), Vector2(7, -9), Vector2(8, -3)])
		lever.width = 1.5
		lever.default_color = Color(0.6, 0.6, 0.62)
		add_child(lever)
		var ring := Line2D.new()
		var rp := Util.circle(2.2, 8)
		rp.append(rp[0])
		for i in rp.size():
			rp[i] += Vector2(-5, -12)
		ring.points = rp
		ring.width = 1.0
		ring.default_color = Color(0.8, 0.8, 0.82)
		add_child(ring)
		var hl := Polygon2D.new()
		hl.polygon = Util.circle(2.0, 8)
		hl.position = Vector2(-3, -3)
		hl.color = Color(0.55, 0.62, 0.42)
		add_child(hl)
	var mark := ColorRect.new()
	mark.size = Vector2(4, 4)
	mark.position = Vector2(-2, -9)
	mark.color = Color(1, 0.3, 0.2)
	mark.visible = style == ""
	add_child(mark)
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = fuse
	add_child(t)
	t.timeout.connect(_explode)
	t.start()

func _explode() -> void:
	var pos := global_position
	var parent := get_parent()
	if mini:
		Util.explode(parent, pos, MINI_RADIUS, 14, 25, team, attacker, true)
	else:
		Util.explode(parent, pos, RADIUS, 30, 40, team, attacker, true)
		var fire := FireZone.new()
		fire.team = team
		fire.attacker = attacker
		fire.position = pos
		parent.add_child(fire)
	for i in split:                # разлетается мини-гранатами
		var g := Grenade.new()
		g.mini = true
		g.team = team
		g.attacker = attacker
		g.position = pos + Vector2(0, -8)
		g.linear_velocity = Vector2(randf_range(-380, 380), randf_range(-560, -300))
		parent.add_child(g)
	queue_free()
