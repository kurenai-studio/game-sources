class_name Enemy
extends CharacterBody2D
## Monstro com IA simples por comportamento (EnemyData.Behavior) e efeitos de status.

signal killed(enemy: Enemy)

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, STUNNED, DEAD }

## Raridade de monstro (MECANICAS #5.2, REGRAS #6). Chefe é roteirizado:
## vira CHEFE no spawn; os dados do EnemyData já são tuned de chefe.
enum Rarity { COMUM, ELITE, CAMPEAO, LENDARIO, CHEFE }

## Afixos de Campeão/Lendário, estilo Diablo (MECANICAS #5.2).
## Sorteados sem repetição pelo RNG do chunk (determinístico pela semente).
enum Affix {
	FURIOSO,              # +30% velocidade de ataque
	ESCUDO_ARCANO,        # escudo que absorve dano e regenera a cada 5s
	TELURICO,             # imune a knockback
	VENENOSO,             # ataques aplicam veneno
	FANTASMA,             # 20% de esquiva
	MESTRE_DE_ENXAME,     # invoca 3 lacaios a 50% de HP
	ARDENTE,              # deixa o piso em chamas
	CAMPEAO_DAS_SOMBRAS,  # teleporta para perto do alvo a cada 6s
}
const AFFIX_NAMES := [
	"Furioso", "Escudo Arcano", "Telúrico", "Venenoso", "Fantasma",
	"Mestre-de-Enxame", "Ardente", "Campeão-das-Sombras",
]

## Multiplicadores por raridade (REGRAS #6): HP, dano, XP/ouro, escala visual
const RARITY_HP := [1.0, 2.5, 5.0, 10.0, 1.0]
const RARITY_DMG := [1.0, 1.3, 1.8, 2.5, 1.0]
const RARITY_REWARD := [1, 3, 6, 15, 1]
const RARITY_SCALE := [1.0, 1.25, 1.4, 1.55, 1.0]
## Cor identificável à primeira vista (aceitação da Fase 3): barra, contorno, HUD
const RARITY_COLORS := [
	Color.WHITE,
	Color(0.3, 0.55, 1.0),   # Elite: azul (atual)
	Color(0.68, 0.32, 1.0),  # Campeão: roxo
	Color(1.0, 0.55, 0.15),  # Lendário: laranja-brasa
	Color(1.0, 0.45, 0.1),   # Chefe: laranja (atual)
]
const ELITE_PREFIXES := ["Ancião", "Furioso", "Pestilento", "Sombrio", "Incandescente"]

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite

var data: EnemyData
var world: World
var depth := 1
var rarity: int = Rarity.COMUM
var display_name := ""
var hp := 10.0
var max_hp := 10.0
var damage := 5.0
var armor := 0.0
var speed := 50.0
var aggro_mult := 1.0  # bônus por instância (ex.: +10% à noite); não toca no EnemyData compartilhado
var xp := 5
var state: State = State.IDLE

var _state_time := 0.0
var _attack_cd := 0.0
var _stun_time := 0.0
var _slow_time := 0.0
var _slow_amount := 0.0
var _confuse_time := 0.0
var _fear_time := 0.0
var _fear_from := Vector2.ZERO
var _curse_time := 0.0
var _knock := Vector2.ZERO
var _path := PackedVector2Array()
var _repath := 0.0
var _flash := 0.0
var _charge_dir := Vector2.ZERO
var _did_hit := false
var _boss_phase := 0
var _wander_target := Vector2.ZERO
var _shader: ShaderMaterial
var _hp_bar_visible := 0.0
var _aura: PointLight2D
## 3.4: beam vertical de spawn do Lendário - visível de longe (REGRAS #6)
var _spawn_beam: Polygon2D
var _home := Vector2.ZERO
var _target: Node2D
var _telegraph_target := Vector2.ZERO
var _frame_h := 16.0
var _single_frame := false
var _sprite_y := 0.0
# 3.2: estado dos afixos (MECANICAS #5.2)
var affixes: Array[int] = []
var _shield := 0.0
var _shield_max := 0.0
var _shield_timer := 5.0
var _swarm_done := false
var _shadow_cd := 3.0
var _fire_cd := 0.0


func setup(p_data: EnemyData, p_world: World, p_depth: int, p_rarity: int, p_affixes: Array = []) -> void:
	data = p_data
	world = p_world
	depth = p_depth
	rarity = p_rarity
	affixes.clear()
	affixes.assign(p_affixes)


