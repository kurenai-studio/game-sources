extends Area2D

@onready var despawn_timer = $DespawnTimer
@onready var coll_shape = $CollisionShape2D
@onready var sprite = $Proj

var damage = 15
var speed = 100;
var pierce = 3;
var dir = Vector2.UP
var lifespan = 0.2
var size = 1
var buff_bonus = 1
var effect = "Null"
var effect_rate = 0
var permanent = false

signal remove_from_array(object)

# juke projectile. fires disregarding direction, and grows over time
func _ready():
	despawn_timer.wait_time = lifespan*size
	despawn_timer.start()
	
	var tween : Tween = create_tween();
	tween.tween_property(self,"modulate",Color(1.0,1.0,1.0,0.0),lifespan*size).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	scale += Vector2(1,1)*delta*speed

func _on_despawn_timer_timeout():
	destroy();

func enemy_hit():
	pierce -= 1;
	if pierce <= 0:
		destroy();

func destroy():
	emit_signal("remove_from_array", self);
	queue_free()
