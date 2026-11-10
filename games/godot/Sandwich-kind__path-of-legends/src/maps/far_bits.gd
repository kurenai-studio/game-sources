class_name FarBits
# ---------- Механики дальних локаций Арены (волны 61–80) ----------
# Ледяная тропа:
#   IcePatch      — наледь: кто на ней (герой или враг), тот катится по инерции —
#                   не остановиться и не развернуться сразу;
#   IcicleCluster — сосульки под карнизом: кто пройдёт под ними — они трещат
#                   и через полсекунды срываются (ранят и обдают инеем); потом отрастают;
#   snowdrift()   — сугроб: за ним можно укрыться, выстрелы его разбивают.
# Храм шторма:
#   WindGusts     — порывы ветра: стрелки на экране, дождь наклоняется — и всех на
#                   поле (героев и врагов) несколько секунд сносит в одну сторону;
#   LightningRod  — громоотвод: копит заряд (по нему бегут искры, на земле круг) —
#                   и в него бьёт молния, разряд ранит всех вокруг. Владыке Бури
#                   громоотводы служат ловушкой: в «Перегрузке» уводят его молнию.
# Лавовые просторы:
#   LavaPool      — лавовое озеро: обжигает и подбрасывает всех, кроме огненных тварей;
#   VolcanoBombs  — вулкан плюётся бомбами: на земле загорается круг, потом падает
#                   ком лавы — взрыв и горящая земля.
# Тронный зал Тёмного лорда:
#   Chandelier    — люстра на цепи: время от времени скрипит, качается — и падает
#                   на того, кто под ней (своих и чужих); потом опускают новую;
#   AbyssGrate    — решётка в полу: в щелях разгорается лиловый свет — и бьёт
#                   столб пламени бездны.

static func _players(world: Node) -> Array:
	var res: Array = []
	for n in world.get_children():
		if n is Player and n.is_alive():
			res.append(n)
	return res

static func _feet(n: Player) -> float:
	return n.global_position.y + n.body_size.y / 2

static func _fireproof(n: Player) -> bool:
	return n.has_meta("fireproof")

# ======================= Ледяная тропа =======================
class IcePatch extends Node2D:
	var width := 280.0
	var _t := 0.0
	var _glints: Array = []

	func _ready() -> void:
		z_index = 2
		var ice := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 11:
			var x := -width / 2 + width * i / 10.0
			pts.append(Vector2(x, -3.0 - sin(PI * i / 10.0) * 2.0))
		pts.append(Vector2(width / 2 + 6, 6))
		pts.append(Vector2(-width / 2 - 6, 6))
		ice.polygon = pts
		ice.color = Color(0.70, 0.88, 1.0, 0.88)
		add_child(ice)
		var rim := Line2D.new()
		rim.points = pts.slice(0, 11)
		rim.width = 2.0
		rim.default_color = Color(0.95, 0.99, 1.0, 0.95)
		add_child(rim)
		for k in 5:                                         # трещинки во льду
			var cr := Line2D.new()
			var x0 := -width / 2 + 20 + k * (width - 40) / 4.0
			cr.points = PackedVector2Array([Vector2(x0, -1), Vector2(x0 + 8, 2), Vector2(x0 + 4, 5)])
			cr.width = 1.0
			cr.default_color = Color(0.45, 0.65, 0.85, 0.8)
			add_child(cr)
		for k in 3:                                         # блики
			var g := Polygon2D.new()
			g.polygon = PackedVector2Array([Vector2(-10, -1), Vector2(10, -2), Vector2(8, 0), Vector2(-12, 1)])
			g.color = Color(1, 1, 1, 0.8)
			g.position = Vector2(-width * 0.3 + k * width * 0.3, -2)
			add_child(g)
			_glints.append(g)

	func _physics_process(delta: float) -> void:
		_t += delta
		for i in _glints.size():
			_glints[i].modulate.a = 0.35 + 0.65 * absf(sin(_t * 1.3 + i * 1.7))
		for n in FarBits._players(get_parent()):
			if n.flying:
				continue
			if absf(n.global_position.x - global_position.x) < width / 2 and absf(FarBits._feet(n) - global_position.y) < 14.0:
				n.slip(0.12)
				if n.is_on_floor() and absf(n.velocity.x) > 220.0 and randf() < 0.12:
					Fx.sparks(get_parent(), Vector2(n.global_position.x, global_position.y - 3), Color(0.85, 0.95, 1.0), 2, 90.0, 2.5, true)

