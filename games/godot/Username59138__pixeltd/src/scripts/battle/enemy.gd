extends Node2D
## A walking enemy. Logic is driven by Battle.tick(); this node only stores state and draws itself.

var type := ""
var def: Dictionary
var cls := 1
var max_hp := 1.0
var hp := 1.0
var speed := 30.0
var armor := 0.0
var fire_res := 0.0
var bounty := 0
var radius := 6.0
var path_i := 0
var dist := 0.0
var path_len := 1.0
var alive := true
var is_friendly := false   # friendly units (garage cars) drive backwards and crash into enemies
var stats := {}             # for friendly units: the stats of the garage that sent them
var owner_tower: Node = null
var gun_cd := 0.0
var undead := false        # friendly unit raised by a Necromancer (an enemy body, no abilities)
var bloated := false       # Bloated enemy: Defs.BLOATED_HP times the HP (looks the same, the tooltip tells)
var lead := false          # Lead enemy: only towers that pierce lead hurt it (Battle.hurts), own grey sprite

# statuses
var stun_t := 0.0
var stun_immune_t := 0.0
var slow_f := 0.0
var slow_t := 0.0
var burn_dps := 0.0
var burn_t := 0.0
var burn_pierce := 0.0
var burn_src: Node = null
var burn_acc := 0.0
var acid_dps := 0.0       # acid: damage over time that ignores armor...
var acid_t := 0.0
var acid_shred := 0.0     # ...and eats this much armor while it lasts
var acid_src: Node = null
var chill := 0.0          # 0..1, built up by the Freezer's water; at 1 the enemy freezes solid
var chill_slow := 0.0     # slow at full chill (from the strongest Freezer that hit it)
var chill_hold := 0.0     # chill only starts melting once nobody sprays it for a moment
var frozen_t := 0.0       # > 0 while stuck in a block of ice
var freeze_immune_t := 0.0
var brittle := 0.0        # extra damage taken while frozen (Cryo Cannon)
var heal_cd := 0.0
var flash_t := 0.0
var heal_lock := 0.0
var incoming := 0.0  # damage of bullets already flying at this enemy
var final_boss := false
var flying := false      # only towers that hit flying can attack it; no melee, fire, grenades or cars
var invisible := false   # only towers that spot invisible enemies can aim at it
var revives := 0         # skeleton: times it can still get back up
var downed_t := 0.0      # > 0 while lying in pieces before getting back up
var rage := 0.0          # berserker: speed multiplier below half HP

var anim_t := 0.0
var sprite: Sprite2D
var tex_normal: Texture2D   # texture of the current view
var tex_flash: Texture2D
var views := {}             # "side" / "down" / "up" -> [texture, hit flash texture]
var view := "side"
var effect_mult := 1.0
var spawn_mult := 1.0      # HP multiplier it was spawned with (slime king children inherit it)
var fx_layer: Node2D        # drawn over the sprite: flames, ice block

const FLY_HEIGHT := 9.0


func setup(t: String, hp_mult: float, p_i: int, p_len: float) -> void:
	if is_friendly:
		_setup_friendly(t, p_i, p_len)
		return
	type = t
	def = Defs.ENEMIES[t]
	cls = int(def["class"])
	effect_mult = Defs.CLASS_EFFECT[cls]
	spawn_mult = hp_mult
	max_hp = roundf(float(def["hp"]) * hp_mult)
	hp = max_hp
	speed = float(def["speed"])
	armor = float(def.get("armor", 0))
	fire_res = float(def.get("fire_res", 0.0))
	# reward grows with HP, a bit slower than it (late enemies have hundreds of times the base HP)
	bounty = maxi(1, int(roundf(float(def["bounty"]) * Defs.BOUNTY_MULT * pow(hp_mult, 0.55))))
	radius = float(def.get("radius", 6))
	flying = bool(def.get("flying", false))
	invisible = bool(def.get("invisible", false))
	revives = 1 if def.has("revive") else 0
	rage = float(def.get("rage", 0.0))
	path_i = p_i
	path_len = p_len
	heal_cd = 2.5
	anim_t = randf() * 10.0
	_make_sprite("res://assets/sprites/enemies/" + t + _variant())


func _setup_friendly(t: String, p_i: int, p_len: float) -> void:
	type = t
	undead = bool(stats.get("undead", false))
	def = Defs.ENEMIES[t] if undead else Defs.VEHICLES[t]
	cls = 1
	effect_mult = 0.0   # friendly units ignore control effects
	max_hp = float(stats.get("car_hp", 24))
	hp = max_hp
	speed = float(stats.get("car_speed", 70))
	radius = float(def.get("radius", 6))
	bounty = 0
	path_i = p_i
	path_len = p_len
	anim_t = randf() * 10.0
	_make_sprite("res://assets/sprites/%s/%s" % ["enemies" if undead else "vehicles", t + _variant()])


