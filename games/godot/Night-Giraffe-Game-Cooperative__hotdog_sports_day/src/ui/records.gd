class_name Records
extends Control
## The record books: each event's world record (the computer's, until a
## player beats it), who holds it, and the player's own best.

signal done


func _ready() -> void:
	Kit.fill(self)
	var st := StadiumView.new()
	add_child(st)
	st.cam = 80.0
	var panel := Kit.panel(Color("1a1424"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var title := Kit.label("RECORDS", "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 1)
	box.add_child(grid)
	for h in ["EVENT", "WORLD RECORD", "HELD BY", "YOUR BEST"]:
		grid.add_child(Kit.label(h, "small", Kit.GREY))
	for id in Catalog.order():
		var e := Catalog.event(id)
		var rec := Profile.record(id)
		grid.add_child(Kit.label(String(e.get("name", id)), "small", Kit.PAPER))
		grid.add_child(Kit.label(Catalog.show_mark(id, float(rec.mark)), "small", Kit.AMBER))
		var holder := String(rec.get("name", ""))
		if holder == "":
			holder = holder_of(id)
		grid.add_child(Kit.label(holder, "small", Kit.PAPER))
		var best := "-"
		if Profile.bests.has(id):
			best = Catalog.show_mark(id, float(Profile.bests[id]))
		grid.add_child(Kit.label(best, "small", Kit.MUSTARD))
	var ml := Kit.label("CHAMPIONSHIPS FINISHED  %d" % Profile.championships, "small", Kit.GREY)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ml)
	var back := Kit.button("BACK", Color("4e4a62"), "small", 80)
	back.pressed.connect(func(): done.emit())
	box.add_child(back)
	add_child(panel)
	Kit.centre(panel)
	back.grab_focus.call_deferred()


## Who holds the record at the start: the athlete best at that event.
static func holder_of(id: String) -> String:
	for n in Catalog.nations():
		if String(n.get("best", "")) == id:
			return String(n.athlete)
	for n in Catalog.nations():
		if Championship.specialist(n, id):
			return String(n.athlete)
	return "?"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		done.emit()