func _ready() -> void:
	add_to_group("enemies")
	# 7.4: Campeões/chefes PARAM o vento ao redor - calmaria sobrenatural
	# (#14.5.2): cue grátis de perigo, as chamas param de crepitar
	if rarity >= Rarity.CAMPEAO:
		WindField.add_calm(get_instance_id(), global_position)
	var diff: Dictionary = Game.hero.difficulty_data() if Game.hero else DB.DIFFICULTIES[0]
	var hp_mult: float = (1.0 + 0.4 * (depth - 1)) * diff.hp
	var dmg_mult: float = (1.0 + 0.25 * (depth - 1)) * diff.dmg
	max_hp = data.max_hp * hp_mult
	damage = data.damage * dmg_mult
	armor = data.armor + depth * 2
	speed = data.move_speed * randf_range(0.9, 1.1)
	xp = int(data.xp * (1.0 + 0.3 * (depth - 1)))
	display_name = data.display_name
	var sc := data.scale
	# 3.1: raridades (REGRAS #6) - multiplicadores, título e escala.
	# Chefe é roteirizado: tabelas valem 1.0/1 no índice CHEFE (dados já tuned).
	if rarity != Rarity.COMUM:
		max_hp *= RARITY_HP[rarity]
		damage *= RARITY_DMG[rarity]
		xp *= RARITY_REWARD[rarity]
		sc *= RARITY_SCALE[rarity]
		match rarity:
			Rarity.ELITE:
				display_name = "%s %s" % [ELITE_PREFIXES.pick_random(), data.display_name]
			Rarity.CAMPEAO:
				display_name = "Campeão %s" % data.display_name
			Rarity.LENDARIO:
				display_name = "%s, o Lendário" % data.display_name
	hp = max_hp
	# 3.2: Escudo Arcano - escudo inicial de 10% do HP máximo, regenera a cada 5s
	if has_affix(Affix.ESCUDO_ARCANO):
		_shield_max = max_hp * 0.1
		_shield = _shield_max
	_home = global_position
	sprite.sprite_frames = DB.frames(data.sprite)
	sprite.play("idle")
	sprite.frame = randi() % maxi(sprite.sprite_frames.get_frame_count("idle"), 1)
	var fs := DB.frame_size(data.sprite)
	_frame_h = fs.y
	sprite.position = Vector2(0, -(fs.y + 2) * 0.5 + 1)
	_sprite_y = sprite.position.y
	_single_frame = sprite.sprite_frames.get_frame_count("run") <= 1
	sprite.self_modulate = data.tint
	visual.scale = Vector2.ONE * sc
	_shader = ShaderMaterial.new()
	_shader.shader = preload("res://shaders/hit_flash.gdshader")
	sprite.material = _shader
	if rarity >= Rarity.ELITE and not is_boss():
		_shader.set_shader_parameter("outline_color", RARITY_COLORS[rarity])
	# Aura pulsante: Campeão/Lendário se destacam à primeira vista (aceitação 3.1)
	if rarity >= Rarity.CAMPEAO and not is_boss():
		# 7.3: energia >1 para a aura florescer no glow (HDR 2D, #14.3)
		_aura = Fx.make_light(RARITY_COLORS[rarity], 1.4, 1.3)
		_aura.position = Vector2(0, -10)
		add_child(_aura)
	# 3.4: Lendário anuncia o spawn com beam visível de longe (REGRAS #6);
	# afunilado (largo na base, estreino no topo) com gradiente até transparente
	if rarity == Rarity.LENDARIO and not is_boss():
		_spawn_beam = Polygon2D.new()
		var bc: Color = RARITY_COLORS[rarity]
		var y0 := _sprite_y - fs.y * 0.5
		_spawn_beam.polygon = PackedVector2Array([
			Vector2(-6.0, y0), Vector2(6.0, y0),
			Vector2(3.0, y0 - 84.0), Vector2(-3.0, y0 - 84.0)])
		var solid: Color = Color(bc.r, bc.g, bc.b, 0.85)
		_spawn_beam.vertex_colors = PackedColorArray([solid, solid,
			Color(bc.r, bc.g, bc.b, 0.0), Color(bc.r, bc.g, bc.b, 0.0)])
		visual.add_child(_spawn_beam)
	if is_boss():
		_shader.set_shader_parameter("outline_color", Color(1.0, 0.45, 0.1, 1.0))
		var l := Fx.make_light(Color(1, 0.4, 0.2), 1.6, 0.8)
		l.position = Vector2(0, -12)
		add_child(l)
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	($CollisionShape2D.shape as CircleShape2D).radius = clampf(fs.x * 0.3, 4.0, 9.0) * sc
	_attack_cd = randf_range(0.2, 1.0)


