extends Label
class_name AttackingNumber

enum MoveMode{
	GRAVITY,
	STRAIGHT
}

var origin_pos:Vector2=Vector2.ZERO
var velocity:Vector2=Vector2.ZERO
var valid:bool=true
var motion_mode:MoveMode=MoveMode.STRAIGHT
var timer:float=0.0

# 配置数据（游戏启动时由 Config 一次性写入，见 _apply_config）
var _gravity_vel_y: Array = []
var _gravity_vel_x: Array = []
var _straight_speed: Array = []
var _gravity: float = 9.8
var _lifetime: float = 0.7

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_config()
	global_position=origin_pos
	if motion_mode==MoveMode.GRAVITY:
		velocity.y=randf_range(_gravity_vel_y[0],_gravity_vel_y[1])
		velocity.x=randf_range(_gravity_vel_x[0],_gravity_vel_x[1])
		var t = create_tween()
		t.tween_property(self,"scale",Vector2.ONE*2.0,0.35).set_ease(Tween.EASE_OUT)
		t.tween_property(self,"scale",Vector2.ZERO,0.35).set_ease(Tween.EASE_IN)
	else:
		var player:Player=get_tree().get_first_node_in_group("player")
		velocity=(origin_pos-player.global_position).normalized()*randf_range(_straight_speed[0],_straight_speed[1])

func _apply_config() -> void:
	var c: Dictionary = Config.data["attacking_number"]
	_gravity_vel_y = c["gravity_velocity_y"]
	_gravity_vel_x = c["gravity_velocity_x"]
	_straight_speed = c["straight_speed"]
	_gravity = c["gravity"]
	_lifetime = c["lifetime"]

func destroy():
	var t=create_tween()
	t.tween_property(self,"modulate:a",0.0,0.5)
	t.tween_callback(queue_free)

func set_motion_mode(mode:MoveMode):
	motion_mode=mode

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer+=delta
	if motion_mode==MoveMode.GRAVITY:
		velocity.y+=_gravity
	else:
		velocity*=0.9
	if timer>=_lifetime:
		if valid:
			valid=false
			destroy()
	position+=velocity*delta
	
		
