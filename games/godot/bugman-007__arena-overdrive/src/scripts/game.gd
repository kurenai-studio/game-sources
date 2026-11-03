extends Node2D
## Run controller. Owns the arena, pools and the wave/upgrade loop, and routes
## gameplay signals to scoring, progression, FX, audio and the HUD.

enum Phase { BETWEEN, SPAWNING, CHOOSING, OVER }

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const AIM_RANGE := 720.0

var character: CharacterData
var layout: Dictionary = {}
var theme_data: Dictionary
var player: Player
var camera: GameCamera
var hud: Hud
var stats: PlayerStats
var upgrades: UpgradeSystem
var progression := Progression.new()
var scores := ScoreManager.new()
var rng := RandomNumberGenerator.new()
var wave: int = 0
var phase: Phase = Phase.BETWEEN
var boss: Enemy
var autopilot: bool = false
var run: Dictionary = {
	"kills": 0, "damage_dealt": 0, "damage_taken": 0, "time": 0.0,
	"coins": 0, "bosses": 0, "flawless_waves": 0,
}

var _arena_rect: Rect2
var _arena_view: ArenaView
var _entities: Node2D
var _fx: Node2D
var _enemy_pool: ObjectPool
var _bullet_pool: ObjectPool
var _pickup_pool: ObjectPool
var _number_pool: ObjectPool
var _spawn_queue: Array[StringName] = []
var _spawn_timer: float = 0.0
var _wave_total: int = 0
var _wave_killed: int = 0
var _wave_damage: int = 0
var _between_timer: float = 1.2
var _pending_picks: int = 0
var _hazard_timer: float = 0.0
var _hazard_time: float = 0.0
var _coin_mult: float = 1.0
var _hitstop: bool = false
var _cards: UpgradeCards
var _pause: PauseMenu
var _results: ResultsScreen
var _auto_t: float = 0.0


