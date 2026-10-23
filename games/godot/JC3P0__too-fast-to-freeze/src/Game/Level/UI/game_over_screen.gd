extends Control

@onready var level_loader     = $"../LevelLoader"
@onready var distance_label   = $GameOver/VBoxContainer/distance
@onready var scores_container = $GameOver/VBoxContainer/ScoresContainer
@onready var name_entry       = $GameOver/VBoxContainer/NameEntrySection
@onready var name_input       = $GameOver/VBoxContainer/NameEntrySection/NameRow/NameInput
@onready var submit_button    = $GameOver/VBoxContainer/NameEntrySection/NameRow/SubmitButton

var _name_regex := RegEx.new()

func _ready() -> void:
	_name_regex.compile("^[A-Z0-9]{3,6}$")
	submit_button.pressed.connect(_on_submit_pressed)

func show_game_over() -> void:
	visible = true
	distance_label.text = "Distance: %dm" % int(GlobalState.total_distance)
	name_entry.visible = false
	get_tree().paused = true

	HighscoreRepository.scores_fetched.connect(_on_scores_fetched, CONNECT_ONE_SHOT)
	HighscoreRepository.fetch_top_10()

# ── Scores fetched ───────────────────────────────────────────────────────────

func _on_scores_fetched(scores: Array) -> void:
	_populate_scores(scores)

	var current := GlobalState.total_distance
	var qualifies := scores.size() < 10 or current > float(scores[-1].get("distance", 0.0))
	if qualifies:
		name_entry.visible = true
		name_input.grab_focus()

const ICE_BLUE := Color(0.6, 0.88, 1.0)
const GOLD    := Color(1.0, 0.84, 0.0)

func _populate_scores(scores: Array) -> void:
	for child in scores_container.get_children():
		child.queue_free()

	if scores.is_empty():
		return

	# Header row
	var header := HBoxContainer.new()
	for col in ["#", "Name", "Dist", "Combo", "Date"]:
		var h := Label.new()
		h.text = col
		h.add_theme_color_override("font_color", ICE_BLUE)
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_child(h)
	scores_container.add_child(header)

	for i in scores.size():
		var s: Dictionary = scores[i]
		var row := HBoxContainer.new()

		var rank := Label.new()
		rank.text = "#%d" % (i + 1)
		rank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var name_lbl := Label.new()
		name_lbl.text = s.get("name", "???")
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var dist_lbl := Label.new()
		dist_lbl.text = "%dm" % int(s.get("distance", 0))
		dist_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dist_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var combo_lbl := Label.new()
		combo_lbl.text = "x%d" % int(s.get("highest_combo", 0))
		combo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		combo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var date_lbl := Label.new()
		date_lbl.text = _format_date(s.get("created_at", ""))
		date_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if i == 0:
			for lbl: Label in [rank, name_lbl, dist_lbl, combo_lbl, date_lbl]:
				lbl.add_theme_color_override("font_color", GOLD)
		else:
			for lbl: Label in [rank, name_lbl, dist_lbl, combo_lbl, date_lbl]:
				lbl.add_theme_color_override("font_color", ICE_BLUE)

		row.add_child(rank)
		row.add_child(name_lbl)
		row.add_child(dist_lbl)
		row.add_child(combo_lbl)
		row.add_child(date_lbl)
		scores_container.add_child(row)

# ── Submit ───────────────────────────────────────────────────────────────────

func _on_submit_pressed() -> void:
	var player_name: String = name_input.text.to_upper().strip_edges()

	if _name_regex.search(player_name) == null:
		name_input.modulate = Color.RED
		await get_tree().create_timer(0.5).timeout
		name_input.modulate = Color.WHITE
		return

	submit_button.disabled = true
	submit_button.text = "Saving..."
	name_input.editable = false

	var highest_combo := 0
	var run_player := get_tree().get_first_node_in_group("Player")
	if run_player:
		var combo := run_player.get_node_or_null("ComboController") as ComboController
		if combo:
			highest_combo = combo.highest_combo_this_run

	HighscoreRepository.score_submitted.connect(_on_score_submitted, CONNECT_ONE_SHOT)
	HighscoreRepository.submit_score(player_name, GlobalState.total_distance, GlobalState.current_phase, highest_combo)

func _on_score_submitted(success: bool, message: String) -> void:
	if success:
		submit_button.text = "Saved!"
		await get_tree().create_timer(0.8).timeout
		name_entry.visible = false
		HighscoreRepository.scores_fetched.connect(_on_scores_fetched, CONNECT_ONE_SHOT)
		HighscoreRepository.fetch_top_10()
	else:
		submit_button.disabled = false
		submit_button.text = "Submit"
		name_input.editable = true
		name_input.placeholder_text = message
		push_warning("Score submit failed: " + message)

# ── Helpers ──────────────────────────────────────────────────────────────────

# Turns "2026-06-24T15:30:00+00:00" into "06-24-26"
func _format_date(iso: String) -> String:
	if iso.length() < 10:
		return ""
	var month := iso.substr(5, 2)
	var day   := iso.substr(8, 2)
	var year  := iso.substr(2, 2)
	return "%s-%s-%s" % [month, day, year]

# ── Retry ────────────────────────────────────────────────────────────────────

func _on_restart_pressed() -> void:
	visible = false
	get_tree().get_first_node_in_group("Player").player_speed = 0
	GlobalState.total_distance = 0
	level_loader.restart_level()
	# Resume music — it pauses with the tree during game over
	var music = get_node_or_null("../MusicLoop/Music")
	if music:
		music.play()
