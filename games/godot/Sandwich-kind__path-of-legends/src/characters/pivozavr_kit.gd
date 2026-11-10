class_name PivozavrKit
extends HeroKit
# ---------- ПИВОЗАВР — легенда из Лавки ----------
# Оружие: крышки от бутылок. Цвет крышки — какой бафф получит враг:
#   серая — просто больно (урон ×1,4); красная — поджигает; зелёная — травит;
#   синяя — покрывает инеем (замедляет); жёлтая — бьёт током (на миг обездвиживает);
#   золотая (редкая) — урон ×2 и маленький взрыв рядом.
# 1 «Жертвенное пиво» — бросает бутылку: она раскалывается — взрыв осколков, а пиво
#   разливается лужей: враги в ней скользят и понемногу получают урон.
#   МЕГА: «Ящик пива» — 3 бутылки веером. Арена: лужа шире и дольше.
# 2 «Напиток жизни» — пьёт из бутылки: лечится, и какое-то время бросает крышки вдвое
#   быстрее. МЕГА: лечит сильнее, бросает по 2 крышки, чаще выпадает золотая.
#   Арена: бодрость дольше.
# 3 «Отрыжка мамонта» — облако газа медленно плывёт вперёд: враги внутри замедлены,
#   получают урон и отравлены. МЕГА: облако через 2,5 с вспыхивает огнём.
#   Арена: облако больше.
# Ульта «Хранитель подвала» — за спиной открывается люк, оттуда выбегает куча детей
#   и бежит туда, куда смотрит Пивозавр: врагов, мимо которых пробегают, ранят и
#   замедляют. МЕГА: детей больше, добегают до края и бегут обратно, кидаясь крышками.
#   Арена: бегут дальше.

const CAPS := {
	"grey":   {"color": Color(0.70, 0.70, 0.74), "w": 30},
	"red":    {"color": Color(0.90, 0.22, 0.16), "w": 20},
	"green":  {"color": Color(0.30, 0.78, 0.28), "w": 20},
	"blue":   {"color": Color(0.35, 0.65, 1.00), "w": 14},
	"yellow": {"color": Color(1.00, 0.85, 0.20), "w": 11},
	"gold":   {"color": Color(1.00, 0.68, 0.10), "w": 5},
}
const BEER := Color(0.95, 0.72, 0.20)

var _drink_t := 0.0                # бодрость после «Напитка жизни»
var _drink_mega := false
var _kids: Array = []

# ---------- Стрельба: крышки ----------
func weapon(delta: float, shoot: bool) -> void:
	var rapid := p.has_buff("rapid")
	if p._reloading > 0.0:
		p._reloading -= delta
		if p._reloading <= 0.0:
			p._reloading = 0.0
			p.ammo = p.clip_size
	elif not p.is_bot and Input.is_action_just_pressed(p.prefix + "_reload") and p.ammo < p.clip_size:
		p._reloading = p.reload_time
	if rapid or _drink_t > 0.0:
		p._reloading = 0.0
		p.ammo = p.clip_size
	if not shoot or p._cooldown_left > 0.0 or p._reloading > 0.0:
		return
	_cap(randf_range(-0.03, 0.03))
	if _drink_t > 0.0 and _drink_mega:
		_cap(0.14)                                     # МЕГА-бодрость: по 2 крышки
	p._anim("throw")
	var cd := p.fire_cooldown
	if rapid:
		cd *= 0.5
	if _drink_t > 0.0:
		cd *= 0.5
	p._cooldown_left = cd
	if not rapid and _drink_t <= 0.0:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

func _pick_cap() -> String:
	var total := 0
	var gold_bonus := 12 if (_drink_t > 0.0 and _drink_mega) else 0
	for k in CAPS:
		total += int(CAPS[k]["w"]) + (gold_bonus if k == "gold" else 0)
	var r := randi() % total
	for k in CAPS:
		r -= int(CAPS[k]["w"]) + (gold_bonus if k == "gold" else 0)
		if r < 0:
			return k
	return "grey"

