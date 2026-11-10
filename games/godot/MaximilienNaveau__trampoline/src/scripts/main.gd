# Entry point for the game's main scene: creates a GameSession, shows its
# board/hand via BoardView/HandView, turns a dropped tile (see
# board_view.gd's `tile_dropped` signal) into an actual placement, and ends
# the current turn on a button press. This is the one place allowed to know
# about both the game rules (GameSession) and the views — BoardView/
# HandView never talk to GameSession directly, per this project's
# "separate logic from graphics" rule. The start card (see start_card.gd)
# lets the player pick how many people are playing before `_session` even
# exists — or, instead,
# start the free-play sandbox (see `_start_free_play`/
# free_play_session.gd), which uses `_free_play_session` in `_session`'s
# place. Everything that needs one or the other stays hidden until then
# (see `_start_session`/`_return_to_start_menu`).
extends Control

# How long the end-turn notification takes to fade in/out (see
# `_set_end_turn_message` below) — snapping straight to full opacity read
# as too abrupt for something popping up over the header.
const _END_TURN_MESSAGE_FADE_SECONDS := 0.25
# How many hand tiles fit on one row on a phone held upright: the board's
# 9 columns, minus the "À rendre" tray's room beside the hand (see
# `_update_board_height_budget`).
const _HAND_TILES_PER_ROW := 7

# Kept as a field (not a local var in _ready()) now that other methods
# below — `_on_board_tile_dropped`, `_on_end_turn_pressed` — need to reach
# it too.
var _session: GameSession

# The free-play sandbox session (see free_play_session.gd), used INSTEAD
# of `_session` when the player picks "Jeu libre" — at most one of the
# two is ever non-null at a time (see `_is_free_play`).
var _free_play_session: FreePlaySession

# The active crossword puzzle (see crossword_puzzle.gd), used ALONGSIDE
# `_free_play_session` when the player picks "Mots croisés" — crossword
# mode is free play's exact same sandbox mechanics, plus this overlay
# checking the board against a hidden target (see `_is_crossword`).
var _crossword_puzzle: CrosswordPuzzle

# Loaded once and reused for every session this app run creates (see
# `_dictionary()` below) — every one of GameSession/FreePlaySession's own
# constructors would otherwise happily load its own fresh copy of the
# ~421,000-word list (see french_dictionary.gd), each time a mode is
# (re)started.
var _shared_dictionary: FrenchDictionary
# Loads that dictionary in the background, started as soon as the start
# menu shows (see `_ready()`), so it's usually done by the time a mode is
# picked instead of making the player wait then (a fraction of a second
# on a phone). A Thread
# is a real OS thread, like std::thread / Python's threading.Thread.
var _dictionary_thread := Thread.new()

# Whether the turn timer (see doc/RULES.md's "3-minute soft/hard time
# limit") is switched on right now — a player preference toggled via
# OptionsPanel's `_timer_toggle`, independent of any particular
# GameSession (it survives a New Game).
var _timer_enabled: bool = false