func _ready() -> void:
	var tour := GameState.is_tour()
	if tour:
		rng.seed = 2026
	else:
		rng.randomize()
	character = GameState.characters.get(GameState.selected_character, GameState.characters[&"vanguard"])
	layout = ArenaGenerator.generate(11 if tour else rng.randi())
	theme_data = ArenaGenerator.THEMES[layout["theme"]]
	_arena_rect = Rect2(Vector2.ZERO, layout["size"])
	_build_world()

	stats = PlayerStats.from_character(character)
	MetaShop.apply_to_stats(stats, SaveSystem.meta_levels())
	_coin_mult = stats.get_stat(&"coin_gain")
	upgrades = UpgradeSystem.new(GameState.upgrades)

	player = PLAYER_SCENE.instantiate()
	player.setup(character, stats)
	player.position = _arena_rect.get_center()
	_entities.add_child(player)
	player.aim_provider = _aim_target
	player.fired.connect(_on_player_fired)
	player.ability_used.connect(_on_ability)
	player.dashed.connect(_on_dashed)
	player.damaged.connect(_on_player_damaged)
	player.healed.connect(func(c: int, m: int) -> void: EventBus.player_healed.emit(c, m))
	player.died.connect(_on_player_died)

	camera = GameCamera.new()
	camera.target = player
	camera.limit_left = -120
	camera.limit_top = -120
	camera.limit_right = int(_arena_rect.size.x) + 120
	camera.limit_bottom = int(_arena_rect.size.y) + 120
	add_child(camera)
	camera.global_position = player.global_position
	camera.reset_smoothing()

	_bullet_pool = ObjectPool.new(func() -> Node: return Projectile.new(), _fx, 96)
	_pickup_pool = ObjectPool.new(func() -> Node: return Pickup.new(), _entities, 48)
	_number_pool = ObjectPool.new(_make_number, _fx, 32)
	_enemy_pool = ObjectPool.new(_make_enemy, _entities, 24)

	hud = Hud.new()
	add_child(hud)
	hud.setup(self)
	var overlay := CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	_cards = UpgradeCards.new()
	overlay.add_child(_cards)
	_cards.chosen.connect(_on_card_chosen)
	_pause = PauseMenu.new()
	overlay.add_child(_pause)
	_pause.resume_requested.connect(_resume)
	_pause.quit_requested.connect(func() -> void: GameState.go_to_menu())
	_results = ResultsScreen.new()
	overlay.add_child(_results)
	_results.retry_requested.connect(func() -> void: GameState.start_run(character.id))
	_results.menu_requested.connect(func() -> void: GameState.go_to_menu())

	progression.leveled_up.connect(_on_level_up)
	scores.combo_changed.connect(_on_combo_changed)
	EventBus.screen_shake.connect(_on_shake)
	EventBus.hit_stop.connect(_on_hit_stop)
	AudioManager.play_music()
	autopilot = tour
	player.invulnerable_debug = tour
	hud.banner(tr(theme_data["key"]), tr("RUN_START_SUB") % tr(character.name_key), theme_data["accent"])


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _build_world() -> void:
	var floor_rect := ColorRect.new()
	floor_rect.size = _arena_rect.size
	floor_rect.z_index = -10
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/arena_floor.gdshader")
	mat.set_shader_parameter("bg_color", theme_data["bg"])
	mat.set_shader_parameter("grid_color", theme_data["grid"])
	mat.set_shader_parameter("accent_color", theme_data["accent"])
	mat.set_shader_parameter("arena_size", _arena_rect.size)
	floor_rect.material = mat
	add_child(floor_rect)
	_arena_view = ArenaView.new()
	_arena_view.layout = layout
	_arena_view.theme_data = theme_data
	_arena_view.z_index = -5
	add_child(_arena_view)
	var walls: Array[Rect2] = [
		Rect2(-200, -200, _arena_rect.size.x + 400, 200), Rect2(-200, _arena_rect.size.y, _arena_rect.size.x + 400, 200),
		Rect2(-200, 0, 200, _arena_rect.size.y), Rect2(_arena_rect.size.x, 0, 200, _arena_rect.size.y),
	]
	walls.append_array(layout["obstacles"])
	for r in walls:
		var body := StaticBody2D.new()
		body.collision_layer = 4
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = r.size
		shape.shape = box
		body.position = r.get_center()
		body.add_child(shape)
		add_child(body)
	_entities = Node2D.new()
	_entities.name = "Entities"
	add_child(_entities)
	_fx = Node2D.new()
	_fx.name = "Fx"
	_fx.z_index = 10
	add_child(_fx)


func _make_enemy() -> Node:
	var e: Enemy = ENEMY_SCENE.instantiate()
	e.died.connect(_on_enemy_died)
	e.fire_requested.connect(_on_enemy_fire)
	e.exploded.connect(_on_explosion)
	e.summon_requested.connect(func(id: StringName, at: Vector2) -> void: _spawn_enemy.call_deferred(id, at))
	e.phase_changed.connect(_on_boss_phase)
	return e


func _make_number() -> Node:
	var n := DamageNumber.new()
	n.finished.connect(func(node: DamageNumber) -> void: _number_pool.release(node))
	return n


# ------------------------------------------------------------------ loop

func _physics_process(delta: float) -> void:
	if phase == Phase.OVER:
		return
	run["time"] += delta
	scores.tick(delta)
	_hazard_time += delta
	_arena_view.t = _hazard_time
	match phase:
		Phase.BETWEEN:
			_between_timer -= delta
			if _between_timer <= 0.0:
				_start_wave(wave + 1)
		Phase.SPAWNING:
			if not _spawn_queue.is_empty():
				_spawn_timer -= delta
				if _spawn_timer <= 0.0:
					_spawn_timer = WaveDirector.spawn_interval(wave)
					_spawn_enemy(_spawn_queue.pop_front(), _spawn_point())
			elif living_enemies().is_empty():
				_wave_cleared()
	if autopilot:
		_drive_autopilot(delta)
	_update_bullets(delta)
	_update_pickups(delta)
	_update_hazards(delta)
	for e: Enemy in _enemy_pool.active.duplicate():
		if e.dissolved():
			_enemy_pool.release(e)


