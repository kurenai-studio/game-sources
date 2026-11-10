class_name Player
extends CharacterBody2D
## Herói controlável. Lê os atributos da ficha (Hero) e cuida da física/ação.
##
## Controles: WASD ou clique esquerdo para andar; clique esquerdo em inimigo ataca;
## Shift + clique ataca parado; botão direito = habilidade secundária; 1-4 = habilidades;
## Espaço = esquiva; Q = poção; R = habilidade racial.

## Preloads para type hints funcionarem em parse time
const Hero := preload("res://scripts/core/hero.gd")
const SkillData := preload("res://scripts/data/skill_data.gd")
const Enemy := preload("res://scripts/game/enemy.gd")
# World não é preloadado aqui para evitar dependência circular com world.gd

signal died

enum State { IDLE, MOVE, WINDUP, RECOVERY, DODGE, DASH, DEAD }

const POTION_COOLDOWN := 20.0
const DODGE_COOLDOWN := 1.1
const DODGE_TIME := 0.28
const DODGE_SPEED_MULT := 3.2
const WINDUP_FRACTION := 0.45
const RACIAL_SLOT := 6

@onready var visual: Node2D = $Visual
@onready var body_sprite: AnimatedSprite2D = $Visual/Body
@onready var weapon_pivot: Node2D = $Visual/WeaponPivot
@onready var weapon_sprite: Sprite2D = $Visual/WeaponPivot/Weapon
@onready var camera: Camera2D = $Camera2D
@onready var light: PointLight2D = $Light

var hero: Hero
var world: World
var state: State = State.IDLE
var hp := 100.0
var max_hp := 100.0
var resource := 0.0
var max_resource := 100.0
var facing := Vector2.RIGHT

var cooldowns: Dictionary = {}          ## skill_id -> segundos restantes
var potion_cd := 0.0
var dodge_cd := 0.0
var auto_dodge_cd := 0.0
var cheat_death_cd := 0.0
var buffs: Dictionary = {}              ## nome -> {stat, amount, stat2, amount2, time, max_time, color, shape}
var minions: Array[Node2D] = []

var _state_time := 0.0
var _cast_skill: SkillData
var _cast_target := Vector2.ZERO
var _cast_slot := -1
var _buffered_slot := -1
var _move_dir := Vector2.ZERO
var _path := PackedVector2Array()
var _attack_target: Enemy
var _interact_target: Node2D
var _lmb_down := false
var _rmb_down := false
var _dash_from := Vector2.ZERO
var _dash_to := Vector2.ZERO
var _dash_time := 0.1
var _invuln := 0.0
var _flash := 0.0
var _step_timer := 0.0
var _combat_timer := 0.0
var _since_spend := 99.0
var _swing_tween: Tween
var _shader: ShaderMaterial
var _combo_count := 0
var _combo_strike := false
var _imbue_charges := 0
var _streak := 0
var _streak_timer := 0.0
var _last_streak_hit := 0
var _melee_cdr_done := false
var _shape := ""
var _base_scale := 1.0
# 3.2: veneno (afixo VENENOSO / piso ardente) - dano por segundo direto
var _poison_dps := 0.0
var _poison_time := 0.0
var _poison_tick := 0.0


func setup(p_hero: Hero, p_world: World) -> void:
	hero = p_hero
	world = p_world


func _ready() -> void:
	_base_scale = hero.race.body_scale
	_shader = ShaderMaterial.new()
	_shader.shader = preload("res://shaders/hit_flash.gdshader")
	body_sprite.material = _shader
	_apply_body_frames(hero.sprite_base())
	light.texture = Fx.light_texture()
	camera.zoom = Vector2.ONE * float(Game.settings.camera_zoom)
	hero.stats_changed.connect(_on_stats_changed)
	hero.leveled_up.connect(_on_level_up)
	_on_stats_changed()
	hp = max_hp
	resource = 0.0 if hero.cls.resource_decays else max_resource
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	($CollisionShape2D.shape as CircleShape2D).radius = 4.5 * minf(_base_scale, 1.0)


