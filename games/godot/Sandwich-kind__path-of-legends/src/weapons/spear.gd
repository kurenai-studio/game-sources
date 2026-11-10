class_name Spear
extends Area2D
# Метательный снаряд гоблинов: летит дугой и втыкается.
#   payload = ""      — копьё: ранит и втыкается в землю
#   payload = "bomb"  — бомба: взрывается при касании
#   payload = "smoke" — дымовая бомба: при касании выпускает облако дыма
#   payload = "seed"  — семя Энта: тяжёлое, ранит, взрывается мелкими корнями

const GRAVITY := 1100.0

var shooter: Node
var team := 1
var velocity := Vector2.ZERO
var damage := 9
var payload := ""
var big := false                 # МЕГА-версия (луч Чемпиона шире)
var _stuck := false
var _life := 4.0
var _vis: Node2D
var _spark: Polygon2D
var _fuse := -1.0
var stun_time := 1.6            # оглушающая бомба Ассасина
var stun_radius := 150.0              # динамит: горит фитиль, потом взрыв

func _ready() -> void:
	collision_layer = 0
	collision_mask = Layer.WORLD | Layer.PLAYER | Layer.BOT
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 10.0 if payload in ["mud", "tina", "lava", "firebottle", "stun_bomb", "bomb", "smoke", "seed", "net", "net_poison", "flask", "thorn_big", "dynamite", "ruby", "snowball"] else 6.0
	col.shape = cs
	add_child(col)
	_vis = Node2D.new()
	add_child(_vis)
	match payload:
		"":
			_poly(PackedVector2Array([Vector2(-22, -2), Vector2(12, -2), Vector2(12, 2), Vector2(-22, 2)]), Color(0.55, 0.38, 0.2))
			_poly(PackedVector2Array([Vector2(12, -5), Vector2(24, 0), Vector2(12, 5)]), Color(0.75, 0.75, 0.78))
			_poly(PackedVector2Array([Vector2(-22, -4), Vector2(-16, 0), Vector2(-22, 4)]), Color(0.9, 0.3, 0.2))
		"mud":
			# ком болотной грязи с каплями
			var m := Polygon2D.new()
			m.polygon = PackedVector2Array([Vector2(-9, -3), Vector2(-5, -9), Vector2(3, -9), Vector2(9, -4), Vector2(8, 5), Vector2(1, 9), Vector2(-7, 7)])
			m.color = Color(0.30, 0.30, 0.18)
			_vis.add_child(m)
			_poly(PackedVector2Array([Vector2(-4, -6), Vector2(2, -7), Vector2(0, -3)]), Color(0.45, 0.48, 0.28))
		"tina":
			# ком тины Осоки: зелёно-бурый, с нитками водорослей
			var m2 := Polygon2D.new()
			m2.polygon = PackedVector2Array([Vector2(-8, -3), Vector2(-4, -8), Vector2(3, -8), Vector2(8, -3), Vector2(7, 5), Vector2(0, 8), Vector2(-7, 6)])
			m2.color = Color(0.30, 0.36, 0.20)
			_vis.add_child(m2)
			_poly(PackedVector2Array([Vector2(-5, -5), Vector2(1, -6), Vector2(-1, -2)]), Color(0.50, 0.66, 0.32))
			var strand := Line2D.new()
			strand.points = PackedVector2Array([Vector2(-6, 2), Vector2(-12, 5), Vector2(-15, 3)])
			strand.width = 2.0
			strand.default_color = Color(0.36, 0.56, 0.26)
			_vis.add_child(strand)
		"snowball":
			# снежок йети: белый ком с голубой тенью
			var sb := Polygon2D.new()
			sb.polygon = Util.circle(11.0, 14)
			sb.color = Color(0.94, 0.97, 1.0)
			_vis.add_child(sb)
			_poly(PackedVector2Array([Vector2(-2, 3), Vector2(8, 2), Vector2(4, 8), Vector2(-4, 8)]), Color(0.70, 0.80, 0.95))
			_poly(PackedVector2Array([Vector2(-6, -6), Vector2(-2, -8), Vector2(-3, -4)]), Color(1, 1, 1))
		"ice_arrow":
			# ледяная стрела: прозрачное древко, наконечник-сосулька
			_poly(PackedVector2Array([Vector2(-18, -1.2), Vector2(8, -1.2), Vector2(8, 1.2), Vector2(-18, 1.2)]), Color(0.70, 0.88, 1.0))
			_poly(PackedVector2Array([Vector2(8, -4), Vector2(18, 0), Vector2(8, 4)]), Color(0.92, 0.98, 1.0))
			_poly(PackedVector2Array([Vector2(-18, -4), Vector2(-12, -1), Vector2(-12, 1), Vector2(-18, 4)]), Color(0.45, 0.70, 0.95))
		"branch":
			# сук мёртвого дерева с отростками
			_poly(PackedVector2Array([Vector2(-16, -2), Vector2(14, -1.5), Vector2(14, 1.5), Vector2(-16, 2)]), Color(0.30, 0.25, 0.22))
			_poly(PackedVector2Array([Vector2(-2, -1), Vector2(6, -9), Vector2(8, -8), Vector2(1, 0)]), Color(0.30, 0.25, 0.22))
			_poly(PackedVector2Array([Vector2(-8, 1), Vector2(-14, 8), Vector2(-12, 9), Vector2(-6, 2)]), Color(0.26, 0.22, 0.20))
		"lava":
			# ком раскалённой лавы (Колосс Пробуждённый): тёмная корка, сквозь трещины светится огонь
			var lv := Polygon2D.new()
			lv.polygon = Util.circle(15.0, 18)
			lv.color = Color(1.0, 0.5, 0.15, 0.35)
			_vis.add_child(lv)
			_poly(PackedVector2Array([Vector2(-10, -4), Vector2(-5, -10), Vector2(4, -10), Vector2(10, -4), Vector2(9, 6), Vector2(1, 10), Vector2(-8, 8)]), Color(0.30, 0.14, 0.10))
			_poly(PackedVector2Array([Vector2(-6, -2), Vector2(0, -6), Vector2(1, -1), Vector2(6, 2), Vector2(0, 2), Vector2(-3, 6)]), Color(1.0, 0.55, 0.15))
			_poly(PackedVector2Array([Vector2(-1, -3), Vector2(2, -2), Vector2(0, 1)]), Color(1.0, 0.92, 0.5))
		"firebottle":
			# бутылка с горючей смесью и горящей тряпкой
			_poly(PackedVector2Array([Vector2(-5, -2), Vector2(5, -2), Vector2(6, 8), Vector2(-6, 8)]), Color(0.45, 0.65, 0.35, 0.85))
			_poly(PackedVector2Array([Vector2(-5, 2), Vector2(5, 2), Vector2(6, 8), Vector2(-6, 8)]), Color(0.95, 0.55, 0.15, 0.9))
			_poly(PackedVector2Array([Vector2(-2, -8), Vector2(2, -8), Vector2(2, -2), Vector2(-2, -2)]), Color(0.45, 0.65, 0.35, 0.85))
			_poly(PackedVector2Array([Vector2(-2, -13), Vector2(3, -12), Vector2(1, -8), Vector2(-2, -8)]), Color(0.85, 0.8, 0.7))
			_poly(PackedVector2Array([Vector2(-3, -13), Vector2(0, -21), Vector2(4, -13)]), Color(1.0, 0.6, 0.15))
			_poly(PackedVector2Array([Vector2(-1, -13), Vector2(0, -17), Vector2(2, -13)]), Color(1.0, 0.95, 0.5))
		"stun_bomb":
			# самодельная бомба: глиняный горшок, обмотка, фитиль с искрой
			var pot := Polygon2D.new()
			pot.polygon = Util.circle(9.0, 14)
			pot.color = Color(0.22, 0.20, 0.24)
			_vis.add_child(pot)
			_poly(PackedVector2Array([Vector2(-9, -2), Vector2(9, -2), Vector2(9, 2), Vector2(-9, 2)]), Color(0.55, 0.35, 0.75))
			_poly(PackedVector2Array([Vector2(-4, -6), Vector2(-1, -7), Vector2(-1, -4), Vector2(-4, -3)]), Color(0.5, 0.48, 0.55))
			_poly(PackedVector2Array([Vector2(-1, -9), Vector2(1, -9), Vector2(3, -15), Vector2(1, -15)]), Color(0.75, 0.65, 0.45))
			_spark = Polygon2D.new()
			_spark.polygon = Util.circle(2.5, 8)
			_spark.color = Color(1.0, 0.9, 0.4)
			_spark.position = Vector2(2, -16)
			_vis.add_child(_spark)
		"bomb":
			var b := Polygon2D.new()
			b.polygon = Util.circle(10.0, 12)
			b.color = Color(0.15, 0.15, 0.17)
			_vis.add_child(b)
			_poly(PackedVector2Array([Vector2(-2, -10), Vector2(2, -10), Vector2(3, -16), Vector2(-1, -16)]), Color(1.0, 0.6, 0.2))
		"smoke":
			var b := Polygon2D.new()
			b.polygon = Util.circle(9.0, 12)
			b.color = Color(0.55, 0.58, 0.55)
			_vis.add_child(b)
		"javelin", "beam":
			# пилум: древко с бликом, кожаная обмотка, длинный железный наконечник
			var beam := payload == "beam"
			_poly(PackedVector2Array([Vector2(-26, -2), Vector2(10, -2), Vector2(10, 2), Vector2(-26, 2)]), Color(0.62, 0.45, 0.24))
			_poly(PackedVector2Array([Vector2(-26, -2), Vector2(10, -2), Vector2(10, -1), Vector2(-26, -1)]), Color(0.8, 0.62, 0.38))
			_poly(PackedVector2Array([Vector2(-6, -2.5), Vector2(0, -2.5), Vector2(0, 2.5), Vector2(-6, 2.5)]), Color(0.35, 0.22, 0.12))
			for x in [-5.0, -3.0, -1.0]:
				_poly(PackedVector2Array([Vector2(x, -2.5), Vector2(x + 0.6, -2.5), Vector2(x + 0.6, 2.5), Vector2(x, 2.5)]), Color(0.5, 0.34, 0.18))
			_poly(PackedVector2Array([Vector2(10, -1.5), Vector2(16, -1.5), Vector2(16, 1.5), Vector2(10, 1.5)]), Color(0.45, 0.45, 0.5))
			var hc := Color(1.0, 0.92, 0.5) if beam else Color(0.82, 0.84, 0.9)
			_poly(PackedVector2Array([Vector2(16, -4), Vector2(29, 0), Vector2(16, 4)]), hc)
			_poly(PackedVector2Array([Vector2(16, -4), Vector2(29, 0), Vector2(16, 0)]), hc.lightened(0.3))
			if beam:
				var gl := Polygon2D.new()
				gl.polygon = Util.circle(7.0, 12)
				gl.position = Vector2(22, 0)
				gl.color = Color(1.0, 0.95, 0.6, 0.35)
				_vis.add_child(gl)
		"thorn", "thorn_big":
			# семя-колючка: тёмные шипы, зелёная оболочка с прожилками и бликом
			var r := 6.0 if payload == "thorn" else 10.0
			var th := Polygon2D.new()
			var pts := PackedVector2Array()
			for i in 16:
				var rr := r * 1.25 if i % 2 == 0 else r * 0.55
				pts.append(Vector2(cos(TAU * i / 16.0), sin(TAU * i / 16.0)) * rr)
			th.polygon = pts
			th.color = Color(0.42, 0.3, 0.15)
			_vis.add_child(th)
			var core := Polygon2D.new()
			core.polygon = Util.circle(r * 0.7, 12)
			core.color = Color(0.4, 0.62, 0.22)
			_vis.add_child(core)
			var vein := Line2D.new()
			vein.points = PackedVector2Array([Vector2(-r * 0.5, 0), Vector2(r * 0.5, 0)])
			vein.width = 1.0
			vein.default_color = Color(0.25, 0.42, 0.14)
			_vis.add_child(vein)
			var hl := Polygon2D.new()
			hl.polygon = Util.circle(r * 0.22, 8)
			hl.position = Vector2(-r * 0.25, -r * 0.3)
			hl.color = Color(0.75, 0.95, 0.55)
			_vis.add_child(hl)
		"flask":
			# склянка: стекло, зелёный яд с пузырьками, пробка, блик
			var glass := Polygon2D.new()
			glass.polygon = PackedVector2Array([Vector2(-2.5, -9), Vector2(2.5, -9), Vector2(2.5, -4), Vector2(7, 0),
					Vector2(7, 7), Vector2(4, 9), Vector2(-4, 9), Vector2(-7, 7), Vector2(-7, 0), Vector2(-2.5, -4)])
			glass.color = Color(0.85, 0.95, 0.9, 0.55)
			_vis.add_child(glass)
			var liq := Polygon2D.new()
			liq.polygon = PackedVector2Array([Vector2(-6.5, 1), Vector2(6.5, 1), Vector2(6.5, 7), Vector2(4, 8.5), Vector2(-4, 8.5), Vector2(-6.5, 7)])
			liq.color = Color(0.35, 0.9, 0.3)
			_vis.add_child(liq)
			for b in [Vector2(-2, 5), Vector2(2, 3), Vector2(3, 6)]:
				var bub := Polygon2D.new()
				bub.polygon = Util.circle(0.9, 6)
				bub.position = b
				bub.color = Color(0.8, 1.0, 0.7)
				_vis.add_child(bub)
			var cork := Polygon2D.new()
			cork.polygon = PackedVector2Array([Vector2(-3, -12), Vector2(3, -12), Vector2(2.5, -8.5), Vector2(-2.5, -8.5)])
			cork.color = Color(0.62, 0.45, 0.28)
			_vis.add_child(cork)
			var sh := Polygon2D.new()
			sh.polygon = PackedVector2Array([Vector2(-5.5, 0), Vector2(-4, 0), Vector2(-4, 6), Vector2(-5.5, 6)])
			sh.color = Color(1, 1, 1, 0.7)
			_vis.add_child(sh)
		"stone":
			var st := Polygon2D.new()
			st.polygon = PackedVector2Array([Vector2(-5, -3), Vector2(-1, -5), Vector2(5, -2), Vector2(4, 4), Vector2(-3, 4)])
			st.color = Color(0.55, 0.53, 0.5)
			_vis.add_child(st)
		"bone":
			_poly(PackedVector2Array([Vector2(-12, -2), Vector2(12, -2), Vector2(12, 2), Vector2(-12, 2)]), Color(0.9, 0.88, 0.8))
			for x in [-13.0, 11.0]:
				_poly(PackedVector2Array([Vector2(x, -5), Vector2(x + 3, -5), Vector2(x + 3, 5), Vector2(x, 5)]), Color(0.92, 0.9, 0.82))
		"net", "web", "net_poison":
			var c := Color(0.9, 0.9, 0.85, 0.9) if payload == "net" else Color(0.95, 0.95, 1.0, 0.85)
			if payload == "net_poison":
				c = Color(0.75, 0.95, 0.55, 0.9)
			if payload != "web":
				for k in 4:                       # грузики по краям сети
					var wgt := Polygon2D.new()
					wgt.polygon = Util.circle(2.0, 6)
					wgt.position = Vector2.from_angle(TAU * k / 4.0 + 0.4) * 11.0
					wgt.color = Color(0.45, 0.45, 0.5)
					_vis.add_child(wgt)
			for i in 4:
				var l := Line2D.new()
				l.width = 1.5
				l.default_color = c
				var a := PI * i / 4.0
				l.points = PackedVector2Array([Vector2(cos(a), sin(a)) * -11.0, Vector2(cos(a), sin(a)) * 11.0])
				_vis.add_child(l)
			var ring := Line2D.new()
			ring.width = 1.5
			ring.default_color = c
			var pts := Util.circle(7.0, 10)
			pts.append(pts[0])
			ring.points = pts
			_vis.add_child(ring)
		"seed":
			var b := Polygon2D.new()
			b.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-4, -9), Vector2(10, -6), Vector2(14, 0), Vector2(10, 6), Vector2(-4, 9)])
			b.color = Color(0.5, 0.75, 0.25)
			_vis.add_child(b)
		"dynamite":
			# шашка с горящим фитилём
			_poly(PackedVector2Array([Vector2(-10, -4), Vector2(8, -4), Vector2(8, 4), Vector2(-10, 4)]), Color(0.85, 0.18, 0.14))
			_poly(PackedVector2Array([Vector2(-10, -4), Vector2(8, -4), Vector2(8, -2), Vector2(-10, -2)]), Color(1.0, 0.45, 0.35))
			_poly(PackedVector2Array([Vector2(-4, -4), Vector2(-2, -4), Vector2(-2, 4), Vector2(-4, 4)]), Color(0.95, 0.85, 0.6))
			_poly(PackedVector2Array([Vector2(8, -1), Vector2(13, -2), Vector2(13, 0), Vector2(8, 1)]), Color(0.3, 0.25, 0.2))
			_spark = Polygon2D.new()
			_spark.polygon = Util.circle(3.0, 8)
			_spark.color = Color(1.0, 0.85, 0.3)
			_spark.position = Vector2(14, -1)
			_vis.add_child(_spark)
		"ruby":
			var gem := Polygon2D.new()
			gem.polygon = PackedVector2Array([Vector2(0, -11), Vector2(9, -3), Vector2(6, 9), Vector2(-6, 9), Vector2(-9, -3)])
			gem.color = Color(0.85, 0.12, 0.22)
			_vis.add_child(gem)
			_poly(PackedVector2Array([Vector2(0, -11), Vector2(9, -3), Vector2(0, 0), Vector2(-9, -3)]), Color(1.0, 0.45, 0.5))
			_poly(PackedVector2Array([Vector2(-3, -6), Vector2(-1, -6), Vector2(-1, -4), Vector2(-3, -4)]), Color(1, 1, 1))
			Shimmer.apply(_vis, 0.25)
		"shard":
			var c2: Color = get_meta("tint", Color(0.7, 0.9, 1.0))
			_poly(PackedVector2Array([Vector2(-7, 0), Vector2(0, -3), Vector2(9, 0), Vector2(0, 3)]), c2)
			_poly(PackedVector2Array([Vector2(-7, 0), Vector2(0, -3), Vector2(9, 0)]), c2.lightened(0.35))
	body_entered.connect(_on_body_entered)

