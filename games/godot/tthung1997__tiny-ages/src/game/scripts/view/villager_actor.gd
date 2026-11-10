class_name VillagerActor
extends Node2D
## A villager on screen: walks to wherever its plan says, then does its work animation. Draws
## in front of or behind props by its foot row.

const SPEED: float = 16.0
const ARRIVE_DISTANCE: float = 0.6
const WALK_FPS: float = 6.0
const CHOP_FPS: float = 5.0
const HAMMER_FPS: float = 4.0
const SHEET_FRAMES: Dictionary = {
	&"idle": [0], &"walk": [1, 2, 3, 4], &"chop": [5, 6, 7], &"hammer": [8, 9], &"spear": [10],
}
const SHEET_SPEEDS: Dictionary = {
	&"idle": 1.0, &"walk": WALK_FPS, &"chop": CHOP_FPS, &"hammer": HAMMER_FPS, &"spear": 1.0,
}
## The part of the sprite a click lands on, relative to the feet: a little generous round the body.
const HIT_OFFSET: Vector2 = Vector2(-8.0, -26.0)
const HIT_SIZE: Vector2 = Vector2(16.0, 28.0)

var villager_id: StringName = &""

var _sprite: AnimatedSprite2D = AnimatedSprite2D.new()
## What a role adds on top of the body (an apron, a pack): the same sheet layout, kept in step with
## the body's animation and frame (docs/engine-and-art.md A4).
var _role_sprite: AnimatedSprite2D = AnimatedSprite2D.new()
var _role: StringName = &""
var _target: Vector2 = Vector2.ZERO
var _pose: StringName = &"idle"
var _focus_x: float = NAN
var _wandering: bool = false
var _placed: bool = false
var _hidden_reason: StringName = &""


func _init() -> void:
	_sprite.centered = false
	_sprite.offset = WorldLayout.FOOT_OFFSET
	add_child(_sprite)
	_role_sprite.centered = false
	_role_sprite.offset = WorldLayout.FOOT_OFFSET
	_role_sprite.visible = false
	add_child(_role_sprite)


func setup(id: StringName, sheet: Texture2D) -> void:
	villager_id = id
	_sprite.sprite_frames = build_frames(sheet)
	_sprite.play(&"idle")


## Puts a role's overlay on the villager (an empty `role` or a missing sheet takes it off).
func set_role(role: StringName, sheet: Texture2D) -> void:
	if role == _role and (sheet != null) == _role_sprite.visible:
		return
	_role = role
	_role_sprite.visible = sheet != null
	if sheet != null:
		_role_sprite.sprite_frames = build_frames(sheet)
		_sync_role()


func role() -> StringName:
	return _role


func _sync_role() -> void:
	if not _role_sprite.visible or _role_sprite.sprite_frames == null:
		return
	if _role_sprite.animation != _sprite.animation:
		_role_sprite.animation = _sprite.animation
	_role_sprite.frame = _sprite.frame
	_role_sprite.flip_h = _sprite.flip_h


## Swaps the art (the villager put on woven clothes) without losing the animation they are in.
func set_sheet(sheet: Texture2D) -> void:
	var animation: StringName = _sprite.animation
	var frame: int = _sprite.frame
	_sprite.sprite_frames = build_frames(sheet)
	_sprite.play(animation)
	_sprite.frame = frame


## Builds idle/walk/chop/hammer/spear animations from a villager sheet (11 cells of 28x30).
static func build_frames(sheet: Texture2D) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation: StringName in SHEET_FRAMES:
		frames.add_animation(animation)
		frames.set_animation_speed(animation, SHEET_SPEEDS[animation])
		frames.set_animation_loop(animation, true)
		for cell: int in SHEET_FRAMES[animation]:
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(
				Vector2(WorldLayout.CELL_SIZE.x * cell, 0), Vector2(WorldLayout.CELL_SIZE)
			)
			frames.add_frame(animation, atlas)
	return frames


## Where a click on this villager lands, in the world's (camp) pixels.
func hit_rect() -> Rect2:
	return Rect2(position + HIT_OFFSET, HIT_SIZE)


func apply_plan(plan: VillagerPlan) -> void:
	if not plan.visible:
		if visible:
			_hidden_reason = plan.hidden_reason
		visible = false
		return
	var was_hidden: bool = not visible
	visible = true
	_pose = plan.pose
	_focus_x = plan.focus_x
	if plan.wander and _wandering and not _arrived():
		return
	_wandering = plan.wander
	_target = plan.target
	if not _placed:
		position = _target
		_placed = true
	elif was_hidden:
		position = _spawn_point()
		_hidden_reason = &""


func _process(delta: float) -> void:
	if not visible:
		return
	var to_target: Vector2 = _target - position
	if to_target.length() > ARRIVE_DISTANCE:
		position += to_target.normalized() * minf(SPEED * delta, to_target.length())
		_sprite.flip_h = to_target.x < 0.0
		_play(&"walk")
	else:
		position = _target
		if not is_nan(_focus_x) and absf(_focus_x - position.x) > 1.0:
			_sprite.flip_h = _focus_x < position.x
		_play(_pose)
	z_index = int(position.y)
	_sync_role()


func _arrived() -> bool:
	return position.distance_to(_target) <= ARRIVE_DISTANCE


func _spawn_point() -> Vector2:
	if _hidden_reason == VillagerPlan.HIDDEN_AWAY:
		return WorldLayout.WEST_EDGE
	return WorldLayout.CAVE_DOOR


func _play(animation: StringName) -> void:
	if _sprite.animation != animation or not _sprite.is_playing():
		_sprite.play(animation)
