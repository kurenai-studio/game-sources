class_name SkillExecutor
extends RefCounted
## Executa o efeito de uma SkillData (fase de "Impacto" do ataque).

## Aplica bônus da árvore de habilidades na skill (modifica a skill temporariamente)
static func _apply_tree_bonuses(skill: SkillData, hero: Hero) -> SkillData:
	var bonus := hero.get_tree_bonus_for_skill(skill.id)
	if bonus.is_empty():
		return skill
	
	# Cria uma cópia da skill para não modificar o original
	var modified := skill.duplicate()
	
	# Aplica multiplicadores
	if bonus.has("damage"):
		modified.damage_mult *= (1.0 + bonus["damage"])
	if bonus.has("cooldown"):
		# Cooldown é aplicado no momento do cast (Player.gd), não aqui
		pass
	if bonus.has("projectile_count"):
		modified.projectile_count += roundi(bonus["projectile_count"])
	if bonus.has("radius"):
		modified.radius *= (1.0 + bonus["radius"])
	if bonus.has("reach"):
		modified.reach *= (1.0 + bonus["reach"])
	if bonus.has("heal"):
		modified.heal_percent *= (1.0 + bonus["heal"])
	if bonus.has("duration"):
		modified.duration += bonus["duration"]
	if bonus.has("resource_gain"):
		modified.generate += bonus["resource_gain"]
	if bonus.has("hits"):
		modified.hits += roundi(bonus["hits"])
	
	return modified