func _poly(pts: PackedVector2Array, c: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = c
	_vis.add_child(p)

# Скорость броска, чтобы попасть из from в to за время t
static func aim(from: Vector2, to: Vector2, t: float) -> Vector2:
	return Vector2((to.x - from.x) / t, (to.y - from.y) / t - 0.5 * GRAVITY * t)

var _trail: Line2D
func _physics_process(delta: float) -> void:
	_life -= delta
	if payload == "beam" and not _stuck:
		# копья света оставляют золотой след
		if _trail == null:
			_trail = Line2D.new()
			_trail.width = 6.0
			_trail.default_color = Color(1.0, 0.85, 0.35, 0.6)
			_trail.top_level = true
			add_child(_trail)
		_trail.add_point(global_position)
		if _trail.get_point_count() > 10:
			_trail.remove_point(0)
	elif _trail and _stuck:
		_trail.queue_free()
		_trail = null
	if _fuse >= 0.0:
		_fuse -= delta
		if _spark:
			_spark.scale = Vector2.ONE * (1.0 + 0.6 * absf(sin(_fuse * 22.0)))
		if _fuse <= 0.0:
			_fuse = -1.0
			_dynamite_boom()
		return
	if _life <= 0.0:
		queue_free()
		return
	if _stuck:
		return
	velocity.y += GRAVITY * delta
	position += velocity * delta
	_vis.rotation = velocity.angle() if payload in ["", "javelin", "beam", "ice_arrow"] else _vis.rotation + delta * 8.0

func _on_body_entered(body: Node) -> void:
	if _stuck or body == shooter:
		return
	if is_instance_valid(shooter) and shooter is Player and shooter.is_bot and Util.is_one_way(body):
		return                        # копья ботов пролетают сквозные платформы (не бьют себе под ноги)
	if payload == "beam" and velocity.y < 0.0 and not body.has_method("take_damage"):
		return                        # копья света взлетают сквозь потолки и цепляются только при падении
	if body.has_method("take_damage"):
		if body.team == team or not body.is_alive():
			return
		if payload == "dynamite":
			pass                          # динамит не ранит ударом — только взрывом
		elif payload in ["", "seed", "stone", "bone", "javelin", "beam", "ruby", "shard", "firebottle", "lava", "branch"]:
			body.take_damage(damage, shooter)
		elif payload == "mud":
			body.take_damage(damage, shooter)
			body.slow(1.6, 0.5, "mud")                # заляпало грязью — вязнет
		elif payload == "snowball":
			body.take_damage(damage, shooter)
			body.chill(1.8, 0.55)                     # облепило снегом — иней
			body.velocity = Vector2(signf(velocity.x) * 420.0, -260.0)
		elif payload == "ice_arrow":
			body.take_damage(damage, shooter)
			body.chill(1.4)
		elif payload == "tina":
			body.take_damage(damage, shooter)
			body.slow(0.8, 0.75, "mud")               # ком тины: чуть замедляет
		elif payload == "net_poison":
			body.slow(2.0, 0.35)
			body._no_jump_t = maxf(body._no_jump_t, 2.0)
			body.poison(4.0, 8.0)          # МЕГА-сеть Чемпиона ещё и травит
			body.take_damage(4, shooter)
		elif payload == "net":
			body.slow(1.6, 0.35)          # сеть: сильно замедляет и не даёт прыгать
			body._no_jump_t = maxf(body._no_jump_t, 2.0)
			body.take_damage(4, shooter)
		elif payload == "web":
			body.slow(1.2, 0.45)          # паутина
			body.take_damage(3, shooter)
	elif body.has_method("hit") and body.get("shield_team") != team and payload in ["", "stone", "bone", "javelin", "beam", "shard"]:
		body.hit(global_position, velocity.normalized(), damage, 0.0, team, {"attacker": shooter})
	_burst()

func _burst() -> void:
	var parent := get_parent()
	match payload:
		"stone", "bone", "net", "web", "net_poison", "branch":
			pass
		"snowball", "ice_arrow":
			Fx.sparks(parent, global_position, Color(0.92, 0.97, 1.0), 10 if payload == "snowball" else 4, 180.0, 4.0)
		"mud", "tina":
			# грязь растекается лужицей: несколько секунд там вязнут все
			# (лужица Осоки — только её враги, а сама Осока в ней скользит)
			var pud := SwampBits.MudPuddle.new()
			pud.width = 90.0 if payload == "mud" else 80.0
			pud.life = 4.0 if payload == "mud" else 3.0
			if payload == "tina":
				pud.team = team
			var gh := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
					global_position + Vector2(0, -10), global_position + Vector2(0, 300), Layer.WORLD | Layer.FRAME))
			pud.position = gh["position"] if not gh.is_empty() else global_position
			parent.call_deferred("add_child", pud)
			Fx.sparks(parent, global_position, Color(0.32, 0.32, 0.2), 8, 160.0, 4.0)
		"javelin", "beam":
			# копьё Чемпиона втыкается; при ульте в него бьёт луч с неба
			_stuck = true
			set_deferred("monitoring", false)
			_life = 2.2
			if payload == "beam":
				var sb := SunBeam.new()
				sb.team = team
				sb.attacker = shooter
				sb.big = big
				sb.position = global_position
				parent.call_deferred("add_child", sb)
			var t2 := create_tween()
			t2.tween_interval(1.6)
			t2.tween_property(self, "modulate:a", 0.0, 0.5)
			return
		"thorn", "thorn_big":
			var big_t := payload == "thorn_big"
			Util.explode(parent, global_position, 85.0 if big_t else 55.0, damage, 12 if big_t else 8, team, shooter)
		"flask":
			PoisonPool.spill(parent, global_position, team, shooter)
		"":
			# копьё втыкается и через пару секунд исчезает
			_stuck = true
			set_deferred("monitoring", false)
			_life = 1.6
			var t := create_tween()
			t.tween_interval(1.1)
			t.tween_property(self, "modulate:a", 0.0, 0.5)
			return
		"firebottle", "lava":
			# бутылка разбивается (лава растекается) — земля горит
			Fx.sparks(parent, global_position, Color(1.0, 0.6, 0.2), 12, 220.0, 4.0)
			var fz := FireZone.new()
			fz.team = team
			fz.attacker = shooter if is_instance_valid(shooter) else null
			fz.position = global_position + Vector2(0, -6)
			parent.call_deferred("add_child", fz)
		"stun_bomb":
			_stun_blast(parent)
		"bomb":
			Util.explode(parent, global_position, 95.0, damage, 30, team, shooter)
		"smoke":
			var s := SmokeCloud.new()
			s.position = global_position
			parent.call_deferred("add_child", s)
		"seed":
			Util.explode(parent, global_position, 70.0, 0, 20, team, shooter)
		"dynamite":
			# падает и лежит, пока горит фитиль: видно, куда отбежать
			_stuck = true
			velocity = Vector2.ZERO
			set_deferred("monitoring", false)
			_fuse = 1.2
			_life = 3.0
			_warn_ring()
			return
		"ruby":
			# рубин раскалывается — веер острых осколков
			Fx.sparks(parent, global_position, Color(1.0, 0.3, 0.4), 10, 220.0, 4.0)
			for k in 5:
				var sh := Spear.new()
				sh.shooter = shooter if is_instance_valid(shooter) else null
				sh.team = team
				sh.payload = "shard"
				sh.damage = maxi(4, damage / 2)
				sh.set_meta("tint", Color(1.0, 0.35, 0.45))
				var a := -PI / 2 + (k - 2) * 0.45
				sh.velocity = Vector2.from_angle(a) * 520.0
				sh.position = global_position + Vector2(0, -12)
				parent.call_deferred("add_child", sh)
		"shard":
			Fx.sparks(parent, global_position, get_meta("tint", Color(0.7, 0.9, 1.0)), 4, 120.0, 2.0)
	queue_free()

