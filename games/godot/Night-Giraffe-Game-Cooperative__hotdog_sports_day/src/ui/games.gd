class_name Games
extends Control
## Setting up the Games: which set series of events (or your own), how
## good the computer is (by age band), how many players. Then off to the first
## event.

signal start(order: Array)
signal back

var stadium: StadiumView
var _series_box: VBoxContainer
var _events_box: GridContainer
var _line: Label
var _rivals_btn: Button
var _players_btn: Button
var _panel: Control
var _count: Label


func _ready() -> void:
	Kit.fill(self)
	stadium = StadiumView.new()
	add_child(stadium)
	stadium.cam = 20.0
	stadium.excite = 0.5
	var panel := Kit.panel(Color("1a1424"))
	_panel = panel
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var title := Kit.label("THE GAMES", "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	box.add_child(cols)
	_series_box = VBoxContainer.new()
	_series_box.add_theme_constant_override("separation", 2)
	cols.add_child(_series_box)
	for s in Catalog.series():
		var b := Kit.small_button(String(s.name).to_upper(), Color("2a5a7a"), 120)
		b.name = String(s.id)
		b.pressed.connect(func():
			Profile.series = String(s.id)
			_refresh())
		_series_box.add_child(b)
	var mine := Kit.small_button("MY OWN SERIES", Color("7a3ad2"), 120)
	mine.name = "custom"
	mine.pressed.connect(func():
		Profile.series = "custom"
		_refresh())
	_series_box.add_child(mine)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 3)
	cols.add_child(right)
	_line = Kit.label("", "small", Kit.GREY)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size = Vector2(200, 0)
	right.add_child(_line)
	_events_box = GridContainer.new()
	_events_box.columns = 6
	_events_box.add_theme_constant_override("h_separation", 3)
	_events_box.add_theme_constant_override("v_separation", 2)
	right.add_child(_events_box)
	_count = Kit.label("", "small", Kit.AMBER)
	right.add_child(_count)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_rivals_btn = Kit.small_button("", Color("6a3a2a"), 150)
	_rivals_btn.pressed.connect(func():
		var r: Array = Championship.RIVALS
		Profile.rivals = r[(r.find(Profile.rivals) + 1) % r.size()]
		_refresh())
	_players_btn = Kit.small_button("", Color("2a5a7a"), 64)
	_players_btn.pressed.connect(func():
		Profile.players = Remote.screen_count() % Remote.MAX_PLAYERS + 1   # 1, 2, 3, 4 on this tablet
		Remote.screen_players = -1
		_refresh())
	row.add_child(_rivals_btn)
	row.add_child(_players_btn)
	box.add_child(row)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", 4)
	var bk := Kit.small_button("BACK", Color("4e4a62"), 60)
	bk.pressed.connect(func():
		Profile.save()
		back.emit())
	var go := Kit.small_button("LET THE GAMES BEGIN!", Kit.KETCHUP, 150)
	go.pressed.connect(func():
		Profile.save()
		var order := events()
		if not order.is_empty():
			start.emit(order))
	foot.add_child(bk)
	foot.add_child(go)
	box.add_child(foot)
	add_child(panel)
	go.grab_focus.call_deferred()
	_refresh()
	Sound.music("stadium")


## The events of the series picked.
func events() -> Array:
	if Profile.series == "custom":
		return Profile.custom.filter(func(id): return not Catalog.event(String(id)).is_empty())
	var s := Catalog.a_series(Profile.series)
	if s.is_empty():
		s = Catalog.series()[0]
	return s.events


func _refresh() -> void:
	for b in _series_box.get_children():
		var on := String(b.name) == Profile.series
		(b as Button).modulate = Color(1, 1, 1) if on else Color(0.62, 0.62, 0.7)
		(b as Button).text = ("> " if on else "") + (b as Button).text.trim_prefix("> ")
	var custom := Profile.series == "custom"
	if custom:
		_line.text = "Tap the events you want. They're held in the order shown."
	else:
		var s := Catalog.a_series(Profile.series)
		_line.text = String(s.get("line", ""))
	for c in _events_box.get_children():
		c.queue_free()
	var chosen := events()
	var shown: Array = Catalog.order() if custom else chosen
	for k in shown.size():
		var id := String(shown[k])
		var on: bool = id in chosen
		var b := Button.new()
		b.icon = Kit.icon(id)
		b.flat = true
		b.focus_mode = Control.FOCUS_ALL if custom else Control.FOCUS_NONE
		b.tooltip_text = String(Catalog.event(id).get("name", id))
		b.modulate = Color(1, 1, 1) if on else Color(0.35, 0.35, 0.45)
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("focus", Kit.box(Color(0, 0, 0, 0), Kit.MUSTARD, 1, 0))
		b.custom_minimum_size = Vector2(32, 32)
		if custom:
			b.pressed.connect(func():
				if id in Profile.custom:
					if Profile.custom.size() > 1:
						Profile.custom.erase(id)
				else:
					Profile.custom.append(id)
				_refresh())
		_events_box.add_child(b)
	_count.text = "%d EVENTS" % chosen.size()
	_rivals_btn.text = "COMPUTER: " + Championship.age_label(Profile.rivals)
	_players_btn.text = "%d PLAYER%s" % [Remote.total(), "S" if Remote.total() > 1 else ""]


func _process(_delta: float) -> void:
	var s := get_viewport_rect().size
	var ps := _panel.get_combined_minimum_size()
	_panel.position = ((s - ps) / 2.0).round()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back.emit()
