class_name Projectile
extends Node3D
## Geschoss: Pfeile, Bolzen, Feuer und Magie fliegen hinter dem Ziel her, Felsbrocken im Bogen auf die
## Stelle, an der das Ziel beim Abschuss stand. `hit` trägt die Wirkung: damage, splash, slow, slow_time,
## burn (Schaden pro Sekunde), chain (springt auf weitere Gegner).

const CHAIN_RANGE := 2.5

var kind: String
var target: Enemy
var hit: Dictionary
var speed := 10.0
## Bei Kettenblitzen: schon getroffene Gegner.
var already: Array[Enemy] = []
var _from: Vector3
var _to: Vector3
var _t := 0.0
var _duration := 1.0
var _model: Node3D


func launch(shot_kind: String, from: Vector3, enemy: Enemy, effect: Dictionary, fly_speed: float) -> void:
	kind = shot_kind
	target = enemy
	hit = effect
	speed = fly_speed
	_from = from
	position = from
	_to = enemy.global_position + Vector3(0, 0.3, 0)
	_duration = maxf(0.12, _from.distance_to(_to) / speed)
	match kind:
		"arrow", "bolt":
			_model = Models.make("td/weapon-ammo-arrow")
			_model.scale = Vector3.ONE * (0.5 if kind == "arrow" else 0.8)
		"boulder":
			_model = Models.make("td/weapon-ammo-boulder")
			_model.scale = Vector3.ONE * (0.5 if hit["splash"] < 1.5 else 0.8)
		"fire":
			_model = _orb(0.1, Color(1.0, 0.55, 0.15))
		_:
			_model = _orb(0.12, Color(0.7, 0.45, 1.0) if hit["chain"] == 0 else Color(0.6, 0.85, 1.0))
	if hit["burn"] > 0.0 and kind == "arrow":
		_model.add_child(_orb(0.07, Color(1.0, 0.5, 0.1)))
	add_child(_model)


static func _orb(radius: float, color: Color) -> MeshInstance3D:
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	sphere.material = material
	orb.mesh = sphere
	return orb


func _process(delta: float) -> void:
	_t += delta
	var arc := kind == "boulder"
	if not arc and is_instance_valid(target) and target.alive:
		_to = target.global_position + Vector3(0, 0.3, 0)
	var f := clampf(_t / _duration, 0.0, 1.0)
	var pos := _from.lerp(_to, f)
	if arc:
		pos.y += sin(f * PI) * maxf(1.0, _from.distance_to(_to) * 0.35)
	if pos.distance_squared_to(position) > 0.0001:
		look_at(pos, Vector3.UP, true)
	position = pos
	if f >= 1.0:
		_hit()


func _hit() -> void:
	var main := get_parent()
	var splash: float = hit["splash"]
	if splash > 0.0:
		for enemy: Enemy in main.enemies.duplicate():
			if enemy.alive and not enemy.air and Vector2(enemy.position.x - _to.x, enemy.position.z - _to.z).length() <= splash:
				_apply(enemy)
		Sfx.play_at(&"burst" if hit["burn"] > 0.0 else &"crash", _to)
		main.call("puff", _to, Color(1.0, 0.5, 0.2, 0.7) if hit["burn"] > 0.0 else Color(0.85, 0.75, 0.6, 0.6))
	elif is_instance_valid(target) and target.alive:
		_apply(target)
		if kind in ["arrow", "bolt"]:
			Sfx.play_at(&"hit", _to)
		if hit["chain"] > 1:
			_jump(main)
	queue_free()


func _apply(enemy: Enemy) -> void:
	if hit["slow"] > 0.0:
		enemy.apply_slow(hit["slow"], hit["slow_time"])
	if hit["burn"] > 0.0:
		enemy.apply_burn(hit["burn"], 3.0)
	enemy.take_damage(hit["damage"], kind in ["magic", "fire"])


## Kettenblitz: weiter zum nächsten Gegner, der noch nicht getroffen wurde.
func _jump(main: Node) -> void:
	already.append(target)
	var best: Enemy = null
	var best_distance := CHAIN_RANGE
	for enemy: Enemy in main.enemies:
		if enemy.alive and not already.has(enemy):
			var d := enemy.global_position.distance_to(_to)
			if d < best_distance:
				best = enemy
				best_distance = d
	if best == null:
		return
	var next := Projectile.new()
	main.add_child(next)
	var effect := hit.duplicate()
	effect["chain"] = hit["chain"] - 1
	effect["damage"] = hit["damage"] * 0.8
	next.already = already
	next.launch(kind, _to, best, effect, speed * 1.5)
