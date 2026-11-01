extends CanvasLayer

const APRIL_24_2026 := "2026-04-24"
const APRIL_25_2026 := "2026-04-25"
const SCORE_LABEL_PREFIX := "SCORE: %05d"
const FILTER_SELECTED_COLOR := Color(0.60, 0.43, 0.98, 1.0)
const FILTER_IDLE_COLOR := Color(1.0, 1.0, 1.0, 1.0)

@onready var hud: Control = $HUD
@onready var score_label: Label = $HUD/ScoreLabel
@onready var game_over_score_label: Label = $GameOverMenu/ScoreLabel
@onready var main_menu: Control = $MainMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var register_menu: Control = $RegisterMenu
@onready var scoreboard_menu: Control = $ScoreboardMenu
@onready var controls_menu: Control = $ControlsMenu
@onready var initials_input: LineEdit = $RegisterMenu/InitialsInput
@onready var score_list: VBoxContainer = $ScoreboardMenu/ScrollContainer/ScoreList
@onready var btn_save: Button = $RegisterMenu/BtnSave
@onready var btn_day_24: Button = $ScoreboardMenu/HBoxContainer/BtnDay24
@onready var btn_day_25: Button = $ScoreboardMenu/HBoxContainer/BtnDay25
@onready var btn_all: Button = $ScoreboardMenu/HBoxContainer/BtnAll
@onready var btn_scoreboard_close: Button = $ScoreboardMenu/BtnClose
@onready var leaderboard_client = get_node("/root/LeaderboardClient")

var _scoreboard_status_label: Label
var _register_status_label: Label

func _ready() -> void:
	if Global.score_updated.is_connected(_on_score_updated):
		Global.score_updated.disconnect(_on_score_updated)
	Global.score_updated.connect(_on_score_updated)
	if Global.game_over_triggered.is_connected(show_game_over):
		Global.game_over_triggered.disconnect(show_game_over)
	Global.game_over_triggered.connect(show_game_over)
	if not btn_day_24.pressed.is_connected(_on_btn_day_24_pressed):
		btn_day_24.pressed.connect(_on_btn_day_24_pressed)
	if not btn_day_25.pressed.is_connected(_on_btn_day_25_pressed):
		btn_day_25.pressed.connect(_on_btn_day_25_pressed)
	if not btn_all.pressed.is_connected(_on_btn_all_pressed):
		btn_all.pressed.connect(_on_btn_all_pressed)

	_ensure_feedback_labels()
	_set_status(_scoreboard_status_label, "", false)
	_set_status(_register_status_label, "", false)

	if Global.is_restarting:
		Global.is_restarting = false
		show_screen(null)
		Global.reset_game()
	else:
		get_tree().paused = true
		show_screen(main_menu)

func _on_score_updated(new_score: int) -> void:
	var score_text := SCORE_LABEL_PREFIX % new_score
	score_label.text = score_text
	game_over_score_label.text = score_text

func show_screen(screen_to_show: Control) -> void:
	main_menu.hide()
	game_over_menu.hide()
	register_menu.hide()
	scoreboard_menu.hide()
	controls_menu.hide()

	if screen_to_show != null:
		screen_to_show.show()

	hud.visible = (screen_to_show == null)

func _on_btn_play_pressed() -> void:
	show_screen(null)
	Global.reset_game()
	get_tree().reload_current_scene()

func _on_btn_controls_pressed() -> void:
	show_screen(controls_menu)

func _on_btn_scoreboard_pressed() -> void:
	show_screen(scoreboard_menu)
	await _load_scoreboard_all()

func show_game_over() -> void:
	game_over_score_label.text = SCORE_LABEL_PREFIX % int(Global.actual_score)
	show_screen(game_over_menu)

func _on_btn_play_again_pressed() -> void:
	_on_btn_play_pressed()

func _on_btn_main_menu_pressed() -> void:
	Global.game_active = false
	Global.clear_touch_actions()
	get_tree().paused = true
	show_screen(main_menu)

func _on_btn_register_pressed() -> void:
	show_screen(register_menu)
	initials_input.clear()
	_set_status(_register_status_label, "", false)
	initials_input.grab_focus()

func _on_btn_save_pressed() -> void:
	await _submit_current_score()

func _on_btn_day_24_pressed() -> void:
	show_screen(scoreboard_menu)
	await _load_scoreboard_by_date(APRIL_24_2026)

func _on_btn_day_25_pressed() -> void:
	show_screen(scoreboard_menu)
	await _load_scoreboard_by_date(APRIL_25_2026)

func _on_btn_all_pressed() -> void:
	show_screen(scoreboard_menu)
	await _load_scoreboard_all()

func _on_btn_close_pressed() -> void:
	show_screen(main_menu)

func _on_btn_close_controls_pressed() -> void:
	show_screen(main_menu)