# `$Layout/Margin/Content/...` look up the child nodes declared in scenes/main.tscn —
# the same shorthand board_view.gd itself uses for its own "Grid" child.
# `@onready` runs this once those children actually exist, rather than too
# early (see board_view.gd for the same pattern). Everything visible lives
# inside `Content`, a VBoxContainer that stacks top-to-bottom instead of
# each node anchoring itself to a hand-picked pixel offset, so the whole
# screen reflows on a narrower/taller window (a phone in portrait) instead
# of clipping or running off-screen. `Layout`, the actual direct child of
# Main, is a ScrollContainer (see drag_steady_scroll.gd) around it all — a safety net in case
# some screen is too short to fit everything (the whole page scrolls
# rather than cropping), not part of the reflow itself. `Margin`, right
# below it, just adds a fixed border of breathing room around `Content`
# on all four sides (see main.tscn) so nothing sits flush against the
# screen edge.
# The start menu on the box lid (see start_card.gd).
@onready var _start_card: Control = $BoxLid/Box/Hinge/Lid/CardArea/Card/Items
# The board with the hand (or palette and clue list) beside or under it:
# its layout is play_area.gd's job, main.gd only says which orientation
# (see `_update_play_area_orientation` below).
@onready var _play_area: PlayArea = $Layout/Margin/Content/PlayArea
# Their margin/position are what `_update_board_height_budget` measures.
@onready var _margin: MarginContainer = $Layout/Margin
@onready var _content: VBoxContainer = $Layout/Margin/Content
@onready var _board_view: BoardView = $Layout/Margin/Content/PlayArea/BoardView
@onready var _hand_view: HandView = $Layout/Margin/Content/PlayArea/HandArea/HandBar/HandView
# Beside the hand: where the player drags tiles to give them back to the
# bag at the end of their turn (see discard_tray.gd).
@onready
var _discard_tray: DiscardTray = $Layout/Margin/Content/PlayArea/HandArea/HandBar/DiscardTray
@onready var _end_turn_button: Button = $Layout/Margin/Content/TopBar/EndTurnButton
# The scores, and the current turn's points as they build up (see
# scoreboard.gd).
@onready var _scoreboard: Scoreboard = $Layout/Margin/Content/Scoreboard
@onready var _game_over_banner: Label = $Layout/Margin/Content/GameOverBanner
# Shown once a turn-based game is over (see end_screen.gd).
@onready var _end_screen: EndScreen = $EndScreen
# A floating notification, not part of the page's normal top-to-bottom
# flow — declared as a direct child of Main in main.tscn (a sibling of
# Layout, not nested inside it) so it draws OVER the header instead of
# pushing the board down, and disappears on its own after
# `_end_turn_message_timer` runs out (see `_set_end_turn_message` below).
# `_end_turn_banner` is the whole colored box, `_end_turn_message` is just
# its text.
@onready var _end_turn_banner: PanelContainer = $EndTurnMessage
@onready var _end_turn_message: Label = $EndTurnMessage/Text
@onready var _end_turn_message_timer: Timer = $EndTurnMessageTimer
# "Quitter la partie" lives inside the "☰" dropdown menu (OptionsPanel)
# instead of a permanently-visible row, to leave more of a small phone
# screen for the board itself — see `_on_options_pressed`.
@onready var _new_game_button: Button = $Layout/Margin/Content/OptionsPanel/MenuItems/NewGameButton
# "Sauvegarder la partie": keeps a copy of the game in progress (see
# `_on_save_copy_pressed`).
@onready var _save_copy_button: Button = %SaveCopyButton
# "Comment jouer": the animated rules (see how_to_play_view.gd), opened
# from the start menu or the ☰ menu, drawn over everything else.
@onready var _how_to_play: HowToPlayView = $HowToPlay
# The music played during a game — a tune per mode (see music_tracks.gd,
# made by tools/audio/make_music.py). An AudioStreamPlayer is the node
# that plays a sound not placed anywhere on screen (no left/right panning
# by position): `play()` starts its `stream` from the top, `stop()` stops
# it. Each file is imported as a loop (see e.g.
# multi_le_bouquiniste.ogg.import), so it goes round until stopped.
# FadingMusic (see fading_music.gd) adds fading in and out.
@onready var _game_music: FadingMusic = $GameMusic
# The start menu's music, "La Valse des lettres" — looped the same way.
@onready var _menu_music: FadingMusic = $MenuMusic
# Every sound effect, played by name (see sound_effects.gd).
@onready var _sound_effects: SoundEffects = $SoundEffects
@onready var _how_to_play_menu_button: Button = %HowToPlayMenuButton
@onready var _options_button: Button = $Layout/Margin/Content/TopBar/OptionsButton
@onready var _options_panel: PanelContainer = $Layout/Margin/Content/OptionsPanel
@onready var _timer_toggle: CheckButton = $Layout/Margin/Content/OptionsPanel/MenuItems/TimerToggle
# The speaker button beside ☰, and the sound menu it opens (volumes and
# mutes for everything, the music and the sound effects: see
# sound_panel.gd).
@onready var _sound_button: Button = $Layout/Margin/Content/TopBar/SoundButton
@onready var _sound_panel: SoundPanel = $Layout/Margin/Content/SoundPanel
@onready var _turn_timer_label: Label = $Layout/Margin/Content/TopBar/TurnTimerLabel
# The game's one-hour clock in the header (see game_clock.gd).
@onready var _game_clock: GameClock = $Layout/Margin/Content/TopBar/GameClock
@onready var _turn_timer: Timer = $TurnTimer
# Puts the board and hand back as they were when the turn began (see
# GameSession.reset_turn).
@onready var _reset_turn_button: Button = $Layout/Margin/Content/TopBar/ResetTurnButton
# Under the hand: "Trier", "Tout jaune", "Tout vert" (see hand_tiles.gd).
@onready var _hand_tools: HBoxContainer = $Layout/Margin/Content/PlayArea/HandArea/HandTools
@onready var _new_game_confirm_dialog: ConfirmationDialog = $NewGameConfirmDialog
@onready var _palette_view: HandView = $Layout/Margin/Content/PlayArea/HandArea/PaletteView
@onready var _clue_list_view: ClueListView = $Layout/Margin/Content/PlayArea/HandArea/ClueListView
# Portrait's replacement for `_clue_list_view`: a "?" per board row that
# pops up its clue in a speech bubble (see clue_markers_view.gd). A child
# of BoardView in main.tscn, so it sits over the board and scrolls with it.
@onready var _clue_markers: ClueMarkersView = $Layout/Margin/Content/PlayArea/BoardView/ClueMarkers
# The start screen: the closed game box, with the menu on a card on its
# lid (see box_lid.gd). Choosing a mode sets the game up underneath
# FIRST, then slides the lid away to reveal it — in multiplayer, that
# reveals the handoff screen ("Au tour de …") (see `_begin_turn`), drawn under the
# lid in main.tscn, so player 1's tiles still stay hidden until "C'est moi !".
@onready var _box_lid: BoxLid = $BoxLid
# The handoff screen ("Au tour de Alice", "C'est moi !") shown between two players' turns (see
# `_begin_turn` below). Like EndTurnMessage, it's a direct child of Main,
# declared AFTER Layout in main.tscn so it draws over the whole page —
# board and hand included — and, being a fully opaque `Panel` (same theme
# background as `Background`), hides the next player's tiles until they
# press "C'est moi !". A `Panel` also swallows every click/touch that lands on
# it, so nothing underneath can be dragged while it's up.
@onready var _handoff_screen: Panel = $HandoffScreen
# An invisible full-screen Control, up from "Fin du tour" until the next
# turn starts: a Control's default `mouse_filter` (STOP) swallows every
# click/touch landing on it, so nothing under it can be changed while the
# turn's points are counted (see `_on_end_turn_pressed`). Declared just
# before HandoffScreen in main.tscn, which then takes over. It also takes
# the keyboard focus (`focus_mode` ALL in main.tscn), so Enter/Space can't
# press a button under it either.
@onready var _input_blocker: Control = $InputBlocker
@onready var _handoff_player_name: Label = $HandoffScreen/Center/Items/PlayerName
@onready var _handoff_play_button: Button = $HandoffScreen/Center/Items/PlayButton
# Everyone's score, and what the last turn changed (see score_recap.gd).
@onready var _score_recap: ScoreRecap = $HandoffScreen/Center/Items/ScoreRecap


