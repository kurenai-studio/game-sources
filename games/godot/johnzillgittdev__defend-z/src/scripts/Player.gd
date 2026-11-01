extends Area2D

signal hit
@export var arrow_scene: PackedScene
var is_dead: bool = false

func _ready():
	$AnimatedSprite2D.play("idle")

func update_state(skel_count: int) -> void:
	if is_dead:
		return
	
	if skel_count > 0:
		if $AnimatedSprite2D.animation != "attack":
			$AnimatedSprite2D.play("attack")
	else:
		if $AnimatedSprite2D.animation != "idle":
			$AnimatedSprite2D.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if ($AnimatedSprite2D.animation != "death"):
		hit.emit()
		is_dead = true
		$AnimatedSprite2D.play("death")


func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "death":
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 9

func fire_arrow():
	var arrow = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = $BowPoint.global_position
	arrow.direction = Vector2.RIGHT

func _on_animated_sprite_2d_frame_changed() -> void:
	if $AnimatedSprite2D.animation == "attack":
		if $AnimatedSprite2D.frame == 7:
			fire_arrow()
