extends Sprite2D
class_name LaserProjectile

const LASER_TEXTURE: Texture2D = preload("res://textures/items/laser1_fired.png")
const SPRITE_FORWARD_ROTATION_OFFSET: float = -PI * 0.5
const MIN_IMPACT_DISTANCE: float = 12.0
const GLOW_COLOR: Color = Color(0.24, 0.92, 1.0, 0.58)
const TRAIL_COLOR: Color = Color(0.08, 0.54, 1.0, 0.34)
const SHADOW_COLOR: Color = Color(0.02, 0.08, 0.14, 0.32)

var speed: float = 4200.0
var damage: int = 1
var owner_peer_id: int = 0
var deals_damage: bool = true

var _target: Node2D
var _source_ship: Node2D
var _fallback_target_position: Vector2 = Vector2.ZERO
var _fallback_target_position_valid: bool = false
var _has_impacted: bool = false
var _is_fog_presentation_visible: bool = true
var _glow_sprite: Sprite2D
var _trail_sprite: Sprite2D
var _shadow_sprite: Sprite2D
var _glow_material: CanvasItemMaterial
var _trail_material: CanvasItemMaterial
var _depth_scale: float = 1.0


func _ready() -> void:
	texture = LASER_TEXTURE
	centered = true
	z_index = 18
	_ensure_depth_layers()
	_apply_depth_styling(1.0, 1)
	_apply_presentation_state()


func initialize(
	target: Node2D,
	source_ship: Node2D,
	laser_level: int,
	damage_amount: int,
	projectile_speed: float,
	projectile_scale: float,
	fallback_target_position: Vector2,
	fallback_target_position_valid: bool,
	should_deal_damage: bool = true
) -> void:
	_target = target
	_source_ship = source_ship
	damage = maxi(damage_amount, 0)
	speed = maxf(projectile_speed, 1.0)
	deals_damage = should_deal_damage
	_fallback_target_position = fallback_target_position
	_fallback_target_position_valid = fallback_target_position_valid
	_depth_scale = maxf(projectile_scale, 0.01)
	scale = Vector2.ONE * _depth_scale
	name = "LaserProjectile%d" % maxi(laser_level, 1)
	texture = LASER_TEXTURE
	centered = true
	z_index = 18
	_ensure_depth_layers()
	_apply_depth_styling(_depth_scale, laser_level)
	_update_rotation()


func set_fog_presentation_visible(is_visible: bool) -> void:
	_is_fog_presentation_visible = is_visible
	_apply_presentation_state()


func _apply_presentation_state() -> void:
	visible = _is_fog_presentation_visible


func _physics_process(delta: float) -> void:
	if _has_impacted:
		return

	var target_position := _get_target_position()
	if not target_position.is_finite():
		queue_free()
		return

	var to_target := target_position - global_position
	var distance_to_target := to_target.length()
	var impact_distance := _get_impact_distance()
	if distance_to_target <= impact_distance:
		_impact()
		return

	var travel_distance := speed * delta
	var travel_direction := to_target / distance_to_target
	var safe_travel_distance := minf(travel_distance, maxf(distance_to_target - impact_distance, 0.0))
	global_position += travel_direction * safe_travel_distance
	rotation = travel_direction.angle() + SPRITE_FORWARD_ROTATION_OFFSET
	_sync_depth_layers()

	if travel_distance >= distance_to_target - impact_distance:
		_impact()


func _get_target_position() -> Vector2:
	if _target != null and is_instance_valid(_target):
		return _target.global_position

	if _fallback_target_position_valid:
		return _fallback_target_position

	return Vector2(INF, INF)


func _update_rotation() -> void:
	var target_position := _get_target_position()
	if not target_position.is_finite():
		return

	var direction := target_position - global_position
	if direction == Vector2.ZERO:
		return

	rotation = direction.angle() + SPRITE_FORWARD_ROTATION_OFFSET
	_sync_depth_layers()


