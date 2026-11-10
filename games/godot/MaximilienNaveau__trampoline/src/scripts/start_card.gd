# The cream card on the box lid (see box_lid.gd): the title, the tagline,
# and the start menu — "Reprendre la partie", "Charger une partie" (then
# the list of games saved by hand), how many players (then their names),
# "Jeu libre", the crosswords, "Comment jouer". It only reports what the
# player chose, through its signals; main.gd starts it.
#
# Purely a menu: it creates no game itself.
extends VBoxContainer

# A game for `names.size()` players, `names[i]` what player i entered
# (maybe empty: see main.gd's `_player_name`).
signal game_chosen(names: Array[String])
# "Reprendre la partie": whatever was played last (see main.gd's
# `_on_resume_chosen`).
signal resume_chosen
# Free play (`puzzle_index` -1), or crossword number `puzzle_index + 1`.
signal free_play_chosen(puzzle_index: int)
signal how_to_play_chosen
# A game saved by hand (see SaveGame.keep_copy), its file at `path`.
signal saved_game_chosen(path: String)

# The saved games listed at most, newest first.
const _SAVED_GAMES_SHOWN := 8

# How many players the count buttons picked, kept until the names are
# confirmed (see `_on_names_confirmed`).
var _player_count := 0

@onready var _start_menu: Control = $StartMenu
@onready var _name_entry: Control = $NameEntry
@onready var _resume_button: Button = $StartMenu/ResumeButton
@onready var _load_button: Button = $StartMenu/LoadButton
# The list of games saved by hand, and the rows in it.
@onready var _saved_games: Control = $SavedGames
@onready var _saved_list: VBoxContainer = $SavedGames/List
# The 4 name fields, indexed 0..3 to match player_id — only the first
# `_player_count` of them are shown (see `_on_player_count_chosen`).
@onready var _name_edits: Array[LineEdit] = [
	$NameEntry/Name1Edit,
	$NameEntry/Name2Edit,
	$NameEntry/Name3Edit,
	$NameEntry/Name4Edit,
]


func _ready() -> void:
	# `Callable.bind(n)` hands the same method one extra fixed argument per
	# button (n itself), rather than four near-identical handlers.
	for count in range(1, 5):
		get_node("StartMenu/Players/Button%d" % count).pressed.connect(
			_on_player_count_chosen.bind(count)
		)
	$NameEntry/Buttons/StartButton.pressed.connect(_on_names_confirmed)
	$NameEntry/Buttons/BackButton.pressed.connect(show_menu)
	_resume_button.pressed.connect(resume_chosen.emit)
	$StartMenu/HowToPlayButton.pressed.connect(how_to_play_chosen.emit)
	_load_button.pressed.connect(_show_saved_games)
	$SavedGames/BackButton.pressed.connect(show_menu)
	$StartMenu/FreePlayButton.pressed.connect(free_play_chosen.emit.bind(-1))
	# The 10 crossword buttons, each reporting its index in
	# CrosswordPuzzles.PUZZLES (see crossword_puzzles.gd).
	for i in range(CrosswordPuzzles.PUZZLES.size()):
		get_node("StartMenu/CrosswordGrid/CrosswordPuzzle%dButton" % (i + 1)).pressed.connect(
			free_play_chosen.emit.bind(i)
		)


# Shows the title and the start menu: "Reprendre la partie" only while
# something is saved, saying what (see `_describe_resume`); "Charger une
# partie" only while a game was saved by hand; the crosswords already
# solved marked (cream, framed in green: the theme's DoneButton). The
# green buttons below "Reprendre la partie" always start afresh.
func show_menu() -> void:
	for node: Control in [$Title, $Tagline, _start_menu]:
		node.visible = true
	_name_entry.visible = false
	_saved_games.visible = false
	var last := SaveGame.summary(SaveGame.newest([SaveGame.AUTOSAVE_PATH, SaveGame.FREE_PLAY_PATH]))
	_resume_button.visible = not last.is_empty()
	if not last.is_empty():
		_resume_button.text = "Reprendre la partie\n" + _describe_resume(last)
	_load_button.visible = not SaveGame.saved_games(SaveGame.SAVES_DIR).is_empty()
	var solved := SaveGame.solved_crosswords()
	for i in range(CrosswordPuzzles.PUZZLES.size()):
		var button: Button = get_node("StartMenu/CrosswordGrid/CrosswordPuzzle%dButton" % (i + 1))
		button.theme_type_variation = &"DoneButton" if solved.has(i) else &""


