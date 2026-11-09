extends Area3D
class_name ExitPortal

signal chamber_completed

@export var portal_color: Color = Color(0.0, 0.9, 1.0)
var is_triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Gentle rotation animation
	var ring = get_node_or_null("PortalRing")
	if ring:
		ring.rotate_z(1.5 * delta)

func _on_body_entered(body: Node3D):
	if is_triggered:
		return
	if body is CharacterBody3D: # Player
		is_triggered = true
		if SoundManager.instance:
			SoundManager.instance.play("portal_enter", 1.0, 2.0)
		chamber_completed.emit()
