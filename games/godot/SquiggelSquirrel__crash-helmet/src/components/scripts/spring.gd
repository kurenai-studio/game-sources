extends Area2D

const BOUNCE_STRENGTH := 100.0
var _bounce_direction :Vector2
var _bouncer_reset := 0.0


func _ready() -> void:
	if rotation < -0.75 * PI or rotation > 0.25 * PI:
		$Bouncer.flip_v = true
	_bounce_direction = Vector2.RIGHT.rotated(rotation)


func _process(delta: float) -> void:
	_bouncer_reset = clampf(_bouncer_reset - delta, 0.0, 1.0)
	if _bouncer_reset == 0.0:
		$Bouncer.position = Vector2.ZERO


func _on_body_entered(body: CharacterBody2D) -> void:
	if body == null:
		return
	$Sound.play()
	body.velocity = (
			body.velocity.bounce(_bounce_direction) * 1.5
			+ BOUNCE_STRENGTH * _bounce_direction)
	var min_bounce := BOUNCE_STRENGTH * 2.0 * _bounce_direction
	if body.velocity.length_squared() < min_bounce.length_squared():
		body.velocity = min_bounce
	if body.has_method("bounce"):
		body.bounce()
	$Bouncer.position = Vector2(11.0, 0.0)
	_bouncer_reset = 1.0