# What "Reprendre la partie" would pick up (a SaveGame.summary): "Jeu
# libre", "Mots croisés n° 3", or a game's players and scores.
static func _describe_resume(last: Dictionary) -> String:
	if last["kind"] == "free_play":
		var index: int = last["puzzle_index"]
		return "Jeu libre" if index < 0 else "Mots croisés n° %d" % (index + 1)
	return _describe_players(last)


# Hides it all, as the lid opens on a game.
func close() -> void:
	for node: Control in [$Title, $Tagline, _start_menu, _name_entry, _saved_games]:
		node.visible = false


# "Charger une partie": the games saved by hand, newest first, one row
# each — a button to load it, saying when it was saved and who has how
# many points, and "×" to delete it.
func _show_saved_games() -> void:
	_start_menu.visible = false
	_saved_games.visible = true
	for row in _saved_list.get_children():
		row.queue_free()
	var games := SaveGame.saved_games(SaveGame.SAVES_DIR)
	if games.is_empty():
		show_menu()
		return
	for game in games.slice(0, _SAVED_GAMES_SHOWN):
		var row := HBoxContainer.new()
		_saved_list.add_child(row)
		var load_button := Button.new()
		load_button.text = _describe(game)
		load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		load_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		load_button.pressed.connect(saved_game_chosen.emit.bind(game["path"]))
		row.add_child(load_button)
		var delete_button := Button.new()
		delete_button.text = "×"
		delete_button.pressed.connect(_delete_saved_game.bind(game["path"]))
		row.add_child(delete_button)


# Deletes the game saved at `path`, and lists the others again.
func _delete_saved_game(path: String) -> void:
	DirAccess.remove_absolute(path)
	_show_saved_games()


# One saved game (see SaveGame.saved_games) in a line: when it was saved,
# in local time — "05/11 14:30" — and each player's points, or, alone,
# just the points.
static func _describe(game: Dictionary) -> String:
	# The system's time zone, as minutes ahead of UTC (`bias`).
	var local: int = game["time"] + Time.get_time_zone_from_system()["bias"] * 60
	var date := Time.get_datetime_dict_from_unix_time(local)
	var when := "%02d/%02d %02d:%02d" % [date["day"], date["month"], date["hour"], date["minute"]]
	return "%s · %s" % [when, _describe_players(game)]


# A turn-based game's players and points (a SaveGame.summary): "Alice 45,
# Bruno 30", or, alone, "Seul · 77 pts".
static func _describe_players(game: Dictionary) -> String:
	var names: Array = game["names"]
	var scores: Array = game["scores"]
	if names.size() == 1:
		return "Seul · %d pts" % scores[0]
	var players: Array[String] = []
	for i in range(names.size()):
		var player_name: String = names[i] if names[i] != "" else "Joueur %d" % (i + 1)
		players.append("%s %d" % [player_name, scores[i]])
	return ", ".join(players)


# A player-count button: shows the name fields, exactly `count` of them.
func _on_player_count_chosen(count: int) -> void:
	_player_count = count
	_start_menu.visible = false
	_name_entry.visible = true
	for i in range(_name_edits.size()):
		_name_edits[i].visible = i < count
		_name_edits[i].text = ""


# "Commencer": the names entered, trimmed of spaces.
func _on_names_confirmed() -> void:
	var names: Array[String] = []
	for i in range(_player_count):
		names.append(_name_edits[i].text.strip_edges())
	game_chosen.emit(names)
