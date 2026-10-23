class_name CheatsScreen
extends Control
## Main menu cheats (dev flag --cheats): paper maps, open any map, mark any difficulty of any map as beaten.
## Session only unless --save-fake, see Game.cheat_*.

signal closed

const MapsData := preload("res://scripts/data/maps_data.gd")
const DIFF_SHORT := ["Light", "Medium", "Difficult", "Hardcore", "Ultra"]
# the table has to fit the panel's 500 px inside: map name + (Open + one column per difficulty), 3 px apart
const NAME_W := 104
const COL_W := 63

var body: VBoxContainer
var panel: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UI.dim_rect(0.7))
	var p := UI.panel("panel", 10)
	p.size = Vector2(520, 0)
	add_child(p)
	panel = p
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	p.add_child(root)
	root.add_child(UI.title("CHEATS", 16))
	var note := "Saved to your save file (--save-fake)" if Game.save_fake else \
		"This session only: your save keeps the real progress (run with --save-fake to keep this)"
	root.add_child(UI.label(note, 10, Color("8b9bb4"), HORIZONTAL_ALIGNMENT_CENTER))
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	root.add_child(body)
	var close := UI.button("Close", "red", Vector2(90, 20))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): closed.emit())
	root.add_child(close)
	_rebuild()
	_center.call_deferred()


## In the middle of the screen, once the table has its size.
func _center() -> void:
	panel.reset_size()
	panel.position = ((Vector2(640, 360) - panel.size) / 2.0).round()


func _rebuild() -> void:
	for c in body.get_children():
		c.queue_free()
	# paper maps
	var pr := _row()
	var pl := UI.label("Paper maps: %d" % Game.paper_maps, 10, Color("fee761"))
	pl.custom_minimum_size.x = 120
	pr.add_child(pl)
	for amt in [100, 1000, 10000]:
		_btn(pr, "+%d" % amt, "gold", 50, func(): Game.cheat_paper_maps(amt))
	_btn(pr, "Set to 0", "gray", 60, func(): Game.cheat_paper_maps(-Game.paper_maps))
	body.add_child(Control.new())
	# map table: open / beaten per difficulty
	var head := _row()
	var hl := UI.label("Map", 10, Color("8b9bb4"))
	hl.custom_minimum_size.x = NAME_W
	head.add_child(hl)
	for t in ["Open"] + DIFF_SHORT:
		var l := UI.label(t, 10, Color("8b9bb4"), HORIZONTAL_ALIGNMENT_CENTER)
		l.custom_minimum_size.x = COL_W
		head.add_child(l)
	for id in MapsData.ORDER:
		var r := _row()
		var nl := UI.label(MapsData.MAPS[id]["name"], 10, Color.WHITE)
		nl.custom_minimum_size.x = NAME_W
		r.add_child(nl)
		var open: bool = Game.is_map_unlocked(id)   # a beaten map stays open even when not bought
		_btn(r, "Open" if open else "Locked", "green" if open else "gray", COL_W,
			func(): Game.cheat_set_map_open(id, not open))
		for d in DIFF_SHORT.size():
			var done := Game.is_beaten(id, d)
			_btn(r, "Beaten" if done else "-", "green" if done else "gray", COL_W,
				func(): Game.cheat_set_beaten(id, d, not done))
	# everything at once
	body.add_child(Control.new())
	var ar := _row()
	_btn(ar, "Open all maps", "blue", 100, func():
		for id in MapsData.ORDER:
			Game.cheat_set_map_open(id, true))
	_btn(ar, "Beat everything", "blue", 100, func():
		for id in MapsData.ORDER:
			for d in DIFF_SHORT.size():
				Game.cheat_set_beaten(id, d, true))
	_btn(ar, "Unlock all maps + towers", "gold", 150, func():
		for id in MapsData.ORDER:
			Game.cheat_set_map_open(id, true)
		for t in Defs.TOWER_ORDER:
			Game.cheat_set_tower_bought(t, true))
	_btn(ar, "Reset progress", "red", 100, func():
		for id in MapsData.ORDER:
			Game.cheat_set_map_open(id, Game.START_MAPS.has(id))
			for d in DIFF_SHORT.size():
				Game.cheat_set_beaten(id, d, false)
		for t in Defs.TOWER_ORDER:
			Game.cheat_set_tower_bought(t, false))


func _row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 3)
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(r)
	return r


## Every button runs its cheat and redraws the table.
func _btn(row: HBoxContainer, text: String, color: String, w: float, fn: Callable) -> void:
	var b := UI.button(text, color, Vector2(w, 16))
	b.pressed.connect(func():
		Sfx.play("click")
		fn.call()
		_rebuild())
	row.add_child(b)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		closed.emit()
		get_viewport().set_input_as_handled()
