class_name ExplorerBeaconPlacementPreview
extends Node2D

const RUNTIME_TEXTURE: Texture2D = preload("res://textures/artifacts/explorer-beacon-runtime.png")

@export var owner_ship: Node2D
@export var sprite_scale: Vector2 = Vector2(0.24, 0.24)
@export_range(64.0, 4000.0, 10.0) var direction_radius: float = 420.0
@export_range(-180.0, 180.0, 1.0, "radians_as_degrees") var sprite_forward_rotation_offset: float = -PI * 0.5
@export_range(1.0, 24.0, 0.5) var arrow_width: float = 7.0
@export_range(6.0, 128.0, 1.0) var arrow_head_length: float = 54.0
@export_range(6.0, 96.0, 1.0) var arrow_head_width: float = 18.0
@export_range(2.0, 64.0, 1.0) var arrow_dash_length: float = 18.0
@export_range(2.0, 64.0, 1.0) var arrow_dash_gap: float = 14.0
@export_range(0.0, 600.0, 5.0) var arrow_dash_speed: float = 155.0
@export_range(0.0, 160.0, 1.0) var beacon_clearance: float = 58.0
@export var valid_arrow_color: Color = Color(0.2, 0.72, 1.0, 0.42)
@export var invalid_arrow_color: Color = Color(1.0, 0.08, 0.08, 0.48)
@export var valid_sprite_color: Color = Color(1.0, 1.0, 1.0, 0.72)
@export var invalid_sprite_color: Color = Color(1.0, 0.25, 0.25, 0.66)

var _sprite: Sprite2D
var _is_valid_placement: bool = true
var _dash_offset: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "RuntimePreviewSprite"
	_sprite.texture = RUNTIME_TEXTURE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = sprite_scale
	add_child(_sprite)
	_apply_valid_state()
	set_process(true)


func set_valid_placement(is_valid_placement: bool) -> void:
	if _is_valid_placement == is_valid_placement:
		return

	_is_valid_placement = is_valid_placement
	_apply_valid_state()
	queue_redraw()


func _process(delta: float) -> void:
	_dash_offset = fposmod(_dash_offset + arrow_dash_speed * maxf(delta, 0.0), arrow_dash_length + arrow_dash_gap)
	_update_sprite_rotation()
	queue_redraw()


func _draw() -> void:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return

	var travel_direction := _get_preview_direction()
	if travel_direction == Vector2.ZERO:
		return

	var ship_position := to_local(owner_ship.global_position)
	var beacon_position := to_local(owner_ship.global_position + travel_direction * maxf(direction_radius, 1.0))
	var arrow_start := ship_position
	var arrow_tip := beacon_position - travel_direction * beacon_clearance
	var arrow_base := arrow_tip - travel_direction * arrow_head_length
	var arrow_shoulder := arrow_tip - travel_direction * arrow_head_length * 0.68
	var arrow_notch := arrow_tip - travel_direction * arrow_head_length * 0.88
	if arrow_start.distance_to(arrow_tip) <= arrow_head_length:
		return

	var side := travel_direction.rotated(PI * 0.5)
	var arrow_color := valid_arrow_color if _is_valid_placement else invalid_arrow_color

	var spear_points := PackedVector2Array([
		arrow_tip,
		arrow_shoulder + side * arrow_head_width,
		arrow_base + side * arrow_width * 0.42,
		arrow_notch,
		arrow_base - side * arrow_width * 0.42,
		arrow_shoulder - side * arrow_head_width,
	])

	_draw_animated_dashed_line(arrow_start, arrow_notch, travel_direction, arrow_color)
	draw_colored_polygon(spear_points, arrow_color)


func _draw_animated_dashed_line(
	line_start: Vector2,
	line_end: Vector2,
	line_direction: Vector2,
	line_color: Color
) -> void:
	var line_length := line_start.distance_to(line_end)
	if line_length <= 0.01:
		return

	var safe_dash_length := maxf(arrow_dash_length, 1.0)
	var safe_dash_gap := maxf(arrow_dash_gap, 1.0)
	var cycle_length := safe_dash_length + safe_dash_gap
	var dash_start_distance := fposmod(_dash_offset, cycle_length) - cycle_length
	var dot_radius := maxf(arrow_width * 0.5, 1.0)

	while dash_start_distance < line_length:
		var dash_end_distance := dash_start_distance + safe_dash_length
		var clamped_start := clampf(dash_start_distance, 0.0, line_length)
		var clamped_end := clampf(dash_end_distance, 0.0, line_length)
		if clamped_end > clamped_start:
			var dash_start := line_start + line_direction * clamped_start
			var dash_end := line_start + line_direction * clamped_end
			draw_line(dash_start, dash_end, line_color, arrow_width, true)
			draw_circle(dash_start, dot_radius, line_color)
			draw_circle(dash_end, dot_radius, line_color)

		dash_start_distance += cycle_length


func _update_sprite_rotation() -> void:
	if _sprite == null or owner_ship == null or not is_instance_valid(owner_ship):
		return

	var travel_direction := _get_preview_direction()
	if travel_direction == Vector2.ZERO:
		return

	_sprite.position = to_local(owner_ship.global_position + travel_direction * maxf(direction_radius, 1.0))
	_sprite.rotation = travel_direction.angle() + sprite_forward_rotation_offset


func _apply_valid_state() -> void:
	if _sprite == null:
		return

	_sprite.modulate = valid_sprite_color if _is_valid_placement else invalid_sprite_color


func _get_preview_direction() -> Vector2:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return Vector2.ZERO

	var travel_direction := global_position - owner_ship.global_position
	if travel_direction == Vector2.ZERO:
		return Vector2.ZERO

	return travel_direction.normalized()
