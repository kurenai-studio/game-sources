extends PanelContainer
const Avatar = preload("res://ui/player_avatar.gd")
const Identity = preload("res://core/player_identity.gd")

func configure(profile: Dictionary, caption: String, avatar_size: int = 44, font_size: int = 16) -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var palette: Array = Identity.PALETTES[profile.color]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(palette[1])
	style.set_content_margin_all(3)
	add_theme_stylebox_override("panel",style)
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",8)
	add_child(row)
	var avatar := Avatar.new()
	avatar.name = "Avatar"
	avatar.configure(profile)
	avatar.custom_minimum_size = Vector2(avatar_size,avatar_size)
	row.add_child(avatar)
	var label := Label.new()
	label.text = caption
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color(palette[2]))
	label.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(label)