func living_enemies() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for e: Enemy in _enemy_pool.active:
		if e.is_alive():
			out.append(e)
	return out


func wave_progress() -> float:
	if _wave_total <= 0:
		return 1.0 if phase != Phase.SPAWNING else 0.0
	return clampf(float(_wave_killed) / _wave_total, 0.0, 1.0)


func _aim_target() -> Variant:
	var best: Enemy = null
	var best_d := AIM_RANGE
	for e in living_enemies():
		var d := e.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best.global_position if best else null


# ------------------------------------------------------------------ waves

func _start_wave(n: int) -> void:
	wave = n
	_spawn_queue = WaveDirector.compose(n, rng, GameState.enemies)
	_wave_total = _spawn_queue.size()
	_wave_killed = 0
	_wave_damage = 0
	_spawn_timer = 0.4
	phase = Phase.SPAWNING
	var is_boss := WaveDirector.is_boss_wave(n)
	EventBus.wave_started.emit(n, is_boss, _wave_total)
	AudioManager.play(&"wave", 0.0)
	if is_boss:
		hud.banner(tr("HUD_BOSS_WAVE") % n, tr("BOSS_INCOMING"), UiTheme.DANGER)
	else:
		hud.banner(tr("HUD_WAVE") % n, tr("ENEMIES_COUNT") % _wave_total, UiTheme.ACCENT)


func _spawn_point() -> Vector2:
	for i in 40:
		var p := Vector2(rng.randf_range(80, _arena_rect.size.x - 80), rng.randf_range(80, _arena_rect.size.y - 80))
		if p.distance_to(player.global_position) > 560.0 and not ArenaGenerator.point_blocked(p, layout["obstacles"], 40.0):
			return p
	return Vector2(100, 100)


func _spawn_enemy(id: StringName, at: Vector2) -> void:
	if phase == Phase.OVER or not GameState.enemies.has(id):
		return
	var data: EnemyData = GameState.enemies[id]
	var e: Enemy = _enemy_pool.acquire()
	e.setup(data, WaveDirector.health_scale(wave))
	e.global_position = at
	e.target = player
	Fx.ring(_fx, at, data.color, data.radius * 3.0, 0.4, 3.0)
	if e.is_boss():
		boss = e
		EventBus.boss_spawned.emit(e)
		AudioManager.play(&"boss", 0.0)
		EventBus.screen_shake.emit(0.7)
		EventBus.screen_flash.emit(UiTheme.DANGER)


func _wave_cleared() -> void:
	EventBus.wave_cleared.emit(wave)
	if _wave_damage == 0 and not player.invulnerable_debug:
		run["flawless_waves"] += 1
		scores.add_bonus(50 * wave)
	player.heal(player.max_health() * 0.1)
	_pending_picks += 1
	GameState.check_achievements(_run_snapshot(true))
	_open_cards()


func _open_cards() -> void:
	var choices := upgrades.roll_choices(rng, 3)
	if choices.is_empty():
		_pending_picks = 0
		phase = Phase.BETWEEN
		_between_timer = 2.0
		return
	phase = Phase.CHOOSING
	get_tree().paused = true
	_cards.present(choices, upgrades.stacks, _pending_picks)


func _on_card_chosen(u: UpgradeData) -> void:
	if phase != Phase.CHOOSING:
		return
	upgrades.take(u)
	stats.apply_upgrade(u)
	if u.stat == &"max_hp":
		player.heal(u.amount)
	EventBus.upgrade_chosen.emit(u.id)
	_pending_picks -= 1
	if _pending_picks > 0:
		_open_cards.call_deferred()
		return
	get_tree().paused = false
	Fx.ring(_fx, player.global_position, u.icon_color, 140.0, 0.5)
	phase = Phase.BETWEEN
	_between_timer = 1.6


