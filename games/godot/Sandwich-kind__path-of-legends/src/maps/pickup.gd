class_name Pickup
extends Area2D
# Шарик, который подбирает герой: «heal» — сердце (лечение), иначе — бафф.
# Боты подобрать не могут.

signal picked(text: String, color: Color)

const HEAL := 60

var kind := "heal"
var mega := false             # МЕГА-сфера: сразу даёт МЕГА-бафф
var allow_mega := true        # можно ли получить МЕГА, подобрав такой же бафф второй раз
var land_y := -INF            # падает с неба до этой высоты (дуэль)
var life := 0.0               # через сколько секунд исчезнет (0 — никогда)
var _vy := 0.0
var _vis: Node2D
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = Layer.PLAYER
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 26.0
	col.shape = cs
	add_child(col)
	_vis = Node2D.new()
	add_child(_vis)
	var c: Color = Color(1.0, 0.35, 0.45) if kind == "heal" else Buffs.TYPES[kind]["color"]
	var halo := Polygon2D.new()
	halo.polygon = Util.circle(26.0, 24)
	halo.color = Color(c.r, c.g, c.b, 0.25)
	_vis.add_child(halo)
	var ring := Line2D.new()
	var pts := Util.circle(22.0, 24)
	pts.append(pts[0])
	ring.points = pts
	ring.width = 3.0
	ring.default_color = c.lightened(0.3)
	_vis.add_child(ring)
	if kind == "heal":
		var heart := Polygon2D.new()
		var hp := PackedVector2Array()
		for i in 24:
			var t := TAU * i / 24.0
			hp.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * 0.85)
		heart.polygon = hp
		heart.color = Color(1.0, 0.25, 0.35)
		_vis.add_child(heart)
		var hshade := Polygon2D.new()             # объём: тень справа снизу, блик слева сверху
		var sh := PackedVector2Array()
		for q in hp:
			sh.append(q * 0.8 + Vector2(2.5, 2.5))
		hshade.polygon = sh
		hshade.color = Color(0.75, 0.1, 0.2, 0.45)
		_vis.add_child(hshade)
		var hgl := Polygon2D.new()
		hgl.polygon = Util.circle(3.5, 10)
		hgl.position = Vector2(-6, -6)
		hgl.color = Color(1, 0.9, 0.92, 0.9)
		_vis.add_child(hgl)
	else:
		var core := Polygon2D.new()
		core.polygon = Util.circle(15.0, 18)
		core.color = c.darkened(0.25)
		_vis.add_child(core)
		for k in 3:                                 # сфера: светлее к левому верхнему краю
			var layer := Polygon2D.new()
			layer.polygon = Util.circle(13.0 - k * 3.5, 18)
			layer.position = Vector2(-1.5, -1.5) * (k + 1)
			layer.color = c.lightened(0.08 * k)
			_vis.add_child(layer)
		var spec := Polygon2D.new()
		spec.polygon = Util.circle(3.0, 10)
		spec.position = Vector2(-6, -7)
		spec.color = Color(1, 1, 1, 0.85)
		_vis.add_child(spec)
		if mega:          # МЕГА-сфера: золотая корона лучей
			for i in 8:
				var ray := Polygon2D.new()
				ray.polygon = PackedVector2Array([Vector2(-4, -26), Vector2(4, -26), Vector2(0, -38)])
				ray.rotation = TAU * i / 8.0
				ray.color = Color(1.0, 0.85, 0.3)
				_vis.add_child(ray)
		var l := Label.new()
		l.text = Buffs.TYPES[kind]["letter"]
		l.size = Vector2(30, 30)
		l.position = Vector2(-15, -16)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 20)
		l.add_theme_color_override("font_color", Color(0.1, 0.08, 0.1))
		l.add_theme_constant_override("outline_size", 0)
		_vis.add_child(l)
	body_entered.connect(_on_body_entered)
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25)

func _process(delta: float) -> void:
	_t += delta
	_vis.position.y = sin(_t * 3.0) * 6.0
	if mega:
		_vis.rotation = sin(_t * 2.0) * 0.2
	if position.y < land_y:             # падает с неба
		_vy = minf(_vy + 900.0 * delta, 600.0)
		position.y = minf(land_y, position.y + _vy * delta)
	if life > 0.0:
		life -= delta
		if life < 3.0:
			modulate.a = 0.4 + 0.6 * absf(sin(_t * 10.0))
		if life <= 0.0:
			queue_free()

func _on_body_entered(body: Node) -> void:
	if not (body is Player) or body.is_bot or not body.is_alive():
		return
	if kind == "heal":
		if body.hp >= body.max_hp:
			return                     # здоровье полное — сердце остаётся лежать
		body.heal(HEAL)
		picked.emit("+%d" % HEAL, Color(1.0, 0.45, 0.5))
	else:
		var got_mega: bool = body.add_buff(kind, mega, allow_mega and body.allow_mega)
		var n: String = Buffs.title(kind, got_mega)
		picked.emit((n.to_upper() + "!") if got_mega else n + "!", Buffs.TYPES[kind]["color"])
	Util.flash(get_parent(), global_position, 40.0, Color(1, 1, 1, 0.7))
	queue_free()
