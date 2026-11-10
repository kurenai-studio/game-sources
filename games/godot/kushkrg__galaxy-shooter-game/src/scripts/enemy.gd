class_name Enemy
extends Node2D
## One enemy ship. Kinds: drone, weaver, tank, boss.
## All behaviour (movement, firing patterns, boss spawns) lives here;
## the game scene owns collisions, score and effects.

signal wants_fire(from_pos: Vector2, dir: Vector2, speed: float, damage: int)
signal wants_drone(pos: Vector2)
signal escaped(enemy: Enemy)

const TEXTURES := {
	"drone": preload("res://assets/sprites/drone.svg"),
	"weaver": preload("res://assets/sprites/weaver.svg"),
	"tank": preload("res://assets/sprites/tank.svg"),
	"boss": preload("res://assets/sprites/boss.svg"),
}
const STATS := {
	"drone": {"hp": 2, "speed": 155.0, "score": 100, "radius": 25.0, "scale": 0.6, "contact": 15},
	"weaver": {"hp": 3, "speed": 175.0, "score": 150, "radius": 25.0, "scale": 0.6, "contact": 15},
	"tank": {"hp": 12, "speed": 80.0, "score": 300, "radius": 38.0, "scale": 0.82, "contact": 25},
	"boss": {"hp": 240, "speed": 62.0, "score": 2000, "radius": 92.0, "scale": 1.02, "contact": 40},
}

var kind := "drone"
var hp := 2
var max_hp := 2
var speed := 150.0
var score_value := 100
var radius := 25.0
var contact_damage := 15
var player_ref: Node2D

var _t := 0.0
var _base_x := 0.0
var _fire_timer := 2.0
var _drone_timer := 5.0
var _pattern := 0
var _sprite: Sprite2D

func setup(p_kind: String, pos: Vector2, level: int) -> void:
	kind = p_kind
	position = pos
	_base_x = pos.x
	var st: Dictionary = STATS[kind]
	hp = int(st["hp"])
	if kind == "boss":
		hp += (level / 5 - 1) * 60
	elif kind == "tank":
		hp += level * 1
	else:
		hp += level / 4
	max_hp = hp
	speed = float(st["speed"]) + level * 5.0
	score_value = int(st["score"])
	radius = float(st["radius"])
	contact_damage = int(st["contact"])
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURES[kind]
	var sc := float(st["scale"])
	_sprite.scale = Vector2(sc, sc)
	add_child(_sprite)
	_fire_timer = randf_range(1.2, 2.4)

func _process(delta: float) -> void:
	_t += delta
	var view := get_viewport_rect().size
	match kind:
		"drone":
			position.y += speed * delta
		"weaver":
			position.y += speed * delta
			position.x = _base_x + sin(_t * 3.1) * 88.0
		"tank":
			position.y += speed * delta
			_fire_timer -= delta
			if _fire_timer <= 0.0 and position.y > 40 and position.y < view.y * 0.6:
				_fire_timer = 2.3
				_aimed_shot()
		"boss":
			# Descend to the patrol line, then sweep side to side.
			if position.y < 185.0:
				position.y += 55.0 * delta
			else:
				position.x = view.x * 0.5 + sin(_t * 0.55) * (view.x * 0.28)
			_fire_timer -= delta
			if _fire_timer <= 0.0:
				_fire_timer = 1.15
				_boss_pattern()
			_drone_timer -= delta
			if _drone_timer <= 0.0:
				_drone_timer = 6.5
				wants_drone.emit(position + Vector2(randf_range(-120, 120), 90))
	if position.y > view.y + 90:
		escaped.emit(self)
		queue_free()
	if kind == "boss":
		queue_redraw()

func _aimed_shot() -> void:
	if player_ref == null:
		return
	var dir := (player_ref.position - position).normalized()
	wants_fire.emit(position + Vector2(0, 30), dir, 265.0, 10)

func _boss_pattern() -> void:
	_pattern = (_pattern + 1) % 3
	match _pattern:
		0:  # aimed burst of 3
			for i in 3:
				if player_ref != null:
					var dir := (player_ref.position - position).normalized()
					dir = dir.rotated((i - 1) * 0.13)
					wants_fire.emit(position + Vector2(0, 70), dir, 300.0, 10)
		1:  # downward spread of 7
			for i in 7:
				var dir := Vector2.DOWN.rotated(lerpf(-0.75, 0.75, float(i) / 6.0))
				wants_fire.emit(position + Vector2(0, 70), dir, 265.0, 10)
		2:  # side cannons
			wants_fire.emit(position + Vector2(-70, 30), Vector2(-0.25, 1).normalized(), 280.0, 10)
			wants_fire.emit(position + Vector2(70, 30), Vector2(0.25, 1).normalized(), 280.0, 10)
			wants_fire.emit(position + Vector2(0, 76), Vector2.DOWN, 320.0, 12)

func take_damage(amount: int) -> bool:
	hp -= amount
	if _sprite != null:
		_sprite.modulate = Color(3, 3, 3)
		var tween := create_tween()
		tween.tween_property(_sprite, "modulate", Color.WHITE, 0.1)
	if kind == "boss":
		queue_redraw()
	return hp <= 0

func _draw() -> void:
	if kind != "boss":
		return
	var w := 230.0
	var pct := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	draw_rect(Rect2(-w / 2, -128, w, 13), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-w / 2 + 1.5, -126.5, (w - 3) * pct, 10), Color(0.95, 0.25, 0.55))