func _cap(spread: float) -> void:
	var kind := _pick_cap()
	var b := Bullet.new()
	b.shooter = p
	b.team = p.team
	b.speed = p.bullet_speed
	b.size = p.bullet_size
	b.style = "cap"
	b.color = CAPS[kind]["color"]
	var dmg := p.bullet_damage
	match kind:
		"grey": dmg = int(round(dmg * 1.4))
		"red": b.burn_t = 2.5
		"green": b.poison = 3.0
		"blue": b.chill = 1.6
		"yellow": b.shock = 0.45
		"gold":
			dmg *= 2
			b.on_hit = _gold_pop
	b.damage = dmg
	var from: Vector2 = (p.rig.muzzle() if p.rig else p.global_position) + Vector2(0, -4)
	var dir := Vector2(p.facing, -0.05).normalized()
	if not p.is_bot and Balance.arena(p):
		dir = p.assist_dir(from, dir)
	b.direction = dir.rotated(spread * p.facing)
	b.position = from
	p.get_parent().add_child(b)

# Золотая крышка: маленький взрыв рядом с тем, в кого попала
func _gold_pop(victim: Node) -> void:
	if not is_instance_valid(p) or not (victim is Player):
		return
	var world := p.get_parent()
	var at: Vector2 = victim.global_position
	Fx.ring(world, at, 80.0, Color(1.0, 0.75, 0.2, 0.9), 0.3, 6.0)
	Fx.sparks(world, at, Color(1.0, 0.8, 0.3), 10, 220.0, 3.0)
	for e in _enemies():
		if e != victim and e.global_position.distance_to(at) < 90.0:
			e.take_damage(8, p)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	p._cd[i] = maxf(0.0, p._cd[i] - delta * p._cd_speed())
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"sacred_beer":
			p._anim("throw")
			if mega:                                    # «Ящик пива»: 3 бутылки веером
				for k in 3:
					_bottle(Vector2(p.facing * (420.0 + k * 210.0), -420.0 - k * 40.0))
			else:
				_bottle(Vector2(p.facing * 560.0, -440.0))
		"life_drink":
			_drink(mega)
		"mammoth_burp":
			_burp(mega)

# ----- 1. Жертвенное пиво -----
func _bottle(vel: Vector2) -> void:
	var b := BeerBottle.new()
	b.team = p.team
	b.attacker = p
	b.vel = vel
	b.arena = Balance.arena(p)
	b.position = (p.rig.muzzle() if p.rig else p.global_position) + Vector2(0, -10)
	p.get_parent().add_child(b)

# ----- 2. Напиток жизни -----
func _drink(mega: bool) -> void:
	p._anim("invoke")                                   # бутылку — к губам, голову назад
	p._forced_time = 0.5
	p._forced_vx = 0.0
	_drink_mega = mega
	var heal := int(p.max_hp * (0.4 if mega else 0.25))
	p.heal(heal)
	_drink_t = (8.0 if Balance.arena(p) else 6.0) + (1.0 if mega else 0.0)
	var world := p.get_parent()
	p._float_label("+%d  Ух!" % heal, Color(1.0, 0.85, 0.35))
	for k in 10:                                        # пена и пузырьки
		Fx.sparks(world, p.global_position + Vector2(p.facing * 10.0, -p.body_size.y * 0.35), Color(1.0, 0.95, 0.8), 1, 120.0, 3.0)
	Fx.ring(world, p.global_position, 70.0, Color(1.0, 0.8, 0.3, 0.8), 0.35, 5.0)

# ----- 3. Отрыжка мамонта -----
func _burp(mega: bool) -> void:
	p._anim("roar")
	var c := BurpCloud.new()
	c.team = p.team
	c.attacker = p
	c.dir = p.facing
	c.mega = mega
	c.radius = 150.0 if Balance.arena(p) else 120.0
	c.position = p.global_position + Vector2(p.facing * 70.0, -p.body_size.y * 0.25)
	p.get_parent().add_child(c)
	p._float_label("БУЭЭЭ!", Color(0.75, 0.9, 0.4))

