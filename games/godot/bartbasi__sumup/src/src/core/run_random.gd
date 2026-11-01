class_name RunRandom extends RefCounted
## The run's one random number generator (GDD 9.5), used for the starting
## board, spawns and Shuffle in the order the moves happen, plus every test
## override (TH5 to TH8). Every value it hands out is a tile exponent.

var start_attempts: int = 0             # TH7: attempts the last new_run used
var shuffle_attempts: int = 0           # TH8: attempts the last Shuffle used

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _scripted: PackedInt64Array = PackedInt64Array()
var _scripted_next: int = 0
var _forced_start: PackedInt64Array = PackedInt64Array()
var _forced_shuffle: PackedInt64Array = PackedInt64Array()


## TH5. Seeds the generator, which also resets its state.
func set_seed(new_seed: int) -> void:
	_rng.seed = new_seed


## A fresh random seed for a real run.
func use_random_seed() -> void:
	_rng.randomize()


## TH5. The generator's state, to read back with set_state.
func get_state() -> int:
	return _rng.state


func set_state(state: int) -> void:
	_rng.state = state


## TH6: next_spawn uses these before any random draw, in fill order, on every spawn path. start_board_attempt and shuffle_attempt never use them.
## A new call replaces any scripted values not used yet. An empty array stops scripting.
func script_spawns(values: PackedInt64Array) -> void:
	_scripted = values.duplicate()
	_scripted_next = 0


## TH7: every start attempt returns this board. An empty array turns forcing off.
func force_start_board(cells: PackedInt64Array) -> void:
	_forced_start = cells.duplicate()


## TH8: every Shuffle attempt returns this arrangement. An empty array turns forcing off.
func force_shuffle(cells: PackedInt64Array) -> void:
	_forced_shuffle = cells.duplicate()


## One spawn value: the next scripted value if any is left, else one weighted
## draw from window (D-10). A scripted value does not use the generator.
func next_spawn(window: PackedInt64Array, config: GameConfig) -> int:
	if _scripted_next < _scripted.size():
		var value: int = _scripted[_scripted_next]
		_scripted_next += 1
		return value
	return CoreRules.draw_value(_draw(config), window, config)


## One full random board from the starting window (D-14 step 1), one draw per
## cell in fill order (D-12). Returns the forced board instead when one is set.
func start_board_attempt(config: GameConfig) -> PackedInt64Array:
	if not _forced_start.is_empty():
		return _forced_start.duplicate()
	var window: PackedInt64Array = CoreRules.spawn_window(0, config)
	var board: PackedInt64Array = PackedInt64Array()
	board.resize(config.cell_count())
	for column: int in config.columns:
		for row: int in config.rows:
			var index: int = CoreRules.index_of(Vector2i(column, row), config.columns)
			board[index] = CoreRules.draw_value(_draw(config), window, config)
	return board


## One random arrangement of the same values, every arrangement equally
## likely (D-25 step 2). Returns the forced arrangement instead when one is set.
func shuffle_attempt(cells: PackedInt64Array) -> PackedInt64Array:
	if not _forced_shuffle.is_empty():
		return _forced_shuffle.duplicate()
	var arranged: PackedInt64Array = cells.duplicate()
	for position: int in range(arranged.size() - 1, 0, -1):
		var other: int = _rng.randi_range(0, position)
		var kept: int = arranged[position]
		arranged[position] = arranged[other]
		arranged[other] = kept
	return arranged


## One draw number from 0 to the total spawn weight minus 1 (0 to 99 by default).
func _draw(config: GameConfig) -> int:
	var total: int = 0
	for weight: int in config.spawn_weights:
		total += weight
	if total <= 0:
		return 0
	return _rng.randi_range(0, total - 1)
