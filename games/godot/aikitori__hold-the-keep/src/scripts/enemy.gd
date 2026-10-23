class_name Enemy
extends Node3D
## Ein Gegner: läuft Abschnitt für Abschnitt über die Kontrollpunkte zur Burg und sucht sich einen neuen
## Weg, wenn gebaut wird. Fliegende Gegner folgen der festen Flugroute über alles hinweg.

const GROUND := 0.2

var kind: StringName
var max_hp := 1.0
var hp := 1.0
var speed := 1.0
var gold := 1
var is_boss := false
var air := false
var alive := true
## Restweg bis zur Burg in Feldern (für die Zielwahl der Türme).
var distance_left := 0.0
var game: Node
var board: Board
var leg := 0
var _path: Array[Vector2i] = []
var _next := 0
var _slow := 0.0
var _slow_time := 0.0
var _burn := 0.0
var _burn_time := 0.0
var _lift := 0.0
var _anim: Figure
var _bob := randf() * TAU
var _fire: Node3D
var _armor := 0.0
var _regen := 0.0


func setup(enemy_kind: StringName, wave: int, main: Node, field: Board) -> void:
	kind = enemy_kind
	game = main
	board = field
	var def: Dictionary = Defs.ENEMIES[kind]
	max_hp = def["hp"] * Defs.health_factor(wave)
	hp = max_hp
	speed = def["speed"]
	gold = def["gold"] + wave / 6
	is_boss = def.get("boss", false)
	air = def.get("air", false)
	_lift = def["lift"]
	_anim = Figure.create(def["model"])
	var size: float = def.get("size", 1.0) * 1.15
	_anim.scale = Vector3(size, size, size)
	add_child(_anim)
	if def.has("tint"):
		# Varianten derselben Figur: Farbe darübermultiplizieren, die Textur bleibt erkennbar.
		var overlay := StandardMaterial3D.new()
		overlay.albedo_color = def["tint"]
		overlay.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for mesh: MeshInstance3D in _anim.find_children("*", "MeshInstance3D", true, false):
			mesh.material_overlay = overlay
	_armor = def.get("armor", 0.0)
	_regen = def.get("regen", 0.0)
	_anim.speed_scale = speed * 1.4
	_anim.play("walk")
	if air:
		var shadow := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.25
		disc.bottom_radius = 0.25
		disc.height = 0.01
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0, 0, 0, 0.3)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		disc.material = material
		shadow.mesh = disc
		shadow.position.y = -_lift + 0.02
		add_child(shadow)
	position = Board.world_of(board.map.spawn, GROUND + _lift)
	repath()


func current_cell() -> Vector2i:
	return Board.cell_of(position)


## Ziel des aktuellen Abschnitts (Kontrollpunkt oder Burg).
func goal() -> Vector2i:
	return board.map.waypoints[mini(leg, board.map.waypoints.size() - 1)]


## Neuen Weg ab der aktuellen Zelle (nach jedem Bau und nach jedem Kontrollpunkt).
func repath() -> void:
	if air:
		if not _path.is_empty() and _next < _path.size():
			return  # Bauen ändert die Flugroute nicht
		_path.assign(board.flight_legs[leg])
	else:
		_path = board.path_between(current_cell(), goal())
	_next = 1 if _path.size() > 1 else 0
	_update_distance()


func _update_distance() -> void:
	var rest := 0.0
	if _next < _path.size():
		rest = Vector2(_path[_next].x - position.x, _path[_next].y - position.z).length()
		rest += Board.path_length(_path.slice(_next))
	distance_left = rest + (board.flight_remaining_after(leg) if air else board.remaining_after(leg))


## pierce: Magie und Feuer gehen durch die Rüstung.
func take_damage(amount: float, pierce := false) -> void:
	if not alive:
		return
	if _armor > 0.0 and not pierce:
		amount = maxf(amount * 0.25, amount - _armor)
	hp -= amount
	if hp <= 0.0:
		_die()


func apply_slow(factor: float, seconds: float) -> void:
	_slow = maxf(_slow, factor)
	_slow_time = maxf(_slow_time, seconds)


func apply_burn(per_second: float, seconds: float) -> void:
	_burn = maxf(_burn, per_second)
	_burn_time = maxf(_burn_time, seconds)
	if _fire == null:
		_fire = Projectile._orb(0.12, Color(1.0, 0.45, 0.1))
		_fire.position.y = 0.5
		add_child(_fire)


func _die() -> void:
	alive = false
	game.enemy_killed(self)
	Sfx.play_at(&"boss_die" if is_boss else &"bones" if kind in [&"skeleton", &"swarm"] else &"ghost" if air else &"die", position)
	_anim.speed_scale = 1.0
	_anim.play("die")
	var tween := create_tween()
	tween.tween_interval(0.7)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	if not alive:
		return
	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow = 0.0
	if _burn_time > 0.0:
		_burn_time -= delta
		take_damage(_burn * delta, true)
		if _burn_time <= 0.0 and _fire != null:
			_fire.queue_free()
			_fire = null
		if not alive:
			return
	if _regen > 0.0 and _burn_time <= 0.0:
		hp = minf(max_hp, hp + max_hp * _regen * delta)
	var height := GROUND + _lift
	var step := speed * (1.0 - _slow) * delta
	while step > 0.0:
		if _next >= _path.size():
			# Abschnitt geschafft: weiter zum nächsten Kontrollpunkt oder in die Burg.
			leg += 1
			if leg >= board.map.waypoints.size():
				alive = false
				game.enemy_reached_keep(self)
				queue_free()
				return
			repath()
			if _next >= _path.size():
				break
		var target := Board.world_of(_path[_next], height)
		var to := target - Vector3(position.x, height, position.z)
		var dist := to.length()
		if dist > 0.001:
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 0.3)
		if dist <= step:
			position = target
			step -= dist
			_next += 1
		else:
			position += to / dist * step
			step = 0.0
	_update_distance()
	if air:
		_bob += delta * 3.0
		position.y = height + sin(_bob) * 0.08