func _apply_body_frames(base: String) -> void:
	body_sprite.sprite_frames = DB.frames(base)
	body_sprite.play("idle")
	var fs := DB.frame_size(base)
	var sc := _base_scale
	if base != hero.sprite_base():
		sc = minf(1.0, 26.0 / fs.y)
	body_sprite.scale = Vector2.ONE * sc
	body_sprite.position = Vector2(0, -(fs.y + 2) * 0.5 * sc + 1)
	body_sprite.self_modulate = hero.tint * hero.race.tint if base == hero.sprite_base() else Color.WHITE
	weapon_pivot.position = Vector2(0, -fs.y * 0.3 * sc)


func _on_stats_changed() -> void:
	var ratio := hp / max_hp if max_hp > 0 else 1.0
	max_hp = hero.max_hp()
	hp = clampf(max_hp * ratio, 1.0, max_hp)
	max_resource = hero.max_resource()
	resource = minf(resource, max_resource)
	var w: Item = hero.equipment.weapon
	weapon_sprite.texture = DB.dt2_texture(w.sprite) if w and w.sprite != "" else null
	weapon_sprite.visible = _shape == ""


func _on_level_up(lvl: int) -> void:
	hp = max_hp
	if not hero.cls.resource_decays:
		resource = max_resource
	Sfx.play(&"levelup")
	FxShape.spawn(world.fx_layer, FxShape.Type.PILLAR, global_position, Color(1, 0.85, 0.3), 30.0, 0.9)
	Fx.burst(world.fx_layer, global_position, Color(1, 0.85, 0.3), 30, 70.0, 1.0)
	if world.hud:
		world.hud.show_message("Nível %d!" % lvl, Color(1, 0.85, 0.3))
	for s in hero.cls.skills:
		if s.unlock_level == lvl:
			if world.hud:
				world.hud.show_message("Nova habilidade: %s" % s.display_name, Color(0.6, 0.85, 1.0))


func is_dead() -> bool:
	return state == State.DEAD


# ------------------------------------------------------------------ INPUT

func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEAD:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_lmb_down = mb.pressed
			if mb.pressed:
				_on_left_click()
				get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_rmb_down = mb.pressed
			if mb.pressed:
				get_viewport().set_input_as_handled()


func _on_left_click() -> void:
	var mouse := get_global_mouse_position()
	var it := world.get_interactable_at(mouse)
	if it:
		_interact_target = it
		_attack_target = null
		_set_path_to(it.global_position)
		return
	_interact_target = null
	var e := world.get_enemy_at(mouse)
	if e:
		_attack_target = e
		_path.clear()


func _set_path_to(pos: Vector2) -> void:
	_path = world.find_path(global_position, pos)


# ------------------------------------------------------------------ LOOP

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_update_visuals(delta)
	if state == State.DEAD:
		velocity = velocity.move_toward(Vector2.ZERO, 400 * delta)
		move_and_slide()
		return

	_state_time += delta
	hero.play_time += delta
	# 3.2: veneno - tique de 1s; dano direto no HP (ignora armadura/resistências)
	if _poison_time > 0.0:
		_poison_time -= delta
		_poison_tick -= delta
		if _poison_tick <= 0.0:
			_poison_tick += 1.0
			hp -= _poison_dps
			_combat_timer = 4.0
			DamageNumber.spawn_text(world.fx_layer, global_position + Vector2(0, -14), "%d" % int(ceilf(_poison_dps)), Color(0.45, 1.0, 0.35))
			if hp <= 0.0:
				_die()
				return
		if _poison_time <= 0.0:
			_poison_dps = 0.0
	var mouse := get_global_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_lmb_down = false
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_rmb_down = false

	# Esquiva cancela recuperação e movimento (cancelamento de animação)
	if Input.is_action_just_pressed("dodge") and dodge_cd <= 0.0 and state in [State.IDLE, State.MOVE, State.RECOVERY]:
		_start_dodge(mouse)
	# Cura simples (Q) - sempre recarrega, sem custo de recurso
	if Input.is_action_just_pressed("heal"):
		_use_simple_heal()
	# Interagir (E) - contextual: fogueira, baú, NPC, portal, item no chão
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	for i in 4:
		if Input.is_action_just_pressed("skill_%d" % (i + 1)):
			_request_cast(i + 2, mouse)
	if Input.is_action_just_pressed("racial"):
		_request_cast(RACIAL_SLOT, mouse)
	# Ataque pesado (botão direito do mouse) - skill genérica
	if _rmb_down:
		_request_cast(1, mouse)

	match state:
		State.WINDUP:
			velocity = Vector2.ZERO
			if _state_time >= _cast_duration() * WINDUP_FRACTION:
				_deliver()
		State.RECOVERY:
			velocity = Vector2.ZERO
			if _buffered_slot >= 0:
				var s := _buffered_slot
				_buffered_slot = -1
				_request_cast(s, mouse)
			elif _state_time >= _cast_duration() * (1.0 - WINDUP_FRACTION):
				_set_state(State.IDLE)
		State.DODGE:
			velocity = _move_dir * hero.move_speed() * DODGE_SPEED_MULT
			if _state_time >= DODGE_TIME:
				_set_state(State.IDLE)
		State.DASH:
			global_position = _dash_from.lerp(_dash_to, clampf(_state_time / _dash_time, 0.0, 1.0))
			velocity = Vector2.ZERO
			if _state_time >= _dash_time:
				_set_state(State.IDLE)
		State.IDLE, State.MOVE:
			_free_movement(mouse)

	if state != State.DASH:
		move_and_slide()


