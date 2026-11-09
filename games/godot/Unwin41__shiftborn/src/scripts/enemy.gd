class_name Enemy
extends Area2D
## Basic chaser. Walks toward [member target] and deals contact damage
## per second while touching it. [HordeSpawner] sets the target.
## Needs an AnimatedSprite2D child named "Sprite" with a "run" animation.

signal died(enemy: Enemy)
## [param resisted] is true when the hit came from the form it resists;
## [param crit] when it was a critical hit.
signal damaged(enemy: Enemy, amount: float, resisted: bool, crit: bool)

const PLAYER_RADIUS := 7.0
const HIT_FLASH_TIME := 0.08
## Values above 1 push sprite pixels toward white for the hit flash.
const HIT_FLASH_MODULATE := Color(8.0, 8.0, 8.0)
## Knockback speed decays by this rate per second (exponential), so an
## impulse of speed v slides the enemy about v / rate pixels.
const KNOCKBACK_DECAY := 10.0
## Death pop: flash, squash and fade before the node is freed.
const DEATH_TIME := 0.2
const DEATH_SCALE := Vector2(1.5, 0.3)
## "No form": a neutral damage source, or an enemy that resists nothing.
const NO_FORM := -1
## Share of damage taken from the resisted form.
const RESISTED_DAMAGE := 0.0
## Gap between the top of the sprite and the weakness mark.
const WEAKNESS_MARK_GAP := 4.0
const SHADOW_TEXTURE := preload("res://assets/ninja/characters/shadow.png")
## Sprite width the shadow texture is drawn for.
const SHADOW_BASE_WIDTH := 16.0
## How far up from the sprite's bottom edge the shadow sits.
const SHADOW_LIFT := 3.0

@export var move_speed: float = 45.0
@export var max_health: float = 3.0
@export var contact_dps: float = 2.0
@export var body_radius: float = 6.0
## XP granted to the player on death.
@export var xp_value: int = 1
## Color of the burst when this enemy dies.
@export var particle_color: Color = Color(0.9, 0.3, 0.35)
## Particles in that burst; bigger enemies make bigger bursts.
@export var particle_count: int = 6
## On death the run spawns [member split_count] of this scene in its place.
@export var split_scene: PackedScene
@export var split_count: int = 2
## Form this enemy is immune to: its attacks deal [constant RESISTED_DAMAGE]
## of their damage (none). Damage without a form (Shift Burst, evolutions)
## still lands.
@export_enum("None:-1", "Warrior:0", "Mage:1") var resisted_form: int = NO_FORM

var target: Node2D
var health: float

var _hit_flash: float = 0.0
var _weakness_mark: WeaknessMark
var _facing: StringName = Facing.DOWN
var _shadow: Node2D

## Opaque area of a frame texture, cached per texture: reading pixels back
## is slow and hundreds of enemies share a few textures.
static var _visible_rects: Dictionary[int, Rect2] = {}
var _knockback_velocity: Vector2 = Vector2.ZERO

@onready var _sprite: AnimatedSprite2D = $Sprite


static func damage_after_resist(amount: float, resisted: int, source_form: int) -> float:
	if resisted != NO_FORM and source_form == resisted:
		return amount * RESISTED_DAMAGE
	return amount


## The form that beats an enemy resisting [param resisted].
static func weak_form_for(resisted: int) -> Player.Form:
	return Player.Form.MAGE if resisted == Player.Form.KNIGHT else Player.Form.KNIGHT


func resists(source_form: int) -> bool:
	return resisted_form != NO_FORM and source_form == resisted_form


## Changes the resisted form at runtime and updates the weakness mark.
func set_resisted_form(form: int) -> void:
	resisted_form = form
	if form == NO_FORM:
		if _weakness_mark != null:
			_weakness_mark.hide()
		return
	if _weakness_mark == null:
		_weakness_mark = WeaknessMark.create(weak_form_for(form), _weakness_mark_offset())
		add_child(_weakness_mark)
	_weakness_mark.set_weak_to(weak_form_for(form))
	_weakness_mark.show()


func _ready() -> void:
	health = max_health
	set_resisted_form(resisted_form)
	_add_shadow()
	_sprite.play(Facing.walk_animation(_sprite.sprite_frames, _facing))
	# Desync animations so a crowd does not bob in lockstep.
	_sprite.frame = randi() % maxi(_sprite.sprite_frames.get_frame_count(_sprite.animation), 1)


func _physics_process(delta: float) -> void:
	_update_hit_flash(delta)
	_update_knockback(delta)
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	_face(offset)
	if distance > body_radius + PLAYER_RADIUS:
		global_position += offset / distance * move_speed * delta
	elif target.has_method("take_damage"):
		target.take_damage(contact_dps * delta)


