# Enforcing that every word actually on the board is a real dictionary
# word — see doc/RULES.md's "Word validation" section. Simplified for now,
# per Maximilien: rather than letting an invalid word sit on the board for
# another player to challenge afterward, a turn simply can't end while one
# is there. See the bottom of this file for the fuller challenge/penalty
# mechanic this might grow into later.
#
# `static`, same reasoning as turn_validity.gd: no state of its own, just
# questions about a `Board`+`FrenchDictionary` passed in.
class_name WordChallenge
extends RefCounted


# Every currently-on-the-board word that doesn't count, as a list of
# `{row, col, word, misplaced}` dictionaries (`col` anchors the word per
# board.gd's `word_at`/`word_columns_at` — see board.gd for why a row can
# hold more than one word): one that isn't a valid dictionary word, or
# one that doesn't start in the first column (`misplaced` true — every
# word does, see doc/RULES.md). Empty cells and gaps aren't words, so
# they're never included. An empty result means the board is entirely
# clean.
static func find_invalid_words(board: Board, dictionary: FrenchDictionary) -> Array:
	var invalid := []
	for row in range(Board.ROWS):
		for segment in board.segments_in_row(row):
			var col: int = segment[0]
			var word := board.word_at(row, col)
			if word == "":
				continue
			if col > 0 or not dictionary.is_word_valid(word):
				invalid.append({"row": row, "col": col, "word": word, "misplaced": col > 0})
	return invalid


# Whether the current player is allowed to end their turn right now: only
# true if every word on the board is valid. Call this before
# `TurnManager.end_turn()` — refuse the end-turn action (e.g. keep an "End
# Turn" button disabled) if this returns false.
static func can_end_turn(board: Board, dictionary: FrenchDictionary) -> bool:
	return find_invalid_words(board, dictionary).is_empty()

# --- Possible future penalty mechanics (not implemented yet) ---
#
# doc/RULES.md's original rule is a reactive CHALLENGE, not a proactive
# block: a turn CAN end with a bad word on the board, and any other player
# may challenge it afterward; if the word is proven wrong, it's removed
# and "the offending player loses their turn." That's a materially
# different (and more complex) design than what's built above, with
# several open questions to settle before attempting it:
#
#   - Removing a challenged word breaks the normal "words only grow"
#     invariant (see GameSession.emptied_cells) — a real letter would
#     need a new, deliberate removal exception just for this case,
#     distinct from the existing blank-tile-only exception.
#   - Where do the removed tiles go? Back to the offending player's hand
#     (they can try again later), or back into the shared bag?
#   - What's the actual penalty — skip their next turn entirely (as
#     doc/RULES.md states), a points deduction, both, or something else?
#   - Who can challenge, and until when — immediately only, any time
#     before the challenged player's next turn, or until the game ends?
#   - What happens on a FAILED challenge (the word turns out valid)? Real
#     Scrabble penalizes wrong challenges (the challenger loses their own
#     turn); doc/RULES.md doesn't say either way for this game.