func _free_movement(mouse: Vector2) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		_path.clear()
		_attack_target = null
		_interact_target = null

	if _lmb_down and input == Vector2.ZERO:
		if Input.is_action_pressed("force_stand"):
			_request_cast(0, mouse)
			return
		if _attack_target == null and _interact_target == null and Game.settings.click_to_move:
			if mouse.distance_to(global_position) > 6.0:
				_path = PackedVector2Array([mouse])
				if world.is_solid(mouse) or not world.has_line_of_sight(global_position, mouse):
					_set_path_to(mouse)

	if _attack_target:
		if not is_instance_valid(_attack_target) or _attack_target.is_dead():
			_attack_target = null
		else:
			var skill := hero.skill_in_slot(0)
			var reach := 26.0
			if skill:
				reach = skill.reach + _attack_target.body_radius() if skill.kind == SkillData.Kind.MELEE_ARC else skill.reach * 0.9
			var dist := global_position.distance_to(_attack_target.global_position)
			if dist <= reach and (skill == null or skill.kind == SkillData.Kind.MELEE_ARC or world.has_line_of_sight(global_position, _attack_target.global_position)):
				_path.clear()
				_request_cast(0, _attack_target.hit_center())
				if not _lmb_down:
					_attack_target = null
				return
			if not _path.is_empty() and _path[_path.size() - 1].distance_to(_attack_target.global_position) > 20.0:
				_set_path_to(_attack_target.global_position)

	if _interact_target:
		if not is_instance_valid(_interact_target):
			_interact_target = null
		elif global_position.distance_to(_interact_target.global_position) < 18.0:
			_interact_target.interact(self)
			_interact_target = null
			_path.clear()

	var dir := input
	if dir == Vector2.ZERO and not _path.is_empty():
		if global_position.distance_to(_path[0]) < 3.0:
			_path.remove_at(0)
		if not _path.is_empty():
			dir = global_position.direction_to(_path[0])
	# 7.4: ventania empurra quem anda a favor do vento (±10%, #14.5.1)
	velocity = dir * hero.move_speed() * WindField.speed_factor(global_position, dir)
	if dir != Vector2.ZERO:
		facing = dir
		if state != State.MOVE:
			_set_state(State.MOVE)
		_step_timer -= get_physics_process_delta_time()
		if _step_timer <= 0:
			_step_timer = 0.32
			Sfx.play(&"step", -22.0, 0.15)
	elif state == State.MOVE:
		_set_state(State.IDLE)


# ------------------------------------------------------------------ HABILIDADES

func skill_for_slot(slot: int) -> SkillData:
	if slot == RACIAL_SLOT:
		return hero.racial_skill()
	return hero.skill_in_slot(slot)


## Usa a skill no slot informado (chamado pelos slots de skill do HUD).
## O alvo é a posição do mouse no mundo.
func _use_skill(slot: int) -> void:
	_request_cast(slot, get_global_mouse_position())