static func execute(skill: SkillData, player: Player, target_pos: Vector2, hero: Hero = null) -> void:
	# Aplica bônus da árvore de habilidades
	if hero:
		skill = _apply_tree_bonuses(skill, hero)
	
	var world := player.world
	var origin := player.global_position + Vector2(0, -5)
	var dir := (target_pos - origin).normalized()
	if dir == Vector2.ZERO:
		dir = player.facing
	var gen_state: Dictionary = {"done": false}
	var hit_cb := func(enemy: Enemy, _src: Variant) -> void:
		if skill.damage_mult > 0.0:
			player.deal_damage(enemy, skill.damage_mult, skill)
		else:
			_apply_status(enemy, skill, player)
		if not gen_state.done and skill.generate > 0:
			gen_state.done = true
			player.gain_resource(skill.generate)

	Sfx.play(skill.sound, -3.0)
	match skill.kind:
		SkillData.Kind.MELEE_ARC:
			FxShape.spawn(world.fx_layer, FxShape.Type.ARC, origin, skill.color, skill.reach, 0.22, dir, skill.arc_degrees)
			var any := false
			for e in _in_cone(world, origin, dir, skill.reach, skill.arc_degrees):
				hit_cb.call(e, null)
				if skill.stun > 0:
					e.stun(skill.stun)
				any = true
			if any:
				Sfx.play(&"hit", -2.0)
				if skill.damage_mult >= 2.5:
					world.shake(3.0)

		SkillData.Kind.CONE:
			for i in 5:
				var a := deg_to_rad(lerpf(-skill.arc_degrees * 0.5, skill.arc_degrees * 0.5, i / 4.0))
				Fx.burst(world.fx_layer, origin + dir.rotated(a) * skill.radius * 0.6, skill.color, 8, 60.0, 0.4, 2.0)
			FxShape.spawn(world.fx_layer, FxShape.Type.ARC, origin, skill.color, skill.radius, 0.3, dir, skill.arc_degrees)
			world.shake(2.5)
			for e in _in_cone(world, origin, dir, skill.radius, skill.arc_degrees):
				hit_cb.call(e, null)

		SkillData.Kind.PROJECTILE:
			var n := maxi(skill.projectile_count, 1)
			for i in n:
				var ang := 0.0
				if n > 1:
					ang = deg_to_rad(lerpf(-skill.spread_degrees * 0.5, skill.spread_degrees * 0.5, float(i) / (n - 1)))
				var p := Projectile.fire(world, origin + dir * 6.0, dir.rotated(ang), skill.projectile_speed, skill.color, false, hit_cb, skill.projectile_sprite)
				p.max_distance = skill.reach
				p.pierce = skill.pierce
				p.explode_radius = skill.explode_radius
				if skill.pierce >= 99 and skill.projectile_speed < 200:
					p.hit_radius = 10.0

		SkillData.Kind.BEAM:
			var end := world.last_free_point(origin, origin + dir * skill.reach)
			FxShape.spawn_beam(world.fx_layer, origin, end, skill.color, maxf(skill.radius, 4.0), 0.3)
			for e in world.enemies_near((origin + end) * 0.5, origin.distance_to(end) * 0.5 + 12.0):
				if Geometry2D.get_closest_point_to_segment(e.hit_center(), origin, end).distance_to(e.hit_center()) <= skill.radius + e.body_radius():
					hit_cb.call(e, null)

		SkillData.Kind.CHAIN:
			var from := origin
			var hit: Dictionary = {}
			var current: Enemy = world.get_enemy_at(target_pos)
			if current == null:
				current = _nearest(world, target_pos, skill.reach, hit)
			for i in maxi(skill.hits, 1):
				if current == null or from.distance_to(current.hit_center()) > skill.reach:
					break
				hit[current] = true
				FxShape.spawn_beam(world.fx_layer, from, current.hit_center(), skill.color, 3.0, 0.25, true)
				hit_cb.call(current, null)
				from = current.hit_center()
				current = _nearest(world, from, skill.radius, hit)
				await player.get_tree().create_timer(0.05, false).timeout
				if not is_instance_valid(player):
					return

		SkillData.Kind.AOE_SELF:
			if skill.hits <= 1:
				Fx.explosion(world.fx_layer, player.global_position, skill.color, skill.radius)
				world.shake(3.0)
				for e in world.enemies_near(player.global_position, skill.radius):
					hit_cb.call(e, null)
					if skill.stun > 0:
						e.stun(skill.stun)
			else:
				var fx := FxShape.spawn(world.fx_layer, FxShape.Type.DISC, player.global_position, skill.color, skill.radius, skill.duration)
				fx.follow = player
				_repeat_hits(player, skill, hit_cb)

		SkillData.Kind.AOE_TARGET:
			var pos := _clamp_target(player, target_pos, skill.reach)
			FxShape.spawn(world.fx_layer, FxShape.Type.TELEGRAPH, pos, skill.color, skill.radius, maxf(skill.delay, 0.05))
			if skill.delay > 0:
				await player.get_tree().create_timer(skill.delay, false).timeout
			if not is_instance_valid(player):
				return
			FxShape.spawn(world.fx_layer, FxShape.Type.PILLAR, pos, skill.color, skill.radius, 0.45)
			Fx.explosion(world.fx_layer, pos, skill.color, skill.radius)
			Sfx.play(&"explode", 0.0)
			world.shake(5.0 if skill.damage_mult >= 3.0 else 2.0)
			for e in world.enemies_near(pos, skill.radius):
				hit_cb.call(e, null)
				if skill.stun > 0:
					e.stun(skill.stun)

		SkillData.Kind.SUMMON_RAIN:
			var center := _clamp_target(player, target_pos, skill.reach)
			FxShape.spawn(world.fx_layer, FxShape.Type.TELEGRAPH, center, skill.color, skill.radius, skill.duration)
			var interval := skill.duration / maxf(skill.hits, 1)
			for i in skill.hits:
				if not is_instance_valid(player):
					return
				var p := center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * skill.radius
				FxShape.spawn(world.fx_layer, FxShape.Type.PILLAR, p, skill.color, 12.0, 0.25)
				Fx.burst(world.fx_layer, p, skill.color, 6, 50.0, 0.3)
				for e in world.enemies_near(p, 20.0):
					player.deal_damage(e, skill.damage_mult, skill)
					if skill.stun > 0:
						e.stun(skill.stun)
				if i % 3 == 0:
					Sfx.play(skill.sound, -10.0)
				await player.get_tree().create_timer(interval, false).timeout

		SkillData.Kind.DASH, SkillData.Kind.LEAP:
			var dest := _clamp_target(player, target_pos, skill.reach)
			dest = world.last_free_point(player.global_position, dest)
			var from := player.global_position
			if skill.kind == SkillData.Kind.DASH and skill.damage_mult <= 0.0:
				Fx.burst(world.fx_layer, from, skill.color, 14, 50.0)
				player.global_position = dest
				Fx.burst(world.fx_layer, dest, skill.color, 14, 50.0)
				FxShape.spawn(world.fx_layer, FxShape.Type.RING, dest, skill.color, 24.0, 0.3)
			elif skill.kind == SkillData.Kind.LEAP:
				player.start_dash(dest, 0.35)
				var tw := player.create_tween()
				tw.tween_property(player.visual, "position:y", -18.0, 0.17).set_ease(Tween.EASE_OUT)
				tw.tween_property(player.visual, "position:y", 0.0, 0.17).set_ease(Tween.EASE_IN)
				await player.get_tree().create_timer(0.35, false).timeout
				if not is_instance_valid(player):
					return
				Fx.explosion(world.fx_layer, dest, skill.color, skill.radius)
				Sfx.play(&"explode")
				world.shake(5.0)
				for e in world.enemies_near(dest, skill.radius):
					hit_cb.call(e, null)
					if skill.stun > 0:
						e.stun(skill.stun)
			else:
				player.start_dash(dest, 0.16)
				for e in world.enemies_near((from + dest) * 0.5, from.distance_to(dest) * 0.5 + skill.radius):
					if Geometry2D.get_closest_point_to_segment(e.hit_center(), from, dest).distance_to(e.hit_center()) <= skill.radius + e.body_radius():
						hit_cb.call(e, null)
				for i in 6:
					Fx.burst(world.fx_layer, from.lerp(dest, i / 6.0), skill.color, 3, 20.0, 0.3)

		SkillData.Kind.HEAL:
			player.heal(player.max_hp * skill.heal_percent)
			FxShape.spawn(world.fx_layer, FxShape.Type.RING, player.global_position, skill.color, 30.0, 0.5)
			Fx.burst(world.fx_layer, player.global_position, skill.color, 20, 40.0, 0.8)

		SkillData.Kind.BUFF:
			player.add_buff(skill.buff_stat, skill.buff_amount, skill.duration, skill.display_name, skill.color, skill.buff_stat_2, skill.buff_amount_2)
			FxShape.spawn(world.fx_layer, FxShape.Type.RING, player.global_position, skill.color, 36.0, 0.5)
			Fx.burst(world.fx_layer, player.global_position, skill.color, 16, 50.0, 0.6)

		SkillData.Kind.SHAPESHIFT:
			player.add_buff(skill.buff_stat, skill.buff_amount, skill.duration, skill.display_name, skill.color, skill.buff_stat_2, skill.buff_amount_2, skill.summon_sprite)
			FxShape.spawn(world.fx_layer, FxShape.Type.RING, player.global_position, skill.color, 30.0, 0.5)

		SkillData.Kind.SUMMON:
			var mine := player.minions.filter(func(m): return m.sprite_base == skill.summon_sprite)
			for i in skill.summon_count:
				if mine.size() >= skill.summon_max:
					var oldest: Node2D = mine.pop_front()
					oldest.queue_free()
				var p := world.last_free_point(player.global_position, player.global_position + Vector2.from_angle(randf() * TAU) * 18.0)
				var m := Minion.spawn(world, player, skill, p)
				player.minions.append(m)
				mine.append(m)

		SkillData.Kind.SLOW_ZONE:
			var pos := _clamp_target(player, target_pos, skill.reach)
			world.add_slow_zone(pos, skill.radius, skill.slow, skill.duration)
			var fx := FxShape.spawn(world.fx_layer, FxShape.Type.DISC, pos, skill.color, skill.radius, skill.duration)
			fx.z_index = -1


