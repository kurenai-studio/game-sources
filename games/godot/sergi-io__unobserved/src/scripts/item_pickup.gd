extends Node2D
class_name ItemPickup

const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")

const ITEM_LASER: StringName = &"laser"
const ITEM_LASER_RATE: StringName = &"laser_rate"
const ITEM_BATTERY: StringName = &"battery"
const ITEM_DRONE: StringName = &"drone"
const ITEM_HOMING_MISSILE: StringName = &"homing_missile"
const ITEM_SHIELD: StringName = &"shield"
const ITEM_VACUUM: StringName = &"vacuum"
const ITEM_RADAR: StringName = &"radar"
const ITEM_REPAIRSET: StringName = &"repairset"
const ITEM_INVISIBILITY: StringName = &"invisibility"
const ITEM_XP_BOX: StringName = &"xpbox"
const ITEM_WORMHOLE_DASH: StringName = &"wormhole_dash"
const ITEM_VORTEX: StringName = &"vortex"
const ITEM_NUKE: StringName = &"nuke"
const ITEM_EXPLORER_BEACON: StringName = &"explorer_beacon"
const ITEM_COLONY_BEACON: StringName = &"colony_beacon"
const SHIELD_TEXTURE_PATH: String = "res://textures/items/shield.png"
const VACUUM_TEXTURE_PATH: String = "res://textures/items/vacuum.png"
const RADAR_TEXTURE_PATH: String = "res://textures/items/radar.png"
const WORMHOLE_DASH_TEXTURE_PATH: String = "res://textures/artifacts/wormhole-dash.png"
const VORTEX_TEXTURE_PATH: String = "res://textures/artifacts/vortex.png"
const NUKE_TEXTURE_PATH: String = "res://textures/artifacts/nuke.png"
const EXPLORER_BEACON_TEXTURE_PATH: String = "res://textures/artifacts/explorer-beacon.png"

@export var item_kind: StringName = ITEM_LASER
@export_range(1, 99, 1) var item_level: int = 1
@export_range(1, 999, 1) var repair_amount: int = 4
@export var ship_path: NodePath = NodePath("../../Ship")
@export var network_id: int = 0

@export_group("Motion")
@export_range(0.0, 64.0, 0.1) var float_amount: float = 7.0
@export_range(0.0, 6.0, 0.01) var float_speed: float = 1.4
@export_range(0.0, 0.15, 0.001) var float_rotation_amount: float = 0.03
@export_range(0.0, 8.0, 0.01) var float_rotation_speed: float = 1.1
@export_range(0.0, 360.0, 1.0) var pickup_padding: float = 12.0
@export_range(0.0, 12000.0, 10.0) var vacuum_attraction_acceleration: float = 2600.0
@export_range(0.0, 20000.0, 10.0) var vacuum_attraction_max_speed: float = 5200.0
@export_range(0.25, 5.0, 0.05) var vacuum_attraction_ease_power: float = 2.0
@export_range(0.0, 90.0, 1.0) var vacuum_attraction_turn_speed: float = 14.0

@onready var pickup_sprite: Sprite2D = $Sprite2D

var _ship: Node2D
var _base_position: Vector2 = Vector2.ZERO
var _base_rotation: float = 0.0
var _float_phase: float = 0.0
var _is_picked_up: bool = false
var _is_attracted: bool = false
var _is_spawning: bool = false
var _spawn_tween: Tween
var _spawn_origin: Vector2 = Vector2.ZERO
var _spawn_initial_velocity: Vector2 = Vector2.ZERO
var _spawn_duration: float = 0.0
var _spawn_target_position: Vector2 = Vector2.ZERO
var _spawn_target_rotation: float = 0.0
var _spawn_target_scale: Vector2 = Vector2.ONE
var _spawn_start_rotation: float = 0.0
var _spawn_initial_scale_multiplier: float = 0.36
var _attraction_speed: float = 0.0
var _shield_texture: Texture2D
var _vacuum_texture: Texture2D
var _radar_texture: Texture2D
var _wormhole_dash_texture: Texture2D
var _vortex_texture: Texture2D
var _nuke_texture: Texture2D
var _explorer_beacon_texture: Texture2D


