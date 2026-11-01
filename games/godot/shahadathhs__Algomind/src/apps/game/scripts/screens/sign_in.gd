extends ScreenBase
## Sign in (or create an account). Optional: guest play is the default and uploads nothing.
## `args["back"]` names where Back and "continue as guest" return to (default "home").

var _creating := false
var _busy := false

var _back: TileButton
var _caption: Label
var _title: Label
var _intro: Label
var _email_caption: Label
var _email: TextField
var _password_caption: Label
var _password: TextField
var _message: Label
var _submit: TileButton
var _switch: TileButton
var _guest: TileButton


func _build() -> void:
	_back = TileButton.make(TileButton.Kind.SECONDARY, "", "back")
	_back.accessibility_name = "Back"
	_back.pressed.connect(go_back)
	add_child(_back)
	_caption = UiKit.label("OPTIONAL", 14, Palette.MUTE, 3)
	add_child(_caption)
	_title = UiKit.label("SIGN IN", 34, Palette.INK, 1)
	add_child(_title)
	_intro = UiKit.label(
		"PLAYING AS GUEST. PROGRESS STAYS ON THIS DEVICE UNTIL YOU SIGN IN.", 14, Palette.MUTE, 1
	)
	_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_intro)

	_email_caption = UiKit.label("EMAIL", 13, Palette.MUTE, 2)
	add_child(_email_caption)
	_email = TextField.new()
	_email.placeholder = "you@example.com"
	_email.email = true
	_email.accessible_label = "Email"
	_email.submitted.connect(func(_text: String) -> void: _password.grab_edit_focus())
	add_child(_email)
	_password_caption = UiKit.label("PASSWORD", 13, Palette.MUTE, 2)
	add_child(_password_caption)
	_password = TextField.new()
	_password.secret = true
	_password.accessible_label = "Password"
	_password.submitted.connect(func(_text: String) -> void: _submit_form())
	add_child(_password)

	_message = UiKit.label("", 14, Palette.INK, 1)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_message)

	_submit = TileButton.make(TileButton.Kind.PRIMARY, "SIGN IN", "", 24)
	_submit.pressed.connect(_submit_form)
	add_child(_submit)
	_switch = TileButton.make(TileButton.Kind.TERTIARY, "CREATE ACCOUNT", "", 16)
	_switch.pressed.connect(_toggle_mode)
	add_child(_switch)
	_guest = TileButton.make(TileButton.Kind.TERTIARY, "CONTINUE AS GUEST", "", 16)
	_guest.pressed.connect(go_back)
	add_child(_guest)
	_apply_mode()


func go_back() -> void:
	navigate.emit(str(args.get("back", "home")), {})


func _layout() -> void:
	if _guest == null:
		return
	var m := margin()
	var width := size.x - 2.0 * m
	var top := inset_top() + (28.0 if size.y >= 700.0 else 12.0)
	_back.position = Vector2(m, top)
	_back.size = Vector2(44.0, 44.0)
	_caption.position = Vector2(m, top + 54.0)
	_caption.size = Vector2(width, 18.0)
	_title.position = Vector2(m, top + 70.0)
	_title.size = Vector2(width, 40.0)
	_intro.position = Vector2(m, top + 114.0)
	_intro.size = Vector2(width, 40.0)
	var y := top + 170.0
	_email_caption.position = Vector2(m, y)
	_email_caption.size = Vector2(width, 18.0)
	_email.position = Vector2(m, y + 22.0)
	_email.size = Vector2(width, 52.0)
	y += 90.0
	_password_caption.position = Vector2(m, y)
	_password_caption.size = Vector2(width, 18.0)
	_password.position = Vector2(m, y + 22.0)
	_password.size = Vector2(width, 52.0)
	_message.position = Vector2(m, y + 84.0)
	_message.size = Vector2(width, 44.0)
	var bottom := size.y - inset_bottom() - m
	_guest.size = Vector2(width, 48.0)
	_guest.position = Vector2(m, bottom - 48.0)
	_switch.size = Vector2(width, 48.0)
	_switch.position = Vector2(m, bottom - 96.0)
	var primary_h := 64.0 if size.y >= 700.0 else 56.0
	_submit.size = Vector2(width, primary_h)
	_submit.position = Vector2(m, bottom - 96.0 - 8.0 - primary_h)


func _toggle_mode() -> void:
	if _busy:
		return
	_creating = not _creating
	_message.text = ""
	_apply_mode()


func _apply_mode() -> void:
	_title.text = "CREATE ACCOUNT" if _creating else "SIGN IN"
	_submit.label = "CREATE ACCOUNT" if _creating else "SIGN IN"
	_submit.accessibility_name = _submit.label
	_switch.label = "I HAVE AN ACCOUNT" if _creating else "CREATE ACCOUNT"
	_switch.accessibility_name = _switch.label
	_submit.queue_redraw()
	_switch.queue_redraw()


func _submit_form() -> void:
	if _busy:
		return
	var email := _email.text.strip_edges()
	var password := _password.text
	if email.is_empty() or password.is_empty():
		_message.text = "ENTER YOUR EMAIL AND PASSWORD"
		return
	_set_busy(true)
	var client := app.account_client
	var result: Dictionary
	if _creating:
		result = await client.register(email, password)
	else:
		result = await client.sign_in(email, password)
	if not is_inside_tree():
		return
	_set_busy(false)
	if result["ok"]:
		app.request_sync()
		navigate.emit("account", {})
	else:
		_message.text = str(result["message"])


func _set_busy(value: bool) -> void:
	_busy = value
	_submit.set_disabled(value)
	_message.text = ("WORKING..." if _creating else "SIGNING IN...") if value else ""