class IcicleCluster extends Node2D:
	var width := 120.0
	var count := 4
	var land_y := 940.0
	var _state := "ready"
	var _t := 0.0
	var _ice: Array = []

	func _ready() -> void:
		z_index = 1
		for i in count:
			var ic := Polygon2D.new()
			var w := randf_range(9.0, 13.0)
			var l := randf_range(32.0, 54.0)
			ic.polygon = PackedVector2Array([Vector2(-w / 2, 0), Vector2(w / 2, 0), Vector2(1, l * 0.8), Vector2(0, l)])
			ic.color = Color(0.72, 0.90, 1.0, 0.92)
			ic.position = Vector2(-width / 2 + 12 + i * (width - 24) / maxf(1, count - 1), 0)
			var shine := Line2D.new()
			shine.points = PackedVector2Array([Vector2(-w / 4, 2), Vector2(-1, l * 0.7)])
			shine.width = 2.0
			shine.default_color = Color(1, 1, 1, 0.7)
			ic.add_child(shine)
			add_child(ic)
			_ice.append(ic)

	func _physics_process(delta: float) -> void:
		_t -= delta
		match _state:
			"ready":
				for n in FarBits._players(get_parent()):
					if n.flying or n.cutscene_shield:
						continue
					var dy: float = n.global_position.y - global_position.y
					if absf(n.global_position.x - global_position.x) < width / 2 + 16.0 and dy > 0.0 and dy < 700.0:
						_state = "crack"
						_t = 0.55
						Fx.sparks(get_parent(), global_position + Vector2(0, 4), Color(0.9, 0.96, 1.0), 6, 80.0, 3.0)
						break
			"crack":
				for ic in _ice:
					ic.rotation = randf_range(-0.08, 0.08)
				if _t <= 0.0:
					_drop()
			"regrow":
				var k := clampf(1.0 - _t / 7.0, 0.0, 1.0)
				for ic in _ice:
					ic.scale = Vector2(1.0, k)
					ic.modulate.a = k
				if _t <= 0.0:
					_state = "ready"

	func _drop() -> void:
		for ic in _ice:
			ic.rotation = 0.0
			var f := FallingIcicle.new()
			f.position = ic.global_position
			f.land_y = land_y
			f.shape = ic.polygon
			get_parent().add_child(f)
			ic.scale = Vector2(1.0, 0.0)
			ic.modulate.a = 0.0
		_state = "regrow"
		_t = 7.0

# Одна сосулька с неба (ливень сосулек Ётуна): тень на земле, через delay — падает
static func drop_icicle(world: Node, x: float, land_y: float, delay: float, dmg := 14) -> void:
	var shadow := Polygon2D.new()
	var pts := Util.circle(26.0, 14)
	for i in pts.size():
		pts[i].y *= 0.25
	shadow.polygon = pts
	shadow.color = Color(0.1, 0.2, 0.4, 0.0)
	shadow.position = Vector2(x, land_y - 2.0)
	shadow.z_index = 3
	world.add_child(shadow)
	var t := shadow.create_tween()
	t.tween_property(shadow, "color:a", 0.5, delay)
	t.tween_callback(func():
		var w2 := shadow.get_parent()
		if w2:
			var f := FallingIcicle.new()
			f.position = Vector2(x, land_y - 760.0)
			f.land_y = land_y
			f.damage = dmg
			f.shape = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(1, 44), Vector2(0, 56)])
			w2.add_child(f)
		shadow.queue_free())

class FallingIcicle extends Node2D:
	var land_y := 940.0
	var damage := 14
	var shape: PackedVector2Array
	var _v := 120.0
	var _hit := {}

	func _ready() -> void:
		z_index = 4
		var p := Polygon2D.new()
		p.polygon = shape
		p.color = Color(0.75, 0.92, 1.0, 0.95)
		add_child(p)

	func _physics_process(delta: float) -> void:
		_v += 2600.0 * delta
		position.y += _v * delta
		for n in FarBits._players(get_parent()):
			if _hit.has(n):
				continue
			var d: Vector2 = n.global_position - (global_position + Vector2(0, 30))
			if absf(d.x) < n.body_size.x / 2 + 8.0 and absf(d.y) < n.body_size.y / 2 + 24.0:
				_hit[n] = true
				n.take_damage(damage)
				n.chill(1.5)
		if position.y + 40.0 >= land_y:
			var world := get_parent()
			Fx.sparks(world, Vector2(position.x, land_y - 4), Color(0.8, 0.94, 1.0), 10, 220.0, 4.0, true)
			Fx.ring(world, Vector2(position.x, land_y), 40.0, Color(0.8, 0.95, 1.0, 0.8), 0.25, 3.0, 0.3)
			queue_free()

