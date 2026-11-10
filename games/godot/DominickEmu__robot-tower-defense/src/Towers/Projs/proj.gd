extends Area2D

@onready var despawn_timer = $DespawnTimer

var damage = 15
var speed = 100;
var pierce = 3;
var dir = Vector2.UP
var lifespan = 0.2
var size = 1
var effect = "Null"
var effect_rate = 0

signal remove_from_array(object)

# regular projectile. fires in direction of robot
func _ready():
	despawn_timer.wait_time = lifespan
	scale *= size
	despawn_timer.start()


func _physics_process(delta):
	global_position += speed*delta*dir

func _on_despawn_timer_timeout():
	destroy();

func enemy_hit():
	pierce -= 1;
	if pierce <= 0:
		destroy();

func destroy():
	emit_signal("remove_from_array", self);
	queue_free()
