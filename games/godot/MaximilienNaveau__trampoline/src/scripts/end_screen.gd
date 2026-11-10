# The screen shown once a turn-based game is over (see main.gd's
# `_begin_turn`): how it ended, who won, every player ranked (see
# score_recap.gd's `show_final`), and two ways on: "Rejouer" (a new game,
# same players) or "Menu" (back to the start card).
#
# Alone, the player is playing against the board itself: a finished board
# with no green face at all (see Scoring.is_perfect) is celebrated — tiles
# rain down, the score pulses — and otherwise the screen counts the green
# faces left, the next game's target.
#
# Purely visual: it only reads the session it's given, and reports the
# buttons through its signals.
class_name EndScreen
# On the same felt as the game (see play_mat.gd).
extends PlayMat

signal replay_pressed
signal menu_pressed

# How many yellow tiles rain down on a perfect board, and how long one
# takes to fall, in seconds (shortest and longest).
const _RAIN_TILES := 36
const _FALL_SECONDS := Vector2(2.5, 4.5)
# The letters they show.
const _RAIN_LETTERS := "TRAMPOLINE"

# The falling tiles and the score's pulse, while celebrating (see
# `_celebrate`), so `_stop_celebrating` can end them.
var _rain: Array[Control] = []
var _pulse: Tween

@onready var _title: Label = $Center/Card/Items/Title
@onready var _winners: Label = $Center/Card/Items/Winners
@onready var _recap: ScoreRecap = $Center/Card/Items/ScoreRecap
# The solo player's target (see `_show_solo`).
@onready var _note: Label = $Center/Card/Items/Note


func _ready() -> void:
	# The felt's own setup first (see play_mat.gd), like Python's
	# `super().__init__()`.
	super()
	# Re-broadcasts each button's own `pressed` signal as this screen's.
	$Center/Card/Items/Buttons/ReplayButton.pressed.connect(replay_pressed.emit)
	$Center/Card/Items/Buttons/MenuButton.pressed.connect(menu_pressed.emit)
	# Built-in signal: this screen was shown or hidden.
	visibility_changed.connect(_on_visibility_changed)


# Shows how `session` ended, `names[i]` being player i's name.
func show_result(session: GameSession, names: Array[String]) -> void:
	_title.text = "Temps écoulé !" if session.ended_by_time else "Partie terminée !"
	var winners := session.winner_ids()
	var score := session.turns.player_score(winners[0])
	# Alone, the ranking would only repeat the score: the note replaces it.
	_note.visible = session.turns.number_of_players == 1
	_recap.visible = not _note.visible
	if session.turns.number_of_players == 1:
		_show_solo(session, score)
	else:
		var who: Array[String] = []
		for player_id in winners:
			who.append(names[player_id])
		# One winner: "Alice gagne"; a tie: "Alice et Bruno gagnent" (see
		# GameSession.winner_ids for how ties are broken first).
		_winners.text = (
			"%s gagne" % who[0]
			if who.size() == 1
			else "%s et %s gagnent" % [", ".join(who.slice(0, -1)), who[-1]]
		)
	_recap.show_final(session, names)
	show()


# A solo game's result: the score, and how it measures up to a perfect
# board (see Scoring.is_perfect) — celebrated if it is one, otherwise the
# green faces left to get rid of next time.
func _show_solo(session: GameSession, score: int) -> void:
	_winners.text = "%d points" % score
	var greens := Scoring.green_face_count(session.board)
	if Scoring.is_perfect(session.board):
		_title.text = "Grille parfaite !"
		_note.text = "Tout en jaune : le plus beau score possible !"
		_celebrate()
	elif greens == 0:
		_note.text = "Aucune face verte ! Remplissez toute la grille pour la victoire parfaite."
	else:
		_note.text = (
			"%d face%s verte%s sur la grille. La prochaine fois, visez le tout jaune !"
			% [greens, "s" if greens > 1 else "", "s" if greens > 1 else ""]
		)


# Yellow tiles rain down behind the card, again and again, and the score
# pulses, until the screen is hidden.
func _celebrate() -> void:
	var side := 48.0
	for i in range(_RAIN_TILES):
		var letter := _RAIN_LETTERS[i % _RAIN_LETTERS.length()]
		var tile := TileView.build_tile_visual(Tile.new(letter, "", false), Vector2.ONE * side)
		tile.pivot_offset = tile.size / 2
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tile)
		# Drawn first, so behind the card.
		move_child(tile, 0)
		_rain.append(tile)
		# Each starts somewhere above the screen, falls past its bottom
		# while turning, and starts over: `set_loops()` repeats a tween
		# forever, `from` sets where each round starts.
		var x := randf() * (size.x - side)
		var seconds := randf_range(_FALL_SECONDS.x, _FALL_SECONDS.y)
		var tween := tile.create_tween().set_loops().set_parallel()
		tween.tween_property(tile, "position", Vector2(x, size.y + side), seconds).from(
			Vector2(x, -side - randf() * size.y)
		)
		tween.tween_property(tile, "rotation", randf_range(-PI, PI), seconds).from(0.0)
	_winners.pivot_offset = _winners.size / 2
	_pulse = _winners.create_tween().set_loops()
	_pulse.tween_property(_winners, "scale", Vector2.ONE * 1.12, 0.5).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(_winners, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


func _on_visibility_changed() -> void:
	if not visible:
		_stop_celebrating()


# Ends the rain and the pulse (see `_celebrate`), if any.
func _stop_celebrating() -> void:
	for tile in _rain:
		tile.queue_free()
	_rain.clear()
	if _pulse != null:
		_pulse.kill()
		_pulse = null
	_winners.scale = Vector2.ONE
