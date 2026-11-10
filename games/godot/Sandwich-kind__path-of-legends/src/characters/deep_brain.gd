class_name DeepBrain
extends Node
# ---------- Особое поведение противников глубин ----------
# Узел-«мозг» внутри бота: то, что не укладывается в обычные способности.
#   kobold_miner — прорубает киркой блоки на пути к герою;
#   gem_beetle   — катится шаром (отскакивает от стен), разбитый роняет золото;
#   cart_rider   — сбитая вагонетка катится дальше сама;
#   ruby_golem   — пока рубиновое сердце цело, урон по нему вдвое меньше;
#   shardling*   — разбитый раскалывается на два меньших;
#   crystal_guard — выстрел в зеркальный щит летит обратно;
#   baron_gryz   — уходит под землю и вылезает под героем;
#   irida        — рассыпается вихрем осколков и собирается в другом месте;
#   irida_image  — отражение: без тени.

var p: Player
var kind := ""
var _t := 0.0
var _roll_t := 0.0
var _roll_dir := 1.0
var _roll_hit := {}
var _cracked := false
var _reflect_cd := 0.0
var _state := ""               # burrow / shatter
var _state_t := 0.0
var _goal_x := 0.0
var _floor_y := 0.0
const IMAGE_LIFE := 14.0

func _ready() -> void:
	name = "DeepBrain"
	p.died.connect(_on_died)
	match kind:
		"ruby_golem":
			p.armor_mult = 0.5
		"crystal_guard":
			p.on_hurt = _on_guard_hurt

func _physics_process(delta: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	_t += delta
	_reflect_cd -= delta
	match kind:
		"kobold_miner":
			if fmod(_t, 0.35) < delta:
				_dig()
		"gem_beetle":
			_roll_tick(delta)
		"ruby_golem":
			if not _cracked and p.is_stunned():
				_cracked = true                    # сердце треснуло — броня пропала
				p.armor_mult = 1.0
				if p.rig is BotRig and p.rig.core:
					p.rig.core.visible = false
				Fx.sparks(p.get_parent(), p.global_position, Color(1.0, 0.3, 0.35), 16, 260.0, 4.0)
				p._float_label("Сердце треснуло!", Color(1.0, 0.5, 0.5))
		"baron_gryz", "irida":
			if _state != "":
				_state_tick(delta)
			if kind == "baron_gryz" and p.rig is DeepRig:
				p.rig.drilling = p._forced_time > 0.0
		"irida_image":
			if p._shadow:
				p._shadow.visible = false          # у отражения нет тени
			if _t > IMAGE_LIFE:                    # отражение живёт недолго и рассыпается само
				p.take_damage(99999)

# ---------- Кобольд прорубает стену ----------
func _dig() -> void:
	if not is_instance_valid(p.target):
		return
	var dir := signf(p.target.global_position.x - p.global_position.x)
	if dir == 0.0:
		return
	var space := p.get_world_2d().direct_space_state
	for dy in [-10.0, 14.0]:
		var from := p.global_position + Vector2(0, dy)
		var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(dir * (p.body_size.x / 2 + 34.0), 0), Layer.WORLD, [p.get_rid()])
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and hit["collider"] is Destructible and not hit["collider"].background:
			hit["collider"].hit(hit["position"] + Vector2(dir * 6.0, 0), Vector2(dir, 0), 45, 12.0, p.team,
					{"strict": true, "attacker": p, "power": 0.5})
			p._anim("punch")
			Fx.sparks(p.get_parent(), hit["position"], Color(0.9, 0.85, 0.7), 5, 140.0, 3.0)
			return

# ---------- Жук катится ----------
func start_roll() -> void:
	_roll_t = 1.8
	_roll_dir = float(p.facing)
	_roll_hit.clear()
	if p.rig is DeepRig:
		p.rig.rolling = true
	p.velocity.y = -180.0

func _roll_tick(delta: float) -> void:
	if _roll_t <= 0.0:
		return
	_roll_t -= delta
	if p.is_on_wall():
		_roll_dir = -_roll_dir                     # отскок от стены
		Fx.sparks(p.get_parent(), p.global_position + Vector2(_roll_dir * -20, 0), Color(0.6, 1.0, 0.7), 6, 160.0, 3.0)
	p._forced_time = 0.1
	p._forced_vx = _roll_dir * 680.0
	for n in p.get_parent().get_children():
		if n is Player and n.team != p.team and n.is_alive() and not _roll_hit.has(n) \
				and n.global_position.distance_to(p.global_position) < (n.body_size.x + p.body_size.x) * 0.55:
			_roll_hit[n] = true
			n.take_damage(14, p)
			n.velocity = Vector2(_roll_dir * 500.0, -300.0)
	if _roll_t <= 0.0 and p.rig is DeepRig:
		p.rig.rolling = false