func _submit_current_score() -> void:
	var initials := initials_input.text.strip_edges().to_upper()
	var score_value := int(Global.actual_score)
	if not _is_valid_initials(initials):
		_set_status(_register_status_label, "Usa exactamente 3 letras mayúsculas.", true)
		return

	_set_loading_state(true, "Enviando score...")
	_set_status(_register_status_label, "", false)
	btn_save.disabled = true

	var result: Dictionary = await leaderboard_client.submit_score(initials, score_value)
	_set_loading_state(false, "")
	btn_save.disabled = false

	if result.get("ok", false):
		_set_status(_register_status_label, "Score enviado correctamente.", false)
		leaderboard_client.clear_cache()
		show_screen(scoreboard_menu)
		await _load_scoreboard_all()
	else:
		_set_status(_register_status_label, String(result.get("message", "No se pudo enviar el score.")), true)

func _load_scoreboard_all() -> void:
	_set_selected_filter_button("all")
	_set_loading_state(true, "Cargando top global...")
	_render_score_list([])
	_set_status(_scoreboard_status_label, "", false)
	_set_score_list_busy(true)

	var result: Dictionary = await leaderboard_client.get_top_all()
	_apply_scoreboard_result(result, "Top global")

func _load_scoreboard_by_date(date_str: String) -> void:
	if date_str == APRIL_24_2026:
		_set_selected_filter_button("24")
	elif date_str == APRIL_25_2026:
		_set_selected_filter_button("25")
	else:
		_set_selected_filter_button("")

	_set_loading_state(true, "Cargando top del %s..." % date_str)
	_render_score_list([])
	_set_status(_scoreboard_status_label, "", false)
	_set_score_list_busy(true)

	var result: Dictionary = await leaderboard_client.get_top_by_date(date_str)
	_apply_scoreboard_result(result, date_str)

func _apply_scoreboard_result(result: Dictionary, _label_name: String) -> void:
	_set_loading_state(false, "")
	_set_score_list_busy(false)

	if not result.get("ok", false):
		_set_status(_scoreboard_status_label, String(result.get("message", "No se pudo cargar el ranking.")), true)
		_render_score_list([])
		return

	var scores: Array = result.get("scores", result.get("data", []))
	_set_status(_scoreboard_status_label, "", false)
	_render_score_list(scores)

func _render_score_list(scores: Array) -> void:
	for child in score_list.get_children():
		child.queue_free()

	if scores.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No hay scores para mostrar."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_list.add_child(empty_label)
		return

	for index in scores.size():
		var entry: Dictionary = scores[index]
		var initials := String(entry.get("initials", entry.get("name", ""))).to_upper()
		var score_value := int(entry.get("score", 0))
		var row := Label.new()
		row.text = "%d. %s - %d" % [index + 1, initials, score_value]
		score_list.add_child(row)

func _set_loading_state(is_loading: bool, message: String) -> void:
	btn_day_24.disabled = is_loading
	btn_day_25.disabled = is_loading
	btn_all.disabled = is_loading
	btn_scoreboard_close.disabled = is_loading
	if is_loading:
		_set_status(_scoreboard_status_label, message, false)

func _set_selected_filter_button(filter_key: String) -> void:
	btn_day_24.modulate = FILTER_SELECTED_COLOR if filter_key == "24" else FILTER_IDLE_COLOR
	btn_day_25.modulate = FILTER_SELECTED_COLOR if filter_key == "25" else FILTER_IDLE_COLOR
	btn_all.modulate = FILTER_SELECTED_COLOR if filter_key == "all" else FILTER_IDLE_COLOR

func _set_score_list_busy(is_busy: bool) -> void:
	score_list.modulate = Color(1, 1, 1, 0.6 if is_busy else 1.0)

func _set_status(label: Label, message: String, is_error: bool) -> void:
	if label == null:
		return
	label.text = message
	label.visible = not message.is_empty()
	label.modulate = Color(1.0, 0.35, 0.35) if is_error else Color(0.85, 0.95, 1.0)

func _ensure_feedback_labels() -> void:
	_scoreboard_status_label = Label.new()
	_scoreboard_status_label.name = "StatusLabel"
	_scoreboard_status_label.position = Vector2(20.0, 28.0)
	_scoreboard_status_label.size = Vector2(280.0, 16.0)
	_scoreboard_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scoreboard_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scoreboard_menu.add_child(_scoreboard_status_label)

	_register_status_label = Label.new()
	_register_status_label.name = "StatusLabel"
	_register_status_label.position = Vector2(104.0, 120.0)
	_register_status_label.size = Vector2(112.0, 24.0)
	_register_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_register_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	register_menu.add_child(_register_status_label)

func _is_valid_initials(initials: String) -> bool:
	if initials.length() != 3:
		return false
	for character_index in initials.length():
		var character := initials.substr(character_index, 1)
		if character < "A" or character > "Z":
			return false
	return true