# ---------- Ульта: Хранитель подвала ----------
func ult() -> void:
	var mega := p._mega_ab()
	var world := p.get_parent()
	p._anim("roar")
	var feet := p.global_position + Vector2(0, p.body_size.y / 2)
	var hatch_x := feet.x - p.facing * 50.0
	# люк в полу за спиной
	var hatch := Node2D.new()
	hatch.position = Vector2(hatch_x, feet.y)
	hatch.z_index = 1
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-34, 0), Vector2(34, 0), Vector2(30, 5), Vector2(-30, 5)])
	hole.color = Color(0.05, 0.04, 0.03)
	hatch.add_child(hole)
	var lid := Polygon2D.new()
	lid.polygon = PackedVector2Array([Vector2(0, 0), Vector2(-4, -34), Vector2(2, -36), Vector2(6, 0)])
	lid.color = Color(0.45, 0.30, 0.16)
	lid.position = Vector2(-p.facing * 34.0, 0)
	hatch.add_child(lid)
	world.add_child(hatch)
	var ht := hatch.create_tween()
	ht.tween_interval(3.5)
	ht.tween_property(hatch, "modulate:a", 0.0, 0.5)
	ht.tween_callback(hatch.queue_free)
	p._float_label("Дети, на прогулку!", Color(1.0, 0.85, 0.4))
	var n := 14 if mega else 8
	for k in n:
		_after(0.1 + k * 0.13, _spawn_kid.bind(Vector2(hatch_x, feet.y), k, mega))

func _spawn_kid(at: Vector2, k: int, mega: bool) -> void:
	if not is_instance_valid(p):
		return
	var kid := CellarKid.new()
	kid.team = p.team
	kid.attacker = p
	kid.dir = p.facing
	kid.look = k
	kid.mega = mega
	kid.life = 4.2 if Balance.arena(p) else 3.2
	if mega:
		kid.life += 2.5
	kid.map_w = p.map_w
	kid.position = at + Vector2(0, -2)
	p.get_parent().add_child(kid)

func ulting() -> bool:
	return false

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	if p == null or not p.is_alive():
		return
	if _drink_t > 0.0:
		_drink_t -= delta
		if randf() < 0.15:
			Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-12, 12), -p.body_size.y * 0.4), Color(1.0, 0.95, 0.8, 0.8), 1, 60.0, 2.5)

func on_death() -> void:
	super()
	_drink_t = 0.0


