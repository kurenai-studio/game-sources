extends ScreenBase
## Settings: sound, music, vibration, reduce motion, run speed, and theme. Every choice shows its
## state in words as well as fill, and each change is saved at once.
##
## Opened from the menu or from the pause menu; `args["back"]` names where Back returns to.

const THEME_NAMES: Array[String] = ["system", "light", "dark"]
const SPEED_NAMES: Array[String] = ["slow", "normal", "fast"]
const LOOK_NAMES: Array[String] = ["flat", "depth"]

var _back: TileButton
var _title: Label
var _scroll: ScrollContainer
var _list: VBoxContainer
var _privacy: TileButton
var _version: Label


func _build() -> void:
	_back = TileButton.make(TileButton.Kind.SECONDARY, "", "back")
	_back.accessibility_name = "Back"
	_back.pressed.connect(go_back)
	add_child(_back)

	_title = UiKit.label("SETTINGS", 34, Palette.INK, 1)
	add_child(_title)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_scroll.add_child(_list)

	var settings := app.progress.settings
	_list.add_child(UiRows.caption("AUDIO AND TOUCH"))
	_list.add_child(UiRows.toggle_row("SOUND", settings.sound(), _toggle_sound))
	_list.add_child(UiRows.toggle_row("MUSIC", settings.music(), _toggle_music))
	# The browser build has no vibration and no link out: the site around it has both.
	if not OS.has_feature("web"):
		_list.add_child(UiRows.toggle_row("VIBRATION", settings.vibration(), _toggle_vibration))
	_list.add_child(UiRows.gap(10.0))
	_list.add_child(UiRows.caption("MOTION"))
	_list.add_child(UiRows.toggle_row("REDUCE MOTION", settings.reduce_motion(), _toggle_motion))
	_list.add_child(UiRows.segment_row("RUN SPEED", SPEED_NAMES, settings.run_speed(), _set_speed))
	_list.add_child(UiRows.gap(10.0))
	_list.add_child(UiRows.caption("LOOK"))
	_list.add_child(UiRows.segment_row("THEME", THEME_NAMES, settings.theme(), _set_theme))
	_list.add_child(UiRows.segment_row("STYLE", LOOK_NAMES, settings.look(), _set_look))

	_restore_scroll.call_deferred()
	if not OS.has_feature("web"):
		_privacy = TileButton.make(TileButton.Kind.TERTIARY, "PRIVACY", "", 16)
		_privacy.align = HORIZONTAL_ALIGNMENT_LEFT
		_privacy.pressed.connect(func() -> void: Links.open("/privacy"))
		add_child(_privacy)
	_version = UiKit.label("VERSION %s" % Links.version(), 14, Palette.MUTE, 2)
	_version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_version)


func go_back() -> void:
	navigate.emit(str(args.get("back", "home")), args.get("back_args", {}))


func _layout() -> void:
	if _version == null:
		return
	var m := margin()
	var width := size.x - 2.0 * m
	var top := inset_top() + (28.0 if size.y >= 700.0 else 12.0)
	_back.position = Vector2(m, top)
	_back.size = Vector2(44.0, 44.0)
	_title.position = Vector2(m, top + 54.0)
	_title.size = Vector2(width, 40.0)
	var footer_h := 48.0
	var bottom := size.y - inset_bottom() - m
	if _privacy != null:
		_privacy.position = Vector2(m, bottom - footer_h)
		_privacy.size = Vector2(width * 0.4, footer_h)
	_version.position = Vector2(size.x - m - width * 0.55, bottom - footer_h)
	_version.size = Vector2(width * 0.55, footer_h)
	var list_top := _title.position.y + 56.0
	_scroll.position = Vector2(m, list_top)
	_scroll.size = Vector2(width, bottom - footer_h - 8.0 - list_top)
	_list.custom_minimum_size = Vector2(width, 0)


func _changed() -> void:
	app.progress.save()
	app.request_sync()
	# The screen is rebuilt (the theme needs it); keep the scroll position.
	args["scroll"] = _scroll.scroll_vertical
	if app.feedback != null:
		app.feedback.apply_music()
	app.apply_theme()
	navigate.emit("settings", args)


func _toggle_sound() -> void:
	app.progress.settings.set_sound(not app.progress.settings.sound())
	_changed()
	app.sfx("tap")


func _toggle_music() -> void:
	app.progress.settings.set_music(not app.progress.settings.music())
	_changed()


func _toggle_vibration() -> void:
	app.progress.settings.set_vibration(not app.progress.settings.vibration())
	_changed()
	app.haptic(40)


func _toggle_motion() -> void:
	app.progress.settings.set_reduce_motion(not app.progress.settings.reduce_motion())
	_changed()


func _set_speed(option: String) -> void:
	app.progress.settings.set_run_speed(option)
	_changed()


func _set_look(option: String) -> void:
	app.progress.settings.set_look(option)
	_changed()


func _set_theme(option: String) -> void:
	app.progress.settings.set_theme(option)
	_changed()


func _restore_scroll() -> void:
	var wanted := int(args.get("scroll", 0))
	if wanted > 0 and is_inside_tree():
		_scroll.scroll_vertical = wanted
