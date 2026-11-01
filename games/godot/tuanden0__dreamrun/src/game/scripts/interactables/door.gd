## Stone gate that slides open. Opens slowly, slams shut fast (weight). Wire a trigger's signal to set_open.
## It never closes on anything: while the player or a crate is in the gateway it stays up, and it comes down as soon
## as the way is clear (so a crate or a person is never shoved out of the floor by a falling door).
class_name Door
extends SolidProp

@export var open_offset := Vector2(0.0, -260.0)
@export var open_time := 0.9
@export var close_time := 0.45

## Logical state: false as soon as it was told to close, even while something still holds it up.
var is_open := false

var _closed_position := Vector2.ZERO
var _tween: Tween
var _gateway: Area2D
var _closing := false  # told to close, waiting for the gateway to clear

var _saved_open := false


func _ready() -> void:
	super()
	add_to_group(&"resettable")
	_closed_position = position
	# the gateway stays where the door shuts, whatever the door is doing
	_gateway = Area2D.new()
	_gateway.name = "Gateway"
	_gateway.top_level = true
	_gateway.global_position = global_position
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = size + Vector2(8.0, 0.0)
	_gateway.add_child(shape)
	add_child(_gateway)
	set_physics_process(false)


## True while it is up only because something is in the way.
func is_held_up() -> bool:
	return _closing


func save_checkpoint() -> void:
	_saved_open = is_open


func reset_to_checkpoint() -> void:
	if _tween != null:
		_tween.kill()
	_closing = false
	set_physics_process(false)
	is_open = _saved_open
	position = _closed_position + (open_offset if is_open else Vector2.ZERO)


func set_open(value: bool) -> void:
	if value == is_open:
		return
	is_open = value
	if _tween != null:
		_tween.kill()
	if value:
		_closing = false
		set_physics_process(false)
		_tween = create_tween()
		_tween.tween_property(self, "position", _closed_position + open_offset, open_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		_closing = true
		set_physics_process(true)  # shuts as soon as the gateway is clear, which may be this very frame
		_try_to_close()


func _physics_process(_delta: float) -> void:
	_try_to_close()


func _try_to_close() -> void:
	if not _closing or _blocked():
		return
	_closing = false
	set_physics_process(false)
	_tween = create_tween()
	_tween.tween_property(self, "position", _closed_position, close_time) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _blocked() -> bool:
	for body in _gateway.get_overlapping_bodies():
		if body.is_in_group(&"player") or body.is_in_group(&"grabbable"):
			return true
	return false