func get_display_name() -> String:
	match item_kind:
		ITEM_LASER:
			return "Laser"
		ITEM_LASER_RATE:
			return "Laser Rate Boost"
		ITEM_BATTERY:
			return "Battery"
		ITEM_DRONE:
			return "Drone"
		ITEM_HOMING_MISSILE:
			return "Homing Missile"
		ITEM_SHIELD:
			return "Shield"
		ITEM_VACUUM:
			return "Vacuum"
		ITEM_RADAR:
			return "Radar"
		ITEM_REPAIRSET:
			return "Repair Kit"
		ITEM_INVISIBILITY:
			return "Invisibility"
		ITEM_XP_BOX:
			return "XP Box"
		ITEM_WORMHOLE_DASH:
			return "Wormhole Dash"
		ITEM_VORTEX:
			return "Vortex"
		ITEM_NUKE:
			return "Nuke"
		ITEM_EXPLORER_BEACON:
			return "Explorer Beacon"
		ITEM_COLONY_BEACON:
			return "Colony Beacon"
		_:
			return "Upgrade"


func get_display_description() -> String:
	match item_kind:
		ITEM_LASER:
			return "Increases laser damage."
		ITEM_LASER_RATE:
			return "Increases laser fire rate."
		ITEM_BATTERY:
			return "Improves thrust and movement."
		ITEM_DRONE:
			return "Adds a drone companion."
		ITEM_HOMING_MISSILE:
			return "Launches homing missiles that explode in a radius."
		ITEM_SHIELD:
			return "Creates a blue shield around the ship."
		ITEM_VACUUM:
			return "Attracts nearby pickups from farther away."
		ITEM_RADAR:
			return "Increases ship vision and weapon range."
		ITEM_REPAIRSET:
			return "Restores ship hit points."
		ITEM_INVISIBILITY:
			return "Makes the ship untargetable for a short time."
		ITEM_XP_BOX:
			return "Contains experience to collect."
		ITEM_WORMHOLE_DASH:
			return "Artifact. Activate it to dash forward through a wormhole."
		ITEM_VORTEX:
			return "Artifact. Activate it, then click the screen to place a gravity vortex."
		ITEM_NUKE:
			return "Artifact. Activate it, then click the screen to launch a nuke."
		ITEM_EXPLORER_BEACON:
			return "Artifact. Activate it, then click the galaxy or minimap to launch a scout beacon."
		ITEM_COLONY_BEACON:
			return "Consumable. Deploy one beacon to colonize one planet."
		_:
			return "Apply this upgrade to the ship."


func get_display_icon_texture() -> Texture2D:
	var sprite := pickup_sprite
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D

	if item_kind == ITEM_SHIELD and (sprite == null or sprite.texture == null):
		return _load_shield_texture()

	if item_kind == ITEM_VACUUM and (sprite == null or sprite.texture == null):
		return _load_vacuum_texture()

	if item_kind == ITEM_RADAR and (sprite == null or sprite.texture == null):
		return _load_radar_texture()

	if item_kind == ITEM_WORMHOLE_DASH and (sprite == null or sprite.texture == null):
		return _load_wormhole_dash_texture()

	if item_kind == ITEM_VORTEX and (sprite == null or sprite.texture == null):
		return _load_vortex_texture()

	if item_kind == ITEM_NUKE and (sprite == null or sprite.texture == null):
		return _load_nuke_texture()

	if item_kind == ITEM_EXPLORER_BEACON and (sprite == null or sprite.texture == null):
		return _load_explorer_beacon_texture()

	if sprite == null:
		return null

	return sprite.texture


func get_touch_radius() -> float:
	return _get_pickup_touch_radius()


func is_spawn_animating() -> bool:
	return _is_spawning


func _ready() -> void:
	_base_position = position
	_base_rotation = rotation
	_float_phase = randf_range(0.0, TAU)
	if item_kind == ITEM_SHIELD and pickup_sprite.texture == null:
		pickup_sprite.texture = _load_shield_texture()
	if item_kind == ITEM_VACUUM and pickup_sprite.texture == null:
		pickup_sprite.texture = _load_vacuum_texture()
	if item_kind == ITEM_RADAR and pickup_sprite.texture == null:
		pickup_sprite.texture = _load_radar_texture()
	if item_kind == ITEM_WORMHOLE_DASH and pickup_sprite.texture == null:
		pickup_sprite.texture = _load_wormhole_dash_texture()
	if item_kind == ITEM_VORTEX and pickup_sprite.texture == null:
		pickup_sprite.texture = _load_vortex_texture()
	if item_kind == ITEM_NUKE and pickup_sprite.texture == null:
		pickup_sprite.texture = _load_nuke_texture()
	if item_kind == ITEM_EXPLORER_BEACON and pickup_sprite.texture == null:
		pickup_sprite.texture = _load_explorer_beacon_texture()
	_resolve_ship()