func _on_level_up(level: int) -> void:
	_pending_picks += 1
	player.heal(player.max_health() * 0.15)
	AudioManager.play(&"level_up", 0.0)
	Fx.ring(_fx, player.global_position, Color("5dffd0"), 160.0, 0.6, 8.0)
	Fx.burst(_fx, player.global_position, Color("5dffd0"), 30, 320.0)
	hud.banner(tr("LEVEL_UP"), tr("LEVEL_UP_SUB") % level, Color("5dffd0"))
	EventBus.level_up.emit(level)


# ------------------------------------------------------------------ combat

func _on_player_fired(origin: Vector2, directions: Array[Vector2]) -> void:
	for d in directions:
		var roll := Combat.roll_damage(stats.get_stat(&"damage"), stats.get_stat(&"crit_chance"), stats.get_stat(&"crit_mult"), rng)
		var b: Projectile = _bullet_pool.acquire()
		var col := UiTheme.GOLD if roll["crit"] else character.color.lightened(0.35)
		b.launch(origin + d * 18.0, d * stats.get_stat(&"projectile_speed"), roll["amount"], Projectile.Team.PLAYER, col, stats.get_int(&"pierce"), roll["crit"], 5.5, 1.2)
	AudioManager.play(&"shoot", 0.12, -8.0)


func _on_enemy_fire(origin: Vector2, directions: Array[Vector2], speed: float, damage: int) -> void:
	for d in directions:
		var b: Projectile = _bullet_pool.acquire()
		b.launch(origin + d * 22.0, d * speed, damage, Projectile.Team.ENEMY, Color(1.0, 0.3, 0.45), 0, false, 7.0, 4.5)
	AudioManager.play(&"enemy_shoot", 0.1, -6.0)


func _update_bullets(delta: float) -> void:
	var living := living_enemies()
	var obstacles: Array[Rect2] = layout["obstacles"]
	for b: Projectile in _bullet_pool.active.duplicate():
		var alive := b.advance(delta)
		if alive and (not _arena_rect.has_point(b.position) or ArenaGenerator.point_blocked(b.position, obstacles)):
			alive = false
			Fx.burst(_fx, b.position, b.color, 5, 140.0, 0.25, 3.0)
		if alive and b.team == Projectile.Team.PLAYER:
			for e in living:
				if not e.is_alive():
					continue
				var id := e.get_instance_id()
				if b.already_hit(id) or b.position.distance_to(e.global_position) > e.data.radius + b.radius:
					continue
				_damage_enemy(e, b.damage, b.crit, b.velocity.normalized() * 160.0)
				if b.register_hit(id):
					alive = false
					break
		elif alive and not player.is_dead and b.position.distance_to(player.global_position) <= Player.RADIUS + b.radius - 2.0:
			if not player.is_dashing:
				player.take_damage(b.damage)
				alive = false
		if not alive:
			_bullet_pool.release(b)


func _damage_enemy(e: Enemy, amount: int, crit: bool, push: Vector2) -> void:
	run["damage_dealt"] += amount
	_spawn_number(e.global_position + Vector2(0, -e.data.radius - 6.0), str(amount), UiTheme.GOLD if crit else Color.WHITE, crit)
	AudioManager.play(&"crit" if crit else &"hit", 0.15, -6.0)
	if crit:
		EventBus.screen_shake.emit(0.12)
	e.take_hit(amount, push)


func _spawn_number(at: Vector2, text_value: String, color: Color, big: bool) -> void:
	var n: DamageNumber = _number_pool.acquire()
	n.show_number(at, text_value, color, big)


