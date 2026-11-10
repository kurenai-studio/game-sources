# The scores recap on the screen between two players' turns (see
# main.gd's `_begin_turn`): every player's score, what the last turn
# changed in orange (or red, if it cost points), and the game's time
# left underneath.
#
# Purely visual: it only reads the game session it's given.
class_name ScoreRecap
extends VBoxContainer

# `cream_text` for the scores, `ribbon` orange for points just won,
# `error` red for points just lost (see doc/ART_DIRECTION.md's palette).
const _TEXT_COLOR := Color(0.953, 0.937, 0.847, 1)
const _GAIN_COLOR := Color("e4733a")
const _LOSS_COLOR := Color("c8463c")
const _FAINT_COLOR := Color(0.953, 0.937, 0.847, 0.6)

# One row per player: name, score, last turn's change. A GridContainer
# lays its children out in `columns` columns, row after row, so the
# three labels of a player line up with everyone else's.
var _grid := GridContainer.new()
# "Temps restant : 41:20", or "Dernier tour".
var _footer := Label.new()
# Everyone's score just before the last turn ended (see
# `remember_scores`); empty when there's nothing to compare with.
var _before: Array[int] = []


func _ready() -> void:
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_grid)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.add_theme_color_override("font_color", _FAINT_COLOR)
	add_child(_footer)


# Remembers every player's score right before a turn ends, so the next
# `show_scores` can show what that turn changed.
func remember_scores(session: GameSession) -> void:
	_before = session.turns.all_player_scores()


# Shows each player (`names[i]`) with their score, what the turn that just
# ended changed (if `remember_scores` was called before it; nothing shown
# when 0), and the game's time left underneath.
func show_scores(session: GameSession, names: Array[String]) -> void:
	for child in _grid.get_children():
		child.queue_free()
	var scores := session.turns.all_player_scores()
	for i in range(names.size()):
		_add_cell(names[i], _TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		_add_cell("%d pts" % scores[i], _TEXT_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
		var gain := scores[i] - _before[i] if i < _before.size() else 0
		# `%+d` always writes the sign: "+12", "-5".
		var change := "" if gain == 0 else "%+d" % gain
		_add_cell(change, _GAIN_COLOR if gain > 0 else _LOSS_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	# Shown once: a new game, or a loaded one, starts with no change.
	_before.clear()
	var seconds := int(ceil(session.remaining_time()))
	_footer.text = (
		"Dernier tour"
		if session.is_last_round()
		else "Temps restant : %d:%02d" % [seconds / 60, seconds % 60]
	)


# The final ranking, for the end screen (see end_screen.gd): each player
# (`names[i]`) best first — by score, then fewest tiles left in hand, the
# tie-break (see GameSession.winner_ids) — with their score and tiles
# left, the winners in orange.
func show_final(session: GameSession, names: Array[String]) -> void:
	for child in _grid.get_children():
		child.queue_free()
	var winners := session.winner_ids()
	var ranking := range(names.size())
	# Sorted with a comparison function, like C++'s `std::sort(begin, end,
	# less)`: `a` goes first if it has more points, or as many and fewer
	# tiles left.
	ranking.sort_custom(
		func(a: int, b: int) -> bool:
			var score_a := session.turns.player_score(a)
			var score_b := session.turns.player_score(b)
			if score_a != score_b:
				return score_a > score_b
			return session.bag.hand(a).size() < session.bag.hand(b).size()
	)
	for player_id: int in ranking:
		var color := _GAIN_COLOR if winners.has(player_id) else _TEXT_COLOR
		_add_cell(names[player_id], color, HORIZONTAL_ALIGNMENT_LEFT)
		_add_cell(
			"%d pts" % session.turns.player_score(player_id), color, HORIZONTAL_ALIGNMENT_RIGHT
		)
		_add_cell(
			"%d en main" % session.bag.hand(player_id).size(),
			_FAINT_COLOR,
			HORIZONTAL_ALIGNMENT_LEFT
		)
	_footer.text = ""


func _add_cell(text: String, color: Color, alignment: HorizontalAlignment) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_color_override("font_color", color)
	_grid.add_child(label)
