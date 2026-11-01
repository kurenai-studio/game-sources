extends Area2D
class_name Balloon

# Balloon-with-pod sprite sheets: 384x512, 6 columns x 8 rows -> 64x64 frames.
const TEX_A := preload("res://assets/pixel/phippy-rescue/podballoon.png")
const TEX_B := preload("res://assets/pixel/phippy-rescue/podballoon2.png")
const FRAME_W := 64
const FRAME_H := 64
const SCALE := 2.0

signal scored

# Falling speed in pixels per second.
@export var fall_speed := 120.0
var screen_h := 600.0
# 0 = sheet A, 1 = sheet B. Set before adding to the scene tree.
var color_index := 0

var _sprite: AnimatedSprite2D
var _caught := false


func _ready() -> void:
	add_to_group("balloon")
	collision_layer = 2
	collision_mask = 1 # only detect the player (layer 1)

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_apply_color()
	_sprite.scale = Vector2(SCALE, SCALE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.offset = Vector2(FRAME_W / 2.0, FRAME_H / 2.0)
	add_child(_sprite)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(FRAME_W * SCALE * 0.4, FRAME_H * SCALE * 0.6)
	col.shape = rect
	add_child(col)

	area_entered.connect(_on_area_entered)
	_sprite.play("float")


func _apply_color() -> void:
	if color_index % 2 == 0:
		return
	var tex: Texture2D = TEX_B
	for anim in ["float", "pop"]:
		for i in _sprite.sprite_frames.get_frame_count(anim):
			var at: AtlasTexture = _sprite.sprite_frames.get_frame_texture(anim, i)
			at.atlas = tex


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	# Row 0: balloon-with-pod gently bobbing (6 frames).
	sf.add_animation("float")
	for c in range(6):
		sf.add_frame("float", _atlas(TEX_A, c, 0))
	sf.set_animation_speed("float", 6.0)
	sf.set_animation_loop("float", true)

	# Rows 4-7: the balloon puffs up and pops. Played once on catch.
	sf.add_animation("pop")
	for spec in [[0, 4], [0, 5], [0, 6], [0, 7], [2, 7], [5, 7]]:
		sf.add_frame("pop", _atlas(TEX_A, spec[0], spec[1]))
	sf.set_animation_speed("pop", 14.0)
	sf.set_animation_loop("pop", false)
	return sf


func _atlas(tex: Texture2D, col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
	return at


func _on_area_entered(area: Area2D) -> void:
	if _caught:
		return
	if area.is_in_group("player"):
		_caught = true
		scored.emit()
		_sprite.play("pop")
		_sprite.animation_finished.connect(queue_free)


func _process(delta: float) -> void:
	if _caught:
		return
	position.y += fall_speed * delta
	# Gentle side-to-side drift so pods are trickier to catch.
	position.x += sin(Time.get_ticks_msec() * 0.003 + position.y * 0.01) * 18.0 * delta
	if position.y > screen_h + 80.0:
		queue_free() # missed
