class_name RunawayCart
extends Node2D
# Сорвавшаяся вагонетка: катится по полу и сбивает героев (вагонетчик, Барон Грызь)

var dir := 1.0
var speed := 640.0
var damage := 16
var team := 1
var attacker: Node
var floor_y := 940.0
var _life := 4.5
var _hit := {}
const K := 3.4

func _ready() -> void:
	var img := DeepArt.cart_image()
	BotRig._volume(img)
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(K * dir, K)
	add_child(s)
	position.y = floor_y - 16 * K / 2

func _physics_process(delta: float) -> void:
	_life -= delta
	position.x += dir * speed * delta
	rotation = sin(Time.get_ticks_msec() * 0.04) * 0.03
	if randf() < 0.3:
		Fx.sparks(get_parent(), global_position + Vector2(-dir * 30, 26), Color(1.0, 0.8, 0.4), 1, 120.0, 2.0)
	for n in get_parent().get_children():
		if n is Player and n.is_alive() and n.team != team and not _hit.has(n):
			if absf(n.global_position.x - global_position.x) < 50.0 + n.body_size.x / 2 \
					and absf(n.global_position.y + n.body_size.y / 2 - floor_y) < 40.0:
				_hit[n] = true
				n.take_damage(damage, attacker if is_instance_valid(attacker) else null)
				n.velocity = Vector2(dir * 650.0, -420.0)
	if _life <= 0.0 or position.x < 60.0 or position.x > Colosseum.W - 60.0:
		Fx.sparks(get_parent(), global_position, Color(0.6, 0.5, 0.4), 10, 200.0, 4.0)
		queue_free()
