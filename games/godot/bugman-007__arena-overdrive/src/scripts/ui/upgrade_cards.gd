class_name UpgradeCards
extends Control
## "Pick 1 of 3" roguelite card choice between waves.

signal chosen(upgrade: UpgradeData)

const RARITY_KEYS := ["RARITY_COMMON", "RARITY_RARE", "RARITY_EPIC"]

var _row: HBoxContainer
var _subtitle: Label
var _choices: Array[UpgradeData] = []
var _armed: bool = false


func _ready() -> void:
	UiKit.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.78)
	UiKit.full_rect(dim)
	add_child(dim)
	var col := VBoxContainer.new()
	UiKit.full_rect(col)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	col.add_child(UiKit.label("CHOOSE_UPGRADE", "HeaderLabel", 40, HORIZONTAL_ALIGNMENT_CENTER))
	_subtitle = UiKit.label("", "MutedLabel", 18, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_subtitle)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 28)
	col.add_child(_row)
	col.add_child(UiKit.label("CARD_HINT", "MutedLabel", 16, HORIZONTAL_ALIGNMENT_CENTER))
	hide()


func present(choices: Array[UpgradeData], stacks: Dictionary, picks_left: int) -> void:
	_choices = choices
	for c in _row.get_children():
		c.queue_free()
	_subtitle.text = tr("PICKS_LEFT") % picks_left
	var buttons: Array = []
	for i in choices.size():
		var card := _make_card(choices[i], int(stacks.get(choices[i].id, 0)), i)
		_row.add_child(card)
		buttons.append(card)
		UiKit.animate_in(card, 0.08 + i * 0.09, 0.7)
	UiKit.focus_chain(buttons, true)
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	_armed = false
	get_tree().create_timer(0.4, true, false, true).timeout.connect(func() -> void:
		_armed = true
		if not buttons.is_empty():
			(buttons[0] as Control).grab_focus())


func _make_card(u: UpgradeData, stacks: int, index: int) -> Button:
	var rc: Color = UiTheme.RARITY_COLORS[u.rarity]
	var b := Button.new()
	b.custom_minimum_size = Vector2(290, 380)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL_2, 0.97), Color(rc, 0.45), 2, 18))
	b.add_theme_stylebox_override("hover", UiTheme.box(Color("212b45"), rc, 3, 18))
	b.add_theme_stylebox_override("focus", UiTheme.box(Color("212b45"), rc, 4, 18))
	b.add_theme_stylebox_override("pressed", UiTheme.box(Color(rc, 0.35), rc, 4, 18))
	UiKit.wire_feedback(b, 1.06)
	b.pressed.connect(_pick.bind(index))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.full_rect(v)
	v.offset_left = 20
	v.offset_right = -20
	v.offset_top = 22
	v.offset_bottom = -20
	v.add_theme_constant_override("separation", 10)
	b.add_child(v)
	var rarity := UiKit.label(RARITY_KEYS[u.rarity], "", 15, HORIZONTAL_ALIGNMENT_CENTER)
	rarity.add_theme_color_override("font_color", rc)
	v.add_child(rarity)
	var icon := Widgets.UpgradeIcon.new(u.stat, u.icon_color)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	var name_label := UiKit.label(u.name_key, "HeaderLabel", 24, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(name_label)
	var desc := UiKit.label(u.desc_key, "", 18, HORIZONTAL_ALIGNMENT_CENTER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var lvl := UiKit.label(tr("CARD_LEVEL") % [stacks, stacks + 1, u.max_stacks], "MutedLabel", 15, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(lvl)
	var key := UiKit.label("[%d]" % (index + 1), "MutedLabel", 14, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(key)
	return b


func _pick(index: int) -> void:
	if not _armed or index >= _choices.size():
		return
	_armed = false
	AudioManager.play_ui(&"level_up")
	var u := _choices[index]
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func() -> void:
		hide()
		chosen.emit(u))


func pick_first() -> void:
	_armed = true
	_pick(0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed:
		return
	var k := (event as InputEventKey).physical_keycode
	if k >= KEY_1 and k <= KEY_3:
		_pick(k - KEY_1)
		get_viewport().set_input_as_handled()
