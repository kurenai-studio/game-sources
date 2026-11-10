class_name Learn
extends Control
## LEARN TO PLAY: a short lesson for each thing you do (RUN, JUMP, and JUMP
## then HOLD), each a real event with the coach saying what to press and
## when. And the LEARN MODE switch: the coach in every event, or not.

signal picked(i: int)
signal back

const LESSONS := [
	{"id": "sprint", "name": "1. RUN!", "text": "TAP RUN, RUN, RUN!  LEFT, RIGHT, LEFT, RIGHT"},
	{"id": "hurdles", "name": "2. JUMP!", "text": "PRESS JUMP WHEN THE CIRCLE GETS SMALL"},
	{"id": "long_jump", "name": "3. JUMP & HOLD!", "text": "JUMP, THEN HOLD JUMP TILL THE RING FILLS"},
]

var news := ""                    ## said at the top: a lesson done, something unlocked
var stadium: StadiumView
var _panel: Control
var _mode: Button


## A lesson's been played: tick it off; all three, and you've learned to play
## (which unlocks things to wear). Returns the words to say about it.
static func finish(id: String) -> String:
	Profile.stats["lesson_" + id] = 1
	var all := true
	for l in LESSONS:
		if int(Profile.stats.get("lesson_" + String(l.id), 0)) < 1:
			all = false
	var said := "WELL BOUNCED! LESSON DONE."
	if all and int(Profile.stats.get("tutorial", 0)) < 1:
		Profile.stats["tutorial"] = 1
		var got := Wardrobe.check()
		said = "YOU'VE LEARNED TO PLAY!"
		if not got.is_empty():
			said += "  NEW TO WEAR: " + Wardrobe.news(got)
	Profile.save()
	return said


static func done(id: String) -> bool:
	return int(Profile.stats.get("lesson_" + id, 0)) >= 1


func _ready() -> void:
	Kit.fill(self)
	stadium = StadiumView.new()
	add_child(stadium)
	stadium.cam = 20.0
	stadium.excite = 0.35
	var panel := Kit.panel(Color("1a1424"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title := Kit.label("LEARN TO PLAY", "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	if news != "":
		var n := Kit.label(news, "small", Kit.RELISH)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(n)
	var colours := [Kit.KETCHUP, Color("d06a2a"), Color("38a03a")]
	var first: Button = null
	for i in LESSONS.size():
		var l: Dictionary = LESSONS[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var b := Kit.event_button(String(l.id), colours[i], 112)
		b.text = String(l.name)
		b.pressed.connect(func(): picked.emit(i))
		row.add_child(b)
		var words := Kit.label(String(l.text), "small", Kit.PAPER)
		words.custom_minimum_size.x = 224
		words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(words)
		var tick := Kit.label("✓" if done(String(l.id)) else "", "small", Kit.RELISH)
		tick.custom_minimum_size.x = 8
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tick)
		box.add_child(row)
		if first == null and not done(String(l.id)):
			first = b
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 4)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	_mode = Kit.button("", Color("1e8a8a"), "small", 150)
	_mode.pressed.connect(func():
		Profile.learn = not Profile.learn
		Profile.save()
		_refresh())
	foot.add_child(_mode)
	var bk := Kit.button("BACK", Color("4e4a62"), "small", 80)
	bk.pressed.connect(func(): back.emit())
	foot.add_child(bk)
	box.add_child(foot)
	var note := Kit.label("LEARN MODE: THE COACH HELPS IN EVERY EVENT", "small", Kit.GREY)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)
	add_child(panel)
	_panel = panel
	Kit.centre(panel)
	_refresh()
	(first if first else bk).grab_focus.call_deferred()


func _refresh() -> void:
	_mode.text = "LEARN MODE: " + ("ON" if Profile.learn else "OFF")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back.emit()