# Сугроб: горка снега из клеток (верх скруглён), выстрелы её разбивают
static func snowdrift(world: Node, x: float, floor_y: float, w := 140.0, h := 60.0) -> void:
	var d := Maps.make_destructible(Rect2(x - w / 2, floor_y - h, w, h), 20.0, Maps.SNOW, 30, 18.0)
	d.anchored = true
	var cols := int(w / 20.0)
	var rows := int(h / 20.0)
	for cx in cols:
		var k := 1.0 - absf((cx + 0.5) / cols - 0.5) * 2.0         # 0 по краям, 1 в середине
		var top := int(round((1.0 - k) * (rows - 1)))
		for cy in range(top, rows):
			d.cells[Vector2i(cx, cy)] = d.cell_hp
			d.cell_colors[Vector2i(cx, cy)] = Maps.SNOW if cy == top else Maps.SNOW.darkened(0.05 + 0.03 * cy)
			if cy == rows - 1:
				d.anchors.append(Vector2i(cx, cy))
	world.add_child(d)

# ======================= Храм шторма =======================
class WindGusts extends Node2D:
	var weather: Weather
	var _state := "calm"
	var _t := 6.0
	var _dir := 1
	var _clock := 0.0

	func _physics_process(delta: float) -> void:
		_t -= delta
		_clock += delta
		var base := 0.18 * sin(_clock * 0.4)
		match _state:
			"calm":
				_set_wind(lerpf(_wind(), base, delta * 1.5))
				if _t <= 0.0:
					_state = "warn"
					_t = 1.6
					_dir = 1 if randf() < 0.5 else -1
					if weather:
						weather.gust_dir = _dir
			"warn":
				_set_wind(lerpf(_wind(), _dir * 0.45, delta * 2.0))
				if _t <= 0.0:
					_state = "gust"
					_t = 3.6
			"gust":
				_set_wind(lerpf(_wind(), _dir * 1.0, delta * 4.0))
				for n in FarBits._players(get_parent()):
					if n.frozen or n.cutscene_shield:
						continue
					n.push_wind(_dir * (140.0 if n.flying else 250.0))
					if n.is_on_floor() and randf() < 0.04:
						Fx.sparks(get_parent(), Vector2(n.global_position.x, FarBits._feet(n) - 4), Color(0.75, 0.8, 0.9), 2, 120.0, 3.0, true)
				if _t <= 0.0:
					_state = "calm"
					_t = randf_range(7.0, 11.0)
					if weather:
						weather.gust_dir = 0

	func _wind() -> float:
		return weather.wind if weather else 0.0

	func _set_wind(v: float) -> void:
		if weather:
			weather.wind = v

	func gusting() -> int:
		return _dir if _state == "gust" else 0