# =====================================================================
# Бутылка: летит по дуге, раскалывается — взрыв осколков и лужа пива
class BeerBottle extends Node2D:
	var team := 0
	var attacker: Player
	var vel := Vector2.ZERO
	var arena := false
	var _t := 0.0

	func _ready() -> void:
		z_index = 6
		var glass := Polygon2D.new()
		glass.polygon = PackedVector2Array([Vector2(-5, 9), Vector2(-5, -2), Vector2(-2, -6), Vector2(-2, -11), Vector2(2, -11), Vector2(2, -6), Vector2(5, -2), Vector2(5, 9)])
		glass.color = Color(0.20, 0.52, 0.24)
		add_child(glass)
		var label := Polygon2D.new()
		label.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(5, 5), Vector2(-5, 5)])
		label.color = Color(0.92, 0.86, 0.66)
		add_child(label)
		var cap := Polygon2D.new()
		cap.polygon = PackedVector2Array([Vector2(-3, -13), Vector2(3, -13), Vector2(3, -11), Vector2(-3, -11)])
		cap.color = Color(0.85, 0.2, 0.15)
		add_child(cap)

	func _physics_process(delta: float) -> void:
		_t += delta
		vel.y += 1500.0 * delta
		rotation += delta * 12.0
		var next := global_position + vel * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters2D.create(global_position, next, Layer.WORLD | Layer.FRAME))
		var touch := false
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and n.hurt_center().distance_to(next) < maxf(n.body_size.x, n.body_size.y) * 0.5 + 8.0:
				touch = true
		if not hit.is_empty() or touch or _t > 2.5:
			_shatter(hit["position"] if not hit.is_empty() else next)
			return
		global_position = next

	func _shatter(at: Vector2) -> void:
		var world := get_parent()
		var who: Player = attacker if is_instance_valid(attacker) else null
		Fx.sparks(world, at, Color(0.45, 0.85, 0.45), 12, 280.0, 3.0)
		Fx.sparks(world, at, Color(1.0, 0.85, 0.35), 10, 220.0, 4.0)
		Fx.ring(world, at, 110.0, Color(1.0, 0.85, 0.4, 0.85), 0.3, 6.0)
		for n in world.get_children():
			if n is Player and n.team != team and n.is_alive() and n.hurt_center().distance_to(at) < 110.0 + n.body_size.x * 0.4:
				n.take_damage(20, who)
		# лужа — на полу под местом удара
		var gy := at.y
		var q := get_world_2d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters2D.create(at + Vector2(0, -10), at + Vector2(0, 900), Layer.WORLD | Layer.FRAME))
		if not q.is_empty():
			gy = q["position"].y
		var pud := BeerPuddle.new()
		pud.team = team
		pud.attacker = who
		pud.width = 360.0 if arena else 260.0
		pud.life = 7.0 if arena else 5.0
		pud.position = Vector2(at.x, gy)
		world.call_deferred("add_child", pud)
		queue_free()


# Лужа пива: враги скользят и понемногу получают урон
class BeerPuddle extends Node2D:
	var team := 0
	var attacker: Player
	var width := 260.0
	var life := 5.0
	var _tick := 0.0
	var _t := 0.0
	var _foam: Array = []

	func _ready() -> void:
		z_index = 2
		var pool := Polygon2D.new()
		var hw := width / 2
		pool.polygon = PackedVector2Array([Vector2(-hw, 1), Vector2(-hw * 0.8, -4), Vector2(-hw * 0.2, -6), Vector2(hw * 0.4, -5), Vector2(hw, 1), Vector2(hw * 0.6, 4), Vector2(-hw * 0.6, 4)])
		pool.color = Color(0.95, 0.68, 0.18, 0.85)
		add_child(pool)
		var shine := Polygon2D.new()
		shine.polygon = PackedVector2Array([Vector2(-hw * 0.5, -3), Vector2(hw * 0.2, -4), Vector2(hw * 0.1, -2), Vector2(-hw * 0.45, -1)])
		shine.color = Color(1.0, 0.9, 0.55, 0.8)
		add_child(shine)
		for k in int(width / 40.0):                  # пена
			var f := Polygon2D.new()
			f.polygon = Util.circle(randf_range(3, 6), 8)
			f.color = Color(1.0, 0.98, 0.9, 0.9)
			f.position = Vector2(randf_range(-hw * 0.8, hw * 0.8), randf_range(-6, -2))
			add_child(f)
			_foam.append(f)
		scale = Vector2(0.2, 1.0)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.25)

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		for k in _foam.size():
			(_foam[k] as Node2D).scale = Vector2.ONE * (0.8 + 0.3 * sin(_t * 5.0 + k))
		_tick -= delta
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive():
				var feet: float = n.global_position.y + n.body_size.y / 2
				if absf(n.global_position.x - global_position.x) < width / 2 and absf(feet - global_position.y) < 14.0:
					n.slip(0.35)
					if _tick <= 0.0:
						n.take_damage(3, attacker if is_instance_valid(attacker) else null)
		if _tick <= 0.0:
			_tick = 0.5
		if life < 0.8:
			modulate.a = life / 0.8
		if life <= 0.0:
			queue_free()


