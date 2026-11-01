extends CharacterBody2D

const motion = Vector2()

func _ready():
	pass

func _physics_process(delta):
	var player : CharacterBody2D = get_parent().get_node("Player")
	
	position += (player.position - position)/50
	look_at(player.position)
	
	move_and_collide(motion)


func _on_area_2d_body_entered(body):
	if body.get_meta("Tag") == "Bullet":
		queue_free()
		body.queue_free()