func _on_enemy_died(e: Enemy, rewarded: bool) -> void:
	var at := e.global_position
	Fx.burst(_fx, at, e.data.color, 70 if e.is_boss() else 22, 520.0 if e.is_boss() else 300.0, 0.7)
	if not rewarded:
		return
	run["kills"] += 1
	_wave_killed += 1
	scores.add_kill(e.data.score)
	EventBus.enemy_killed.emit(e.data.id, at)
	AudioManager.play(&"kill", 0.15, -3.0)
	var shards := clampi(int(e.data.xp / 3.0), 1, 12)
	for i in shards:
		_drop(Pickup.Kind.XP, maxi(1, int(round(float(e.data.xp) / shards))), at)
	if rng.randf() < e.data.coin_chance:
		for i in (20 if e.is_boss() else 1):
			_drop(Pickup.Kind.COIN, 1 + wave / 4, at)
	var heal_chance := 0.2 if e.data.behavior == EnemyData.Behavior.TANK else 0.03
	if e.is_boss() or rng.randf() < heal_chance:
		_drop(Pickup.Kind.HEALTH, 25, at)
	if e.is_boss():
		run["bosses"] += 1
		AudioManager.play(&"explode", 0.0)
		Fx.ring(_fx, at, UiTheme.GOLD, 420.0, 0.8, 12.0)
		EventBus.hit_stop.emit(0.3)
		EventBus.screen_shake.emit(1.0)
		EventBus.screen_flash.emit(Color.WHITE)
		hud.banner(tr("BOSS_DEFEATED"), tr("BOSS_DEFEATED_SUB"), UiTheme.GOLD)
		scores.add_bonus(500 * wave)
	elif e.data.behavior == EnemyData.Behavior.TANK:
		EventBus.hit_stop.emit(0.06)
		EventBus.screen_shake.emit(0.35)
	else:
		EventBus.hit_stop.emit(0.016)
		EventBus.screen_shake.emit(0.1)


func _drop(kind: Pickup.Kind, value: int, at: Vector2) -> void:
	var p: Pickup = _pickup_pool.acquire()
	p.setup(kind, value, at, Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(60.0, 200.0))


func _update_pickups(delta: float) -> void:
	if player.is_dead:
		return
	var radius := stats.get_stat(&"pickup_radius")
	for p: Pickup in _pickup_pool.active.duplicate():
		if not p.update(delta, player.global_position, radius):
			continue
		match p.kind:
			Pickup.Kind.XP:
				progression.add_xp(p.value)
				AudioManager.play(&"pickup", 0.2, -10.0)
			Pickup.Kind.COIN:
				run["coins"] += int(round(p.value * _coin_mult))
				EventBus.run_coins_changed.emit(run["coins"])
				AudioManager.play(&"coin", 0.05, -6.0)
			Pickup.Kind.HEALTH:
				player.heal(p.value)
				AudioManager.play(&"heal", 0.0)
				Fx.ring(_fx, player.global_position, UiTheme.SUCCESS, 80.0, 0.4)
		_pickup_pool.release(p)


func _on_explosion(origin: Vector2, radius: float, damage: int) -> void:
	AudioManager.play(&"explode", 0.1)
	Fx.burst(_fx, origin, Color(1.0, 0.6, 0.2), 40, 420.0, 0.6, 6.0)
	Fx.ring(_fx, origin, Color(1.0, 0.7, 0.3), radius, 0.35, 10.0)
	EventBus.screen_shake.emit(0.45)
	if player.global_position.distance_to(origin) <= radius:
		player.take_damage(damage)
	for e in living_enemies():
		if e.global_position.distance_to(origin) <= radius:
			_damage_enemy(e, int(damage * 0.75), false, (e.global_position - origin).normalized() * 400.0)


func _on_boss_phase(p: int) -> void:
	EventBus.boss_phase_changed.emit(p)
	EventBus.screen_shake.emit(0.6)
	EventBus.screen_flash.emit(UiTheme.ACCENT_2)
	AudioManager.play(&"boss", 0.0)
	if boss:
		Fx.ring(_fx, boss.global_position, UiTheme.DANGER, 300.0, 0.6, 10.0)


