class_name Practice
extends Control
## Practice: pick any event and have a go, against three of the world's best.

signal picked(id: String)
signal back

var stadium: StadiumView


func _ready() -> void:
	Kit.fill(self)
	stadium = StadiumView.new()
	add_child(stadium)
	stadium.cam = 30.0
	var panel := Kit.panel(Color("1a1424"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title := Kit.label("PRACTICE", "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	var colours := [Kit.KETCHUP, Color("a0661e"), Color("38a03a"), Color("7a3ad2"), Color("2a4ad2"), Color("1e9a9a")]
	var order := Catalog.order()
	for k in order.size():
		var id := String(order[k])
		var e := Catalog.event(id)
		var b := Kit.event_button(id, colours[k % colours.size()], 108)
		b.text = String(e.get("short", id)).to_upper()
		b.pressed.connect(func(): picked.emit(id))
		grid.add_child(b)
		if k == 0:
			b.grab_focus.call_deferred()
	var bk := Kit.button("BACK", Color("4e4a62"), "small", 80)
	bk.pressed.connect(func(): back.emit())
	box.add_child(bk)
	add_child(panel)
	_panel = panel


var _panel: Control


func _process(_delta: float) -> void:
	_panel.position = ((get_viewport_rect().size - _panel.get_combined_minimum_size()) / 2.0).round()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back.emit()
