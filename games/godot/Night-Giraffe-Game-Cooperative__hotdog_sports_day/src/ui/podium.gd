class_name Podium
extends Control
## The closing ceremony: evening at the stadium, the floodlights on, the top
## three nations' athletes on the podium with their flags behind them, the
## crowd on its feet, confetti. Then the medal table.

signal done

var champ: Championship
var stadium: StadiumView
var fx: Fx
var views: Array = []
var _t := 0.0
var _table: Control
var _over: Control


func setup(c: Championship) -> void:
	champ = c


func _ready() -> void:
	Kit.fill(self)
	stadium = StadiumView.new()
	add_child(stadium)
	stadium.cam = 30.0
	stadium.dusk = 0.85
	stadium.excite = 1.0
	var rows := champ.table() if champ else []
	for p in mini(3, rows.size()):
		var nat := String(rows[p].nation)
		var look := _look_for(nat)
		var v := AthleteView.new()
		v.set_look(look)
		add_child(v)
		views.append(v)
	fx = Fx.new()
	add_child(fx)
	_over = Control.new()
	Kit.fill(_over)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_draw_over)
	add_child(_over)
	Sound.music("ceremony")
	Sound.play("fanfare")
	get_tree().create_timer(4.0).timeout.connect(_show_table)


func _look_for(nat: String) -> Dictionary:
	if champ:
		for p in champ.players:
			if String(p.get("nation", "")) == nat:
				return p
	var n := Catalog.nation(nat)
	return Championship.look_of(n) if not n.is_empty() else Profile.default_athlete()


func _show_table() -> void:
	if _table or champ == null:
		return
	_table = Results.table(champ, "FINAL MEDAL TABLE")
	var box: VBoxContainer = _table.get_child(0)
	var b := Kit.button("THE END", Kit.KETCHUP, "small", 90)
	b.pressed.connect(func(): done.emit())
	box.add_child(b)
	add_child(_table)
	_table.ready.connect(func():
		_table.position = Vector2(roundf(get_viewport_rect().size.x - _table.get_combined_minimum_size().x - 8), 8))
	b.grab_focus.call_deferred()
	if get_tree().root.get_node_or_null("Main") and get_tree().root.get_node("Main").get("bot"):
		get_tree().create_timer(0.5).timeout.connect(func(): done.emit())


func _process(delta: float) -> void:
	_t += delta
	stadium.beat = _t * 1.5
	var s := get_viewport_rect().size
	var base := Vector2(roundf(s.x * 0.3), roundf(stadium.lane_y(3.0)))
	var steps := [Vector2(0, -30), Vector2(-40, -20), Vector2(40, -12)]
	for i in views.size():
		var v: AthleteView = views[i]
		var ph := fposmod(_t * 1.5 + i * 0.33, 1.0)
		v.position = (base + steps[i]).round()
		v.lift = 6.0 * 4.0 * ph * (1.0 - ph) if i == 0 else 0.0
		v.squash = 0.85 if i == 0 and (ph < 0.08 or ph > 0.95) else 1.0
		v.mood = "joy" if i == 0 else "happy"
		v.ground_shadow = 0.0
	if fposmod(_t, 0.7) < delta:
		fx.burst("confetti", Vector2(randf_range(20, s.x - 20), -4), 12)
	_over.queue_redraw()


func _draw_over() -> void:
	var s := get_viewport_rect().size
	var base := Vector2(roundf(s.x * 0.3), roundf(stadium.lane_y(3.0)))
	var steps := [[Vector2(-18, -30), 30.0, "1"], [Vector2(-58, -20), 20.0, "2"], [Vector2(22, -12), 12.0, "3"]]
	var f := Kit.font("big")
	for st in steps:
		var p: Vector2 = base + st[0]
		var h: float = st[1]
		_over.draw_rect(Rect2(p, Vector2(36, h)), Color("d4d4e0"))
		_over.draw_rect(Rect2(p, Vector2(36, 2)), Color("fffaf0"))
		_over.draw_rect(Rect2(p + Vector2(0, h - 1), Vector2(36, 1)), Color("4e4a62"))
		_over.draw_rect(Rect2(p + Vector2(35, 0), Vector2(1, h)), Color("7a7690"))
		_over.draw_string(f, p + Vector2(13, minf(h - 2, 18)), String(st[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("4e4a62"))
	# the flags, raised behind
	var rows := champ.table() if champ else []
	var poles := [Vector2(0, -150), Vector2(-40, -130), Vector2(40, -120)]
	for i in mini(3, rows.size()):
		var p2: Vector2 = base + poles[i]
		var rise := clampf(_t / 2.5, 0.0, 1.0)
		_over.draw_rect(Rect2(p2 + Vector2(0, 0), Vector2(1, 70)), Color("a0a0b8"))
		var tex := Kit.flag(String(rows[i].nation), "m")
		_over.draw_texture(tex, (p2 + Vector2(1, 40 - 40 * rise)).round())
	var title := "CHAMPIONS!" if champ == null or champ.buns > 0 else "OUT OF BUNS!"
	var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var tp := Vector2(roundf(s.x * 0.3 - w / 2), 14)
	_over.draw_string(f, tp + Vector2(2, 2), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Kit.INK)
	_over.draw_string(f, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Kit.MUSTARD)


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		if _table == null:
			_show_table()