class LightningRod extends Node2D:
	const R := 170.0
	var auto := true                   # сам по себе копит заряд и бьёт (в «Перегрузке» Владыки — по команде)
	var _state := "idle"
	var _t := 0.0
	var _ball: Polygon2D
	var _aura: Polygon2D
	var _mark: Node2D
	var height := 120.0

	func _ready() -> void:
		z_index = -1
		_t = randf_range(6.0, 12.0)
		var rod := Line2D.new()
		rod.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -height)])
		rod.width = 6.0
		rod.default_color = Color(0.72, 0.45, 0.22)
		add_child(rod)
		var shine := Line2D.new()
		shine.points = PackedVector2Array([Vector2(-1.5, -4), Vector2(-1.5, -height + 6)])
		shine.width = 1.5
		shine.default_color = Color(1.0, 0.75, 0.45, 0.8)
		add_child(shine)
		for k in 4:                                       # медная обмотка
			var coil := Line2D.new()
			var y := -20.0 - k * 22.0
			coil.points = PackedVector2Array([Vector2(-7, y), Vector2(7, y - 4)])
			coil.width = 3.0
			coil.default_color = Color(0.55, 0.32, 0.16)
			add_child(coil)
		var base := Polygon2D.new()
		base.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(-10, -12), Vector2(10, -12), Vector2(16, 0)])
		base.color = Color(0.40, 0.42, 0.48)
		add_child(base)
		_aura = Polygon2D.new()
		_aura.polygon = Util.circle(20.0, 16)
		_aura.color = Color(0.55, 0.75, 1.0, 0.0)
		_aura.position = Vector2(0, -height)
		add_child(_aura)
		_ball = Polygon2D.new()
		_ball.polygon = Util.circle(7.0, 12)
		_ball.color = Color(0.85, 0.65, 0.40)
		_ball.position = Vector2(0, -height)
		add_child(_ball)

	func tip() -> Vector2:
		return global_position + Vector2(0, -height)

	# Стоит ли герой под защитой громоотвода (для «Перегрузки» Владыки Бури)
	func shelters(n: Player) -> bool:
		return absf(n.global_position.x - global_position.x) < 150.0 and absf(FarBits._feet(n) - global_position.y) < 200.0

	func glow(on: bool) -> void:
		_aura.color.a = 0.55 if on else 0.0
		_ball.color = Color(0.85, 0.95, 1.0) if on else Color(0.85, 0.65, 0.40)

	func _physics_process(delta: float) -> void:
		if not auto:
			_aura.scale = Vector2.ONE * (1.0 + 0.2 * sin(Time.get_ticks_msec() * 0.02))
			return
		_t -= delta
		match _state:
			"idle":
				if _t <= 0.0:
					_state = "charge"
					_t = 1.4
					_mark = Fx.rune_circle(get_parent(), global_position, R, Color(0.55, 0.75, 1.0, 0.85), 1.5)
			"charge":
				var k := 1.0 - _t / 1.4
				_aura.color.a = 0.2 + 0.5 * k
				_aura.scale = Vector2.ONE * (0.6 + k)
				if randf() < 0.4:
					Fx.zap(get_parent(), global_position + Vector2(randf_range(-4, 4), -randf() * height), Color(0.7, 0.85, 1.0), 14.0)
				if _t <= 0.0:
					strike()
					_state = "idle"
					_t = randf_range(8.0, 13.0)

	# Удар молнии в громоотвод: разряд бьёт всех вокруг
	func strike() -> void:
		var world := get_parent()
		_aura.color.a = 0.0
		_aura.scale = Vector2.ONE
		Fx.bolt(world, tip() + Vector2(randf_range(-60, 60), -900.0), tip(), Color(0.85, 0.92, 1.0))
		Fx.bolt(world, tip() + Vector2(randf_range(-60, 60), -900.0), tip(), Color(0.6, 0.75, 1.0))
		Util.flash(world, tip(), 70.0, Color(0.85, 0.92, 1.0, 0.9))
		for k in 5:
			var to := global_position + Vector2(randf_range(-R, R), randf_range(-6, 4))
			Fx.bolt(world, tip(), to, Color(0.7, 0.85, 1.0))
		Fx.ring(world, global_position, R, Color(0.7, 0.85, 1.0, 0.9), 0.35, 5.0, 0.3)
		Fx.shake(world, 5.0)
		for n in FarBits._players(world):
			if n.cutscene_shield:
				continue
			if absf(n.global_position.x - global_position.x) < R and FarBits._feet(n) > global_position.y - 260.0 \
					and FarBits._feet(n) < global_position.y + 40.0:
				n.take_damage(18)
				Fx.zap(world, n.global_position, Color(0.8, 0.9, 1.0), 30.0)

	# Молния из громоотвода в цель (Перегрузка Владыки Бури)
	func discharge_into(target: Vector2) -> void:
		var world := get_parent()
		Fx.bolt(world, tip() + Vector2(0, -900.0), tip(), Color(0.9, 0.95, 1.0))
		for k in 3:
			Fx.bolt(world, tip(), target, Color(0.75, 0.88, 1.0) if k % 2 == 0 else Color(1, 1, 1))
		Util.flash(world, tip(), 90.0, Color(0.85, 0.92, 1.0, 0.95))
		Util.flash(world, target, 120.0, Color(0.85, 0.92, 1.0, 0.95))