func _on_ability(kind: int, origin: Vector2, dir: Vector2) -> void:
	var power := stats.get_stat(&"ability_power")
	AudioManager.play(&"ability", 0.0)
	EventBus.hit_stop.emit(0.04)
	match kind:
		CharacterData.Ability.SHOCKWAVE:
			_area_damage(origin, 200.0, int(power), 650.0)
			Fx.ring(_fx, origin, character.color, 200.0, 0.4, 12.0)
			EventBus.screen_shake.emit(0.4)
		CharacterData.Ability.VOLLEY:
			for d in Combat.ring_directions(18, rng.randf() * TAU):
				var b: Projectile = _bullet_pool.acquire()
				b.launch(origin + d * 18.0, d * stats.get_stat(&"projectile_speed"), int(power), Projectile.Team.PLAYER, character.color.lightened(0.5), 1, false, 6.5, 1.0)
			Fx.ring(_fx, origin, character.color, 90.0, 0.3)
		CharacterData.Ability.BLINK_NOVA:
			var target := origin
			for i in range(8, 0, -1):
				var t := origin + dir * 30.0 * i
				if _arena_rect.grow(-30.0).has_point(t) and not ArenaGenerator.point_blocked(t, layout["obstacles"], 24.0):
					target = t
					break
			Fx.burst(_fx, origin, character.color, 24, 260.0)
			player.global_position = target
			_area_damage(target, 160.0, int(power), 450.0)
			Fx.ring(_fx, target, character.color, 160.0, 0.4, 10.0)
			EventBus.screen_shake.emit(0.35)


func _area_damage(origin: Vector2, radius: float, damage: int, push: float) -> void:
	for e in living_enemies():
		var d := e.global_position.distance_to(origin)
		if d <= radius + e.data.radius:
			_damage_enemy(e, damage, false, (e.global_position - origin).normalized() * push)


func _on_dashed() -> void:
	AudioManager.play(&"dash", 0.1)
	Fx.burst(_fx, player.global_position, character.color, 12, 180.0, 0.35)


func _on_player_damaged(amount: int, current: int, maximum: int) -> void:
	run["damage_taken"] += amount
	_wave_damage += amount
	EventBus.player_damaged.emit(amount, current, maximum)
	EventBus.screen_shake.emit(0.4)
	EventBus.hit_stop.emit(0.05)
	AudioManager.play(&"hurt", 0.05)
	_spawn_number(player.global_position + Vector2(0, -26), "-%d" % amount, UiTheme.DANGER, false)


func _update_hazards(delta: float) -> void:
	player.slow_factor = 1.0
	_hazard_timer = maxf(0.0, _hazard_timer - delta)
	for h: Dictionary in layout["hazards"]:
		if not (h["rect"] as Rect2).has_point(player.global_position):
			continue
		match int(h["type"]):
			ArenaGenerator.Hazard.SLOW:
				player.slow_factor = 0.55
			ArenaGenerator.Hazard.BURN:
				if _hazard_timer <= 0.0:
					_hazard_timer = 0.5
					player.take_damage(6)
					Fx.burst(_fx, player.global_position, Color(1, 0.4, 0.1), 8, 160.0)
			ArenaGenerator.Hazard.SHOCK:
				if ArenaView.shock_active(_hazard_time) and _hazard_timer <= 0.0:
					_hazard_timer = 0.6
					player.take_damage(12)
					Fx.burst(_fx, player.global_position, Color(0.8, 0.5, 1.0), 14, 240.0)
		break


# ------------------------------------------------------------------ feel

func _on_shake(strength: float) -> void:
	camera.add_trauma(strength)


func _on_hit_stop(duration: float) -> void:
	if _hitstop or phase == Phase.OVER:
		return
	_hitstop = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	if phase != Phase.OVER:
		Engine.time_scale = 1.0
	_hitstop = false


func _on_combo_changed(combo: int, _mult: float) -> void:
	if combo >= 2:
		hud.combo_pop()


# ------------------------------------------------------------------ flow

