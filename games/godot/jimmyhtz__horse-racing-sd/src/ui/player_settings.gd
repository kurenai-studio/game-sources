extends VBoxContainer
const Identity = preload("res://core/player_identity.gd")
const Avatar = preload("res://ui/player_avatar.gd")
var flow: RefCounted
var color_controls: Array = []

func configure(controller: RefCounted) -> void:
	flow = controller
	size_flags_horizontal = SIZE_EXPAND_FILL
	var explanation := Label.new()
	explanation.text = "Names, avatars and PIN edits take effect on Return to Game. Leave both PIN fields empty to keep the current PIN."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(explanation)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	add_child(grid)
	for i in range(8):
		build_player(grid,i)
	refresh_colors()

func text_label(caption: String) -> Label:
	var label := Label.new()
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func action(caption: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = caption
	control.pressed.connect(callback)
	return control

func build_player(grid: GridContainer, index: int) -> void:
	var draft: Dictionary = flow.drafts[index]
	var panel := PanelContainer.new()
	panel.name = "PlayerBlock%d" % index
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f5f7fa")
	style.border_color = Color(Identity.PALETTES[draft.profile.color][1])
	style.set_border_width_all(2)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel",style)
	grid.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(text_label("PLAYER %d" % (index+1)))
	var name_field := LineEdit.new()
	name_field.name = "PlayerName%d" % index
	name_field.max_length = 24
	name_field.text = draft.nickname
	name_field.text_changed.connect(func(value): flow.drafts[index].nickname = value)
	box.add_child(name_field)
	var preview := Avatar.new()
	preview.configure(draft.profile)
	box.add_child(preview)
	preview.custom_minimum_size=Vector2(72,72)
	var avatars := Button.new()
	avatars.text="Choose icon: "+draft.profile.avatar
	avatars.pressed.connect(func(): create_avatar_gallery(index,preview,avatars).popup_centered())
	box.add_child(avatars)
	var image_actions := HBoxContainer.new()
	image_actions.add_child(action("Upload image",func(): choose_image(index,preview)))
	image_actions.add_child(action("Remove image",func():
		flow.drafts[index].profile.image = ""
		preview.configure(flow.drafts[index].profile)))
	box.add_child(image_actions)
	var colors := OptionButton.new()
	colors.name = "PlayerColors%d" % index
	colors.size_flags_horizontal = SIZE_EXPAND_FILL
	colors.fit_to_longest_item = false
	for palette in Identity.PALETTES:
		colors.add_item(palette[0])
	colors.select(draft.profile.color)
	colors.item_selected.connect(func(selected):
		flow.drafts[index].profile.color = selected
		preview.configure(flow.drafts[index].profile)
		refresh_colors())
	box.add_child(colors)
	color_controls.append(colors)
	box.add_child(text_label("Player PIN: " + ("Enabled" if flow.session.access.credentials.has("player_%d" % index) else "Off")))
	var pin := pin_field("NewPin%d" % index,"Enter new PIN",draft.pin)
	var confirmation := pin_field("ConfirmPin%d" % index,"Enter new PIN again",draft.confirm)
	pin.editable = not draft.remove
	confirmation.editable = not draft.remove
	pin.text_changed.connect(func(value): flow.drafts[index].pin = value)
	confirmation.text_changed.connect(func(value): flow.drafts[index].confirm = value)
	box.add_child(pin)
	box.add_child(confirmation)
	var remove := CheckBox.new()
	remove.text = "Remove player PIN"
	remove.button_pressed = draft.remove
	remove.toggled.connect(func(value):
		flow.drafts[index].remove = value
		if value:
			flow.drafts[index].pin = ""
			flow.drafts[index].confirm = ""
			pin.text = ""
			confirmation.text = ""
		pin.editable = not value
		confirmation.editable = not value)
	box.add_child(remove)
	var virtual_note := Label.new()
	virtual_note.text="Use V on the betting panels for simulated play. Edit numbered styles in Virtual player styles."
	virtual_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	box.add_child(virtual_note)

func pin_field(node_name: String, prompt: String, initial: String) -> LineEdit:
	var field := LineEdit.new()
	field.name = node_name
	field.secret = true
	field.max_length = 4
	field.placeholder_text = prompt
	field.text = initial
	return field

func refresh_colors() -> void:
	for i in range(color_controls.size()):
		for color in range(Identity.PALETTES.size()):
			var owner := -1
			for other in range(8):
				if other != i and flow.drafts[other].profile.color == color:
					owner = other
			color_controls[i].set_item_disabled(color,owner >= 0)
			color_controls[i].set_item_text(color,Identity.PALETTES[color][0] + (" (Player %d)" % (owner+1) if owner >= 0 else ""))

func choose_image(index: int, preview: Control) -> void:
	var dialog := create_image_picker(index,preview)
	dialog.popup_centered_ratio(0.7)

func create_image_picker(index: int, preview: Control) -> FileDialog:
	var dialog := preload("res://ui/file_picker.gd").make()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Player image"])
	add_child(dialog)
	dialog.file_selected.connect(func(path):
		var result := Identity.image_from_file(path)
		if result.ok:
			flow.drafts[index].profile.image = result.image
			preview.configure(flow.drafts[index].profile)
		else:
			var alert := AcceptDialog.new()
			alert.dialog_text = result.error
			add_child(alert)
			alert.confirmed.connect(alert.queue_free)
			alert.popup_centered()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	return dialog

func create_avatar_gallery(index: int, preview: Control, caption: Button) -> AcceptDialog:
	var dialog:=AcceptDialog.new()
	dialog.name="AvatarGallery"
	dialog.title="Player %d: choose an icon" % (index+1)
	dialog.get_ok_button().text="Keep current image"
	dialog.min_size=Vector2i(560,540)
	var grid:=GridContainer.new()
	grid.name="AvatarChoices"
	grid.columns=5
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	dialog.add_child(grid)
	var group:=ButtonGroup.new()
	for avatar in Identity.AVATARS:
		var button:=Button.new()
		button.name="Icon"+avatar
		button.tooltip_text=avatar
		button.custom_minimum_size=Vector2(98,108)
		button.toggle_mode=true; button.button_group=group
		button.button_pressed=flow.drafts[index].profile.image.is_empty() and flow.drafts[index].profile.avatar==avatar
		var content:=VBoxContainer.new()
		content.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left=5; content.offset_right=-5; content.offset_top=5; content.offset_bottom=-5
		var picture:=Avatar.new()
		picture.configure({"avatar":avatar,"image":"","color":flow.drafts[index].profile.color})
		picture.custom_minimum_size=Vector2(70,70)
		picture.size_flags_vertical=Control.SIZE_EXPAND_FILL
		content.add_child(picture)
		var label:=Label.new(); label.text=avatar; label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",14); label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
		button.pressed.connect(func():
			flow.drafts[index].profile.avatar=avatar
			flow.drafts[index].profile.image=""
			preview.configure(flow.drafts[index].profile)
			preview.custom_minimum_size=Vector2(72,72)
			caption.text="Choose icon: "+avatar
			dialog.hide(); dialog.queue_free())
		grid.add_child(button)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	return dialog