# ======================= Лавовые просторы =======================
class LavaPool extends Node2D:
	var width := 240.0
	var glow_layer: CanvasLayer
	var _t := 0.0
	var _cd := {}
	var _surface: Polygon2D
	var _bubbles: Array = []
	var _glow: Sprite2D

	func _ready() -> void:
		z_index = 2
		var crust := Polygon2D.new()                     # тёмная корка по краю
		var cp := PackedVector2Array()
		for i in 13:
			var x := -width / 2 - 10 + (width + 20) * i / 12.0
			cp.append(Vector2(x, -3.0 - sin(PI * i / 12.0) * 3.0))
		cp.append(Vector2(width / 2 + 10, 8))
		cp.append(Vector2(-width / 2 - 10, 8))
		crust.polygon = cp
		crust.color = Color(0.12, 0.08, 0.08)
		add_child(crust)
		_surface = Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 13:
			var x := -width / 2 + width * i / 12.0
			pts.append(Vector2(x, -2.0 - sin(PI * i / 12.0) * 2.0))
		pts.append(Vector2(width / 2, 7))
		pts.append(Vector2(-width / 2, 7))
		_surface.polygon = pts
		_surface.color = Color(1.0, 0.45, 0.10)
		add_child(_surface)
		for k in 4:                                       # тёмные плиты корки на поверхности
			var pl := Polygon2D.new()
			pl.polygon = PackedVector2Array([Vector2(-12, -1), Vector2(10, -2), Vector2(14, 2), Vector2(-9, 3)])
			pl.color = Color(0.25, 0.10, 0.06, 0.85)
			pl.position = Vector2(-width * 0.35 + k * width * 0.23, 1)
			add_child(pl)
		for k in 5:
			var b := Polygon2D.new()
			b.polygon = Util.circle(4.0, 8)
			b.color = Color(1.0, 0.75, 0.3)
			b.position = Vector2(randf_range(-width / 2 + 10, width / 2 - 10), -3)
			add_child(b)
			_bubbles.append(b)
		_glow = Torch.make_glow(width * 1.4, Color(1.0, 0.5, 0.2, 0.75))
		_glow.scale.y *= 0.5
		if glow_layer:
			_glow.position = position + Vector2(0, -10)
			glow_layer.add_child(_glow)

	func _physics_process(delta: float) -> void:
		_t += delta
		_surface.color = Color(1.0, 0.42 + 0.12 * sin(_t * 2.0), 0.10)
		for i in _bubbles.size():
			var b: Polygon2D = _bubbles[i]
			var k := fmod(_t * 0.7 + i * 0.31, 1.0)
			b.scale = Vector2.ONE * (0.3 + k * 1.3)
			b.modulate.a = 1.0 - k
			if k < 0.02:
				b.position.x = randf_range(-width / 2 + 10, width / 2 - 10)
		if randf() < delta * 1.5:
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-width / 2, width / 2), -4), Color(1.0, 0.6, 0.2), 2, 120.0, 3.0, true)
		for n in FarBits._players(get_parent()):
			if n.flying or FarBits._fireproof(n):
				continue
			if absf(n.global_position.x - global_position.x) < width / 2 and absf(FarBits._feet(n) - global_position.y) < 16.0:
				var cd: float = _cd.get(n, 0.0)
				if Time.get_ticks_msec() / 1000.0 >= cd:
					_cd[n] = Time.get_ticks_msec() / 1000.0 + 0.45
					n.take_damage(7)
					n.burn(1.5, 6.0)
					n.velocity.y = -560.0                  # обжёгся — подпрыгнул
					Fx.sparks(get_parent(), Vector2(n.global_position.x, global_position.y - 4), Color(1.0, 0.55, 0.15), 8, 200.0, 4.0, true)

class VolcanoBombs extends Node2D:
	var map_w := 2600.0
	var floor_y := 940.0
	var _t := 6.0

	func _physics_process(delta: float) -> void:
		_t -= delta
		if _t > 0.0:
			return
		_t = randf_range(5.0, 8.0)
		var who: Array = []
		for n in FarBits._players(get_parent()):
			if not n.is_bot and not n.is_minion:          # целится в героев (в Дуэли — в обоих)
				who.append(n)
		var shots := 1 if who.size() < 2 else 2
		for k in shots:
			var x := randf_range(200.0, map_w - 200.0)
			if not who.is_empty() and randf() < 0.8:
				var w: Player = who[k % who.size()]
				x = clampf(w.global_position.x + randf_range(-160.0, 160.0), 150.0, map_w - 150.0)
			_launch(x)

	func _launch(x: float) -> void:
		var world := get_parent()
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
				Vector2(x, 40.0), Vector2(x, floor_y + 20.0), Layer.WORLD | Layer.FRAME))
		var land: float = hit["position"].y if not hit.is_empty() else floor_y
		var mark := Fx.rune_circle(world, Vector2(x, land), 70.0, Color(1.0, 0.45, 0.15, 0.9), 1.5)
		mark.z_index = 3
		var b := LavaBomb.new()
		b.position = Vector2(x + randf_range(-120, 120), -160.0)
		b.goal = Vector2(x, land)
		b.delay = 0.6
		world.add_child(b)