## Custo efetivo (recurso, ou vida para o Bruxo)
func skill_cost(skill: SkillData) -> float:
	if hero.cls.costs_life and skill != hero.racial_skill():
		return max_hp * skill.cost * 0.0025
	return skill.cost


func can_afford(skill: SkillData) -> bool:
	if skill == hero.racial_skill():
		return true
	if hero.cls.costs_life:
		return hp > skill_cost(skill) + 1.0
	return resource >= skill.cost


func _request_cast(slot: int, target: Vector2) -> void:
	if state == State.WINDUP or state == State.DODGE or state == State.DASH:
		_buffered_slot = slot if slot > 0 else _buffered_slot
		return
	var skill := skill_for_slot(slot)
	if skill == null:
		return
	if cooldowns.get(skill.id, 0.0) > 0.0:
		if slot >= 1:
			world.hud.flash_slot(slot)
		return
	if not can_afford(skill):
		if slot >= 1:
			world.hud.flash_slot(slot)
			world.hud.show_message("%s insuficiente" % ("Vida" if hero.cls.costs_life else hero.cls.resource_label), Color(0.7, 0.7, 1.0), 0.8)
		return
	if skill.cost > 0 and skill != hero.racial_skill():
		if hero.cls.costs_life:
			hp -= skill_cost(skill)
		else:
			resource -= skill.cost
		_since_spend = 0.0
	if skill.cooldown > 0:
		cooldowns[skill.id] = skill.cooldown * hero.cooldown_mult()
	_cast_skill = skill
	_cast_slot = slot
	_cast_target = target
	facing = (target - global_position).normalized() if target.distance_to(global_position) > 1.0 else facing
	_path.clear()
	_set_state(State.WINDUP)
	_combat_timer = 4.0
	_play_swing_anim()


func _cast_duration() -> float:
	if _cast_skill == null:
		return 0.3
	match _cast_skill.kind:
		SkillData.Kind.BUFF, SkillData.Kind.HEAL, SkillData.Kind.SHAPESHIFT, SkillData.Kind.SUMMON:
			return 0.3
		SkillData.Kind.DASH, SkillData.Kind.LEAP:
			return 0.15
	var base := 0.42 if _cast_slot == 0 else 0.55
	return base / maxf(hero.attack_speed(), 0.2)


func _deliver() -> void:
	_set_state(State.RECOVERY)
	if _cast_skill == null:
		return
	_melee_cdr_done = false
	_combo_strike = false
	if _cast_slot == 0 and hero.cls.combo_every > 0:
		_combo_count += 1
		if _combo_count >= hero.cls.combo_every:
			_combo_count = 0
			_combo_strike = true
	if _cast_slot > 0 and _cast_slot != RACIAL_SLOT and hero.cls.spell_imbue_bonus > 0 and _cast_skill.kind != SkillData.Kind.DASH:
		_imbue_charges = 3
	SkillExecutor.execute(_cast_skill, self, _cast_target, hero)
	if _cast_slot == 0 and _imbue_charges > 0:
		_imbue_charges -= 1


func _play_swing_anim() -> void:
	if _swing_tween:
		_swing_tween.kill()
	var base_angle := facing.angle()
	var dur := _cast_duration()
	_swing_tween = create_tween()
	if _cast_skill and _cast_skill.kind == SkillData.Kind.MELEE_ARC:
		weapon_pivot.rotation = base_angle - 1.6
		_swing_tween.tween_property(weapon_pivot, "rotation", base_angle - 2.0, dur * WINDUP_FRACTION * 0.8).set_ease(Tween.EASE_OUT)
		_swing_tween.tween_property(weapon_pivot, "rotation", base_angle + 1.5, dur * 0.18).set_ease(Tween.EASE_IN)
	else:
		weapon_pivot.rotation = base_angle
		_swing_tween.tween_property(weapon_sprite, "position:x", 3.0, dur * WINDUP_FRACTION)
		_swing_tween.tween_property(weapon_sprite, "position:x", 11.0, dur * 0.15)
		_swing_tween.tween_property(weapon_sprite, "position:x", 8.0, dur * 0.3)
	var squash := create_tween()
	squash.tween_property(visual, "scale", Vector2(1.15, 0.88), dur * 0.3)
	squash.tween_property(visual, "scale", Vector2.ONE, dur * 0.4)