func _process(delta: float) -> void:
	if _is_picked_up:
		return

	if _is_spawning:
		return

	if not _is_ship_valid():
		_resolve_ship()
		if not _is_ship_valid():
			return

	var attraction_radius := _get_ship_attraction_radius()
	if attraction_radius > 0.0 and _is_attracted:
		attract_toward_world_position(_ship.global_position, delta, attraction_radius)
	elif attraction_radius > 0.0 and global_position.distance_to(_ship.global_position) <= attraction_radius:
		_is_attracted = true
		attract_toward_world_position(_ship.global_position, delta, attraction_radius)
	else:
		reset_attraction()
		_float_phase += delta
		position = _base_position + Vector2(0.0, sin(_float_phase * float_speed + _base_rotation) * float_amount)
		rotation = _base_rotation + sin(_float_phase * float_rotation_speed + _base_rotation) * float_rotation_amount
	_try_pickup()


func _resolve_ship() -> void:
	_ship = get_node_or_null(ship_path) as Node2D


func _is_ship_valid() -> bool:
	return _ship != null and is_instance_valid(_ship)


func _try_pickup() -> void:
	if not _is_ship_valid():
		return

	var ship_touch_radius := _get_ship_touch_radius()
	var pickup_touch_radius := _get_pickup_touch_radius()
	if ship_touch_radius <= 0.0 or pickup_touch_radius <= 0.0:
		return

	if global_position.distance_to(_ship.global_position) > ship_touch_radius + pickup_touch_radius + pickup_padding:
		return

	_collect()


func attract_toward_world_position(target_world_position: Vector2, delta: float, attraction_radius: float) -> void:
	_is_attracted = true
	var direction_to_ship := target_world_position - global_position
	var distance_to_ship := direction_to_ship.length()
	if distance_to_ship <= 0.001:
		return

	var normalized_progress := clampf(1.0 - distance_to_ship / maxf(attraction_radius, 1.0), 0.0, 1.0)
	var eased_progress := ease(normalized_progress, vacuum_attraction_ease_power)
	var acceleration_scale := lerpf(0.35, 1.0, eased_progress)
	var speed_scale := lerpf(0.30, 1.0, eased_progress)
	_attraction_speed = minf(
		_attraction_speed + vacuum_attraction_acceleration * acceleration_scale * delta,
		vacuum_attraction_max_speed * speed_scale
	)

	global_position = global_position.move_toward(target_world_position, _attraction_speed * delta)
	rotation = lerp_angle(rotation, direction_to_ship.angle() + PI * 0.5, clampf(delta * vacuum_attraction_turn_speed, 0.0, 1.0))


func reset_attraction() -> void:
	_is_attracted = false
	_attraction_speed = 0.0


func play_splash_spawn(
	spawn_origin: Vector2,
	initial_velocity: Vector2,
	duration: float,
	delay: float = 0.0,
	initial_scale_multiplier: float = 0.36
) -> void:
	if _spawn_tween != null:
		_spawn_tween.kill()

	_is_spawning = true
	_spawn_origin = spawn_origin
	_spawn_initial_velocity = initial_velocity
	_spawn_duration = maxf(duration, 0.01)
	_spawn_target_position = position
	_spawn_target_rotation = rotation
	_spawn_target_scale = scale
	_spawn_start_rotation = _spawn_target_rotation + randf_range(-0.45, 0.45)
	_spawn_initial_scale_multiplier = clampf(initial_scale_multiplier, 0.1, 1.0)
	_set_splash_spawn_progress(0.0)

	_spawn_tween = create_tween()
	_spawn_tween.set_trans(Tween.TRANS_QUAD)
	_spawn_tween.set_ease(Tween.EASE_OUT)
	var splash_tween := _spawn_tween.tween_method(_set_splash_spawn_progress, 0.0, 1.0, _spawn_duration)
	if delay > 0.0:
		splash_tween.set_delay(delay)
	_spawn_tween.tween_callback(Callable(self, "_finish_spawn_animation"))