# Оглушающая бомба: вспышка и звёздочки — все враги рядом замирают
func _stun_blast(parent: Node) -> void:
	var at := global_position
	Fx.ring(parent, at, stun_radius, Color(0.75, 0.55, 1.0, 0.9), 0.4, 8.0)
	Fx.ring(parent, at, stun_radius * 0.6, Color(1, 1, 1, 0.9), 0.3, 5.0)
	Util.flash(parent, at, stun_radius * 0.7, Color(0.95, 0.9, 1.0, 0.85))
	Fx.sparks(parent, at, Color(0.8, 0.6, 1.0), 18, 300.0, 4.0)
	for k in 6:
		Fx.star(parent, at + Vector2.from_angle(TAU * k / 6.0) * stun_radius * 0.5, 10.0, Color(1.0, 0.9, 0.4), 0.6)
	for n in parent.get_children():
		if n is Player and n.team != team and n.is_alive() and n.global_position.distance_to(at) <= stun_radius + n.body_size.x * 0.4:
			n.take_damage(damage, shooter if is_instance_valid(shooter) else null)
			n.stun(stun_time)

func _warn_ring() -> void:
	var ring := Line2D.new()
	var pts := Util.circle(110.0, 28)
	pts.append(pts[0])
	ring.points = pts
	ring.width = 3.0
	ring.default_color = Color(1.0, 0.4, 0.2, 0.55)
	add_child(ring)
	var t := ring.create_tween()
	t.tween_property(ring, "scale", Vector2(0.15, 0.15), 1.2).from(Vector2.ONE)

func _dynamite_boom() -> void:
	var parent := get_parent()
	Util.explode(parent, global_position, 110.0, damage, 60, team, shooter)
	Fx.ring(parent, global_position, 110.0, Color(1.0, 0.6, 0.2, 0.9), 0.35, 6.0)
	Fx.sparks(parent, global_position, Color(1.0, 0.7, 0.25), 14, 300.0, 4.0, true)
	queue_free()