func is_dead() -> bool:
	return state == State.DEAD


## Sorteia a raridade do pack (REGRAS #6): Elite 8% +1%/nível, Campeão 2%,
## Lendário 0,3%. `bonus` = dificuldade (diff.loot: 0/8/16/28%) - cada
## dificuldade aumenta as chances de raridade. `rng` opcional para
## determinismo por chunk; null usa o RNG global.
static func roll_rarity(level: int, bonus := 0.0, rng: RandomNumberGenerator = null) -> int:
	var p_lend := 0.003 + bonus * 0.01
	var p_camp := 0.02 + bonus * 0.02
	var p_elit := 0.08 + level * 0.01 + bonus
	var r := rng.randf() if rng != null else randf()
	if r < p_lend:
		return Rarity.LENDARIO
	if r < p_lend + p_camp:
		return Rarity.CAMPEAO
	if r < p_lend + p_camp + p_elit:
		return Rarity.ELITE
	return Rarity.COMUM


## Sorteia `count` afixos sem repetição (MECANICAS #5.2). `rng` opcional para
## determinismo por chunk; null usa o RNG global.
static func roll_affixes(rng: RandomNumberGenerator, count: int) -> Array[int]:
	var pool: Array[int] = [
		Affix.FURIOSO, Affix.ESCUDO_ARCANO, Affix.TELURICO, Affix.VENENOSO,
		Affix.FANTASMA, Affix.MESTRE_DE_ENXAME, Affix.ARDENTE, Affix.CAMPEAO_DAS_SOMBRAS,
	]
	var out: Array[int] = []
	for i in count:
		if pool.is_empty():
			break
		var idx := rng.randi_range(0, pool.size() - 1) if rng != null else randi_range(0, pool.size() - 1)
		out.append(pool[idx])
		pool.remove_at(idx)
	return out


## Afixos por raridade: Campeão 1-2, Lendário 2-3 (MECANICAS #5.2).
## Inferno dá +1 a Elite+ (REGRAS #7). Comum e Chefe (roteirizado) não ganham.
static func affixes_for(rarity: int, rng: RandomNumberGenerator = null, hell_bonus := false) -> Array[int]:
	var count := 0
	match rarity:
		Rarity.CAMPEAO:
			count = 1 + (1 if (rng.randf() if rng != null else randf()) < 0.5 else 0)
		Rarity.LENDARIO:
			count = 2 + (1 if (rng.randf() if rng != null else randf()) < 0.5 else 0)
	if hell_bonus and rarity >= Rarity.ELITE and rarity != Rarity.CHEFE:
		count += 1
	if count <= 0:
		return []
	return roll_affixes(rng, count)


func has_affix(a: int) -> bool:
	return affixes.has(a)


## Nomes legíveis dos afixos (HUD do alvo, 3.4)
func affix_names() -> Array[String]:
	var out: Array[String] = []
	for a in affixes:
		out.append(AFFIX_NAMES[a])
	return out


func is_boss() -> bool:
	return data.behavior == EnemyData.Behavior.BOSS


func is_cc() -> bool:
	return state == State.STUNNED or _slow_time > 0.0 or _confuse_time > 0.0 or _fear_time > 0.0


func hit_center() -> Vector2:
	return global_position + Vector2(0, -_frame_h * 0.45 * visual.scale.y)


func body_radius() -> float:
	return clampf(_frame_h * 0.3, 5.0, 12.0) * visual.scale.x


# ------------------------------------------------------------------ DANO E STATUS