## Aplica dano do herói em um inimigo (com todos os modificadores de raça/classe)
func deal_damage(enemy: Enemy, mult: float, skill: SkillData) -> void:
	if not is_instance_valid(enemy) or enemy.is_dead():
		return
	var primary := skill != null and skill == hero.skill_in_slot(0)
	if primary and _combo_strike:
		mult *= 2.0
		enemy.stun(0.5)
	if primary and _imbue_charges > 0:
		mult *= 1.0 + hero.cls.spell_imbue_bonus
	if enemy.is_cc() and hero.race.cc_damage_bonus > 0:
		mult *= 1.0 + hero.race.cc_damage_bonus
	var roll := hero.roll_damage(mult)
	var kb := skill.knockback if skill else 40.0
	var element := skill.element if skill else "physical"
	var ignore_armor := skill != null and skill == hero.racial_skill()
	var dealt: float = enemy.take_damage(roll[0], roll[1], global_position, kb, element, ignore_armor)
	if dealt <= 0:
		return
	if hero.life_on_hit() > 0:
		heal(hero.life_on_hit(), false)
	var ls := hero.lifesteal()
	if ls > 0:
		heal(dealt * ls, false)
	if skill:
		if skill.slow > 0:
			enemy.apply_slow(skill.slow, maxf(skill.duration, 2.0))
		if skill.curse:
			enemy.curse(maxf(skill.duration, 6.0))
		if skill.confuse > 0:
			enemy.confuse(skill.confuse)
		if skill.fear > 0:
			enemy.fear(skill.fear, global_position)
	# Lâmina Arcana: golpes corpo a corpo reduzem recargas
	if primary and hero.cls.melee_cdr_on_hit > 0 and not _melee_cdr_done:
		_melee_cdr_done = true
		for k in cooldowns.keys():
			cooldowns[k] = maxf(cooldowns[k] - hero.cls.melee_cdr_on_hit, 0.0)
	# Tabaxi: sequência de acertos
	if primary and hero.race.frenzy_hits > 0:
		var now := Time.get_ticks_msec()
		if now - _last_streak_hit > 150:
			_last_streak_hit = now
			_streak += 1
			_streak_timer = 2.5
			if _streak >= hero.race.frenzy_hits:
				_streak = 0
				add_buff("speed", 0.4, 4.0, "Arrancada Feroz", Color(1, 0.7, 0.3), "attack_speed", 0.4)
	_combat_timer = 4.0


func gain_resource(amount: float) -> void:
	resource = minf(resource + amount, max_resource)


func start_dash(dest: Vector2, time: float) -> void:
	_dash_from = global_position
	_dash_to = dest
	_dash_time = time
	_invuln = time + 0.1
	_set_state(State.DASH)


func _start_dodge(mouse: Vector2) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_move_dir = input if input != Vector2.ZERO else global_position.direction_to(mouse)
	if _move_dir == Vector2.ZERO:
		_move_dir = facing
	facing = _move_dir
	dodge_cd = DODGE_COOLDOWN
	_invuln = DODGE_TIME
	_path.clear()
	_set_state(State.DODGE)
	Sfx.play(&"cloth", -4.0)
	var tw := create_tween()
	tw.tween_property(visual, "rotation", TAU * signf(_move_dir.x if _move_dir.x != 0 else 1.0), DODGE_TIME)
	tw.tween_callback(func(): visual.rotation = 0.0)


func use_potion() -> void:
	if potion_cd > 0.0:
		world.hud.show_message("Poção em recarga (%ds)" % ceili(potion_cd), Color(0.9, 0.6, 0.6), 0.8)
		return
	potion_cd = POTION_COOLDOWN
	heal(max_hp * 0.5)
	Sfx.play(&"potion")
	Fx.burst(world.fx_layer, global_position + Vector2(0, -6), Color(1, 0.2, 0.2), 16, 40.0, 0.7)


## Cura simples (Q) - sempre disponível, sem custo, CD 8s
## Público: o tutorial (prologue) e a HUD leem este cooldown
var simple_heal_cd := 0.0
const SIMPLE_HEAL_CD := 8.0
const SIMPLE_HEAL_PERCENT := 0.15

