class_name CrystalGrower
extends Node
# Кристаллы, которые отрастают: если друзу разбили больше чем наполовину,
# через несколько секунд она вырастает снова (если на её месте никто не стоит).

var rect := Rect2()
var color := DeepArt.CRYSTAL
var regrow_time := 9.0
var _d: Destructible
var _full := 0
var _t := -1.0

func _ready() -> void:
	_grow(false)

func _grow(fx: bool) -> void:
	var world := get_parent()
	if is_instance_valid(_d):
		_d.queue_free()
	_d = Maps.make_destructible(rect, 20.0, color, 40, 40.0)
	_d.mat_kind = "crystal"
	_d.anchored = true
	for x in _d.cols:
		for y in _d.rows:
			_d.cells[Vector2i(x, y)] = _d.cell_hp
	# острая верхушка: в верхнем ряду только середина
	if _d.rows >= 3:
		for x in _d.cols:
			if x == 0 or x == _d.cols - 1:
				_d.cells.erase(Vector2i(x, 0))
	for x in _d.cols:
		_d.anchors.append(Vector2i(x, _d.rows - 1))
	Shimmer.apply(_d, 0.2, 0.6)
	world.add_child.call_deferred(_d)
	_full = maxi(1, _d.cells.size())
	if fx:
		Fx.sparks(world, rect.get_center(), Color(0.7, 0.9, 1.0), 14, 160.0, 3.0)
		Util.flash(world, rect.get_center(), rect.size.y * 0.6, Color(0.6, 0.85, 1.0, 0.6))

func _process(delta: float) -> void:
	var left := _d.cells.size() if is_instance_valid(_d) else 0
	if _t < 0.0:
		if left < _full / 2:
			_t = regrow_time
		return
	_t -= delta
	if _t <= 0.0:
		for n in get_parent().get_children():
			if n is Player and n.is_alive() and rect.grow(10.0).has_point(n.global_position):
				_t = 1.0            # кто-то стоит на месте друзы — подождём
				return
		_t = -1.0
		_grow(true)