## Retorna o dano efetivamente causado
## 8.2: multiplicador de dano por tipo elemental (REGRAS #3) - estático
## para o smoke conferir os números sem instanciar inimigo.
static func _resist_calc(amount: float, element: String, edata: EnemyData) -> float:
	if element == "holy" and edata.elemental_type == EnemyData.ElementalType.UNDEAD:
		return amount * 1.5  # mortos-vivos levam x1.5 de Sagrado
	if element == "holy" and edata.elemental_type == EnemyData.ElementalType.DEMON:
		return amount * 1.5  # demônios fracos a Sagrado
	if element == "shadow" and edata.elemental_type == EnemyData.ElementalType.DEMON:
		return 0.0  # demônios imunes a Sombrio (não têm laço - LORE)
	return amount


func take_damage(amount: float, crit: bool, from_pos: Vector2, knockback: float, element := "physical", ignore_armor := false) -> float:
	if is_dead():
		return 0.0
	# FANTASMA: 20% de esquiva (MECANICAS #5.2)
	if has_affix(Affix.FANTASMA) and randf() < 0.2:
		DamageNumber.spawn_text(world.fx_layer, hit_center(), "Esquiva", Color(0.65, 0.85, 1.0))
		return 0.0
	var final := amount if ignore_armor else amount * (100.0 / (100.0 + armor))
	# REGRAS #3: resistências/vulnerabilidades por tipo elemental
	final = _resist_calc(final, element, data)
	if final <= 0.0:
		DamageNumber.spawn_text(world.fx_layer, hit_center(), "Imune", Color(0.75, 0.5, 1))
		return 0.0
	_flash = 1.0
	_hp_bar_visible = 4.0
	# ESCUDO ARCANO: absorve o dano antes de tocar o HP
	if _shield > 0.0 and final > 0.0:
		var absorbed: float = minf(_shield, final)
		_shield -= absorbed
		final -= absorbed
		DamageNumber.spawn_text(world.fx_layer, hit_center(), "%.0f" % absorbed, Color(0.55, 0.8, 1.0))
		if final <= 0.0:
			if state == State.IDLE:
				state = State.CHASE
			return 0.0
	hp -= final
	DamageNumber.spawn(world.fx_layer, hit_center(), final, crit, DB.ELEMENT_COLORS.get(element, Color.WHITE))
	Fx.burst(world.fx_layer, hit_center(), Color(0.7, 0.05, 0.05) if element == "physical" else DB.ELEMENT_COLORS.get(element, Color.WHITE), 5 if not crit else 10, 50.0, 0.35, 1.5)
	# TELURICO: imune a knockback (MECANICAS #5.2)
	if not is_boss() and knockback > 0 and not has_affix(Affix.TELURICO):
		_knock = from_pos.direction_to(global_position) * knockback * (0.4 if rarity >= Rarity.ELITE else 1.0)
	if state == State.IDLE:
		state = State.CHASE
	# MESTRE-DE-ENXAME: invoca 3 lacaios ao chegar a 50% de HP (uma vez)
	if has_affix(Affix.MESTRE_DE_ENXAME) and not _swarm_done and hp > 0.0 and hp <= max_hp * 0.5:
		_summon_swarm()
	if hp <= 0.0:
		_die()
	return final


func stun(time: float) -> void:
	if is_dead():
		return
	if is_boss():
		time *= 0.3
	_stun_time = maxf(_stun_time, time)
	state = State.STUNNED
	_state_time = 0.0


func apply_slow(amount: float, time: float) -> void:
	_slow_amount = maxf(_slow_amount if _slow_time > 0 else 0.0, amount * (0.5 if is_boss() else 1.0))
	_slow_time = maxf(_slow_time, time)


func confuse(time: float) -> void:
	if is_boss():
		return
	_confuse_time = maxf(_confuse_time, time)


func fear(time: float, from: Vector2) -> void:
	if is_boss():
		return
	_fear_time = maxf(_fear_time, time)
	_fear_from = from


func curse(time: float) -> void:
	_curse_time = maxf(_curse_time, time)


func _die() -> void:
	state = State.DEAD
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	Sfx.play(&"death", -6.0)
	Sfx.play(&"hit_heavy", -4.0)
	Fx.burst(world.fx_layer, hit_center(), Color(0.6, 0.05, 0.05), 18, 80.0, 0.6, 2.5)
	# Maldição: explode ferindo os vizinhos
	if _curse_time > 0.0:
		Fx.explosion(world.fx_layer, global_position, Color(0.6, 1, 0.4), 40.0)
		Sfx.play(&"explode", -6.0)
		for e in world.enemies_near(global_position, 40.0):
			e.take_damage(max_hp * 0.35, false, global_position, 60.0, "shadow", true)
	killed.emit(self)
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector2(visual.scale.x * 1.3, 0.1), 0.25)
	tw.parallel().tween_property(visual, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)