func _set_splash_spawn_progress(progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var elapsed := _spawn_duration * clamped_progress
	var deceleration := -_spawn_initial_velocity / maxf(_spawn_duration, 0.001)
	position = _spawn_origin + _spawn_initial_velocity * elapsed + deceleration * (0.5 * elapsed * elapsed)
	if clamped_progress >= 1.0:
		position = _spawn_target_position

	rotation = lerp_angle(_spawn_start_rotation, _spawn_target_rotation, clamped_progress)
	var scale_progress := 1.0 - pow(1.0 - clamped_progress, 3.0)
	scale = _spawn_target_scale * lerpf(_spawn_initial_scale_multiplier, 1.0, scale_progress)


func _finish_spawn_animation() -> void:
	_is_spawning = false
	_spawn_tween = null
	position = _spawn_target_position
	rotation = _spawn_target_rotation
	scale = _spawn_target_scale
	_base_position = _spawn_target_position
	_base_rotation = _spawn_target_rotation
	_float_phase = 0.0
	reset_attraction()


func _collect() -> void:
	_is_picked_up = true
	if _spawn_tween != null:
		_spawn_tween.kill()
	if _ship != null and is_instance_valid(_ship) and _ship.has_method("collect_item"):
		_ship.call("collect_item", item_kind, item_level, repair_amount, global_position)
	GAME_SFX.play(self, GAME_SFX.CUE_PICKUP)

	queue_free()


func _get_ship_touch_radius() -> float:
	if _ship == null or not is_instance_valid(_ship):
		return 0.0

	if _ship.has_method("get_touch_radius"):
		return maxf(float(_ship.call("get_touch_radius")), 0.0)

	return 0.0


func _get_ship_attraction_radius() -> float:
	if _ship == null or not is_instance_valid(_ship):
		return 0.0

	if _ship.has_method("get_pickup_attraction_radius"):
		return maxf(float(_ship.call("get_pickup_attraction_radius")), 0.0)

	return 0.0


func _get_pickup_touch_radius() -> float:
	if pickup_sprite == null or pickup_sprite.texture == null:
		return 0.0

	var texture_size := pickup_sprite.texture.get_size()
	if texture_size == Vector2.ZERO:
		return 0.0

	var scaled_size := texture_size * pickup_sprite.global_scale.abs()
	return maxf(scaled_size.x, scaled_size.y) * 0.5


func _load_shield_texture() -> Texture2D:
	if _shield_texture != null:
		return _shield_texture

	var texture := load(SHIELD_TEXTURE_PATH) as Texture2D
	if texture == null:
		return null

	_shield_texture = texture
	return _shield_texture


func _load_vacuum_texture() -> Texture2D:
	if _vacuum_texture != null:
		return _vacuum_texture

	var texture := load(VACUUM_TEXTURE_PATH) as Texture2D
	if texture == null:
		return null

	_vacuum_texture = texture
	return _vacuum_texture


func _load_radar_texture() -> Texture2D:
	if _radar_texture != null:
		return _radar_texture

	var texture := load(RADAR_TEXTURE_PATH) as Texture2D
	if texture == null:
		return null

	_radar_texture = texture
	return _radar_texture


func _load_wormhole_dash_texture() -> Texture2D:
	if _wormhole_dash_texture != null:
		return _wormhole_dash_texture

	var texture := load(WORMHOLE_DASH_TEXTURE_PATH) as Texture2D
	if texture == null:
		return null

	_wormhole_dash_texture = texture
	return _wormhole_dash_texture


func _load_vortex_texture() -> Texture2D:
	if _vortex_texture != null:
		return _vortex_texture

	var texture := load(VORTEX_TEXTURE_PATH) as Texture2D
	if texture == null:
		return null

	_vortex_texture = texture
	return _vortex_texture


func _load_nuke_texture() -> Texture2D:
	if _nuke_texture != null:
		return _nuke_texture

	var texture := load(NUKE_TEXTURE_PATH) as Texture2D
	if texture == null:
		return null

	_nuke_texture = texture
	return _nuke_texture


func _load_explorer_beacon_texture() -> Texture2D:
	if _explorer_beacon_texture != null:
		return _explorer_beacon_texture

	var texture := load(EXPLORER_BEACON_TEXTURE_PATH) as Texture2D
	if texture == null:
		return null

	_explorer_beacon_texture = texture
	return _explorer_beacon_texture
