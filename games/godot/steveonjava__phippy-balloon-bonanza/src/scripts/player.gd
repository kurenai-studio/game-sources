extends Area2D
class_name Player

# Phippy pixel sprite sheet: 192x240, 3 columns x 8 rows -> 64x30 frames.
const PHIPPY_TEX := preload("res://assets/pixel/phippy-rescue/phippy.png")
const FRAME_W := 64
const FRAME_H := 30
const SCALE := 3.0

# Horizontal movement speed in pixels per second.
@export var speed := 360.0
# Width of the play area, used to keep Phippy on screen.
var screen_w := 1024.0

var _sprite: AnimatedSprite2D
var _half_w: float


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 0

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.scale = Vector2(SCALE, SCALE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.offset = Vector2(FRAME_W / 2.0, FRAME_H / 2.0)
	add_child(_sprite)

	# Match the collision box to Phippy's body (a little narrower than the frame).
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(FRAME_W * SCALE * 0.45, FRAME_H * SCALE * 0.8)
	col.shape = rect
	add_child(col)

	_half_w = (FRAME_W * SCALE) * 0.5
	_sprite.play("idle")


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	# Row 0 reads as a gentle idle; rows 1-3 as a walk cycle.
	var anims := {
		"idle": [[0, 0], [0, 1], [0, 2]],
		"walk": [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2], [2, 0], [2, 1], [2, 2]],
	}
	for anim in anims:
		sf.add_animation(anim)
		for cell in anims[anim]:
			var at := AtlasTexture.new()
			at.atlas = PHIPPY_TEX
			at.region = Rect2(cell[0] * FRAME_W, cell[1] * FRAME_H, FRAME_W, FRAME_H)
			sf.add_frame(anim, at)
		sf.set_animation_speed(anim, 8.0)
	sf.set_animation_loop("walk", true)
	sf.set_animation_loop("idle", true)
	return sf


func _process(delta: float) -> void:
	var dir := 0
	if Input.is_action_pressed("move_left"):
		dir -= 1
	if Input.is_action_pressed("move_right"):
		dir += 1

	position.x += dir * speed * delta
	position.x = clampf(position.x, _half_w, screen_w - _half_w)

	if dir < 0:
		_sprite.flip_h = true
		if not _sprite.is_playing():
			_sprite.play("walk")
	elif dir > 0:
		_sprite.flip_h = false
		if not _sprite.is_playing():
			_sprite.play("walk")
	else:
		if _sprite.animation != "idle":
			_sprite.play("idle")
