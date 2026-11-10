class_name Weather
extends CanvasLayer
# ---------- Погода поверх арены ----------
# Частицы рисуются в экранных координатах (их немного — только то, что видно),
# но сдвигаются вместе с камерой, поэтому кажутся частью мира.
#   snow — снегопад: хлопья разного размера плавно кружат и падают;
#   rain — косой ливень, наклон зависит от ветра (wind); flashes — вспышки молний;
#   soot — сажа медленно оседает, снизу поднимаются искры.
# wind (-1..1) меняет механика «Порывы ветра» Храма шторма.

var mode := "snow"
var wind := 0.0
var flashes := false
var gust_dir := 0                 # стрелка порыва: 0 — нет, ±1 — куда дует (подсказка на экране)
var _parts: Array = []            # [x, y, скорость, размер, фаза]
var _canvas: Node2D
var _last_cam := Vector2.INF
var _flash: ColorRect
var _flash_t := 5.0
var _t := 0.0

func _ready() -> void:
	layer = 2
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_draw_parts)
	var vs := _screen()
	var n: int = {"snow": 170, "rain": 260, "soot": 150, "embers": 60}.get(mode, 120)
	for i in n:
		_parts.append(_new_part(vs, true))
	if flashes:
		_flash = ColorRect.new()
		_flash.color = Color(0.85, 0.9, 1.0, 0.0)
		_flash.size = vs
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_flash)

func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1600, 720)

func _new_part(vs: Vector2, anywhere: bool) -> Array:
	var x := randf_range(-40.0, vs.x + 40.0)
	var y := randf_range(-40.0, vs.y) if anywhere else -randf_range(5.0, 60.0)
	match mode:
		"snow":
			return [x, y, randf_range(40.0, 110.0), randf_range(2.0, 5.0), randf() * TAU]
		"rain":
			return [x, y, randf_range(900.0, 1300.0), randf_range(14.0, 26.0), randf()]
		_:
			# сажа (падает) или искра (поднимается): знак скорости
			var ember := randf() < 0.3 or mode == "embers"
			if ember and not anywhere:
				y = vs.y + randf_range(5.0, 40.0)
			return [x, y, randf_range(-90.0, -40.0) if ember else randf_range(25.0, 70.0), randf_range(2.0, 4.0), randf() * TAU]

func _process(delta: float) -> void:
	_t += delta
	var vs := _screen()
	# сдвиг вместе с камерой
	var cam := get_viewport().get_camera_2d()
	var shift := Vector2.ZERO
	if cam:
		var cp := cam.get_screen_center_position()
		if _last_cam != Vector2.INF:
			shift = (cp - _last_cam) * cam.zoom.x
		_last_cam = cp
	if shift.length() > 400.0:
		shift = Vector2.ZERO               # камеру перенесли (перестройка арены) — не тянем частицы
	for p in _parts:
		p[0] -= shift.x
		p[1] -= shift.y
		match mode:
			"snow":
				p[4] += delta * 1.6
				p[0] += (sin(p[4]) * 30.0 + wind * 260.0) * delta
				p[1] += p[2] * delta
			"rain":
				p[0] += (wind * 520.0 + 120.0) * delta
				p[1] += p[2] * delta
			_:
				p[4] += delta * 2.0
				p[0] += (sin(p[4]) * 20.0 + 25.0 + wind * 200.0) * delta
				p[1] += p[2] * delta
		if p[1] > vs.y + 60.0 or p[1] < -80.0 or p[0] < -120.0 or p[0] > vs.x + 120.0:
			var np := _new_part(vs, false)
			if p[0] < -120.0 or p[0] > vs.x + 120.0:
				np[0] = vs.x + 40.0 if p[0] < -120.0 else -40.0
				np[1] = randf_range(0.0, vs.y)
			if mode in ["soot", "embers"] and p[2] < 0.0 and p[1] < -80.0:
				np[1] = vs.y + randf_range(5.0, 40.0)
			for i in 5:
				p[i] = np[i]
	if flashes and _flash:
		_flash.size = vs
		_flash_t -= delta
		if _flash_t <= 0.0:
			_flash_t = randf_range(6.0, 13.0)
			_lightning()
	_canvas.queue_redraw()

# Вспышка молнии: экран дважды белеет, через миг — дальний раскат (лёгкая тряска)
func _lightning() -> void:
	var t := _flash.create_tween()
	t.tween_property(_flash, "color:a", 0.32, 0.05)
	t.tween_property(_flash, "color:a", 0.0, 0.12)
	t.tween_property(_flash, "color:a", 0.22, 0.05)
	t.tween_property(_flash, "color:a", 0.0, 0.35)
	var world := get_parent()
	t.tween_interval(0.5)
	t.tween_callback(func():
		if is_instance_valid(world) and world is Node2D:
			Fx.shake(world, 3.0))

func _draw_parts() -> void:
	var vs := _screen()
	match mode:
		"snow":
			for p in _parts:
				var s: float = p[3]
				var a := 0.55 + 0.35 * (s - 2.0) / 3.0
				_canvas.draw_rect(Rect2(p[0], p[1], s, s), Color(0.92, 0.96, 1.0, a))
		"rain":
			var dir := Vector2(wind * 520.0 + 120.0, 1100.0).normalized()
			for p in _parts:
				var a := Vector2(p[0], p[1])
				_canvas.draw_line(a, a + dir * float(p[3]), Color(0.72, 0.80, 0.95, 0.38), 2.0)
		_:
			for p in _parts:
				var s: float = p[3]
				if p[2] < 0.0:
					var fl := 0.6 + 0.4 * sin(p[4] * 3.0)
					_canvas.draw_rect(Rect2(p[0], p[1], s * 0.8, s * 0.8), Color(1.0, 0.55 + 0.2 * fl, 0.2, 0.75 * fl))
				else:
					_canvas.draw_rect(Rect2(p[0], p[1], s, s), Color(0.08, 0.06, 0.06, 0.7))
	# стрелка порыва ветра: прозрачные «шевроны» поперёк экрана
	if gust_dir != 0:
		var k := 0.5 + 0.5 * sin(_t * 8.0)
		for i in 3:
			var cx := vs.x / 2 + (i - 1) * 46.0 + fmod(_t * 160.0, 46.0) * gust_dir
			var cy := 150.0
			var g := float(gust_dir)
			var pts := PackedVector2Array([Vector2(cx - 14 * g, cy - 22), Vector2(cx + 12 * g, cy), Vector2(cx - 14 * g, cy + 22)])
			_canvas.draw_polyline(pts, Color(0.85, 0.92, 1.0, 0.35 + 0.35 * k), 6.0)
