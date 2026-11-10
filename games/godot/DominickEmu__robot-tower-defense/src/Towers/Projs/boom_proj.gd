extends Area2D

@onready var despawn_timer = $DespawnTimer
@onready var boom_rad = %BoomRad
@onready var boom_duration = $BoomDuration
@onready var explosion = $Explosion
@onready var boom_area = $BoomArea

var damage = 15
var speed = 100;
var pierce = 3;
var dir = Vector2.UP
var lifespan = 0.2
var size = 1
var effect = "Null"
var effect_rate = 0

var detonated = false;

signal remove_from_array(object)

func _ready():
	despawn_timer.wait_time = lifespan
	scale *= size
	despawn_timer.start()


func _physics_process(delta):
	global_position += speed*delta*dir

func _on_despawn_timer_timeout():
	destroy();

func enemy_hit():
	if !detonated:
		boom()
		detonated = true

# difference between proj and this. triggers bigger blast radius, and destroys itself
func boom():
	explosion.visible = true;
	speed = 0
	boom_duration.start()
	
	for i in boom_area.get_overlapping_bodies():
		if i is CharacterBody2D:
			i._on_hitbox_area_entered(self);

func destroy():
	emit_signal("remove_from_array", self);
	queue_free()

func _on_boom_duration_timeout():
	destroy()