class LavaBomb extends Node2D:
	var goal := Vector2.ZERO
	var delay := 0.0
	var team := -1
	var attacker = null
	var damage := 16
	var _from := Vector2.ZERO
	var _k := 0.0
	var _vis: Node2D

	func _ready() -> void:
		z_index = 6
		_from = position
		_vis = Node2D.new()
		add_child(_vis)
		var rock := Polygon2D.new()
		rock.polygon = PackedVector2Array([Vector2(-14, -6), Vector2(-4, -15), Vector2(10, -12), Vector2(15, 2), Vector2(6, 13), Vector2(-10, 12)])
		rock.color = Color(0.22, 0.10, 0.06)
		_vis.add_child(rock)
		var hot := Polygon2D.new()
		hot.polygon = Util.circle(8.0, 10)
		hot.color = Color(1.0, 0.6, 0.2)
		_vis.add_child(hot)
		visible = delay <= 0.0

	func _physics_process(delta: float) -> void:
		if delay > 0.0:
			delay -= delta
			visible = delay <= 0.0
			return
		_k = minf(1.0, _k + delta / 0.75)
		position = _from.lerp(goal, _k * _k)
		_vis.rotation += delta * 8.0
		if randf() < 0.6:
			Fx.sparks(get_parent(), position, Color(1.0, 0.55, 0.2), 1, 60.0, 4.0)
		if _k >= 1.0:
			var world := get_parent()
			Util.explode(world, goal + Vector2(0, -10), 95.0, damage, 25, team, attacker, true)
			Fx.ring(world, goal, 110.0, Color(1.0, 0.5, 0.15, 0.9), 0.4, 6.0, 0.3)
			Fx.sparks(world, goal + Vector2(0, -6), Color(1.0, 0.6, 0.2), 16, 300.0, 5.0, true)
			var fz := FireZone.new()
			fz.team = team
			fz.attacker = attacker
			fz.position = goal
			world.add_child(fz)
			queue_free()

