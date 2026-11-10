class_name MineLamp
extends Node2D
# Шахтёрский фонарь на цепи. Его можно сбить выстрелом — тогда вокруг темнеет.

var glow_layer: CanvasLayer
var chain_len := 70.0
var _glow: Sprite2D
var _d: Destructible
var _chain: Line2D

func _ready() -> void:
	_chain = Line2D.new()
	_chain.points = PackedVector2Array([Vector2(0, -chain_len), Vector2(0, -10)])
	_chain.width = 3.0
	_chain.default_color = Color(0.32, 0.32, 0.36)
	_chain.z_index = -4
	add_child(_chain)
	_d = Destructible.new()
	_d.cell = 22.0
	_d.cols = 1
	_d.rows = 1
	_d.cell_hp = 8
	_d.anchored = true
	_d.anchors = [Vector2i(0, 0)]
	_d.color = Color(0.85, 0.65, 0.3)
	_d.mat_kind = "iron"
	add_child(_d)
	var spr := Sprite2D.new()
	var img := DeepArt.lamp_image()
	spr.texture = ImageTexture.create_from_image(img)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(3, 3)
	_d.add_child(spr)
	_glow = Torch.make_glow(420.0, Color(1.0, 0.78, 0.45, 0.85))
	_glow.position = global_position
	if glow_layer:
		glow_layer.add_child(_glow)
	_d.tree_exiting.connect(_out)

func _process(_dt: float) -> void:
	if is_instance_valid(_glow) and is_instance_valid(_d):
		_glow.position = global_position
		_glow.modulate.a = 0.7 + 0.05 * sin(Time.get_ticks_msec() * 0.004 + position.x)

# фонарь разбит — свет гаснет, цепь болтается
func _out() -> void:
	# срабатывает только когда разбит сам фонарь, а не когда уходит вся карта
	if not is_instance_valid(_d) or not _d.is_queued_for_deletion() or is_queued_for_deletion():
		return
	if is_instance_valid(_glow):
		var t := _glow.create_tween()
		t.tween_property(_glow, "modulate:a", 0.0, 0.5)
		t.tween_callback(_glow.queue_free)
	if is_instance_valid(_chain):
		_chain.points = PackedVector2Array([Vector2(0, -chain_len), Vector2(6, -chain_len * 0.5)])
	Fx.sparks.call_deferred(get_parent(), global_position, Color(1.0, 0.8, 0.4), 10, 220.0, 3.0)