# ------------------------------------------------------------------ AFIXOS (3.2)

## MESTRE-DE-ENXAME: 3 lacaios COMUM (sem afixos, evita recursão)
func _summon_swarm() -> void:
	_swarm_done = true
	FxShape.spawn(world.fx_layer, FxShape.Type.RING, global_position, Color(0.9, 0.7, 1.0), 34.0, 0.5)
	Sfx.play(&"magic", -8.0)
	for i in 3:
		var p := global_position + Vector2.from_angle(TAU * i / 3.0 + randf() * 0.6) * 26.0
		if world.is_solid(p):
			p = global_position
		var m: Enemy = world.spawn_enemy(data, p, Rarity.COMUM, depth)
		if m:
			m.state = State.CHASE


## CAMPEAO-DAS-SOMBRAS: reaparece a ~60px do alvo, em solo livre
func _teleport_to_target() -> void:
	var p := _target.global_position + Vector2.from_angle(randf() * TAU) * 64.0
	if world.is_solid(p):
		p = world.last_free_point(_target.global_position, p)
	Fx.burst(world.fx_layer, hit_center(), Color(0.45, 0.25, 0.9), 12, 70.0, 0.4, 2.0)
	global_position = p
	Fx.burst(world.fx_layer, hit_center(), Color(0.45, 0.25, 0.9), 12, 70.0, 0.4, 2.0)


## FURIOSO: recarga de ataque 30% mais rápida (MECANICAS #5.2)
func _reset_attack_cd(base: float) -> float:
	_attack_cd = base * (0.7 if has_affix(Affix.FURIOSO) else 1.0)
	return _attack_cd


# ------------------------------------------------------------------ IA

func _exit_tree() -> void:
	# 7.4: a calmaria morre com o campeão (#14.5.2)
	if rarity >= Rarity.CAMPEAO:
		WindField.remove_calm(get_instance_id())