func _make_sprite(base: String) -> void:
	for v: String in ["side", "down", "up"]:
		var suffix := "" if v == "side" else "_" + v
		views[v] = [Game.tex(base + suffix + ".png"), Game.tex(base + suffix + "_flash.png")]
	sprite = Sprite2D.new()
	sprite.centered = true
	add_child(sprite)
	fx_layer = preload("res://scripts/battle/draw_node.gd").new()
	fx_layer.draw_fn = _draw_fx
	add_child(fx_layer)
	_set_view("side")


## Show the side, front (walking down) or back (walking up) view, feet always on the same line.
func _set_view(v: String) -> void:
	view = v
	tex_normal = views[v][0]
	tex_flash = views[v][1]
	sprite.texture = tex_normal
	var h := tex_normal.get_height()
	sprite.offset = Vector2(0, -h / 2.0 + 4)
	if int(tex_normal.get_width()) % 2 == 1:
		sprite.offset.x = 0.5
	if h % 2 == 1:
		sprite.offset.y += 0.5


func display_name() -> String:
	return ("Bloated " if bloated else "") + ("Lead " if lead else "") + String(def["name"])


## The wave modifiers, as spawn_enemy() takes them (slime king children and undead keep them).
func mods() -> Array:
	var m: Array = []
	if bloated:
		m.append("bloated")
	if lead:
		m.append("lead")
	return m


func _variant() -> String:
	return "_lead" if lead else ""


func remaining() -> float:
	return path_len - dist


func is_stunned() -> bool:
	return stun_t > 0.0


## Can this enemy be hit / targeted right now (skeletons lying in pieces can't).
func targetable() -> bool:
	return alive and not is_friendly and downed_t <= 0.0


func is_enraged() -> bool:
	return rage > 0.0 and hp < max_hp * 0.5


func current_speed() -> float:
	if stun_t > 0.0 or downed_t > 0.0 or frozen_t > 0.0:
		return 0.0
	var s := speed
	if is_enraged():
		s *= rage
	if slow_t > 0.0:
		s *= (1.0 - slow_f)
	if chill > 0.0:
		s *= (1.0 - chill * chill_slow)
	return s


## Control effects are scaled by class (I 100% ... IV 20%).
func apply_stun(duration: float) -> void:
	if stun_immune_t > 0.0:
		return
	var d := duration * effect_mult
	if d < 0.04:
		return
	stun_t = maxf(stun_t, d)
	stun_immune_t = d + 0.35


func apply_slow(amount: float, duration: float) -> void:
	var a := amount * effect_mult
	var d := duration * effect_mult
	if a >= slow_f or slow_t <= 0.0:
		slow_f = a
	slow_t = maxf(slow_t, d)


## Freezer water. Chill is a control effect: it builds slower on higher classes, and the ice holds shorter.
## Returns true when this spray froze the enemy solid.
func apply_chill(rate: float, dt: float, max_slow: float, freeze_time: float, brittle_ice := 0.0) -> bool:
	chill_hold = 0.3
	chill_slow = maxf(chill_slow, max_slow)
	if frozen_t > 0.0 or freeze_immune_t > 0.0:
		return false
	chill = minf(1.0, chill + rate * dt * effect_mult)
	if chill < 1.0:
		return false
	chill = 0.0
	frozen_t = freeze_time * effect_mult
	freeze_immune_t = frozen_t + 1.0
	brittle = brittle_ice
	return true


## Fire melts the ice and the chill.
func thaw() -> bool:
	var was := chill > 0.0 or frozen_t > 0.0
	chill = 0.0
	frozen_t = 0.0
	return was


## Armor left after acid ate some of it.
func cur_armor() -> float:
	return maxf(0.0, armor - (acid_shred if acid_t > 0.0 else 0.0))


## Acid is damage, so class doesn't weaken it. The strongest acid wins, the armor loss keeps the highest value.
func apply_acid(dps: float, duration: float, shred: float, src: Node) -> void:
	if acid_t <= 0.0:
		acid_shred = 0.0
	if dps >= acid_dps or acid_t <= 0.0:
		acid_dps = dps
		acid_src = src
	acid_shred = maxf(acid_shred, shred)
	acid_t = maxf(acid_t, duration)


## Burn is damage, so it is NOT reduced by class.
func apply_burn(dps: float, duration: float, pierce: float, src: Node) -> void:
	if dps >= burn_dps or burn_t <= 0.0:
		burn_dps = dps
		burn_pierce = pierce
		burn_src = src
	burn_t = maxf(burn_t, duration)


