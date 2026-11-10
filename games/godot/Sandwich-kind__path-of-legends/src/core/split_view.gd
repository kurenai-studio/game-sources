class_name SplitView
extends CanvasLayer
# Разделённый экран для больших карт (Гора).
# Когда игроки далеко друг от друга, экран делится пополам: слева — Игрок 1,
# справа — Игрок 2, у каждого своя камера крупным планом.
# По краю каждой половины стрелка показывает, где соперник, и сколько до него блоков.
# Когда игроки снова сходятся — экран опять общий.

const SPLIT_DIST := 1600.0     # дальше этого — делим экран
const MERGE_DIST := 1250.0     # ближе этого — снова общий экран
const ZOOM := 0.8
const BLOCK := 40.0            # сколько пикселей в одном «блоке» для подписи расстояния

var players: Array = []
var bounds := Rect2()
var open_top := true

var _halves: Array = []        # {box, cam, arrow, dist}
var _on := false
var _divider: ColorRect

func _ready() -> void:
	layer = 1
	var vs := Config.screen(self)
	var h := vs.y - Config.panel()
	for i in 2:
		var box := SubViewportContainer.new()
		box.stretch = true
		box.position = Vector2(i * vs.x / 2.0, 0)
		box.size = Vector2(vs.x / 2.0, h)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(box)
		var sv := SubViewport.new()
		sv.world_2d = get_viewport().world_2d     # тот же мир, что и на главном экране
		sv.handle_input_locally = false
		sv.gui_disable_input = true
		box.add_child(sv)
		var cam := Camera2D.new()
		cam.zoom = Vector2(ZOOM, ZOOM)
		sv.add_child(cam)
		cam.enabled = true
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(26, 0), Vector2(-14, -18), Vector2(-6, 0), Vector2(-14, 18)])
		var col: Color = Config.OUTLINE_P2 if i == 0 else Config.OUTLINE_P1   # цвет соперника
		arrow.color = col
		box.add_child(arrow)
		var dist := Label.new()
		dist.size = Vector2(120, 30)
		dist.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dist.add_theme_font_size_override("font_size", 18)
		dist.add_theme_color_override("font_color", col.lightened(0.3))
		box.add_child(dist)
		_halves.append({"box": box, "cam": cam, "arrow": arrow, "dist": dist, "sv": sv})
	_divider = ColorRect.new()
	_divider.color = Color(0.08, 0.07, 0.1)
	_divider.position = Vector2(vs.x / 2.0 - 3, 0)
	_divider.size = Vector2(6, h)
	_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_divider)
	_set_on(false)

func is_split() -> bool:
	return _on

func _set_on(v: bool) -> void:
	_on = v
	visible = v
	for hf in _halves:
		hf["sv"].render_target_update_mode = SubViewport.UPDATE_ALWAYS if v else SubViewport.UPDATE_DISABLED

func _process(_delta: float) -> void:
	if players.size() < 2:
		return
	var a: Player = players[0]
	var b: Player = players[1]
	if not (is_instance_valid(a) and is_instance_valid(b)):
		return
	var d := a.global_position.distance_to(b.global_position)
	if not a.is_alive() or not b.is_alive():
		d = MERGE_DIST + 1.0 if _on else 0.0     # пока кто-то возрождается — ничего не меняем
	if not _on and d > SPLIT_DIST:
		_set_on(true)
	elif _on and d < MERGE_DIST:
		_set_on(false)
	if not _on:
		return
	for i in 2:
		var me: Player = players[i]
		var foe: Player = players[1 - i]
		var hf: Dictionary = _halves[i]
		var box: SubViewportContainer = hf["box"]
		var cam: Camera2D = hf["cam"]
		var half := box.size / ZOOM / 2.0
		var c := me.global_position + Vector2(0, -60)
		c.x = clampf(c.x, bounds.position.x + half.x, bounds.end.x - half.x)
		c.y = minf(c.y, bounds.end.y - half.y)
		if not open_top:
			c.y = maxf(c.y, bounds.position.y + half.y)
		cam.position = c
		# стрелка на краю половины экрана — в сторону соперника
		var dir := (foe.global_position - c).normalized()
		var center := box.size / 2.0
		var edge := box.size / 2.0 - Vector2(40, 40)
		var t := minf(edge.x / maxf(absf(dir.x), 0.001), edge.y / maxf(absf(dir.y), 0.001))
		var arrow: Polygon2D = hf["arrow"]
		arrow.position = center + dir * t
		arrow.rotation = dir.angle()
		var lbl: Label = hf["dist"]
		lbl.text = "%d бл." % int(me.global_position.distance_to(foe.global_position) / BLOCK)
		lbl.position = arrow.position - dir * 46.0 - lbl.size / 2.0
