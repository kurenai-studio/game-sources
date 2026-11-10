class_name TntCrate
extends Node2D
# ---------- Ящик с динамитом (Драгоценные пещеры) ----------
# Красный ящик с надписью. Выбей из него пару клеток — и он взрывается,
# раня всех вокруг (героя тоже!) и поджигая соседние ящики — цепная реакция.

var _d: Destructible
var _broken := 0
var _boom := false

func _ready() -> void:
	_d = Destructible.new()
	_d.cell = 20.0
	_d.cols = 3
	_d.rows = 3
	_d.cell_hp = 18
	_d.density = 10.0
	_d.color = Color(0.72, 0.16, 0.12)
	_d.mat_kind = "crate"
	# сам ящик — прямо в мире (как все разрушаемые): так его задевают и взрывы
	_d.position = position
	get_parent().add_child.call_deferred(_d)
	_d.cells_removed.connect(_on_removed)
	var lbl := Label.new()
	lbl.text = "TNT"
	lbl.position = Vector2(-28, -12)
	lbl.size = Vector2(56, 24)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_color_override("font_outline_color", Color(0.25, 0.05, 0.03))
	_d.add_child(lbl)
	var fuse := Line2D.new()
	fuse.points = PackedVector2Array([Vector2(8, -30), Vector2(14, -40), Vector2(10, -46)])
	fuse.width = 2.0
	fuse.default_color = Color(0.3, 0.25, 0.2)
	_d.add_child(fuse)

func _on_removed(count: int, attacker, _at: Vector2) -> void:
	_broken += count
	if _broken >= 2 and not _boom:
		_boom = true
		var world := get_parent()
		var at := global_position
		var who = attacker
		var tw := create_tween()             # твин живёт вместе с ящиком — не сработает после смены арены
		tw.tween_interval(0.12)
		tw.tween_callback(func():
			if not is_instance_valid(world):
				return
			Util.explode(world, at, 150.0, 30, 70, -1, who if is_instance_valid(who) else null, true)
			Fx.ring(world, at, 170.0, Color(1.0, 0.55, 0.15, 0.95), 0.4, 9.0)
			Fx.sparks(world, at, Color(1.0, 0.6, 0.2), 24, 380.0, 6.0)
			if is_instance_valid(_d):
				Fx.sparks(world, at, Color(0.72, 0.16, 0.12), 10, 300.0, 6.0)
				_d.queue_free()
			queue_free())