# Облако отрыжки: плывёт вперёд, замедляет, ранит и травит; МЕГА — вспыхивает
class BurpCloud extends Node2D:
	var team := 0
	var attacker: Player
	var dir := 1
	var mega := false
	var radius := 120.0
	var life := 4.0
	var _t := 0.0
	var _tick := 0.0
	var _puffs: Array = []
	var _lit := false

	func _ready() -> void:
		z_index = 6
		for k in 9:
			var c := Polygon2D.new()
			c.polygon = Util.circle(randf_range(radius * 0.35, radius * 0.55), 12)
			c.color = Color(0.62, 0.75, 0.28, 0.45)
			c.position = Vector2(randf_range(-radius * 0.5, radius * 0.5), randf_range(-radius * 0.35, radius * 0.35))
			add_child(c)
			_puffs.append(c)
		scale = Vector2(0.3, 0.3)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		position.x += dir * 110.0 * delta
		for k in _puffs.size():
			var c: Polygon2D = _puffs[k]
			c.rotation = sin(_t * 1.5 + k) * 0.3
			c.scale = Vector2.ONE * (1.0 + 0.12 * sin(_t * 3.0 + k))
		_tick -= delta
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and n.global_position.distance_to(global_position) < radius + n.body_size.x * 0.3:
				n.slow(0.3, 0.55, "mud")
				if _tick <= 0.0:
					n.take_damage(4, attacker if is_instance_valid(attacker) else null)
					n.poison(3.0, 4.0)
		if _tick <= 0.0:
			_tick = 0.5
		if mega and not _lit and _t >= 2.5:
			_ignite()
			return
		if life < 0.6:
			modulate.a = life / 0.6
		if life <= 0.0:
			queue_free()

	func _ignite() -> void:
		_lit = true
		var world := get_parent()
		var who: Player = attacker if is_instance_valid(attacker) else null
		Util.flash(world, global_position, radius * 1.3, Color(1.0, 0.6, 0.2, 0.95))
		Fx.ring(world, global_position, radius * 1.4, Color(1.0, 0.5, 0.15, 0.9), 0.4, 9.0)
		Fx.sparks(world, global_position, Color(1.0, 0.55, 0.15), 22, 320.0, 5.0)
		Fx.shake(world, 6.0)
		for n in world.get_children():
			if n is Player and n.team != team and n.is_alive() and n.global_position.distance_to(global_position) < radius * 1.3:
				n.take_damage(30, who)
				if not n.has_meta("fireproof"):
					n.burn(3.0, 6.0, who)
		queue_free()