func _use_simple_heal() -> void:
	if simple_heal_cd > 0.0:
		world.hud.show_message("Cura simples em recarga (%ds)" % ceili(simple_heal_cd), Color(0.9, 0.6, 0.6), 0.8)
		return
	simple_heal_cd = SIMPLE_HEAL_CD
	heal(max_hp * SIMPLE_HEAL_PERCENT)
	Sfx.play(&"magic")
	Fx.burst(world.fx_layer, global_position + Vector2(0, -6), Color(0.3, 1, 0.5), 12, 30.0, 0.6)
	world.hud.show_message("Cura Simples (+%d%% HP)" % int(SIMPLE_HEAL_PERCENT * 100), Color(0.4, 1, 0.4), 1.2)


## Interagir (E) - contextual: fogueira, baú, NPC, portal, item no chão
## Prioridade: LootDrop > Interactable/Npc > Portal (por proximidade do jogador)
func _try_interact() -> void:
	var ppos := global_position
	var max_reach := 96.0

	# 1. LootDrop mais próximo do jogador
	var best_loot: LootDrop = null
	var best_dist := max_reach
	for n in world.get_tree().get_nodes_in_group("interactables"):
		if n is LootDrop:
			var d: float = n.global_position.distance_to(ppos)
			if d < best_dist:
				best_dist = d
				best_loot = n
	if best_loot:
		best_loot.interact(self)
		return

	# 2. Interactable ou Npc mais próximo do jogador que aceite interação
	var best_interactable: Node2D = null
	best_dist = max_reach
	for n in world.get_tree().get_nodes_in_group("interactables"):
		if (n is Interactable or n is Npc) and not (n is LootDrop):
			if n is Interactable and not (n as Interactable).can_interact(self):
				continue
			var d: float = n.global_position.distance_to(ppos)
			if d < best_dist:
				best_dist = d
				best_interactable = n
	if best_interactable:
		best_interactable.interact(self)
		return

	# 3. Portal/transição de área
	for n in world.get_tree().get_nodes_in_group("area_transitions"):
		if n.global_position.distance_to(ppos) < 48.0:
			n.activate(self)
			return


## Usar consumível do slot 1-9
func _use_consumable_slot(slot: int) -> void:
	if slot < 0 or slot >= hero.consumable_slots.size():
		return
	var item: Item = hero.consumable_slots[slot]
	if item == null:
		world.hud.show_message("Slot %d vazio" % (slot + 1), Color(0.9, 0.6, 0.6), 0.8)
		return
	# Verifica cooldown do item
	var cd: float = hero.consumable_cooldowns.get(item.base_id, 0.0)
	if cd > 0.0:
		world.hud.show_message("%s em recarga (%ds)" % [item.name, ceili(cd)], Color(0.9, 0.6, 0.6), 0.8)
		return
	# Verifica se tem o item no inventário
	var count: int = hero.count_item(item.base_id)
	if count <= 0:
		world.hud.show_message("Sem %s no inventário" % item.name, Color(0.9, 0.6, 0.6), 0.8)
		# Limpa o slot se não tem mais o item
		hero.consumable_slots[slot] = null
		if world.hud.has_method("_refresh_consumable_slot"):
			world.hud._refresh_consumable_slot(slot)
		return
	# Usa o consumível
	if item.use(self):
		# Consome uma cópia do item do inventário
		for it in hero.inventory.items:
			if it.base_id == item.base_id:
				hero.inventory.remove(it)
				break
		# Aplica cooldown se houver
		if item.cooldown > 0:
			hero.consumable_cooldowns[item.base_id] = item.cooldown
		if world.hud.has_method("_flash_consumable_slot"):
			world.hud._flash_consumable_slot(slot)
		Sfx.play(&"potion")
	else:
		world.hud.show_message("Não pode usar agora", Color(0.9, 0.6, 0.6), 0.8)


func heal(amount: float, show := true) -> void:
	if is_dead():
		return
	var before := hp
	hp = minf(hp + amount, max_hp)
	if show and hp - before >= 1.0:
		DamageNumber.spawn(world.fx_layer, global_position + Vector2(0, -10), hp - before, false, Color(0.4, 1, 0.4))


