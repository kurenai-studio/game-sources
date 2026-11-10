class_name Projectile
extends Node2D
## Projétil do jogador ou de inimigos. Colisão feita por distância (barato para hordas).

var velocity := Vector2.ZERO
var max_distance := 260.0
var hostile := false             ## true = atinge o jogador
var hits_minions := false        ## projéteis hostis também atingem aliados invocados
var hits_enemies := false        ## projétil hostil de inimigo confuso atinge outros inimigos
var color := Color.WHITE
var sprite_name := ""
## 7.4: massa 0-1 - flecha leve desvia mais (#14.5.4); projéteis mágicos
## (sem sprite) só sentem o vento se marcados wind_affected
var wind_mass := 0.8
var wind_affected := false
var pierce := 0
var explode_radius := 0.0
var hit_radius := 6.0
## Callable(target, projectile) chamado ao acertar
var on_hit: Callable
var _travelled := 0.0
var _hit: Dictionary = {}
var _world: World
var _trail: Array[Vector2] = []


static func fire(world: World, from: Vector2, dir: Vector2, speed: float, p_color: Color, p_hostile: bool, hit_cb: Callable, p_sprite := "") -> Projectile:
	var p := Projectile.new()
	p._world = world
	p.position = from
	p.velocity = dir.normalized() * speed
	p.color = p_color
	p.hostile = p_hostile
	p.on_hit = hit_cb
	p.sprite_name = p_sprite
	p.z_index = 4
	world.fx_layer.add_child(p)
	return p


func _ready() -> void:
	rotation = velocity.angle()
	if sprite_name != "":
		var s := Sprite2D.new()
		s.texture = DB.dt2_texture(sprite_name)
		# Sprites de armas estão na vertical (ponta para cima)
		s.rotation = PI / 2.0
		s.scale = Vector2.ONE * 0.8
		add_child(s)
	var l := Fx.make_light(color, 0.35, 0.8)
	add_child(l)


func _physics_process(delta: float) -> void:
	# Dobra Temporal desacelera projéteis inimigos
	var step := velocity * delta * (_world.time_scale_at(global_position) if hostile else 1.0)
	# 7.4: o vento desvia projéteis físicos (#14.5.4) - mágicos só se marcados;
	# "Ler o Vento" (Caçador) faz as flechas do herói voarem retas (#14.5.5)
	if sprite_name != "" or wind_affected:
		var straight := false
		if not hostile and _world.player != null:
			for b in _world.player.buffs.values():
				if b.stat == "wind_reader":
					straight = true
					break
		if not straight:
			var w := WindField.at(global_position)
			velocity += w * 90.0 * (1.5 - wind_mass) * delta
	rotation = velocity.angle()
	position += step
	_travelled += step.length()
	_trail.push_front(Vector2.ZERO)
	if _trail.size() > 6:
		_trail.pop_back()
	queue_redraw()
	if _world.is_solid(global_position):
		_impact(null)
		return
	if _travelled >= max_distance:
		if explode_radius > 0:
			_impact(null)
		else:
			queue_free()
		return
	if hostile:
		var pl := _world.player
		var body_r := 5.0 * (pl.hero.race.body_scale if pl else 1.0)
		if pl and not pl.is_dead() and pl.global_position.distance_to(global_position + Vector2(0, 4)) < hit_radius + body_r:
			_impact(pl)
			return
		if hits_minions:
			for m in _world.minions_near(global_position, hit_radius + 8.0):
				_impact(m)
				return
		if hits_enemies:
			for e in _world.enemies_near(global_position, hit_radius + 8.0):
				if e.hit_center().distance_to(global_position) < hit_radius + e.body_radius():
					_impact(e)
					return
	else:
		for e in _world.enemies_near(global_position, hit_radius + 16.0):
			if _hit.has(e):
				continue
			if e.hit_center().distance_to(global_position) < hit_radius + e.body_radius():
				_hit[e] = true
				if explode_radius > 0:
					_impact(e)
					return
				on_hit.call(e, self)
				if pierce <= 0:
					_impact(null, false)
					return
				pierce -= 1


func _impact(target: Node2D, call_hit := true) -> void:
	if explode_radius > 0:
		Fx.explosion(_world.fx_layer, global_position, color, explode_radius)
		Sfx.play(&"explode", -4.0)
		_world.shake(2.0)
		if not hostile:
			for e in _world.enemies_near(global_position, explode_radius):
				on_hit.call(e, self)
	elif call_hit and target:
		on_hit.call(target, self)
	else:
		Fx.burst(_world.fx_layer, global_position, color, 5, 40.0, 0.3)
	queue_free()


func _draw() -> void:
	if sprite_name != "":
		return
	for i in _trail.size():
		var k := 1.0 - float(i) / _trail.size()
		draw_circle(Vector2(-i * 3.0, 0), 3.5 * k, Color(color, 0.35 * k))
	draw_circle(Vector2.ZERO, 4.0, Color(color, 0.5))
	draw_circle(Vector2.ZERO, 2.5, color.lightened(0.5))
