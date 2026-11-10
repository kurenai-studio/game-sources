class_name IceBlock
extends StaticBody2D


func smash() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	get_node("Sprite2D").visible = false
	var particles := get_node("Particles") as CPUParticles2D
	particles.restart()
	particles.emitting = true
	$SmashSound.play() 


func _on_particles_finished() -> void:
	queue_free()