## [param source_form] is the attacking form, or [constant NO_FORM] for
## damage that ignores resistance (Shift Burst).
func take_damage(amount: float, source_form: int = NO_FORM, crit: bool = false) -> void:
	if health <= 0.0:
		return
	var resisted := resists(source_form)
	var final_amount := damage_after_resist(amount, resisted_form, source_form)
	if final_amount <= 0.0:
		# Immune: report the hit (an IMMUNE popup) but no flash, no damage.
		damaged.emit(self, 0.0, resisted, false)
		return
	var dealt := minf(final_amount, health)
	health -= final_amount
	damaged.emit(self, dealt, resisted, crit)
	_hit_flash = HIT_FLASH_TIME
	_sprite.modulate = HIT_FLASH_MODULATE
	if health <= 0.0:
		_die()


## Leaves every gameplay group and stops colliding at once, so targeting,
## bolts and the alive count ignore the corpse while the death pop plays.
func _die() -> void:
	died.emit(self)
	AudioManager.play(&"enemy_death")
	for group in get_groups():
		if not String(group).begins_with("_"):
			remove_from_group(group)
	set_deferred(&"monitorable", false)
	set_physics_process(false)
	if _weakness_mark != null:
		_weakness_mark.hide()
	if _shadow != null:
		_shadow.hide()
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, ^"scale", DEATH_SCALE, DEATH_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, ^"modulate", Color(HIT_FLASH_MODULATE, 0.0), DEATH_TIME)
	tween.chain().tween_callback(queue_free)


## Pushes the enemy with [param impulse] (px/s), fading out quickly.
func knockback(impulse: Vector2) -> void:
	_knockback_velocity += impulse


func _update_knockback(delta: float) -> void:
	if _knockback_velocity.is_zero_approx():
		return
	global_position += _knockback_velocity * delta
	_knockback_velocity *= exp(-KNOCKBACK_DECAY * delta)
	if _knockback_velocity.length_squared() < 1.0:
		_knockback_velocity = Vector2.ZERO


## Turns toward [param offset]: four-way animations when the sprite has
## them, a horizontal flip otherwise (boss strips).
func _face(offset: Vector2) -> void:
	var frames := _sprite.sprite_frames
	if not Facing.is_directional(frames):
		if not is_zero_approx(offset.x):
			_sprite.flip_h = offset.x < 0.0
		return
	var next := Facing.from_vector(offset, _facing)
	if next != _facing:
		_facing = next
		var frame := _sprite.frame
		_sprite.play(Facing.walk_animation(frames, _facing))
		_sprite.frame = frame


## A shadow under the feet: the pixel shadow for small sprites, a soft
## ellipse for big ones (a scaled pixel shadow turns into a black block).
func _add_shadow() -> void:
	var bounds := _visible_bounds()
	var width := bounds.size.x
	var feet := bounds.end.y
	if width > SHADOW_BASE_WIDTH * 1.5:
		_shadow = EllipseShadow.create(width, Vector2(0.0, feet - width * 0.12))
	else:
		var sprite_shadow := Sprite2D.new()
		sprite_shadow.texture = SHADOW_TEXTURE
		sprite_shadow.position = Vector2(0.0, feet - SHADOW_LIFT)
		sprite_shadow.show_behind_parent = true
		_shadow = sprite_shadow
	add_child(_shadow)


func _first_frame() -> Texture2D:
	return _sprite.sprite_frames.get_frame_texture(_sprite.animation, 0)


## Just above the top of the drawn pixels, whatever the sprite's size.
func _weakness_mark_offset() -> Vector2:
	return Vector2(0.0, _visible_bounds().position.y - WEAKNESS_MARK_GAP)


## The non-transparent part of the first frame, in this node's space.
## Frames have empty margins (16 px cells, 82 px boss strips), so the
## full frame size would float marks and shadows away from the body.
func _visible_bounds() -> Rect2:
	var frame := _first_frame()
	if frame == null:
		return Rect2(-8.0, -8.0, 16.0, 16.0)
	var used := Rect2(Vector2.ZERO, frame.get_size())
	var key := frame.get_instance_id()
	if _visible_rects.has(key):
		used = _visible_rects[key]
	else:
		# get_image() can be null without a real renderer (headless tests).
		var image := frame.get_image()
		if image != null and not image.is_empty():
			used = Rect2(image.get_used_rect())
		_visible_rects[key] = used
	var top_left := (used.position - frame.get_size() * 0.5) * _sprite.scale + _sprite.position + _sprite.offset
	return Rect2(top_left, used.size * _sprite.scale)


func _update_hit_flash(delta: float) -> void:
	if _hit_flash <= 0.0:
		return
	_hit_flash -= delta
	if _hit_flash <= 0.0:
		_sprite.modulate = Color.WHITE
