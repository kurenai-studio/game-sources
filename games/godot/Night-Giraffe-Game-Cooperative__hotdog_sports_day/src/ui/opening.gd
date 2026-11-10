class_name Opening
extends Control
## The opening ceremony, before the first event of the Games: the stadium at
## sunset, every nation's athlete bouncing past with its flag stuck in its bun
## (no arms to carry it), the players' team last, the announcer naming each one,
## then the Mustard Flame lit in its cauldron and fireworks. A tap skips it.

signal done

const GAP := 64.0
const SPEED := 46.0              ## pixels a second the parade moves

var teams: Array = []            ## [{look, name, nation, country}]
var stadium: StadiumView
var fx: Fx
var views: Array = []
var _over: Control
var _t := 0.0
var _lit := -1.0
var _done := false
var _said := ""


func setup(players: Array) -> void:
	for n in Catalog.nations():
		teams.append({"look": Championship.look_of(n), "name": String(n.athlete), "nation": String(n.id),
			"country": String(n.country)})
	for p in players:
		teams.append({"look": p, "name": String(p.get("name", "")), "nation": String(p.get("nation", "ngc")),
			"country": String(Catalog.nation(String(p.get("nation", "ngc"))).get("country", "Night Giraffe"))})


func _ready() -> void:
	Kit.fill(self)
	stadium = StadiumView.new()
	add_child(stadium)
	stadium.cam = 2.0
	stadium.dusk = 0.55
	stadium.excite = 0.9
	for tm in teams:
		var v := AthleteView.new()
		v.set_look(tm.look)
		add_child(v)
		views.append(v)
	fx = Fx.new()
	fx.z_index = 60
	add_child(fx)
	_over = Control.new()
	Kit.fill(_over)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.z_index = 70
	_over.draw.connect(_draw_over)
	add_child(_over)
	Sound.music("ceremony")
	Sound.play("fanfare", 0.8)


func _process(delta: float) -> void:
	_t += delta
	var s := get_viewport_rect().size
	stadium.beat = _t * 1.5
	var y := stadium.lane_y(2.6)
	var front := -40.0 + _t * SPEED
	var mid := s.x * 0.45
	for i in views.size():
		var v: AthleteView = views[i]
		var x := front - i * GAP
		var ph := fposmod(_t * 1.5 + i * 0.25, 1.0)
		v.position = Vector2(roundf(x), roundf(y))
		v.lift = 8.0 * 4.0 * ph * (1.0 - ph)
		v.squash = 0.82 if ph < 0.08 or ph > 0.95 else 1.0
		v.mood = "joy" if absf(x - mid) < 30.0 else "happy"
		v.visible = x > -30 and x < s.x + 30
		if absf(x - mid) < GAP * 0.5:
			var tm: Dictionary = teams[i]
			_said = "%s  ·  %s" % [String(tm.country).to_upper(), String(tm.name)]
	# when the last has gone by, light the flame
	var last_x := front - (views.size() - 1) * GAP
	if last_x > s.x * 0.75 and _lit < 0.0:
		_lit = _t
		Sound.play("finish")
		_said = "LET THE GAMES BEGIN!"
	if _lit >= 0.0:
		if fposmod(_t, 0.45) < delta:
			fx.burst("confetti", Vector2(randf_range(40, s.x - 40), randf_range(20, 80)), 16)
			fx.burst("spark", Vector2(randf_range(40, s.x - 40), randf_range(20, 70)), 10)
		if _t - _lit > 3.5:
			_finish()
	_over.queue_redraw()


func _draw_over() -> void:
	var s := get_viewport_rect().size
	# each athlete's flag, on a pole stuck in its bun
	for i in views.size():
		var v: AthleteView = views[i]
		if not v.visible:
			continue
		var base := v.position + Vector2(8, -v.lift - 10)
		_over.draw_line(base, base + Vector2(0, -44), Color("e0e0ee"), 1.0)
		var tex := Kit.flag(String(teams[i].nation), "m")
		var wave := roundf(sin(_t * 6.0 + i) * 1.0)
		_over.draw_texture(tex, base + Vector2(1, -44 + wave))
	# the cauldron on its tower, and the Mustard Flame
	var cx := s.x - 46.0
	var top := stadium.wall_y() - 54.0
	_over.draw_rect(Rect2(cx - 4, top + 14, 8, stadium.wall_y() - top), Color("4e4a62"))
	_over.draw_rect(Rect2(cx - 4, top + 14, 2, stadium.wall_y() - top), Color("7a7690"))
	_over.draw_colored_polygon(PackedVector2Array([Vector2(cx - 14, top), Vector2(cx + 14, top), Vector2(cx + 8, top + 14),
		Vector2(cx - 8, top + 14)]), Color("c88a52"))
	_over.draw_rect(Rect2(cx - 14, top, 28, 2), Color("e8b878"))
	if _lit >= 0.0:
		var k := clampf((_t - _lit) / 0.8, 0.0, 1.0)
		for layer in 3:
			var col: Color = [Color("e0383a"), Color("f0a030"), Color("fff07a")][layer]
			var h := (26.0 - layer * 7.0) * k * (0.85 + 0.15 * sin(_t * 17.0 + layer))
			var w := 11.0 - layer * 3.0
			var flick := sin(_t * 11.0 + layer * 2.0) * 2.0
			_over.draw_colored_polygon(PackedVector2Array([Vector2(cx - w, top), Vector2(cx + w, top),
				Vector2(cx + flick, top - h)]), col)
	# the announcer
	var f := Kit.font("big" if _lit >= 0.0 else "small")
	var fs := 18 if _lit >= 0.0 else 9
	var title := "OPENING CEREMONY"
	var small := Kit.font("small")
	var tw := small.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	Kit.outlined(_over, small, Vector2(roundf(s.x / 2 - tw / 2), 8), title, 9, Kit.GREY)
	if _said != "":
		var w2 := f.get_string_size(_said, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		Kit.outlined(_over, f, Vector2(roundf(s.x / 2 - w2 / 2), 22), _said, fs, Kit.MUSTARD)


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	done.emit()
