extends CharacterBody2D

@export var obeliskspeed := 280.0
@export var ohealth := 5
@export var okeepdistance := 180.0
@export var oreloadkeepdistance := 240.0
@export var ostrafespeed := 120.0
@export var obulletaggro := 600.0
@export var oaggrotime := 2.5

@onready var player = get_tree().get_first_node_in_group("player")
@onready var anim = $obelisksprite
@onready var notifier = $VisibleOnScreenNotifier2D

var engage_voicelines: Array[AudioStream] = [
	preload("assets/sounds/input/obliskvoicelines/zealotVoice1.mp3"),
	preload("assets/sounds/input/obliskvoicelines/zealotVoice2.mp3"),
	preload("assets/sounds/input/obliskvoicelines/zealotVoiceCombat1.mp3"),
	preload("assets/sounds/input/obliskvoicelines/zealotVoiceCombat2.mp3"),
	preload("assets/sounds/input/obliskvoicelines/zealotVoiceCombat3.mp3"),
	]


const CELL := 28.0
const HALFW := 10

var activated := false
var _aggrotimer := 0.0
var _strafetime := 0.0
var _path: PackedVector2Array = []
var _pathi := 0
var _repathtimer := 0.0
var _grid: AStarGrid2D
var blood = load("res://bloodFIXED.tscn")

func _ready() -> void:
	add_to_group("enemy")
	notifier.screen_entered.connect(_on_screen_entered)


func _play_random_voiceline(lines: Array[AudioStream]) -> void:
	if lines.is_empty():
		return
	var sfx := AudioStreamPlayer2D.new()
	sfx.stream = lines.pick_random()
	sfx.global_position = global_position
	sfx.finished.connect(sfx.queue_free)
	get_tree().current_scene.add_child(sfx)
	sfx.play()

func _on_screen_entered() -> void:
	if not activated:
		activated = true
		print(name, " woke up")
	_play_random_voiceline(engage_voicelines)

func is_gun_ready() -> bool:
	return _aggrotimer > 0.0

func _is_reloading() -> bool:
	for child in get_children():
		if "reloading" in child:
			return child.reloading
	return false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		anim.stop()
		return

	# see you, see a bullet, or just got shot -> fight. otherwise fade after a few seconds
	if _stimulus():
		if _aggrotimer <= 0.0:
			print(name, " aggro")
		_aggrotimer = oaggrotime
		activated = true
	else:
		_aggrotimer -= delta

	if _aggrotimer <= 0.0:
		activated = false
		velocity = Vector2.ZERO
		anim.stop()
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var dir = to_player.normalized() if dist > 0.001 else Vector2.RIGHT

	_strafetime += delta
	var strafeamt = sin(_strafetime * 1.8)
	var keep = oreloadkeepdistance if _is_reloading() else okeepdistance

	var motion := Vector2.ZERO
	if dist > keep + 28.0:
		motion = _move_dir(dir) * obeliskspeed
	elif dist < keep - 28.0:
		motion = _move_dir(-dir) * obeliskspeed
	else:
		_path = PackedVector2Array()
	motion += dir.orthogonal() * strafeamt * ostrafespeed

	velocity = motion
	anim.play("walk")
	anim.flip_h = dir.x < 0
	move_and_slide()

func _move_dir(dir: Vector2) -> Vector2:
	# clear line -> walk straight. blocked -> follow a tiny local A* around the wall
	if _ray_free(dir):
		_path = PackedVector2Array()
		_repathtimer = 0.0
		return dir
	_repathtimer -= get_physics_process_delta_time()
	if _repathtimer <= 0.0 or _path.is_empty():
		_repathtimer = 0.35
		_path = _astar_path(global_position, player.global_position)
		_pathi = 0
	if _path.is_empty():
		return _steer(dir)
	if _pathi < _path.size() - 1 and global_position.distance_to(_path[_pathi]) < 16.0:
		_pathi += 1
	var to_next = _path[_pathi] - global_position
	if to_next.length() < 0.001:
		return dir
	return to_next.normalized()

func _astar_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var center = _w2c((from + to) * 0.5)
	var origin = center - Vector2i(HALFW, HALFW)
	var size = Vector2i(HALFW * 2 + 1, HALFW * 2 + 1)
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(origin, size)
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()

	var space = get_world_2d().direct_space_state
	for y in range(origin.y, origin.y + size.y):
		for x in range(origin.x, origin.x + size.x):
			var c = Vector2i(x, y)
			if _point_blocked(space, _c2w(c)):
				_grid.set_point_solid(c, true)

	var a = _snap(_w2c(from))
	var b = _snap(_w2c(to))
	if a == null or b == null:
		return out
	for id in _grid.get_id_path(a, b, true):
		out.append(_c2w(id))
	return out

func _snap(cell: Vector2i) -> Variant:
	if _grid.is_in_boundsv(cell) and not _grid.is_point_solid(cell):
		return cell
	for r in range(1, 8):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if abs(dx) != r and abs(dy) != r:
					continue
				var n = cell + Vector2i(dx, dy)
				if _grid.is_in_boundsv(n) and not _grid.is_point_solid(n):
					return n
	return null

func _w2c(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / CELL)), int(floor(p.y / CELL)))

func _c2w(c: Vector2i) -> Vector2:
	return Vector2(c) * CELL + Vector2(CELL, CELL) * 0.5

func _point_blocked(space: PhysicsDirectSpaceState2D, pos: Vector2) -> bool:
	var q = PhysicsPointQueryParameters2D.new()
	q.position = pos
	q.collide_with_bodies = true
	q.collide_with_areas = false
	for h in space.intersect_point(q, 8):
		if h.get("collider") is CharacterBody2D:
			continue
		return true
	return false

func _steer(dir: Vector2) -> Vector2:
	if _ray_free(dir):
		return dir
	for ang in [0.55, -0.55, 1.1, -1.1]:
		var alt = dir.rotated(ang)
		if _ray_free(alt):
			return alt
	return Vector2.ZERO

func _ray_free(dir: Vector2) -> bool:
	var q = PhysicsRayQueryParameters2D.create(global_position, global_position + dir * 52.0)
	q.exclude = [get_rid()]
	q.collide_with_areas = false
	var hit = get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return true
	return hit.get("collider") is CharacterBody2D

func _stimulus() -> bool:
	if notifier.is_on_screen():
		return true
	return _player_bullet_nearby()

func _player_bullet_nearby() -> bool:
	for b in get_tree().get_nodes_in_group("bullet"):
		if not is_instance_valid(b):
			continue
		if b.shooter != null and b.shooter.is_in_group("player"):
			if global_position.distance_to(b.global_position) <= obulletaggro:
				return true
	return false

func take_damage(amount: int) -> void:
	_aggrotimer = oaggrotime
	activated = true
	ohealth -= amount
	print(name, " hp: ", ohealth)
	var blood_instance = blood.instantiate()
	get_tree().current_scene.add_child(blood_instance)
	blood_instance.global_position = global_position
	if ohealth <= 0:
		print(name, " died")
		queue_free()