func _run_snapshot(include_unbanked: bool) -> Dictionary:
	var s := {"wave": wave, "max_combo": scores.max_combo, "level": progression.level, "flawless_waves": run["flawless_waves"]}
	if include_unbanked:
		s["kills_unbanked"] = run["kills"]
		s["bosses_unbanked"] = run["bosses"]
	return s


func results() -> Dictionary:
	var r := run.duplicate()
	r["score"] = scores.score
	r["wave"] = wave
	r["level"] = progression.level
	r["max_combo"] = scores.max_combo
	r["character"] = String(character.id)
	r["character_name"] = character.name_key
	return r


func _on_player_died() -> void:
	phase = Phase.OVER
	EventBus.player_died.emit()
	AudioManager.play(&"explode", 0.0)
	Fx.burst(_fx, player.global_position, character.color, 80, 600.0, 1.0, 6.0)
	Fx.ring(_fx, player.global_position, character.color, 300.0, 0.8, 10.0)
	camera.add_trauma(1.0)
	Engine.time_scale = 0.25
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(1.1)
	await tw.finished
	Engine.time_scale = 1.0
	_show_results()


func _show_results() -> void:
	var r := results()
	GameState.last_results = r
	var new_best := SaveSystem.record_run(r)
	SaveSystem.save_data()
	var unlocked := GameState.check_achievements(_run_snapshot(false))
	get_tree().paused = true
	_results.present(r, unlocked, new_best)


func _resume() -> void:
	_pause.hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and phase != Phase.OVER and phase != Phase.CHOOSING and not get_tree().paused:
		_open_pause()
		get_viewport().set_input_as_handled()


func _open_pause() -> void:
	get_tree().paused = true
	AudioManager.play_ui(&"ui_click")
	_pause.open(tr("PAUSE_STATS") % [wave, scores.score, run["kills"]])


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not autopilot and phase != Phase.OVER and phase != Phase.CHOOSING and is_inside_tree() and not get_tree().paused:
		_open_pause()


# ------------------------------------------------------------------ autopilot / debug (used by the screenshot tour)

func _drive_autopilot(delta: float) -> void:
	_auto_t += delta
	var living := living_enemies()
	var nearest: Enemy = null
	var best := INF
	var close := 0
	for e in living:
		var d := e.global_position.distance_to(player.global_position)
		if d < 200.0:
			close += 1
		if d < best:
			best = d
			nearest = e
	var center_pull := player.global_position.direction_to(_arena_rect.get_center()) * clampf(player.global_position.distance_to(_arena_rect.get_center()) / 600.0, 0.0, 1.0)
	var dir := Vector2.RIGHT.rotated(_auto_t * 0.7) * 0.4 + center_pull
	if nearest:
		var to := player.global_position.direction_to(nearest.global_position)
		if best < 200.0:
			dir += -to * 1.2 + to.orthogonal() * 0.6
		elif best > 340.0:
			dir += to
		else:
			dir += to.orthogonal()
	player.input_override = dir.normalized()
	if close >= 3:
		player.try_ability(player.facing)
	if nearest and best < 70.0:
		player.try_dash(dir)


func debug_force_upgrade() -> void:
	_pending_picks += 1
	_open_cards()


func debug_grant(id: StringName, times: int = 1) -> void:
	for u in GameState.upgrades:
		if u.id == id:
			for i in times:
				upgrades.take(u)
				stats.apply_upgrade(u)


func debug_pick_first() -> void:
	_cards.pick_first()


func debug_jump_to_wave(n: int) -> void:
	for e: Enemy in _enemy_pool.active.duplicate():
		_enemy_pool.release(e)
	_spawn_queue.clear()
	boss = null
	_cards.hide()
	get_tree().paused = false
	_pending_picks = 0
	wave = n - 1
	phase = Phase.BETWEEN
	_between_timer = 0.1


func debug_game_over() -> void:
	player.invulnerable_debug = false
	player.die()