func add_buff(stat: String, amount: float, duration: float, buff_name: String, color: Color, stat2 := "", amount2 := 0.0, shape := "") -> void:
	if shape != "":
		# Só uma forma por vez
		for k in buffs.keys():
			if buffs[k].shape != "":
				buffs.erase(k)
	buffs[buff_name] = {"stat": stat, "amount": amount, "stat2": stat2, "amount2": amount2, "time": duration, "max_time": duration, "color": color, "shape": shape}
	_recompute_buffs()
	world.hud.show_message(buff_name, color, 1.0)


func _recompute_buffs() -> void:
	hero.temp.clear()
	var shape := ""
	for b in buffs.values():
		hero.temp[b.stat] = float(hero.temp.get(b.stat, 0.0)) + b.amount
		if b.stat2 != "":
			hero.temp[b.stat2] = float(hero.temp.get(b.stat2, 0.0)) + b.amount2
		if b.shape != "":
			shape = b.shape
	if shape != _shape:
		_shape = shape
		_apply_body_frames(shape if shape != "" else hero.sprite_base())
		Fx.burst(world.fx_layer, global_position + Vector2(0, -8), Color(0.7, 1, 0.6), 20, 50.0, 0.6)
	hero.stats_changed.emit()


# ------------------------------------------------------------------ DANO

## Veneno (3.2): dps por segundo que ignora armadura/resistências
func apply_poison(dps: float, time: float) -> void:
	if is_dead() or dps <= 0.0 or time <= 0.0:
		return
	_poison_dps = maxf(_poison_dps, dps)
	_poison_time = maxf(_poison_time, time)

func is_poisoned() -> bool:
	return _poison_time > 0.0


func take_damage(amount: float, from_pos: Vector2 = Vector2.INF, element := "physical", attacker: Node2D = null) -> void:
	if is_dead() or _invuln > 0.0:
		return
	var race := hero.race
	# Passos Leves (Elfo da Floresta)
	if race.auto_dodge_interval > 0.0 and auto_dodge_cd <= 0.0:
		auto_dodge_cd = race.auto_dodge_interval
		DamageNumber.spawn_text(world.fx_layer, global_position + Vector2(0, -16), "Esquiva!", Color(0.6, 1, 0.6))
		return
	# Bloqueio com escudo (golpes físicos)
	if element == "physical" and randf() < hero.block_chance():
		DamageNumber.spawn_text(world.fx_layer, global_position + Vector2(0, -16), "Bloqueado!", Color(0.7, 0.8, 1))
		Sfx.play(&"block", -4.0)
		if hero.cls.gain_on_block > 0:
			gain_resource(hero.cls.gain_on_block)
		return
	var final := amount * (1.0 - hero.resist(element))
	if final <= 0.0:
		DamageNumber.spawn_text(world.fx_layer, global_position + Vector2(0, -16), "Imune", Color(1, 0.6, 0.3))
		return
	hp -= final
	_combat_timer = 4.0
	_flash = 0.6
	_streak = 0
	if hero.cls.gain_on_hurt > 0:
		gain_resource(hero.cls.gain_on_hurt)
	# Pele Infernal (Tiefling): espinhos de fogo
	if race.thorns > 0 and element == "physical" and attacker is Enemy and is_instance_valid(attacker):
		(attacker as Enemy).take_damage(amount * race.thorns, false, global_position, 0.0, "fire", true)
	DamageNumber.spawn(world.fx_layer, global_position + Vector2(0, -12), final, false, DB.ELEMENT_COLORS.get(element, Color(1, 0.3, 0.3)).lerp(Color(1, 0.3, 0.3), 0.5))
	Sfx.play(&"hurt", -4.0)
	body_sprite.play("hit")
	world.shake(clampf(final / max_hp * 30.0, 1.5, 6.0))
	world.hud.damage_vignette()
	if from_pos != Vector2.INF and not race.knockback_immune:
		velocity += from_pos.direction_to(global_position) * 40.0
	if hp <= 0.0:
		# Fúria Implacável (Meio-Orc)
		if race.cheat_death_cooldown > 0.0 and cheat_death_cd <= 0.0:
			cheat_death_cd = race.cheat_death_cooldown
			hp = 1.0
			_invuln = 3.0
			world.hud.show_message("Fúria Implacável!", Color(1, 0.3, 0.2), 2.0)
			FxShape.spawn(world.fx_layer, FxShape.Type.RING, global_position, Color(1, 0.2, 0.1), 40.0, 0.6)
			return
		_die()