func _physics_process(delta: float) -> void:
	if is_dead():
		return
	var tscale := world.time_scale_at(global_position)
	delta *= tscale
	_state_time += delta
	if _aura:
		# 7.3/7.4: pulsa ATRAVESSANDO o threshold do glow (1.0) - a aura
		# de Campeão/Lendário floresce e apaga com a respiração
		_aura.energy = 1.15 + sin(_state_time * 3.2) * 0.3
	# 7.4: a calmaria segue o campeão (#14.5.2)
	if rarity >= Rarity.CAMPEAO:
		WindField.move_calm(get_instance_id(), global_position)
	if _spawn_beam:
		_spawn_beam.modulate.a = 0.65 + sin(_state_time * 3.2) * 0.35
	_attack_cd -= delta
	_repath -= delta
	_hp_bar_visible -= delta
	_slow_time -= delta
	_confuse_time -= delta
	_fear_time -= delta
	_curse_time -= delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	_shader.set_shader_parameter("flash", _flash)
	queue_redraw()

	# 3.2: afixos com pulso contínuo (MECANICAS #5.2) - antes da economia de CPU
	# do "sono", para que os efeitos rodam mesmo longe do jogador (teste/despawn)
	if has_affix(Affix.ESCUDO_ARCANO) and _shield < _shield_max:
		_shield_timer -= delta
		if _shield_timer <= 0.0:
			_shield_timer = 5.0
			_shield = _shield_max
	if has_affix(Affix.ARDENTE):
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_fire_cd = 1.5
			world.add_fire_zone(global_position, 18.0, damage * 0.15, 3.0)
	if has_affix(Affix.CAMPEAO_DAS_SOMBRAS) and state == State.CHASE and _target != null and is_instance_valid(_target):
		_shadow_cd -= delta
		if _shadow_cd <= 0.0:
			_shadow_cd = 6.0
			_teleport_to_target()

	# Inimigos ociosos longe do jogador "dormem" (economiza CPU em hordas grandes)
	if state == State.IDLE and world.player and global_position.distance_squared_to(world.player.global_position) > 360.0 * 360.0:
		if sprite.animation != "idle":
			sprite.play("idle")
		return
	_target = _pick_target()
	var to_target := _target.global_position - global_position if _target else Vector2.ZERO
	var dist := to_target.length()
	var desired := Vector2.ZERO
	var spd_mult := (1.0 - _slow_amount if _slow_time > 0.0 else 1.0) * tscale

	if _fear_time > 0.0 and state != State.STUNNED:
		desired = _fear_from.direction_to(global_position) * speed * 0.9
		if state in [State.WINDUP, State.ATTACK]:
			state = State.CHASE
	else:
		match state:
			State.STUNNED:
				_stun_time -= delta
				sprite.rotation = sin(_state_time * 30.0) * 0.15
				if _stun_time <= 0.0:
					sprite.rotation = 0.0
					state = State.CHASE
			State.IDLE:
				var pl := world.player
				if pl and not pl.is_dead() and pl.global_position.distance_to(global_position) < data.aggro_range * aggro_mult * Game.aggro_mult() and world.has_line_of_sight(global_position, pl.global_position):
					state = State.CHASE
					_alert_pack()
				elif _confuse_time > 0.0 and _target:
					state = State.CHASE
				else:
					desired = _wander()
			State.CHASE:
				if _target == null:
					state = State.IDLE
				else:
					desired = _chase(to_target, dist)
			State.WINDUP:
				_do_windup(to_target)
			State.ATTACK:
				desired = _do_attack()
			State.RECOVER:
				if _state_time > 0.35:
					state = State.CHASE

	_knock = _knock.move_toward(Vector2.ZERO, 500 * delta)
	velocity = desired * spd_mult + _knock + _separation() * 30.0
	move_and_slide()
	if absf(velocity.x) > 2.0 and state != State.WINDUP:
		sprite.flip_h = velocity.x < 0
	var anim := "run" if desired.length() > 1.0 else "idle"
	if sprite.animation != anim:
		sprite.play(anim)
	# Sprites de um quadro só "pulam" ao andar
	if _single_frame:
		var bob := absf(sin(Time.get_ticks_msec() * 0.015 + get_instance_id())) * 1.5 if anim == "run" else 0.0
		sprite.position.y = _sprite_y - bob
	sprite.speed_scale = spd_mult
	if _slow_time > 0.0:
		sprite.modulate = Color(0.7, 0.85, 1.0)
	elif _confuse_time > 0.0:
		sprite.modulate = Color(1.0, 0.7, 1.0)
	else:
		sprite.modulate = Color.WHITE


## Alvo: jogador, aliado mais próximo ou (confuso) outro inimigo
func _pick_target() -> Node2D:
	if _confuse_time > 0.0:
		var best: Node2D
		var bd := INF
		for e in world.enemies_near(global_position, 150.0):
			if e == self:
				continue
			var d := e.global_position.distance_to(global_position)
			if d < bd:
				bd = d
				best = e
		if best:
			return best
	var pl := world.player
	var target: Node2D = pl if pl and not pl.is_dead() else null
	var td := target.global_position.distance_to(global_position) if target else INF
	for m in world.minions_near(global_position, 120.0):
		var d: float = m.global_position.distance_to(global_position)
		if d < td * 0.8 or (m.taunts and d < 120.0):
			target = m
			td = d
	return target


func _hit_target(t: Node2D, dmg: float) -> void:
	if not is_instance_valid(t):
		return
	if t is Enemy:
		(t as Enemy).take_damage(dmg, false, global_position, 40.0, data.element)
	elif t.has_method("take_damage"):
		t.take_damage(dmg, global_position, data.element, self)
		# VENENOSO: o golpe aplica veneno (não em outros inimigos; MECANICAS #5.2)
		if has_affix(Affix.VENENOSO) and t.has_method("apply_poison"):
			t.apply_poison(dmg * 0.25, 3.0)


