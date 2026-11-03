extends CharacterBody2D

var LIFETIME: float
var FADE_TIME: float
var damage: int = 2

var timer: float = 0.0
var valid: bool = true


func _ready() -> void:
	var c: Dictionary = Config.data["enemy_bullet"]
	LIFETIME = c["lifetime"]
	FADE_TIME = c["fade_time"]
	damage = int(c["damage"])
	$Hitter.body_entered.connect(_on_hitter_body_entered)


func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= LIFETIME and valid:
		valid = false
		_fade_out()
	move_and_slide()


func _on_hitter_body_entered(body: Node2D) -> void:
	if body is Player:
		body.get_damage(damage)
		valid = false
		_fade_out(true)


func _fade_out(shrink := false) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	if shrink:
		t.parallel().tween_property(self, "scale", Vector2.ZERO, FADE_TIME)
	t.tween_callback(queue_free)