# ---------- Страж отражает выстрел ----------
func _on_guard_hurt(amount: int, attacker) -> void:
	if _reflect_cd > 0.0 or attacker == null or not is_instance_valid(attacker) or not (attacker is Player):
		return
	var to: Vector2 = attacker.global_position - p.global_position
	if signf(to.x) != p.facing or to.length() < 150.0 or p.is_stunned():
		return
	_reflect_cd = 0.35
	var b := Bullet.new()
	b.shooter = p
	b.team = p.team
	b.direction = to.normalized()
	b.speed = 950.0
	b.damage = maxi(5, amount * 2)
	b.size = 9.0
	b.style = "light"
	b.position = p.global_position + Vector2(p.facing * 30.0, -8.0)
	p.get_parent().add_child(b)
	Fx.sparks(p.get_parent(), b.position, Color(0.75, 0.9, 1.0), 6, 140.0, 3.0)

# ---------- Смерть: раскол, золото, вагонетка ----------
func _on_died(_i: int) -> void:
	var world := p.get_parent()
	var t: Dictionary = Bots.TYPES.get(kind, {})
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	if t.has("split") and am and not p.has_meta("no_split"):
		for k in 2:
			am.spawn_at.call_deferred(String(t["split"]), p.global_position + Vector2((k * 2 - 1) * 22.0, -10.0))
		Fx.sparks(world, p.global_position, Color(0.7, 0.9, 1.0), 10, 200.0, 3.0)
	if kind == "gem_beetle" and am:
		am.bonus_gold(4, p.global_position)
	if kind == "cart_rider":
		var rc := RunawayCart.new()
		rc.dir = float(p.facing)
		rc.team = p.team
		rc.attacker = p
		rc.floor_y = p.global_position.y + p.body_size.y / 2
		rc.speed = 520.0
		rc.position = Vector2(p.global_position.x, 0)
		world.add_child.call_deferred(rc)

# ---------- Барон под землёй / Ирида вихрем осколков ----------
func start_burrow() -> void:
	_begin("burrow", 1.5)
	_goal_x = p.target.global_position.x
	Fx.cracks(p.get_parent(), Vector2(p.global_position.x, _floor_y), Color(0.25, 0.2, 0.18), 90.0)

func start_shatter() -> void:
	_begin("shatter", 1.2)
	var tx: float = p.target.global_position.x if is_instance_valid(p.target) else Colosseum.W / 2
	# собирается по другую сторону от героя
	_goal_x = clampf(tx + (300.0 if p.global_position.x < tx else -300.0), 220.0, Colosseum.W - 220.0)
	Shards.burst(p.get_parent(), p.global_position, p.team, p, 10, 10, Color(0.8, 0.85, 1.0))

func _begin(st: String, time: float) -> void:
	_state = st
	_state_t = time
	_floor_y = p.global_position.y + p.body_size.y / 2
	p.cutscene_shield = true
	p.visible = false
	p.frozen = true
	p.velocity = Vector2.ZERO
	p._col.set_deferred("disabled", true)
	p.set_physics_process(false)
	set_physics_process(true)

func _state_tick(delta: float) -> void:
	_state_t -= delta
	var world := p.get_parent()
	if _state == "burrow":
		# под землёй ползёт к герою; на земле трещины и пыль
		if is_instance_valid(p.target):
			_goal_x = move_toward(_goal_x, p.target.global_position.x, 400.0 * delta) if _state_t > 0.6 else _goal_x
		p.global_position.x = move_toward(p.global_position.x, _goal_x, 700.0 * delta)
		if fmod(_state_t, 0.15) < delta:
			Fx.sparks(world, Vector2(p.global_position.x, _floor_y - 4), Color(0.55, 0.45, 0.35), 3, 150.0, 4.0)
		if _state_t < 0.6 and fmod(_state_t, 0.2) < delta:
			Fx.cracks(world, Vector2(_goal_x, _floor_y), Color(0.3, 0.22, 0.16), 70.0)
	else:
		p.global_position.x = move_toward(p.global_position.x, _goal_x, 2400.0 * delta)
		if fmod(_state_t, 0.08) < delta:
			Fx.sparks(world, p.global_position + Vector2(randf_range(-40, 40), randf_range(-60, 40)), Color(0.8, 0.85, 1.0), 4, 260.0, 3.0)
	if _state_t <= 0.0:
		_emerge()

func _emerge() -> void:
	var world := p.get_parent()
	var st := _state
	_state = ""
	p.global_position = Vector2(_goal_x, _floor_y - p.body_size.y / 2 - 2.0)
	p.visible = true
	p.frozen = false
	p.cutscene_shield = false
	p._col.set_deferred("disabled", false)
	p.set_physics_process(true)
	if st == "burrow":
		var at := Vector2(_goal_x, _floor_y)
		Util.explode(world, at, 130.0, 26, 40, p.team, p)
		for n in world.get_children():
			if n is Player and n.team != p.team and n.is_alive() and absf(n.global_position.x - _goal_x) < 130.0:
				n.velocity = Vector2(signf(n.global_position.x - _goal_x) * 300.0, -700.0)
		Fx.ring(world, at, 140.0, Color(0.9, 0.75, 0.5, 0.9), 0.4, 6.0)
		Fx.cracks(world, at, Color(0.25, 0.2, 0.18), 140.0)
		if p.rig:
			p.rig.play("roar")
	else:
		Shards.burst(world, p.global_position, p.team, p, 12, 12, Color(0.85, 0.8, 1.0))
		if p.rig:
			p.rig.play("roar")