func _ready() -> void:
	# Godot batches mouse-motion events into one per rendered frame by
	# default (meant to save work for games that don't need per-event
	# precision). For a dragged tile that means it visibly lags behind the
	# real cursor whenever the frame rate dips below the mouse's own
	# polling rate. Turning accumulation off delivers every motion event
	# immediately instead, which is the standard fix for sluggish-feeling
	# drags in Godot.
	Input.set_use_accumulated_input(false)

	# `start()` runs the given function on the thread; its return value is
	# handed back by `wait_to_finish()` (see `_dictionary()`). Safe here:
	# loading only reads a file and fills a brand-new object nothing else
	# touches until then.
	_dictionary_thread.start(func() -> FrenchDictionary: return FrenchDictionary.new())

	# Connects BoardView's/HandView's signals, and every button's built-in
	# `pressed` signal (every Button has one), to the methods below — see
	# board_cell.gd's header comment for what a signal/connection is.
	_board_view.tile_dropped.connect(_on_board_tile_dropped)
	_board_view.tile_moved.connect(_on_board_tile_moved)
	_board_view.tiles_moved.connect(_on_board_tiles_moved)
	_board_view.tile_flipped.connect(_on_board_tile_flipped)
	# Keeps the free-play palette's (and the turn-based hand's) own tile
	# size in sync with the board's, which BoardView already recomputes on
	# every viewport resize (see board_view.gd's `_update_cell_sizes`) —
	# without this, resizing the window would resize the board but leave
	# the hand/palette at whatever size they were last drawn at.
	_board_view.cell_size_changed.connect(_on_board_cell_size_changed)
	# A wide-but-short window (a computer) fits the board and hand/palette
	# comfortably side by side; a narrow-but-tall one (a phone) doesn't —
	# see `_update_play_area_orientation` below.
	get_viewport().size_changed.connect(_update_play_area_orientation)
	_update_play_area_orientation()
	# `item_rect_changed` fires whenever a Control's position or size
	# changes — here, whenever something above PlayArea (the scoreboard
	# wrapping onto a second line, the game-over banner appearing) pushes
	# the board down, so its height budget can follow.
	_play_area.item_rect_changed.connect(_update_board_height_budget)
	_hand_view.tile_returned.connect(_on_hand_tile_returned)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_discard_tray.tile_marked.connect(_on_tile_marked_for_discard)
	_hand_view.tile_unmarked.connect(_on_tile_unmarked_for_discard)
	_handoff_play_button.pressed.connect(_on_handoff_play_pressed)
	_hand_view.tile_reordered.connect(_on_hand_tile_reordered)
	# Each button runs its own small anonymous function (`func() -> void:
	# ...`, like a Python `lambda`), see `_on_turn_action`.
	_reset_turn_button.pressed.connect(_on_turn_action.bind(func() -> void: _session.reset_turn()))
	var tools := _hand_tools
	tools.get_node("SortButton").pressed.connect(
		_on_turn_action.bind(func() -> void: HandTiles.sort(_hand()))
	)
	tools.get_node("AllYellowButton").pressed.connect(
		_on_turn_action.bind(func() -> void: HandTiles.show_faces(_hand(), false))
	)
	tools.get_node("AllGreenButton").pressed.connect(
		_on_turn_action.bind(func() -> void: HandTiles.show_faces(_hand(), true))
	)
	_start_card.game_chosen.connect(_on_game_chosen)
	_start_card.resume_chosen.connect(_on_resume_chosen)
	_start_card.free_play_chosen.connect(_start_free_play)
	_start_card.how_to_play_chosen.connect(_how_to_play.open)
	_start_card.saved_game_chosen.connect(_on_saved_game_chosen)
	_save_copy_button.pressed.connect(_on_save_copy_pressed)
	_end_screen.replay_pressed.connect(_on_replay_pressed)
	_end_screen.menu_pressed.connect(_start_new_game)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_game_clock.is_running = _is_play_clock_running
	_how_to_play_menu_button.pressed.connect(_on_how_to_play_menu_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_timer_toggle.toggled.connect(_on_timer_toggle_toggled)
	_sound_button.pressed.connect(_on_sound_pressed)
	_sound_panel.changed.connect(_update_sound_icon)
	_update_sound_icon()
	_end_turn_message_timer.timeout.connect(_on_end_turn_message_timer_timeout)
	# `confirmed` fires when the dialog's own built-in OK button (relabeled
	# "Quitter" — see scenes/main.tscn) is pressed.
	_new_game_confirm_dialog.confirmed.connect(_start_new_game)
	# The palette (free play) and the hand (turn-based play) are never both
	# visible at once, so both can safely feed the same handler.
	_palette_view.tile_returned.connect(_on_hand_tile_returned)

	_return_to_start_menu()


# Called whenever a TilePanel gets dropped onto a BoardCell (see
# board_cell.gd/tile_panel.gd) — onto an empty cell, or onto a tile, which
# then swaps into the hand (see GameSession.place_tile). `place_tile`
# also checks the tile is actually in the current player's hand.
func _on_board_tile_dropped(row: int, col: int, tile: Tile) -> void:
	if _is_free_play():
		_free_play_session.place_tile(row, col, tile)
	else:
		_session.place_tile(row, col, tile)
	_sound_effects.play("tile_drop")
	_refresh_views()


# Called whenever a BoardCell gets dragged onto another BoardCell (see
# board_cell.gd) — any tile may move during a turn; onto another tile,
# that one swaps into the hand (see GameSession.move_tile).
func _on_board_tile_moved(from_row: int, from_col: int, to_row: int, to_col: int) -> void:
	if _is_free_play():
		_free_play_session.move_tile(from_row, from_col, to_row, to_col)
	else:
		_session.move_tile(from_row, from_col, to_row, to_col)
	_sound_effects.play("tile_drop")
	_refresh_views()


# Called whenever the selected tiles are dragged together (see
# board_view.gd's selection box): `cells` all move by `offset` (see
# block_move.gd).
func _on_board_tiles_moved(cells: Array[Vector2i], offset: Vector2i) -> void:
	if _is_free_play():
		_free_play_session.move_tiles(cells, offset)
	else:
		_session.move_tiles(cells, offset)
	_sound_effects.play("tile_drop")
	_refresh_views()


# Called whenever a BoardCell is clicked (not dragged) — flipping that
# tile in place (see game_session.gd's `flip_tile`). Any board tile may be
# flipped, any time, by any player (see doc/RULES.md's "trampoline"
# mechanic), so there's no eligibility check to make here first.
func _on_board_tile_flipped(row: int, col: int) -> void:
	if _is_free_play():
		_free_play_session.flip_tile(row, col)
	else:
		_session.flip_tile(row, col)
	_sound_effects.play("tile_flip")
	_refresh_views()


# BoardView itself starts recomputing cell sizes from `_ready()` onward,
# well before either kind of session might exist (e.g. resizing the window
# while still at the start menu) — `_refresh_views()` reaches straight into
# `_session`/`_free_play_session`, so it'd error without this guard.
func _on_board_cell_size_changed(_side: float) -> void:
	if _is_free_play() or _session != null:
		_refresh_views()


# Landscape (wider than tall) arranges PlayArea's two children — BoardView
# and HandArea — side by side instead of stacked, matching BoardView's own
# `_is_landscape` check so the board's own width math (see
# `LANDSCAPE_BOARD_WIDTH_FRACTION`) agrees with how the page is actually
# laid out. `vertical = true` behaves exactly like a VBoxContainer (today's
# portrait layout); `false` behaves exactly like an HBoxContainer — that's
# genuinely the entire difference between those two node types under the
# hood, `BoxContainer.vertical` is just normally locked once you pick one.
func _update_play_area_orientation() -> void:
	_play_area.arrange(_is_portrait())
	# On a phone, room at the top for the status bar or camera cutout:
	# the screen's "safe area" (what the system keeps clear of them, in
	# screen pixels, turned into the game's own by the stretch's scale),
	# and at least 36 px. The spare room at the bottom stays free for
	# Android's back/home buttons.
	if OS.has_feature("mobile"):
		var scale := get_viewport().get_final_transform().get_scale().y
		var inset := DisplayServer.get_display_safe_area().position.y / scale
		_margin.add_theme_constant_override("margin_top", int(maxf(36.0, inset + 12.0)))


# Tells BoardView how much of the screen's height isn't its own (see its
# `vertical_overhead`/`reserved_bottom_rows`), so the board, plus the hand
# under it in portrait turn-based play, fits on screen without scrolling.
# The overhead is measured from the real layout — where PlayArea starts,
# plus the page's bottom margin — rather than guessed, since the
# scoreboard's height depends on how many players there are. That
# position never depends on the board's own size, so re-fitting the
# board can't feed back into it. The ☰ menu (OptionsPanel) is left out:
# it's only open briefly, and counting it would shrink the board while
# it's open.
func _update_board_height_budget() -> void:
	var overhead := _content.position.y + _play_area.position.y
	overhead += _margin.get_theme_constant("margin_bottom")
	for panel: Control in [_options_panel, _sound_panel]:
		if panel.visible:
			overhead -= panel.size.y + _content.get_theme_constant("separation")
	# As many rows as the hand needs, at least 2 (the tray's height): a
	# hand starts at 9-14 tiles (see draw_plan.gd), but swaps and tiles
	# taken back off the board can make it longer. Only in turn-based
	# portrait: free play's palette holds all 117 tiles and scrolls anyway,
	# and in landscape the hand sits beside the board instead of below it.
	var hand_below := _session != null and _is_portrait()
	var hand_rows := 0
	if hand_below:
		var kept := _hand().size() - _session.marked_for_discard().size()
		hand_rows = maxi(2, ceili(kept / float(_HAND_TILES_PER_ROW)))
	_board_view.reserved_bottom_rows = hand_rows
	# ...and the row of buttons under it (see `_hand_tools`).
	if hand_below:
		overhead += _hand_tools.get_combined_minimum_size().y
		overhead += _hand_tools.get_parent().get_theme_constant("separation")
	_board_view.vertical_overhead = overhead


# Whether the window is at least as tall as it is wide (a phone held
# upright) — read straight off the viewport rather than `_play_area.
# vertical`, since BoardView's own resize handling can trigger
# `_refresh_views` before `_update_play_area_orientation` has caught up.
func _is_portrait() -> bool:
	var size := get_viewport_rect().size
	return size.x <= size.y


# Called whenever a BoardCell gets dragged onto the hand row OR the
# free-play palette (see hand_row.gd) — giving a tile back to the current
# player's storage, or back to the free-play pool of available tiles.
func _on_hand_tile_returned(from_row: int, from_col: int) -> void:
	if _is_free_play():
		_free_play_session.remove_tile(from_row, from_col)
	else:
		_session.remove_tile(from_row, from_col)
	_sound_effects.play("tile_drop")
	_refresh_views()


# A new game, from the start card (see start_card.gd): `names[i]` is what
# player i entered.
func _on_game_chosen(names: Array[String]) -> void:
	var session := GameSession.new(names.size(), _dictionary())
	session.player_names = names
	_start_session(session)


# "Rejouer" on the end screen: a new game, with the same players.
func _on_replay_pressed() -> void:
	var session := GameSession.new(_session.turns.number_of_players, _dictionary())
	session.player_names = _session.player_names
	_end_screen.hide()
	_start_session(session)


# "Reprendre la partie": whatever was played last — the turn-based game
# saved as its last turn began (see `_begin_turn`), or free play or a
# crossword, saved on every change (see `_refresh_views`). Should the
# file be unreadable, it's deleted, and the button goes with it.
func _on_resume_chosen() -> void:
	var path := SaveGame.newest([SaveGame.AUTOSAVE_PATH, SaveGame.FREE_PLAY_PATH])
	if path == SaveGame.FREE_PLAY_PATH:
		var session := SaveGame.load_free_play(path, _dictionary())
		if session != null:
			_show_free_play(session, SaveGame.summary(path).get("puzzle_index", -1))
			return
	else:
		var loaded := SaveGame.load(path, _dictionary())
		if loaded != null:
			_start_session(loaded)
			return
	DirAccess.remove_absolute(path)
	_start_card.show_menu()


# A game saved by hand, from the start card's list (see start_card.gd);
# should its file be unreadable, back to the menu.
func _on_saved_game_chosen(path: String) -> void:
	var loaded := SaveGame.load(path, _dictionary())
	if loaded == null:
		_start_card.show_menu()
		return
	_start_session(loaded)


# "Sauvegarder la partie" in the ☰ menu: keeps a copy of the game as its
# current turn began (the autosave, see `_begin_turn`), to load again from
# the start card ("Charger une partie") — say, to put a solo game aside
# for a game with friends. The button says it worked, for a moment.
func _on_save_copy_pressed() -> void:
	var kept := SaveGame.keep_copy(SaveGame.AUTOSAVE_PATH, SaveGame.SAVES_DIR)
	_save_copy_button.text = "Partie sauvegardée !" if kept else "Rien à sauvegarder"
	await get_tree().create_timer(1.5).timeout
	_save_copy_button.text = "Sauvegarder la partie"


# Shows `session`, a new or resumed turn-based game, and starts its turn.
func _start_session(session: GameSession) -> void:
	_session = session
	_start_card.close()
	_board_view.visible = true
	_hand_view.visible = true
	_end_turn_button.visible = true
	_discard_tray.visible = true
	_reset_turn_button.visible = true
	_hand_tools.visible = true
	_save_copy_button.visible = true
	_new_game_button.visible = true
	_refresh_views()
	_begin_turn()
	_box_lid.open()
	_start_game_music(MusicTracks.MULTIPLAYER)


# The one FrenchDictionary this whole app run ever loads (see
# `_shared_dictionary` above) — every GameSession/FreePlaySession this
# script creates should be handed this instead of leaving their own
# constructor default to loading yet another copy.
func _dictionary() -> FrenchDictionary:
	if _shared_dictionary == null:
		# Joins the background load: returns at once if it's finished,
		# otherwise blocks until it is (a mode picked within the first
		# couple of seconds).
		_shared_dictionary = _dictionary_thread.wait_to_finish()
	return _shared_dictionary


# Built-in callback Godot calls when this node leaves the scene tree
# (here: the app quitting). A Thread must be joined before it's freed,
# or Godot warns — e.g. when quitting from the menu before ever playing.
func _exit_tree() -> void:
	if _dictionary_thread.is_started():
		_dictionary_thread.wait_to_finish()


# Whether the free-play sandbox is the one currently active, rather than
# a turn-based `_session` (or nothing at all, at the start menu).
func _is_free_play() -> bool:
	return _free_play_session != null


# Starts free play ("Jeu libre", `puzzle_index` -1) or crossword number
# `puzzle_index + 1` (see the `Callable.bind` calls in `_ready()`): free
# play's sandbox — all 117 tiles, unrestricted placement, live scoring —
# plus, for a crossword, its clues; `_refresh_views` checks the puzzle's
# progress each time something changes. There's no turn to end and no
# timer to run (EndTurnButton stays hidden). Always a fresh, empty board:
# picking up a saved one is "Reprendre la partie"'s job (see
# `_on_resume_chosen`).
func _start_free_play(puzzle_index: int) -> void:
	_show_free_play(FreePlaySession.new(_dictionary()), puzzle_index)


# Shows free play `session`, solving crossword `puzzle_index` (-1: none).
func _show_free_play(session: FreePlaySession, puzzle_index: int) -> void:
	_free_play_session = session
	_crossword_puzzle = CrosswordPuzzle.new(puzzle_index) if puzzle_index >= 0 else null
	_start_card.close()
	_board_view.visible = true
	_palette_view.visible = true
	_new_game_button.visible = true
	_refresh_views()
	_box_lid.open()
	# A crossword has its own tune; plain free play, free play's.
	_start_game_music(MusicTracks.free_play(puzzle_index))


# Crossfades from the menu's music to the mode's tune, `music` ("Rejouer"
# goes straight from one game to the next: the same tune just carries on).
# The tiles land on the board with a bounce.
func _start_game_music(music: AudioStream) -> void:
	if not _game_music.playing:
		_sound_effects.play("bounce")
	_menu_music.fade_out()
	_game_music.fade_in(music)


# Built-in callback Godot calls on every node for engine-wide events
# ("notifications", numbered constants — no direct Python equivalent;
# think of a signal every node receives without connecting to it).
# NOTIFICATION_DRAG_BEGIN reaches all nodes whenever any drag starts, so
# this one place hears every tile being picked up, wherever it sits.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		_sound_effects.play("tile_pick")


# Whether a crossword puzzle is the one currently active — always
# alongside a `_free_play_session` (see `_start_free_play`), never on
# its own.
func _is_crossword() -> bool:
	return _crossword_puzzle != null


# Called when "Quitter la partie" is pressed — asks first, rather than
# abandoning the current session outright (see `_start_new_game`, and
# NewGameConfirmDialog in scenes/main.tscn). Nothing is lost: a
# turn-based game is saved at the start of every turn (see `_begin_turn`),
# free play on every change (see `_refresh_views`). Closes the "☰"
# dropdown first — otherwise it would stay open, floating over the
# confirmation dialog.
func _on_new_game_pressed() -> void:
	_options_panel.visible = false
	_sound_panel.visible = false
	_new_game_confirm_dialog.popup_centered()


# Actually leaves the current session (see `_on_new_game_pressed`) and
# goes back to `StartMenu`. Connected
# to NewGameConfirmDialog's `confirmed` signal (its built-in OK button,
# relabeled "Quitter" in scenes/main.tscn).
func _start_new_game() -> void:
	_session = null
	_free_play_session = null
	_crossword_puzzle = null
	_return_to_start_menu()


# Called when the options button ("☰") is pressed — just shows/hides
# OptionsPanel, the dropdown menu holding "Quitter la partie", "Comment
# jouer" and the timer toggle. Showing the button itself doesn't need
# `_session` to exist, but "Quitter la partie" is hidden until a game
# actually starts (see `_start_session`/`_return_to_start_menu`).
func _on_options_pressed() -> void:
	_options_panel.visible = not _options_panel.visible
	_sound_panel.visible = false


# Called when the speaker button is pressed: shows/hides the sound menu
# (one dropdown at a time, so it closes ☰'s).
func _on_sound_pressed() -> void:
	_sound_panel.visible = not _sound_panel.visible
	_options_panel.visible = false


# The speaker button shows a crossed-out speaker while nothing can be heard.
func _update_sound_icon() -> void:
	var silent := _sound_panel.settings.is_all_silent()
	_sound_button.icon = SoundPanel.SPEAKER_MUTED if silent else SoundPanel.SPEAKER


# Called when OptionsPanel's timer CheckButton is switched. Turning it on
# starts counting down immediately for whichever turn is already under
# way (see `_restart_turn_timer`); turning it off just hides the
# countdown rather than leaving a stale number on screen.
func _on_timer_toggle_toggled(enabled: bool) -> void:
	_timer_enabled = enabled
	if enabled:
		_restart_turn_timer()
	else:
		_turn_timer.stop()
		_turn_timer_label.visible = false


# Restarts the 3-minute countdown from the top — called whenever a new
# turn actually begins (a fresh session, a successful End Turn, or a
# loaded save) — but only if the timer is switched on AND a game is
# actually in progress; a no-op otherwise (e.g. toggled on while still
# at the start menu, with no `_session` yet to time).
func _restart_turn_timer() -> void:
	if not _timer_enabled or _session == null:
		return
	_turn_timer_label.visible = true
	_turn_timer.start()


# Runs every frame (defining `_process` is all a Node needs to opt in —
# see board_cell.gd's `_gui_input` comment for the same idea applied to
# input instead of per-frame updates) to keep the countdown label
# showing the actual time left on `_turn_timer`. Once it reaches zero,
# `time_left` just reads 0 from then on (Godot stops a one-shot Timer
# there on its own) — this is the RULES.md "soft" limit: a reminder,
# nothing is forced.
func _process(_delta: float) -> void:
	if not _timer_enabled or _session == null:
		return
	var seconds_left := int(ceil(_turn_timer.time_left))
	if seconds_left > 0:
		_turn_timer_label.remove_theme_color_override("font_color")
		_turn_timer_label.text = "%d:%02d" % [seconds_left / 60, seconds_left % 60]
	else:
		_turn_timer_label.add_theme_color_override("font_color", Color(0.96, 0.4, 0.4, 1))
		_turn_timer_label.text = "Temps écoulé !"


# Whether the hour is ticking: only while someone is actually playing a
# turn — not while its points are counted, on the handoff screen ("Au
# tour de …"), in a menu or dialog, in "Comment jouer", or with the box
# closed (see game_clock.gd).
func _is_play_clock_running() -> bool:
	return (
		not _handoff_screen.visible
		and not _input_blocker.visible
		and not _options_panel.visible
		and not _sound_panel.visible
		and not _how_to_play.visible
		and not _box_lid.visible
		and not _new_game_confirm_dialog.visible
	)


# Called when the End Turn button is pressed. `end_turn()` itself refuses
# and returns false if an invalid word is currently on the board (see
# word_challenge.gd) — in which case `_end_turn_message` explains why,
# listing the offending word(s) (see `_format_end_turn_error` below).
# Cleared on success, since the turn actually ended.
func _on_end_turn_pressed() -> void:
	if not _session.can_end_turn():
		_set_end_turn_message(_format_end_turn_error())
		_refresh_views()
		_board_view.shake_errors()
		_sound_effects.play("word_invalid")
		return
	_sound_effects.play(_turn_end_sound(_session.turn_bonuses()))
	# So the recap between turns can show what this turn changed.
	_score_recap.remember_scores(_session)
	# The turn's points float into the score BEFORE it ends: once it has,
	# the next player's hand would show (see `_begin_turn`). Nothing can
	# change in the meantime (see `_input_blocker`), so the turn checked
	# above still ends fine; then the handoff screen covers everything
	# until the next player presses "C'est moi !".
	_input_blocker.visible = true
	_input_blocker.grab_focus()
	# The words the points come from hop, letter after letter.
	_board_view.hop(_session.turn_start.scored_cells(_session.board, _session.dictionary), 0.03)
	await _scoreboard.play_turn_end(_session.turn_points(), _session.turn_bonuses())
	_input_blocker.visible = false
	_session.end_turn()
	_set_end_turn_message("")
	_begin_turn()
	_refresh_views()


# The sound a turn ends on, from the bonuses it wins (see
# `GameSession.turn_bonuses`): a fanfare for a whole word placed in one
# move (+30/+50), a strum for a line simply filled (+10), else a little
# arpeggio.
func _turn_end_sound(bonuses: Array[int]) -> String:
	if bonuses.any(func(bonus: int) -> bool: return bonus >= Scoring.MIXED_COLOR_WORD_BONUS):
		return "word_bonus"
	if not bonuses.is_empty():
		return "line_complete"
	return "word_valid"


# Runs `action`, what one of the turn's buttons does (see `_ready`), then
# redraws.
func _on_turn_action(action: Callable) -> void:
	action.call()
	_refresh_views()


# The current player's hand (see TileBag.hand), the live array.
func _hand() -> Array[Tile]:
	return _session.bag.hand(_session.turns.current_player_id())


# A hand tile dropped elsewhere in the hand, just before `before` (null:
# at the end) — see hand_row.gd. Free play's palette has no order to keep.
func _on_hand_tile_reordered(tile: Tile, before: Tile) -> void:
	if not _is_free_play():
		HandTiles.move(_hand(), tile, before)
		_sound_effects.play("tile_drop")
		_refresh_views()


# "Comment jouer" from the ☰ menu: closes the menu, then shows the rules.
func _on_how_to_play_menu_pressed() -> void:
	_options_panel.visible = false
	_sound_panel.visible = false
	_how_to_play.open()


# A hand tile dragged into the discard tray: it'll go back to the bag
# when the turn ends.
func _on_tile_marked_for_discard(tile: Tile) -> void:
	_session.set_marked_for_discard(tile, true)
	_refresh_views()


# A tile dragged from the discard tray back into the hand: keep it after
# all.
func _on_tile_unmarked_for_discard(tile: Tile) -> void:
	_session.set_marked_for_discard(tile, false)
	_refresh_views()


# Starts whoever's turn it now is. With 2+ players sharing one device, the
# next player's hand must stay hidden from the one who just played, so
# this first covers the screen with HandoffScreen showing who's up next —
# the real turn (and its timer) only starts once they press "C'est moi !" (see
# `_on_handoff_play_pressed`). Solo play has nobody to hand over to, so it
# skips straight to the timer. A game that just ended shows the end screen.
func _begin_turn() -> void:
	# Saved as each turn begins, for "Reprendre la partie"; once the game
	# is over, there's nothing left to pick up again.
	if _session.is_game_over():
		DirAccess.remove_absolute(SaveGame.AUTOSAVE_PATH)
		_turn_timer.stop()
		if _session.board.is_complete():
			# A full board: every tile hops, row after row, top to bottom.
			var cells: Array[Vector2i] = []
			for row in range(Board.ROWS):
				for col in range(Board.COLUMNS):
					cells.append(Vector2i(col, row))
			_board_view.hop(cells, 0.012)
			await get_tree().create_timer(1.8).timeout
		_sound_effects.play("game_end")
		_end_screen.show_result(_session, _all_player_names())
		return
	SaveGame.save(_session, SaveGame.AUTOSAVE_PATH)
	if _session.turns.number_of_players == 1:
		_restart_turn_timer()
		return
	_handoff_player_name.text = _player_name(_session.turns.current_player_id())
	_score_recap.show_scores(_session, _all_player_names())
	_handoff_screen.visible = true
	# Paused while the device changes hands, so passing it around doesn't
	# eat into the next player's 3 minutes.
	_turn_timer.stop()


# Called when HandoffScreen's "C'est moi !" button is pressed — the next player
# is at the screen, so reveal their hand and start their clock.
func _on_handoff_play_pressed() -> void:
	_handoff_screen.visible = false
	_sound_effects.play("bounce_small")
	_restart_turn_timer()


# Sets a status label's text AND hides it whenever that text is empty —
# used for `_game_over_banner`, which spends most of their
# time with nothing to say. A `Label` still reserves its own line height in
# `Content`'s VBoxContainer even while showing an empty string (only
# `visible=false` actually removes it), so setting `.text` alone left a
# permanent gap between the header and the board.
func _set_status_text(label: Label, text: String) -> void:
	label.text = text
	label.visible = text != ""


# Same idea as `_set_status_text` above, but for the end-turn notification
# specifically: it's a `PanelContainer` (for its colored background, see
# main.tscn's EndTurnBannerStyle), not a plain `Label`, so the text and the
# visibility toggle land on two different nodes (see `_end_turn_banner`/
# `_end_turn_message` above) — and, being a notification rather than a
# persistent status line, it fades in, then fades back out on its own once
# `_end_turn_message_timer` runs out (see `_on_end_turn_message_timer_
# timeout` below) rather than staying up until something else clears it.
func _set_end_turn_message(text: String) -> void:
	_end_turn_message.text = text
	_end_turn_message_timer.stop()
	if text == "":
		_fade_out_end_turn_banner()
		return
	_end_turn_banner.visible = true
	_end_turn_banner.modulate.a = 0.0
	# `create_tween()` hands back a fresh Tween — Godot's way of animating a
	# property smoothly over time instead of jumping straight to the target
	# value; `tween_property` says WHICH property (here, the banner's own
	# alpha/transparency), to WHAT value, over how many seconds.
	create_tween().tween_property(
		_end_turn_banner, "modulate:a", 1.0, _END_TURN_MESSAGE_FADE_SECONDS
	)
	_end_turn_message_timer.start()


# Called once `_end_turn_message_timer` (see main.tscn, 4 seconds, one-shot)
# runs out — fades out whatever notification is currently showing, same as
# if `_set_end_turn_message("")` had been called directly.
func _on_end_turn_message_timer_timeout() -> void:
	_fade_out_end_turn_banner()


# Shared by both ways the notification can go away (an explicit clear, or
# the timer running out) — animates its alpha back down to 0, then actually
# hides it (`visible = false`) only once that finishes, so a still-fading
# banner doesn't just vanish mid-fade.
func _fade_out_end_turn_banner() -> void:
	if not _end_turn_banner.visible:
		return
	var tween := create_tween()
	tween.tween_property(_end_turn_banner, "modulate:a", 0.0, _END_TURN_MESSAGE_FADE_SECONDS)
	tween.tween_callback(func(): _end_turn_banner.visible = false)


# Redraws both views from the session's current state — the board, and
# whichever player's turn it currently is, with what stops the turn from
# ending framed in red (see board_view.gd's `refresh`). Also checks
# whether the game has just ended (see `_update_game_over_banner`).
func _refresh_views() -> void:
	# Also re-checked here, not only on PlayArea moving: starting or
	# leaving a turn-based game changes whether the hand needs room.
	_update_board_height_budget()
	# Only a turn-based game is timed; free play has no time limit.
	_game_clock.session = null if _is_free_play() else _session
	if _is_free_play():
		# Saved on every change, for "Reprendre la partie" (see
		# `_on_resume_chosen`).
		var puzzle_index := _crossword_puzzle.puzzle_index if _is_crossword() else -1
		SaveGame.save_free_play(_free_play_session, puzzle_index)
		_board_view.refresh(_free_play_session.board)
		_palette_view.refresh(_free_play_session.available_tiles(), _board_view.cell_side())
		_scoreboard.show_score(_free_play_session.current_score())
		# Clues as a list beside the board in landscape, where it fits; as
		# "?" bubbles on the board itself in portrait, where a list would
		# push the palette off-screen.
		_clue_list_view.visible = _is_crossword() and not _is_portrait()
		_clue_markers.visible = _is_crossword() and _is_portrait()
		# Shrinks the cells just enough to fit the "?" column inside the
		# frame. Re-fitting the cells calls back into `_refresh_views`
		# (see `_on_board_cell_size_changed`), but only on an actual
		# change, so this settles after one extra pass.
		_board_view.reserved_right_width = (
			ClueMarkersView.LANE_WIDTH if _clue_markers.visible else 0.0
		)
		if _is_crossword():
			var solved := _crossword_puzzle.solved_rows(_free_play_session.board)
			_clue_list_view.refresh(_crossword_puzzle.clues, solved)
			var row_rects: Array[Rect2] = []
			for row in range(Board.ROWS):
				row_rects.append(_board_view.row_rect(row))
			_clue_markers.refresh(_crossword_puzzle.clues, solved, row_rects)
			if _crossword_puzzle.is_solved(_free_play_session.board):
				_set_status_text(_game_over_banner, "Mots croisés résolus !")
				# Marked on the start card from now on (see start_card.gd).
				SaveGame.mark_crossword_solved(puzzle_index)
			else:
				_set_status_text(_game_over_banner, "")
		return
	_board_view.refresh(
		_session.board, _session.invalid_cells(), _session.invalid_words(), _session.emptied_cells()
	)
	# The hand shows the tiles the player keeps; the tray beside it, the
	# ones marked to give back.
	var kept: Array[Tile] = []
	var marked := _session.marked_for_discard()
	for tile in _hand():
		if not marked.has(tile):
			kept.append(tile)
	_hand_view.refresh(kept, _board_view.cell_side())
	_discard_tray.refresh(marked, _board_view.cell_side())
	_scoreboard.show_players(_session, _all_player_names())
	_update_game_over_banner()


# `player_id`'s name: what they entered (see GameSession.player_names),
# or "Joueur N" if they left it empty (N counting from 1).
func _player_name(player_id: int) -> String:
	var names := _session.player_names
	if player_id < names.size() and names[player_id] != "":
		return names[player_id]
	return "Joueur %d" % (player_id + 1)


# Every player's name, in player order (see `_player_name`).
func _all_player_names() -> Array[String]:
	var names: Array[String] = []
	for player_id in range(_session.turns.number_of_players):
		names.append(_player_name(player_id))
	return names


# Builds the message shown by `_end_turn_banner` after a refused
# `end_turn()` — names the actual invalid word(s) (see game_session.gd's
# `invalid_words`), explains a broken single-row/single-word turn (see
# `invalid_cells`) and/or emptied cells (see `emptied_cells`) rather than
# just saying "no". Several can be true at once, so each gets its own line
# rather than one crowding the others out.
func _format_end_turn_error() -> String:
	var messages: Array[String] = []

	var words: Array[String] = []
	var misplaced := false
	for entry in _session.invalid_words():
		if entry["misplaced"]:
			misplaced = true
		else:
			words.append(entry["word"])
	if misplaced:
		messages.append("Les mots commencent à la première colonne.")
	if words.size() == 1:
		messages.append("Mot invalide : %s" % words[0])
	elif words.size() > 1:
		messages.append("Mots invalides : %s" % ", ".join(words))

	if not _session.invalid_cells().is_empty():
		messages.append(
			"Les lettres jouées ce tour doivent former un seul mot, sur une seule ligne."
		)

	# Cells left empty that held a letter when the turn began (framed in
	# red on the board, see GameSession.emptied_cells).
	if not _session.emptied_cells().is_empty():
		messages.append("Une case remplie au début du tour doit l'être encore à la fin.")

	return "\n".join(messages)


# Hides everything that depends on `_session` and shows `StartMenu`
# again — used both by `_ready()` (before any game has started yet) and
# by `_start_new_game()` (after abandoning one).
func _return_to_start_menu() -> void:
	_start_card.show_menu()
	_box_lid.close()
	_board_view.visible = false
	_hand_view.visible = false
	_end_turn_button.visible = false
	_discard_tray.visible = false
	_reset_turn_button.visible = false
	_hand_tools.visible = false
	_save_copy_button.visible = false
	_new_game_button.visible = false
	_palette_view.visible = false
	_clue_list_view.visible = false
	_clue_markers.visible = false
	_board_view.reserved_right_width = 0.0
	_options_panel.visible = false
	_sound_panel.visible = false
	_handoff_screen.visible = false
	_end_screen.visible = false
	_set_end_turn_message("")
	_set_status_text(_game_over_banner, "")
	_scoreboard.hide_scores()
	_turn_timer.stop()
	_turn_timer_label.visible = false
	_game_clock.session = null
	_game_music.fade_out()
	_menu_music.fade_in()


# Once the game is over (see game_session.gd's `is_game_over`), there's
# no turn left to end: "Fin du tour" is disabled. The end screen says the
# rest (see `_begin_turn`).
func _update_game_over_banner() -> void:
	_end_turn_button.disabled = _session.is_game_over()