func _die() -> void:
	hp = 0.0
	_set_state(State.DEAD)
	Sfx.play(&"death")
	var tw := create_tween()
	tw.tween_property(visual, "rotation", PI / 2.0, 0.4)
	tw.parallel().tween_property(visual, "modulate", Color(0.6, 0.2, 0.2), 0.6)
	died.emit()


func revive() -> void:
	hp = max_hp
	resource = 0.0 if hero.cls.resource_decays else max_resource
	visual.rotation = 0.0
	visual.modulate = Color.WHITE
	_invuln = 2.0
	_poison_dps = 0.0
	_poison_time = 0.0
	_poison_tick = 0.0
	_set_state(State.IDLE)


# ------------------------------------------------------------------ TIMERS / VISUAL

func _tick_timers(delta: float) -> void:
	for k in cooldowns.keys():
		cooldowns[k] = maxf(cooldowns[k] - delta, 0.0)
	potion_cd = maxf(potion_cd - delta, 0.0)
	simple_heal_cd = maxf(simple_heal_cd - delta, 0.0)
	dodge_cd = maxf(dodge_cd - delta, 0.0)
	auto_dodge_cd = maxf(auto_dodge_cd - delta, 0.0)
	cheat_death_cd = maxf(cheat_death_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_combat_timer = maxf(_combat_timer - delta, 0.0)
	_since_spend += delta
	_streak_timer -= delta
	if _streak_timer <= 0.0:
		_streak = 0
	var expired := false
	for k in buffs.keys():
		buffs[k].time -= delta
		if buffs[k].time <= 0:
			buffs.erase(k)
			expired = true
	if expired:
		_recompute_buffs()
	minions = minions.filter(func(m): return is_instance_valid(m))
	if is_dead():
		return
	# Recurso de classe
	var cls := hero.cls
	var regen := hero.resource_regen()
	if cls.burst_regen_after_idle > 0.0 and _since_spend > 2.0:
		regen *= cls.burst_regen_after_idle
	if cls.regen_only_still and state != State.IDLE:
		regen *= 0.15
	if cls.resource_decays and _combat_timer <= 0.0:
		regen -= 5.0
	resource = clampf(resource + regen * delta, 0.0, max_resource)
	# Regeneração de vida fora de combate
	if _combat_timer <= 0.0:
		hp = minf(hp + max_hp * 0.02 * hero.race.ooc_regen_mult * delta, max_hp)


func _update_visuals(delta: float) -> void:
	_flash = maxf(_flash - delta * 5.0, 0.0)
	_shader.set_shader_parameter("flash", _flash)
	_shader.set_shader_parameter("flash_color", Color(1, 0.2, 0.2))
	var mouse_dir := get_global_mouse_position() - global_position
	var look := facing if state != State.IDLE else mouse_dir
	if absf(look.x) > 0.5:
		body_sprite.flip_h = look.x < 0
	if body_sprite.animation != "hit" or not body_sprite.is_playing():
		var anim := "run" if state in [State.MOVE, State.DODGE, State.DASH] else "idle"
		if body_sprite.animation != anim:
			body_sprite.play(anim)
	if state in [State.IDLE, State.MOVE] and (_swing_tween == null or not _swing_tween.is_running()):
		weapon_pivot.rotation = lerp_angle(weapon_pivot.rotation, (-PI / 2.0 + 0.6) if not body_sprite.flip_h else (-PI / 2.0 - 0.6), 10 * delta)
		weapon_sprite.position.x = 8.0
	modulate.a = 0.5 if _invuln > 0.0 and state != State.DASH and state != State.DODGE and state != State.DEAD else 1.0


func _draw() -> void:
	draw_set_transform(Vector2(0, -0.5), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 6.0 * _base_scale, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


func _exit_tree() -> void:
	"""Desconectar signals do herói para evitar memory leak"""
	if hero.stats_changed.is_connected(_on_stats_changed):
		hero.stats_changed.disconnect(_on_stats_changed)
	if hero.leveled_up.is_connected(_on_level_up):
		hero.leveled_up.disconnect(_on_level_up)