# Ребёнок из подвала: бежит вперёд, ранит и замедляет врагов, мимо которых пробегает
class CellarKid extends Node2D:
	var team := 0
	var attacker: Player
	var dir := 1
	var look := 0
	var mega := false
	var life := 3.2
	var map_w := 2600.0
	var _vy := 0.0
	var _t := 0.0
	var _hit_t := {}
	var _turned := false
	var _threw := false
	var _body: Sprite2D
	const SPEED := 520.0

	func _ready() -> void:
		z_index = 5
		_body = Sprite2D.new()
		_body.texture = ImageTexture.create_from_image(_kid_img(look))
		_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_body.offset = Vector2(0, -7)
		_body.scale = Vector2(3.0 * dir, 3.0)
		add_child(_body)

	static func _kid_img(k: int) -> Image:
		var im := Image.create(9, 14, false, Image.FORMAT_RGBA8)
		var shirts := [Color(0.85, 0.25, 0.2), Color(0.25, 0.5, 0.9), Color(0.95, 0.8, 0.2), Color(0.3, 0.7, 0.35), Color(0.7, 0.35, 0.8), Color(0.95, 0.55, 0.2)]
		var hairs := [Color(0.35, 0.22, 0.12), Color(0.9, 0.75, 0.35), Color(0.12, 0.10, 0.10), Color(0.6, 0.3, 0.15)]
		var skin := Color(0.95, 0.76, 0.62)
		var sh: Color = shirts[k % shirts.size()]
		var hc: Color = hairs[(k * 7 + 1) % hairs.size()]
		im.fill_rect(Rect2i(2, 0, 5, 1), hc)                 # волосы
		im.fill_rect(Rect2i(1, 1, 6, 1), hc)
		im.fill_rect(Rect2i(2, 2, 5, 3), skin)               # лицо
		im.fill_rect(Rect2i(1, 2, 1, 2), hc)
		im.set_pixel(5, 3, Color(0.1, 0.08, 0.08))           # глаз
		im.set_pixel(6, 4, Color(0.7, 0.3, 0.3))             # улыбка
		im.fill_rect(Rect2i(2, 5, 5, 4), sh)                 # футболка
		im.fill_rect(Rect2i(1, 6, 1, 2), skin)               # руки
		im.fill_rect(Rect2i(7, 6, 1, 2), skin)
		im.fill_rect(Rect2i(2, 9, 5, 2), Color(0.25, 0.3, 0.5))   # шорты
		im.fill_rect(Rect2i(2, 11, 2, 2), skin)              # ноги
		im.fill_rect(Rect2i(5, 11, 2, 2), skin)
		im.fill_rect(Rect2i(1, 13, 3, 1), Color(0.95, 0.95, 0.95))   # кеды
		im.fill_rect(Rect2i(5, 13, 3, 1), Color(0.95, 0.95, 0.95))
		return im

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		var space := get_world_2d().direct_space_state
		# стена впереди — разворот (МЕГА) или прыжок обратно в подвал
		var ahead := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -20), global_position + Vector2(dir * 26.0, -20), Layer.WORLD))
		if not ahead.is_empty() or global_position.x < 50.0 or global_position.x > map_w - 50.0:
			if mega and not _turned:
				_turn()
			else:
				_vanish()
				return
		position.x += dir * SPEED * delta
		# бегут по земле: падают с края, взбегают на ступеньку
		_vy += 1800.0 * delta
		var down := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -30), global_position + Vector2(0, maxf(4.0, _vy * delta + 2.0)), Layer.WORLD | Layer.FRAME))
		if not down.is_empty() and _vy >= 0.0:
			global_position.y = down["position"].y
			_vy = 0.0
		else:
			position.y += _vy * delta
		# бег: подпрыгивают и машут ногами
		_body.position.y = -absf(sin(_t * 18.0)) * 4.0
		_body.rotation = sin(_t * 18.0) * 0.12
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive():
				var c: Vector2 = n.global_position
				var feet: float = c.y + n.body_size.y / 2
				if absf(c.x - global_position.x) < 30.0 + n.body_size.x / 2 and feet > global_position.y - 70.0 and feet < global_position.y + 30.0:
					var nt: float = _hit_t.get(n, 0.0)
					if _t >= nt:
						_hit_t[n] = _t + 0.3
						n.take_damage(5, attacker if is_instance_valid(attacker) else null)
						n.slow(0.8, 0.6, "mud")
		if mega and _turned and not _threw and _t > 0.3:
			_throw_cap()
		if life <= 0.0:
			_vanish()

	func _turn() -> void:
		_turned = true
		dir = -dir
		_body.scale.x = 3.0 * dir

	func _throw_cap() -> void:
		_threw = true
		var target: Player = null
		var bd := 700.0
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive():
				var d: float = n.global_position.distance_to(global_position)
				if d < bd:
					bd = d
					target = n
		if target == null:
			return
		var b := Bullet.new()
		b.shooter = attacker if is_instance_valid(attacker) else null
		b.team = team
		b.speed = 700.0
		b.damage = 5
		b.size = 7.0
		b.style = "cap"
		b.color = [Color(0.9, 0.22, 0.16), Color(0.3, 0.78, 0.28), Color(0.35, 0.65, 1.0)][look % 3]
		b.direction = (target.hurt_center() - (global_position + Vector2(0, -20))).normalized()
		b.position = global_position + Vector2(0, -20)
		get_parent().add_child(b)

	func _vanish() -> void:
		Fx.sparks(get_parent(), global_position + Vector2(0, -12), Color(0.85, 0.82, 0.75), 5, 120.0, 3.0)
		queue_free()