# ======================= Тронный зал =======================
class Chandelier extends Node2D:
	var hang := 300.0                 # длина цепи (от потолка до люстры)
	var floor_y := 940.0
	var glow_layer: CanvasLayer
	var _state := "idle"
	var _t := 0.0
	var _chain: Line2D
	var _body: Node2D
	var _shadow: Polygon2D
	var _glows: Array = []
	var _wait := 0.0
	var _clock := 0.0
	var _land := 940.0

	func _ready() -> void:
		z_index = 1
		_t = randf_range(9.0, 15.0)
		_chain = Line2D.new()
		_chain.width = 3.0
		_chain.default_color = Color(0.30, 0.28, 0.30)
		add_child(_chain)
		_build_body()
		_set_hang(hang)

	func _build_body() -> void:
		_body = Node2D.new()
		add_child(_body)
		var ring := Line2D.new()
		var rp := Util.circle(1.0, 24)
		rp.append(rp[0])
		for i in rp.size():
			rp[i] = rp[i] * Vector2(62, 12)
		ring.points = rp
		ring.width = 5.0
		ring.default_color = Color(0.22, 0.18, 0.18)
		_body.add_child(ring)
		for s in [-1.0, 1.0]:                             # подвесы к цепи
			var arm := Line2D.new()
			arm.points = PackedVector2Array([Vector2(0, -36), Vector2(s * 60, 0)])
			arm.width = 2.0
			arm.default_color = Color(0.25, 0.22, 0.22)
			_body.add_child(arm)
		var spike := Polygon2D.new()
		spike.polygon = PackedVector2Array([Vector2(-6, 6), Vector2(6, 6), Vector2(0, 26)])
		spike.color = Color(0.22, 0.18, 0.18)
		_body.add_child(spike)
		for i in 7:                                       # свечи с огоньками
			var x := -54.0 + i * 18.0
			var candle := Polygon2D.new()
			candle.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(3, -12), Vector2(-3, -12)])
			candle.color = Color(0.85, 0.80, 0.70)
			candle.position = Vector2(x, -4 + absf(x) * 0.05)
			_body.add_child(candle)
			var fl := Polygon2D.new()
			fl.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(0, -9), Vector2(3, 0)])
			fl.color = Color(1.0, 0.45, 0.2)
			fl.position = candle.position + Vector2(0, -12)
			_body.add_child(fl)
		if glow_layer:
			for k in 3:
				var g := Torch.make_glow(140.0, Color(1.0, 0.45, 0.2, 0.7))
				glow_layer.add_child(g)
				_glows.append([g, Vector2(-40 + k * 40, -16)])

	func _set_hang(h: float) -> void:
		_chain.points = PackedVector2Array([Vector2(0, 0), Vector2(0, h - 36)])
		_body.position = Vector2(0, h)

	func _process(_delta: float) -> void:
		for gg in _glows:
			var g: Sprite2D = gg[0]
			if is_instance_valid(g):
				g.position = _body.global_position + (gg[1] as Vector2)
				g.visible = _body.visible

	func _physics_process(delta: float) -> void:
		_t -= delta
		_clock += delta
		match _state:
			"idle":
				_body.rotation = sin(_clock * 1.1) * 0.03
				if _t <= 0.0:
					# падает, когда под ней кто-то есть (подождёт до 6 с), иначе — всё равно
					var under := false
					for n in FarBits._players(get_parent()):
						if not n.flying and absf(n.global_position.x - global_position.x) < 140.0:
							under = true
					_wait += delta
					if under or _wait > 6.0:
						_wait = 0.0
						_state = "warn"
						_t = 1.1
						_warn()
			"warn":
				_body.rotation = sin(_clock * 18.0) * 0.12
				if randf() < 0.3:
					Fx.sparks(get_parent(), global_position + Vector2(randf_range(-4, 4), 4), Color(0.8, 0.7, 0.5), 2, 80.0, 3.0)
				if _t <= 0.0:
					_state = "fall"
					_t = 0.0
			"fall":
				_body.position.y += (900.0 + _t * 2200.0) * delta
				_t += delta
				_chain.points = PackedVector2Array([Vector2(0, 0), Vector2(0, maxf(10.0, hang * 0.4))])
				var land := _land - global_position.y
				for n in FarBits._players(get_parent()):
					var d: Vector2 = n.global_position - _body.global_position
					if absf(d.x) < 70.0 + n.body_size.x / 2 and absf(d.y) < n.body_size.y / 2 + 14.0 and not n.has_meta("_chand_hit"):
						n.set_meta("_chand_hit", true)
						n.take_damage(24)
						n.stun(0.6)
				if _body.position.y >= land - 10.0:
					_crash()
			"gone":
				if _t <= 0.0:
					_state = "lower"
					_t = 0.0
					_body.visible = true
					_body.rotation = 0.0
					_body.position.y = 0.0
			"lower":
				_t += delta
				var h := lerpf(0.0, hang, clampf(_t / 2.5, 0.0, 1.0))
				_set_hang(h)
				if _t >= 2.5:
					_state = "idle"
					_t = randf_range(10.0, 16.0)

	func _warn() -> void:
		# куда упадёт: первая опора под люстрой (пол или уступ)
		var from := _body.global_position + Vector2(0, 30)
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, Vector2(from.x, floor_y + 20.0), Layer.WORLD | Layer.FRAME))
		_land = hit["position"].y if not hit.is_empty() else floor_y
		if is_instance_valid(_shadow):
			_shadow.queue_free()
		_shadow = Polygon2D.new()
		var pts := Util.circle(70.0, 18)
		for i in pts.size():
			pts[i].y *= 0.2
		_shadow.polygon = pts
		_shadow.color = Color(0, 0, 0, 0.0)
		_shadow.position = Vector2(global_position.x, _land - 2)
		_shadow.z_index = 3
		get_parent().add_child(_shadow)
		_shadow.create_tween().tween_property(_shadow, "color:a", 0.5, 1.0)

	func _crash() -> void:
		var world := get_parent()
		var at := Vector2(global_position.x, _land - 8)
		for n in FarBits._players(world):
			if n.has_meta("_chand_hit"):
				n.remove_meta("_chand_hit")
		Fx.sparks(world, at, Color(0.85, 0.75, 0.55), 18, 300.0, 5.0, true)
		Fx.ring(world, at, 110.0, Color(1.0, 0.6, 0.3, 0.8), 0.35, 6.0, 0.3)
		Fx.shake(world, 7.0)
		for k in 8:                                      # обломки кольца и свечи
			var pc := Polygon2D.new()
			pc.polygon = PackedVector2Array([Vector2(-6, -2), Vector2(6, -3), Vector2(5, 2), Vector2(-5, 3)])
			pc.color = Color(0.25, 0.20, 0.20) if k % 2 else Color(0.85, 0.80, 0.70)
			pc.position = at
			pc.z_index = 4
			world.add_child(pc)
			var tw := pc.create_tween()
			tw.tween_property(pc, "position", at + Vector2(randf_range(-140, 140), randf_range(-60, 0)), 0.35).set_ease(Tween.EASE_OUT)
			tw.tween_property(pc, "position:y", at.y + 4, 0.25).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(pc, "rotation", randf_range(-4, 4), 0.6)
			tw.tween_interval(1.5)
			tw.tween_property(pc, "modulate:a", 0.0, 0.5)
			tw.tween_callback(pc.queue_free)
		var fz := FireZone.new()
		fz.team = -1
		fz.position = at + Vector2(0, 8)
		world.add_child(fz)
		if is_instance_valid(_shadow):
			_shadow.queue_free()
		_body.visible = false
		_chain.points = PackedVector2Array([Vector2(0, 0), Vector2(0, 10)])
		_state = "gone"
		_t = 9.0