func _get_impact_distance() -> float:
	var target_radius := 0.0
	if _target != null and is_instance_valid(_target):
		if _target.has_method("get_damage_impact_radius"):
			target_radius = maxf(float(_target.call("get_damage_impact_radius")), 0.0)
		elif _target.has_method("get_touch_radius"):
			target_radius = maxf(float(_target.call("get_touch_radius")), 0.0)

	var projectile_radius := 0.0
	if texture != null:
		var texture_size := texture.get_size()
		projectile_radius = maxf(texture_size.x, texture_size.y) * maxf(scale.x, scale.y) * 0.25

	return maxf(MIN_IMPACT_DISTANCE, target_radius + projectile_radius)


func _impact() -> void:
	if _has_impacted:
		return

	_has_impacted = true
	if deals_damage and _target != null and is_instance_valid(_target) and _target.has_method("take_damage"):
		var damage_multiplier := 1.0
		if _source_ship != null and is_instance_valid(_source_ship) and _source_ship.has_method("get_safe_zone_attack_multiplier"):
			damage_multiplier = maxf(float(_source_ship.call("get_safe_zone_attack_multiplier")), 1.0)
		var applied_damage := maxi(1, int(round(float(damage) * damage_multiplier)))
		if _target.has_method("get_damage_impact_position"):
			var impact_position := _target.call("get_damage_impact_position", global_position) as Vector2
			_target.call("take_damage", applied_damage, impact_position)
		else:
			_target.call("take_damage", applied_damage)

	queue_free()


func _ensure_depth_layers() -> void:
	if _glow_sprite == null:
		_glow_material = CanvasItemMaterial.new()
		_glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_glow_sprite = Sprite2D.new()
		_glow_sprite.name = "Glow"
		_glow_sprite.texture = LASER_TEXTURE
		_glow_sprite.centered = true
		_glow_sprite.material = _glow_material
		_glow_sprite.z_index = -2
		add_child(_glow_sprite)

	if _trail_sprite == null:
		_trail_material = CanvasItemMaterial.new()
		_trail_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_trail_sprite = Sprite2D.new()
		_trail_sprite.name = "Trail"
		_trail_sprite.texture = LASER_TEXTURE
		_trail_sprite.centered = true
		_trail_sprite.material = _trail_material
		_trail_sprite.z_index = -3
		add_child(_trail_sprite)

	if _shadow_sprite == null:
		_shadow_sprite = Sprite2D.new()
		_shadow_sprite.name = "Shadow"
		_shadow_sprite.texture = LASER_TEXTURE
		_shadow_sprite.centered = true
		_shadow_sprite.z_index = -4
		add_child(_shadow_sprite)


func _apply_depth_styling(projectile_scale: float, laser_level: int) -> void:
	var level_scale := maxf(float(maxi(laser_level, 1) - 1), 0.0)
	modulate = Color(1.0, 0.97, 0.92, 1.0)
	if _glow_sprite != null:
		_glow_sprite.modulate = GLOW_COLOR
		_glow_sprite.scale = Vector2(1.45 + level_scale * 0.05, 2.4 + level_scale * 0.08)
	if _trail_sprite != null:
		_trail_sprite.modulate = TRAIL_COLOR
		_trail_sprite.scale = Vector2(0.9 + level_scale * 0.03, 3.1 + level_scale * 0.12)
	if _shadow_sprite != null:
		_shadow_sprite.modulate = SHADOW_COLOR
		_shadow_sprite.scale = Vector2(1.08, 1.75)
	_sync_depth_layers()


func _sync_depth_layers() -> void:
	var texture_height := 0.0
	if texture != null:
		texture_height = texture.get_size().y
	var trail_offset := maxf(texture_height * 0.72 * _depth_scale, 10.0)
	var glow_offset := maxf(texture_height * 0.08 * _depth_scale, 2.0)
	var shadow_offset := maxf(texture_height * 0.24 * _depth_scale, 5.0)
	if _glow_sprite != null:
		_glow_sprite.position = Vector2(0.0, glow_offset)
		_glow_sprite.rotation = 0.0
	if _trail_sprite != null:
		_trail_sprite.position = Vector2(0.0, trail_offset)
		_trail_sprite.rotation = 0.0
	if _shadow_sprite != null:
		_shadow_sprite.position = Vector2(2.0, shadow_offset)
		_shadow_sprite.rotation = 0.0
