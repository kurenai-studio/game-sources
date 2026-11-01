extends Area2D

@export_enum("health", "rapid", "damage") var pickup_kind: String = "health"
var life: float = 14.0
var time: float = 0.0
var tint := Color("45ff9a")

const BURST := preload("res://scripts/effects/EffectBurst.gd")

func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	match pickup_kind:
		"rapid": tint = Color("ffe45d")
		"damage": tint = Color("ff58c7")
		_: tint = Color("45ff9a")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 15.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_collected)

func _process(delta: float) -> void:
	time += delta
	life -= delta
	rotation += delta * 1.5
	queue_redraw()
	if life <= 0.0:
		queue_free()

func _collected(body: Node) -> void:
	if body.is_in_group("player"):
		body.apply_pickup(pickup_kind)
		AudioManager.play_pickup()
		BURST.spawn(get_tree().current_scene, global_position, tint, 14, 16.0)
		queue_free()

func _draw() -> void:
	var pulse := 1.0 + sin(time * 5.0) * 0.12
	draw_circle(Vector2.ZERO, 23.0 * pulse, Color(tint, 0.10))
	var diamond := PackedVector2Array([Vector2(0, -14), Vector2(14, 0), Vector2(0, 14), Vector2(-14, 0)])
	draw_colored_polygon(diamond, Color("101426"))
	draw_polyline(PackedVector2Array(diamond + PackedVector2Array([diamond[0]])), tint, 3.0)
	if pickup_kind == "health":
		draw_rect(Rect2(-3, -9, 6, 18), tint)
		draw_rect(Rect2(-9, -3, 18, 6), tint)
	elif pickup_kind == "rapid":
		draw_polyline(PackedVector2Array([Vector2(-7,-9),Vector2(2,-3),Vector2(-2,1),Vector2(8,9)]), tint, 4.0)
	else:
		draw_circle(Vector2.ZERO, 6.0, tint)

