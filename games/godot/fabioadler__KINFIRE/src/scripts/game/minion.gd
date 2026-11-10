class_name Minion
extends CharacterBody2D
## Aliado invocado (esqueletos, lobo, golem, diabrete). Segue o dono e ataca inimigos próximos.

var world: World
var owner_player: Player
var skill: SkillData
var sprite_base := "skelet"
var hp := 30.0
var max_hp := 30.0
var damage_mult := 0.4
## Golem provoca: inimigos preferem atacá-lo
var taunts := false
var _sprite: AnimatedSprite2D
var _target: Enemy
var _attack_cd := 0.0
var _flash := 0.0
var _frame_h := 16.0
var _repath := 0.0
var _path := PackedVector2Array()


static func spawn(w: World, p: Player, s: SkillData, pos: Vector2) -> Minion:
	var m := Minion.new()
	m.world = w
	m.owner_player = p
	m.skill = s
	m.sprite_base = s.summon_sprite
	m.max_hp = p.max_hp * s.summon_hp_mult
	m.hp = m.max_hp
	m.damage_mult = 0.35 * maxf(s.summon_hp_mult, 0.6)
	m.taunts = s.summon_hp_mult >= 2.5
	m.position = pos
	w.entities.add_child(m)
	return m


func _ready() -> void:
	add_to_group("minions")
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	cs.shape = circle
	cs.position = Vector2(0, -2)
	add_child(cs)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = DB.frames(sprite_base)
	var fs := DB.frame_size(sprite_base)
	_frame_h = fs.y
	var sc := minf(1.0, 30.0 / fs.y)
	_sprite.scale = Vector2.ONE * sc
	_sprite.position = Vector2(0, -(fs.y + 2) * 0.5 * sc + 1)
	_sprite.modulate = Color(0.75, 1.0, 0.85)
	_sprite.play("idle")
	add_child(_sprite)
	_frame_h *= sc
	Fx.burst(world.fx_layer, global_position + Vector2(0, -6), Color(0.5, 1, 0.6), 14, 40.0, 0.6)


func is_dead() -> bool:
	return hp <= 0.0


func take_damage(amount: float, _from_pos: Vector2 = Vector2.INF, _element := "physical", _attacker: Node2D = null) -> void:
	if is_dead():
		return
	hp -= amount * 0.7
	_flash = 1.0
	if hp <= 0.0:
		Fx.burst(world.fx_layer, global_position + Vector2(0, -6), Color(0.6, 0.9, 0.7), 14, 50.0, 0.5)
		queue_free()


func _physics_process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return
	_attack_cd -= delta
	_repath -= delta
	_flash = maxf(_flash - delta * 5.0, 0.0)
	_sprite.self_modulate = Color(1, 0.5, 0.5) if _flash > 0.1 else Color.WHITE
	queue_redraw()
	if _target == null or not is_instance_valid(_target) or _target.is_dead() or _target.global_position.distance_to(owner_player.global_position) > 180.0:
		_target = _find_target()
	var desired := Vector2.ZERO
	if _target:
		var d := global_position.distance_to(_target.global_position)
		if d > 14.0:
			desired = _dir_to(_target.global_position) * 85.0
		elif _attack_cd <= 0.0:
			_attack_cd = 0.9
			var roll := owner_player.hero.roll_damage(damage_mult)
			_target.take_damage(roll[0], roll[1], global_position, 30.0, "physical")
			Sfx.play(&"chop", -14.0)
			var tw := create_tween()
			tw.tween_property(_sprite, "scale", _sprite.scale * Vector2(1.2, 0.85), 0.08)
			tw.tween_property(_sprite, "scale", _sprite.scale, 0.12)
	else:
		var home := owner_player.global_position + Vector2(-18 if get_instance_id() % 2 == 0 else 18, 8)
		if global_position.distance_to(home) > 10.0:
			desired = _dir_to(home) * 80.0
		if global_position.distance_to(owner_player.global_position) > 300.0:
			global_position = owner_player.global_position
	velocity = desired
	move_and_slide()
	if absf(velocity.x) > 2.0:
		_sprite.flip_h = velocity.x < 0
	var anim := "run" if desired.length() > 1.0 else "idle"
	if _sprite.animation != anim:
		_sprite.play(anim)


func _dir_to(p: Vector2) -> Vector2:
	if world.has_line_of_sight(global_position, p):
		return global_position.direction_to(p)
	if _repath <= 0.0 or _path.is_empty():
		_repath = 0.5
		_path = world.find_path(global_position, p)
	while not _path.is_empty() and global_position.distance_to(_path[0]) < 4.0:
		_path.remove_at(0)
	return global_position.direction_to(_path[0]) if not _path.is_empty() else Vector2.ZERO


func _find_target() -> Enemy:
	var best: Enemy
	var bd := INF
	for e in world.enemies_near(global_position, 140.0):
		var d := e.global_position.distance_to(global_position)
		if d < bd:
			bd = d
			best = e
	return best


func _draw() -> void:
	draw_set_transform(Vector2(0, -0.5), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	var w := 14.0
	var y := -_frame_h - 4.0
	draw_rect(Rect2(-w * 0.5 - 1, y - 1, w + 2, 3), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0, 1), 1.5), Color(0.3, 0.9, 0.4))