func tick_status(dt: float) -> void:
	anim_t += dt
	if stun_t > 0.0:
		stun_t -= dt
	if stun_immune_t > 0.0:
		stun_immune_t -= dt
	if slow_t > 0.0:
		slow_t -= dt
		if slow_t <= 0.0:
			slow_f = 0.0
	if flash_t > -1.0:   # below 0 it counts the pause since the last hit flash
		flash_t -= dt
	if heal_lock > 0.0:
		heal_lock -= dt
	if downed_t > 0.0:
		downed_t -= dt
	if frozen_t > 0.0:
		frozen_t -= dt
	if freeze_immune_t > 0.0:
		freeze_immune_t -= dt
	if chill_hold > 0.0:
		chill_hold -= dt
	elif chill > 0.0:
		chill = maxf(0.0, chill - 0.3 * dt)
		if chill <= 0.0:
			chill_slow = 0.0


func update_visual(dir: Vector2) -> void:
	# roads are straight lines, so the dominant axis tells which way we are walking
	var want := view
	if absf(dir.y) > absf(dir.x):
		want = "down" if dir.y > 0.0 else "up"
	elif absf(dir.x) > 0.1:
		want = "side"
		sprite.flip_h = dir.x < 0
	if want != view:
		_set_view(want)
	if view != "side":
		sprite.flip_h = false
	var moving := current_speed() > 0.0
	var bob := 0.0
	if flying:
		bob = -FLY_HEIGHT + roundf(sin(anim_t * 7.0) * 1.5)
	elif moving:
		bob = -roundf(absf(sin(anim_t * (6.0 + speed * 0.08))) * (1.0 if cls < 4 else 2.0))
	sprite.position = Vector2(0, bob)
	sprite.texture = tex_flash if flash_t > 0.0 else tex_normal
	# a skeleton in pieces lies on its side
	sprite.rotation = PI * 0.5 if downed_t > 0.0 else 0.0
	if downed_t > 0.0:
		sprite.position = Vector2(-sprite.offset.y, -2.0)
	# statuses are shown with particles, never by tinting the sprite
	var m := Color.WHITE
	if invisible:
		# shimmering, see-through
		m.a = 0.32 + 0.12 * sin(anim_t * 5.0)
	sprite.modulate = m
	fx_layer.modulate.a = 0.4 if invisible else 1.0
	queue_redraw()
	fx_layer.queue_redraw()


func _draw() -> void:
	var h := tex_normal.get_height()
	# shadow
	var sw := maxf(4.0, tex_normal.get_width() * 0.35)
	if flying:
		sw *= 0.6
	if not invisible:
		draw_rect(Rect2(-sw, 3, sw * 2, 2), Color(0, 0, 0, 0.25 if not flying else 0.18))
	var top := -h + (sprite.position.y if sprite else 0.0)
	# status pixels
	if stun_t > 0.0:
		var a := anim_t * 8.0
		for i in 3:
			var ang := a + i * TAU / 3.0
			var p := Vector2(cos(ang) * 6.0, top + sin(ang) * 2.0 - 2.0).round()
			draw_rect(Rect2(p, Vector2(1, 1)), Color("fee761"))


## Over the sprite: flames licking a burning enemy and the ice block around a frozen one.
func _draw_fx(n: Node2D) -> void:
	var w := float(tex_normal.get_width())
	var h := float(tex_normal.get_height())
	var y0 := sprite.position.y
	if frozen_t > 0.0:
		var r := Rect2(Vector2(-ceilf(w / 2.0) - 1.0, y0 - h + 3.0), Vector2(ceilf(w / 2.0) * 2.0 + 2.0, h + 2.0))
		var a := 1.0 if frozen_t > 0.4 or int(anim_t * 10.0) % 2 == 0 else 0.5   # blinks just before it breaks
		n.draw_rect(r, Color(0.55, 0.85, 0.97, 0.5 * a))
		var edge := Color(0.17, 0.6, 0.86, a)   # dark enough to read on snow too
		n.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), edge)
		n.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), edge)
		n.draw_rect(Rect2(r.position + Vector2(r.size.x - 1, 0), Vector2(1, r.size.y)), edge)
		n.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), Color(0.17, 0.6, 0.8, a))
		for i in 3:   # shine
			n.draw_rect(Rect2(r.position + Vector2(2 + i, 2 + i * 2), Vector2(1, 2)), Color(1, 1, 1, 0.85 * a))
	if burn_t > 0.0:
		var cols := [Color("fee761"), Color("feae34"), Color("f77622"), Color("e43b44")]
		for i in 4:
			var k := fmod(anim_t * 2.2 + i * 0.25, 1.0)   # 0 = just lit at the feet, 1 = burnt out at the head
			var fx := sin(anim_t * 7.0 + i * 1.7) * (w * 0.3)
			var fy := y0 + 2.0 - k * h * 0.8
			n.draw_rect(Rect2(Vector2(fx, fy).round(), Vector2(1, 2 if k < 0.5 else 1)), cols[mini(3, int(k * 4.0))])
