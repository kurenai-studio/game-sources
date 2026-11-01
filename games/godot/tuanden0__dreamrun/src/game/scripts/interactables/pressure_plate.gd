## Floor plate pressed by the player or a crate standing on it. Emits pressed_changed; sinks while pressed.
## Origin is the floor line.
class_name PressurePlate
extends Area2D

signal pressed_changed(pressed: bool)

@export var size := Vector2(90.0, 10.0)
@export var sink_depth := 6.0
@export var shape_seed := 9
@export var color := Color(0.03, 0.03, 0.035)

var is_pressed := false

var _weight := 0
var _slab: Polygon2D
var _tween: Tween


func _ready() -> void:
	var outline := SolidProp.build_outline(SolidProp.Kind.SLAB, size, shape_seed, 1.6)
	_slab = Polygon2D.new()
	_slab.name = &"Slab"
	_slab.polygon = outline
	_slab.position = Vector2(0.0, -size.y * 0.5 + 2.0)  # top sits 2 px proud of the floor
	_slab.color = color
	_slab.antialiased = true
	add_child(_slab)
	# Sensor hovers above the slab: only things standing on it overlap it.
	var sensor := CollisionShape2D.new()
	sensor.shape = RectangleShape2D.new()
	sensor.shape.size = Vector2(size.x * 0.7, 20.0)
	sensor.position = Vector2(0.0, -14.0)
	add_child(sensor)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _counts(body: Node) -> bool:
	return body.is_in_group(&"player") or body.is_in_group(&"grabbable")


func _on_body_entered(body: Node) -> void:
	if _counts(body):
		_weight += 1
		_update()


func _on_body_exited(body: Node) -> void:
	if _counts(body):
		_weight -= 1
		_update()


func _update() -> void:
	var pressed := _weight > 0
	if pressed == is_pressed:
		return
	is_pressed = pressed
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_slab, "position:y", -size.y * 0.5 + 2.0 + (sink_depth if pressed else 0.0), 0.12)
	pressed_changed.emit(pressed)