class AbyssGrate extends Node2D:
	var width := 130.0
	var _state := "idle"
	var _t := 0.0
	var _glow: Polygon2D
	var _flames: Node2D
	var _tick := 0.0

	func _ready() -> void:
		z_index = 2
		_t = randf_range(3.0, 7.0)
		var frame := Polygon2D.new()
		frame.polygon = PackedVector2Array([Vector2(-width / 2 - 6, -3), Vector2(width / 2 + 6, -3), Vector2(width / 2 + 6, 6), Vector2(-width / 2 - 6, 6)])
		frame.color = Color(0.20, 0.17, 0.20)
		add_child(frame)
		_glow = Polygon2D.new()
		_glow.polygon = PackedVector2Array([Vector2(-width / 2, -2), Vector2(width / 2, -2), Vector2(width / 2, 4), Vector2(-width / 2, 4)])
		_glow.color = Color(0.7, 0.25, 1.0, 0.0)
		add_child(_glow)
		var n := int(width / 14.0)
		for i in n + 1:                                    # прутья решётки
			var bar := Polygon2D.new()
			var x := -width / 2 + i * width / n
			bar.polygon = PackedVector2Array([Vector2(x - 2, -3), Vector2(x + 2, -3), Vector2(x + 2, 5), Vector2(x - 2, 5)])
			bar.color = Color(0.10, 0.08, 0.10)
			add_child(bar)
		_flames = Node2D.new()
		_flames.visible = false
		add_child(_flames)
		for i in 9:
			var f := Polygon2D.new()
			var x := -width / 2 + 8 + i * (width - 16) / 8.0
			f.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-4, -120), Vector2(0, -200), Vector2(5, -110), Vector2(12, 0)])
			f.color = Color(0.45, 0.12, 0.75, 0.75) if i % 2 == 0 else Color(0.12, 0.04, 0.18, 0.85)
			f.position = Vector2(x, 0)
			_flames.add_child(f)

	func _physics_process(delta: float) -> void:
		_t -= delta
		match _state:
			"idle":
				_glow.color.a = 0.0
				if _t <= 0.0:
					_state = "warn"
					_t = 0.9
			"warn":
				_glow.color.a = 0.4 + 0.5 * absf(sin(_t * 14.0))
				if randf() < 0.3:
					Fx.sparks(get_parent(), global_position + Vector2(randf_range(-width / 2, width / 2), -4), Color(0.75, 0.35, 1.0), 1, 90.0, 3.0, true)
				if _t <= 0.0:
					_state = "fire"
					_t = 1.1
					_tick = 0.0
					_flames.visible = true
					_flames.scale = Vector2(1.0, 0.2)
					_flames.create_tween().tween_property(_flames, "scale", Vector2.ONE, 0.15)
			"fire":
				for f in _flames.get_children():
					f.scale = Vector2(1.0 + randf_range(-0.1, 0.1), 0.85 + randf() * 0.3)
				_tick -= delta
				if _tick <= 0.0:
					_tick = 0.3
					for n in FarBits._players(get_parent()):
						if n.cutscene_shield or FarBits._fireproof(n):
							continue
						if absf(n.global_position.x - global_position.x) < width / 2 + n.body_size.x * 0.3 \
								and FarBits._feet(n) > global_position.y - 220.0 and FarBits._feet(n) < global_position.y + 12.0:
							n.take_damage(9)
				if _t <= 0.0:
					_state = "idle"
					_t = randf_range(4.0, 7.0)
					_flames.visible = false
