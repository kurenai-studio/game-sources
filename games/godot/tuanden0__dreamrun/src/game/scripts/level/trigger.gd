## Invisible zone that fires `triggered` when the player enters (once by default). Wire the signal in the
## scene, e.g. to Monster.start. Fired state is restored with the checkpoint.
class_name Trigger
extends Area2D

signal triggered

@export var size := Vector2(60.0, 300.0)
@export var one_shot := true

var fired := false

var _saved_fired := false


func _ready() -> void:
	add_to_group(&"resettable")
	var zone := CollisionShape2D.new()
	zone.shape = RectangleShape2D.new()
	zone.shape.size = size
	zone.position = Vector2(0.0, -size.y * 0.5)
	add_child(zone)
	body_entered.connect(_on_body_entered)


func save_checkpoint() -> void:
	_saved_fired = fired


func reset_to_checkpoint() -> void:
	fired = _saved_fired


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and not (one_shot and fired):
		fired = true
		triggered.emit()