func _chase(to_target: Vector2, dist: float) -> Vector2:
	var b := data.behavior
	var los := world.has_line_of_sight(global_position, _target.global_position)
	match b:
		EnemyData.Behavior.RANGED:
			if los and dist < data.attack_range and _attack_cd <= 0.0:
				_begin_windup()
				return Vector2.ZERO
			if los and dist < data.attack_range * 0.55:
				return -to_target.normalized() * speed * 0.8
			if los and dist < data.attack_range * 0.9:
				return to_target.orthogonal().normalized() * speed * 0.4 * (1 if get_instance_id() % 2 == 0 else -1)
		EnemyData.Behavior.CHARGER:
			if los and dist < 90.0 and dist > 20.0 and _attack_cd <= 0.0:
				_begin_windup()
				return Vector2.ZERO
			if dist < data.attack_range + 6.0 and _attack_cd <= 0.0:
				_begin_windup()
				return Vector2.ZERO
		EnemyData.Behavior.BOSS:
			if _attack_cd <= 0.0 and dist < 140.0 and los:
				_begin_windup()
				return Vector2.ZERO
		_:
			if dist < data.attack_range + 6.0 * visual.scale.x and _attack_cd <= 0.0:
				_begin_windup()
				return Vector2.ZERO
	if dist < data.attack_range * 0.7 and b != EnemyData.Behavior.RANGED:
		return Vector2.ZERO
	return _move_towards(_target.global_position, los) * speed


func _move_towards(target: Vector2, los: bool) -> Vector2:
	if los:
		_path.clear()
		return global_position.direction_to(target)
	if _repath <= 0.0 or _path.is_empty():
		_repath = 0.6 + randf() * 0.3
		_path = world.find_path(global_position, target)
	while not _path.is_empty() and global_position.distance_to(_path[0]) < 4.0:
		_path.remove_at(0)
	if _path.is_empty():
		return Vector2.ZERO
	return global_position.direction_to(_path[0])


func _wander() -> Vector2:
	if _wander_target == Vector2.ZERO or global_position.distance_to(_wander_target) < 4.0 or _state_time > 4.0:
		_state_time = 0.0
		var p := _home + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		_wander_target = p if not world.is_solid(p) else _home
	if _state_time < 1.5:
		return Vector2.ZERO
	return global_position.direction_to(_wander_target) * speed * 0.3


func _alert_pack() -> void:
	for e in world.enemies_near(global_position, 80.0):
		if e.state == State.IDLE:
			e.state = State.CHASE


func _separation() -> Vector2:
	var push := Vector2.ZERO
	for e in world.enemies_near(global_position, 12.0):
		if e == self:
			continue
		var d := global_position - e.global_position
		var l := d.length()
		if l < 0.01:
			d = Vector2.from_angle(randf() * TAU)
			l = 0.01
		push += d / l * (1.0 - l / 12.0)
	return push


func _begin_windup() -> void:
	state = State.WINDUP
	_state_time = 0.0
	_did_hit = false
	_telegraph_target = _target.global_position
	_charge_dir = global_position.direction_to(_target.global_position)
	if is_boss():
		_boss_phase = (_boss_phase + 1) % 3
		if hp < max_hp * 0.5 and randf() < 0.5:
			_boss_phase = 1
		if _boss_phase == 0:
			FxShape.spawn(world.fx_layer, FxShape.Type.TELEGRAPH, _telegraph_target, Color(1, 0.3, 0.1), 46.0, _windup_time())
	var tw := create_tween()
	tw.tween_property(visual, "scale", visual.scale * Vector2(0.85, 1.15), _windup_time() * 0.8)
	tw.tween_property(visual, "scale", visual.scale, 0.1)


func _windup_time() -> float:
	match data.behavior:
		EnemyData.Behavior.SWARM: return 0.25
		EnemyData.Behavior.CHARGER: return 0.5
		EnemyData.Behavior.RANGED: return 0.55
		EnemyData.Behavior.BOSS: return 0.8
	return 0.4


func _do_windup(to_target: Vector2) -> void:
	_flash = 0.35 * absf(sin(_state_time * 20.0))
	_shader.set_shader_parameter("flash_color", Color(1, 0.3, 0.2))
	if data.behavior == EnemyData.Behavior.CHARGER and _target:
		_charge_dir = to_target.normalized()
	if _state_time >= _windup_time():
		_shader.set_shader_parameter("flash_color", Color(1, 1, 1))
		state = State.ATTACK
		_state_time = 0.0
		_execute_attack(to_target)