static func _apply_status(e: Enemy, skill: SkillData, player: Player) -> void:
	if skill.fear > 0:
		e.fear(skill.fear, player.global_position)
	if skill.confuse > 0:
		e.confuse(skill.confuse)
	if skill.slow > 0:
		e.apply_slow(skill.slow, maxf(skill.duration, 2.0))
	if skill.curse:
		e.curse(maxf(skill.duration, 6.0))


static func _in_cone(world: World, origin: Vector2, dir: Vector2, reach: float, arc: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for e in world.enemies_near(origin, reach + 14.0):
		var to: Vector2 = e.hit_center() - origin
		if to.length() > reach + e.body_radius():
			continue
		if to.length() > 6.0 and absf(rad_to_deg(dir.angle_to(to))) > arc * 0.5 + 10.0:
			continue
		out.append(e)
	return out


static func _nearest(world: World, pos: Vector2, r: float, exclude: Dictionary) -> Enemy:
	var best: Enemy
	var bd := INF
	for e in world.enemies_near(pos, r):
		if exclude.has(e):
			continue
		var d := e.global_position.distance_to(pos)
		if d < bd:
			bd = d
			best = e
	return best


static func _repeat_hits(player: Player, skill: SkillData, hit_cb: Callable) -> void:
	var interval := skill.duration / maxf(skill.hits, 1)
	for i in skill.hits:
		if not is_instance_valid(player) or player.is_dead():
			return
		for e in player.world.enemies_near(player.global_position, skill.radius):
			hit_cb.call(e, null)
			if skill.stun > 0:
				e.stun(skill.stun)
		if i % 2 == 0:
			Sfx.play(skill.sound, -10.0)
		await player.get_tree().create_timer(interval, false).timeout


static func _clamp_target(player: Player, target: Vector2, max_dist: float) -> Vector2:
	var from := player.global_position
	var to := target - from
	if to.length() > max_dist:
		to = to.normalized() * max_dist
	return from + to
