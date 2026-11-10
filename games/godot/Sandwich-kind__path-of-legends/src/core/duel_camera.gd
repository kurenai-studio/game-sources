class_name DuelCamera
extends Camera2D
# Камера режима на двоих.
#   follow = false — показывает всю арену целиком (TEST_FIELD).
#   follow = true  — держит обоих игроков в кадре: сходятся — приближает,
#                    расходятся — отдаляет. За стены и под пол не заглядывает.
# Нижняя часть экрана занята панелью кнопок, камера это учитывает.

var targets: Array = []
var bounds := Rect2(0, 0, Config.W, Config.H)   # границы карты
var follow := false
var open_top := false        # над картой небо — его можно показывать
var max_zoom := 1.0          # сильнее этого не приближает
var min_zoom := 0.0          # дальше этого не отдаляет (на огромных картах экран делится)
var margin := Vector2(260.0, 200.0)   # запас вокруг игроков

var _center := Vector2.ZERO
var _z := 1.0
var _first := true

func _ready() -> void:
	make_current()

func _process(delta: float) -> void:
	var vs := get_viewport_rect().size
	var play := Vector2(vs.x, vs.y - Config.panel())   # видимая часть над панелью
	var want_center: Vector2
	var want_z: float
	if not follow:
		want_center = bounds.get_center()
		want_z = minf(play.x / bounds.size.x, play.y / bounds.size.y)
	else:
		var box := Rect2()
		var any := false
		for t in targets:
			if is_instance_valid(t) and t.is_alive():
				if not any:
					box = Rect2(t.global_position, Vector2.ZERO)
					any = true
				else:
					box = box.expand(t.global_position)
		if not any:
			return
		box = box.grow_individual(margin.x, margin.y * 1.3, margin.x, margin.y * 0.5)
		want_center = box.get_center()
		want_z = minf(minf(play.x / box.size.x, play.y / box.size.y), max_zoom)
		# дальше, чем помещается карта по ширине, не отдаляет
		var min_z := play.x / bounds.size.x
		if not open_top:
			min_z = maxf(min_z, play.y / bounds.size.y)
		want_z = maxf(want_z, maxf(min_z, min_zoom))

	if _first:
		_z = want_z
		_center = want_center
		_first = false
	else:
		_z = lerpf(_z, want_z, minf(1.0, 2.5 * delta))
		_center = _center.lerp(want_center, minf(1.0, 4.0 * delta))

	var half := play / _z / 2.0
	var c := _center
	if follow:
		c.x = _clamp_axis(c.x, half.x, bounds.position.x, bounds.end.x)
		c.y = minf(c.y, bounds.end.y - half.y)          # под пол не заглядывает
		if not open_top:
			c.y = maxf(c.y, bounds.position.y + half.y)
	zoom = Vector2(_z, _z)
	position = c + Vector2(0, Config.panel() / 2.0 / _z)

func _clamp_axis(v: float, half: float, lo: float, hi: float) -> float:
	if hi - lo <= half * 2.0:
		return (lo + hi) / 2.0
	return clampf(v, lo + half, hi - half)