func _execute_attack(to_target: Vector2) -> void:
	if _target == null or not is_instance_valid(_target):
		state = State.RECOVER
		return
	var hostile_to_player := not (_target is Enemy)
	match data.behavior:
		EnemyData.Behavior.RANGED:
			var dmg := damage
			var elem := data.element
			var me: Enemy = self
			var pr := Projectile.fire(world, hit_center(), to_target, 150.0, data.projectile_color, true, func(t, _p):
				if is_instance_valid(me):
					me._hit_target(t, dmg)
				elif t.has_method("take_damage") and not t is Enemy:
					t.take_damage(dmg, Vector2.INF, elem, null)
			)
			pr.max_distance = data.attack_range * 1.4
			pr.hits_minions = true
			pr.hits_enemies = not hostile_to_player
			Sfx.play(&"magic", -12.0)
			_reset_attack_cd(data.attack_cooldown)
		EnemyData.Behavior.CHARGER:
			Sfx.play(&"cloth", -8.0)
			_reset_attack_cd(data.attack_cooldown + 1.0)
		EnemyData.Behavior.BOSS:
			match _boss_phase:
				0:
					Fx.explosion(world.fx_layer, _telegraph_target, Color(1, 0.4, 0.1), 46.0)
					Sfx.play(&"explode")
					world.shake(6.0)
					if world.player.global_position.distance_to(_telegraph_target) < 46.0:
						world.player.take_damage(damage * 1.5, global_position, data.element, self)
					for m in world.minions_near(_telegraph_target, 46.0):
						m.take_damage(damage * 1.5, global_position, data.element, self)
				1:
					var dmg := damage * 0.7
					var elem := data.element
					var n := 14
					for i in n:
						var d := Vector2.from_angle(i * TAU / n + randf() * 0.2)
						var pr := Projectile.fire(world, hit_center(), d, 110.0, data.projectile_color, true, func(t, _p):
							t.take_damage(dmg, Vector2.INF, elem, null)
						)
						pr.max_distance = 260.0
						pr.hits_minions = true
					Sfx.play(&"magic", -4.0)
				2:
					Sfx.play(&"hit_heavy", -4.0)
			_reset_attack_cd(data.attack_cooldown + (0.8 if _boss_phase != 2 else 0.0))
		_:
			Sfx.play(&"chop", -10.0)
			if _target.global_position.distance_to(global_position) < data.attack_range + 10.0 * visual.scale.x:
				_hit_target(_target, damage)
			FxShape.spawn(world.fx_layer, FxShape.Type.ARC, hit_center(), Color(1, 0.4, 0.3), 14.0 * visual.scale.x, 0.18, to_target.normalized(), 90.0)
			_reset_attack_cd(data.attack_cooldown)


func _do_attack() -> Vector2:
	var is_charge := data.behavior == EnemyData.Behavior.CHARGER or (is_boss() and _boss_phase == 2)
	if is_charge:
		var t := 0.45 if not is_boss() else 0.7
		if not _did_hit and _target and is_instance_valid(_target) and _target.global_position.distance_to(global_position) < 10.0 * visual.scale.x + 6.0:
			_did_hit = true
			_hit_target(_target, damage * (1.3 if is_boss() else 1.0))
		if _state_time > t:
			state = State.RECOVER
			_state_time = 0.0
		return _charge_dir * speed * 3.2
	state = State.RECOVER
	_state_time = 0.0
	return Vector2.ZERO


func _draw() -> void:
	var r := body_radius()
	draw_set_transform(Vector2(0, -0.5), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	if _curse_time > 0.0:
		draw_arc(Vector2(0, -1), r + 2.0, 0, TAU, 20, Color(0.5, 1, 0.3, 0.7), 1.0)
	# Barra de vida sobre elites/danificados
	var always: bool = Game.settings.always_show_health
	if (rarity >= Rarity.ELITE or always or _hp_bar_visible > 0.0) and not is_boss() and not is_dead():
		var w := 16.0 * visual.scale.x
		var y := -(_frame_h + 4.0) * visual.scale.y
		draw_rect(Rect2(-w * 0.5 - 1, y - 1, w + 2, 4), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0, 1), 2),
			Color(0.85, 0.1, 0.1) if rarity == Rarity.COMUM else RARITY_COLORS[rarity])
	if _confuse_time > 0.0 or _fear_time > 0.0 or state == State.STUNNED:
		var y2 := -(_frame_h + 9.0) * visual.scale.y
		var t := Time.get_ticks_msec() * 0.006
		for i in 3:
			var a := t + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 5.0, y2 + sin(a) * 1.5), 1.0, Color(1, 1, 0.4) if state == State.STUNNED else (Color(1, 0.5, 1) if _confuse_time > 0 else Color(0.6, 0.6, 1)))
