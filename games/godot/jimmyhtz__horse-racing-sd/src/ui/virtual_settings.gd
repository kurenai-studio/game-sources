extends VBoxContainer
const V = preload("res://core/virtual_players.gd")
var flow: RefCounted
var seat_index := 0
var controls: VBoxContainer
func configure(controller: RefCounted) -> void:
	flow=controller
	var title := Label.new()
	title.text="Private virtual-player styles"
	add_child(title)
	var note := Label.new()
	note.text="Choose V mode on the betting panels. Edit numbered styles here. V has no credit account and never sits out automatically. Random modes hide their personality."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(note)
	var player := OptionButton.new()
	for i in range(8): player.add_item("Player %d" % (i+1))
	player.item_selected.connect(func(index): seat_index=index; rebuild())
	add_child(player)
	controls=VBoxContainer.new(); add_child(controls)
	rebuild()
	visibility_changed.connect(func(): if visible and controls!=null: rebuild())

func rebuild() -> void:
	for child in controls.get_children(): controls.remove_child(child); child.queue_free()
	var seat: Dictionary=flow.virtual_draft.seats[seat_index]
	var mode := OptionButton.new()
	mode.name="VirtualStyleMode"
	for value in V.MODES: mode.add_item(value)
	mode.select(V.MODES.find(seat.mode))
	mode.disabled=true
	mode.tooltip_text="Change mode using V on the betting panels."
	controls.add_child(mode)
	var preset := OptionButton.new()
	preset.name="VirtualPreset"
	for i in range(10): preset.add_item("Style %d" % (i+1))
	preset.select(seat.preset)
	preset.disabled=seat.mode!=V.MODES[0]
	preset.item_selected.connect(func(index): seat.preset=index; rebuild())
	controls.add_child(preset)
	var random_mode: bool=seat.mode!=V.MODES[0]
	if random_mode:
		var hidden := Label.new()
		hidden.text="Hidden personality. Sliders are inactive and show no selected values."
		hidden.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		controls.add_child(hidden)
	var style: Dictionary=flow.virtual_draft.styles[seat.preset]
	for factor in V.FACTORS:
		var row := HBoxContainer.new()
		var label := Label.new(); label.text=factor[1]; label.custom_minimum_size.x=235
		row.add_child(label)
		var slider := HSlider.new()
		slider.name="VirtualFactor_"+factor[0]
		slider.min_value=factor[2]; slider.max_value=factor[3]; slider.step=factor[4]
		slider.value=(float(factor[2])+float(factor[3]))/2.0 if random_mode else style[factor[0]]
		slider.editable=not random_mode
		slider.size_flags_horizontal=SIZE_EXPAND_FILL
		slider.custom_minimum_size.x=150
		row.add_child(slider)
		var value := Label.new(); value.custom_minimum_size.x=60
		value.text="Hidden" if random_mode else readable(slider.value,float(factor[3]))
		row.add_child(value)
		slider.value_changed.connect(func(amount): style[factor[0]]=amount; value.text=readable(amount,float(factor[3])))
		if random_mode: row.modulate=Color(1,1,1,0.45)
		controls.add_child(row)
	var reset := Button.new()
	reset.text="Return Style %d to defaults" % (seat.preset+1)
	reset.disabled=random_mode
	reset.pressed.connect(func(): flow.virtual_draft.styles[seat.preset]=V.default_styles()[seat.preset]; rebuild())
	controls.add_child(reset)

func readable(value: float, maximum: float) -> String:
	return "%d%%" % roundi(value*100.0) if maximum==1.0 else str(roundi(value))
