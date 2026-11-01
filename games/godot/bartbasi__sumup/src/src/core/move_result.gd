class_name MoveResult extends RefCounted
## What one move did, for tests (TH12) and for the board view's animations.
## Every move returns one, accepted or refused. A refused move changes nothing.
## Every board and every tile value here is an exponent (the tile is 2^k, 0 is
## empty or none); points and cost are BigNum (docs/ARCHITECTURE.md section 17).

enum Kind { NEW_RUN, CHAIN, HAMMER, SWAP, SHUFFLE, DOUBLE, UNDO }

var kind: Kind
var accepted: bool = false
var refusal: StringName = &""           # &"" when accepted, else for example &"invalid_chain", &"cannot_afford", &"no_snapshot", &"bad_target", &"not_now"
var booster_id: StringName = &""
var points: BigNum = BigNum.zero()      # added by a chain (0 for boosters)
var cost: BigNum = BigNum.zero()        # charged by a booster (0 when it used a free booster)
var cells_before: PackedInt64Array = PackedInt64Array()
var cells_after: PackedInt64Array = PackedInt64Array()
var chain: Array[Vector2i] = []         # chain in drag order
var targets: Array[Vector2i] = []       # booster targets as given
var result_cell: Vector2i = Vector2i(-1, -1)   # chain result, or the doubled tile
var result_value: int = 0
var emptied: Array[Vector2i] = []       # chain cells other than the result, or the hammered cell
var floor_before: int = 0
var floor_after: int = 0
var cleared_small: Array[Vector2i] = [] # D-38: cells cleared, in index order
var cleared_values: PackedInt64Array = PackedInt64Array()    # D-38: distinct exponents cleared, ascending
## D-45: every exponent that left the spawn window in this move, ascending: floor_before up to
## floor_after - 1. Empty when the floor did not rise. The clear notice names these (AT-104).
var notice_values: PackedInt64Array = PackedInt64Array()
var stars_earned: int = 0               # D-45: stars this move earned (0, 1, or more when the floor jumps)
var free_earned: int = 0                # D-46: free boosters this move earned
var free_used: bool = false             # D-46: this booster used a free booster, so cost is 0
var fall_from: Array[Vector2i] = []     # gravity: tile at fall_from[i] moved to fall_to[i]
var fall_to: Array[Vector2i] = []
var spawn_cells: Array[Vector2i] = []   # in fill order (D-12)
var spawn_values: PackedInt64Array = PackedInt64Array()
var new_best_score: bool = false
var new_best_tile: bool = false
var has_valid_move: bool = true         # after the move (D-15)
var offer_opens: bool = false           # set by GameSession: the no moves offer opens after this move
var run_ends: bool = false              # set by GameSession: the run ends after this move
