class_name GameConfig extends RefCounted
## Every tunable from GDD section 18 that the rules read. Tests make their own
## instance to override values (TH4). Everything that needs a constant takes a
## GameConfig, so nothing reads these numbers from anywhere else.
##
## Tiles are held as exponents (docs/ARCHITECTURE.md section 17), but
## spawn_top_min, spawn_top_divisor and cost_basis_min keep the GDD's plain
## values (16, 64, 128), and label_step its 1024. They must be powers of
## two; CoreRules and NumberFormat read their exponents. label_full_max is
## an exponent.

var columns: int = 5                    # BOARD_COLUMNS
var rows: int = 8                       # BOARD_ROWS
var min_chain_length: int = 2           # MIN_CHAIN_LENGTH
var join_radius: float = 0.42           # JOIN_RADIUS, share of the tile pitch (D-07)
var spawn_window_size: int = 4          # SPAWN_WINDOW_SIZE
var spawn_weights: PackedInt32Array = PackedInt32Array([40, 30, 20, 10])   # smallest value first, total 100
var spawn_top_min: int = 16             # SPAWN_TOP_MIN
var spawn_top_divisor: int = 64         # SPAWN_TOP_DIVISOR
var start_board_max_attempts: int = 100 # START_BOARD_MAX_ATTEMPTS
var shuffle_max_attempts: int = 100     # SHUFFLE_MAX_ATTEMPTS
var cost_basis_min: int = 128           # COST_BASIS_MIN
## Each cost is B shifted by this many bits: 0 is B, 1 is 2B, -1 is B/2. Keeps every cost a power of two.
var cost_shift: Dictionary[StringName, int] = {&"hammer": 0, &"swap": 0, &"shuffle": 0, &"double": 1, &"undo": -1}
var label_full_max: int = 10            # LABEL_FULL_MAX, an exponent: 2^10 = 1024 is the largest label in full
var label_step: int = 1024              # LABEL_STEP
var label_suffixes: PackedStringArray = PackedStringArray(["K", "M", "B", "T", "Q"])   # LABEL_SUFFIXES, shared by tiles and scores (D-31, D-32)
## LABEL_LETTERS (D-31): the letters of the two and three letter suffixes, in order. No l, no o.
var label_letters: PackedStringArray = PackedStringArray(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "m", "n", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"])
var score_full_max_digits: int = 10     # SCORE_FULL_MAX_DIGITS (D-32)
var stars_per_free_booster: int = 3     # STARS_PER_FREE_BOOSTER (D-46)
var max_exponent: int = 65535           # MAX_EXPONENT (D-37): no tile may pass 2^max_exponent
var max_score_bits: int = 65600         # MAX_SCORE_BITS (D-37): no score may reach 2^max_score_bits


## Number of cells on the board: columns times rows.
func cell_count() -> int:
	return columns * rows
