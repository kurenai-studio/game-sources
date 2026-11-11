class_name Egg
extends Unit

func _ready() -> void:
	set_sprite(preload("res://src/egg_sprite.tscn").instantiate() as Sprite2D)
	super()

func _physics_process(_delta: float) -> void:
	update_z_index()

	for i: int in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(i)

		if (
			collision.get_collider() is Mother
			and not Mother.get_singleton().is_broken()
			and not is_broken()
		):
			Mother.get_singleton().feed_mother()
			queue_free()

	super(_delta)

	set_velocity(Vector3(0, get_velocity().y, 0))
