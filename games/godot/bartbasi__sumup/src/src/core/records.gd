class_name Records extends RefCounted
## Best Score and Best Tile (D-16, D-17). They outlive runs and never go down.
## best_tile is an exponent (0 for none); best_score is a BigNum.

var best_score: BigNum = BigNum.zero()
var best_tile: int = 0


## Step 7 of D-09: Best Score becomes the larger of itself and the score, and
## Best Tile the larger of itself and H. Returns true when either record rose.
func update_from(state: RunState) -> bool:
	var rose: bool = false
	if state.score.compare(best_score) > 0:
		best_score = state.score
		rose = true
	var top: int = state.highest()
	if top > best_tile:
		best_tile = top
		rose = true
	return rose


func copy() -> Records:
	var other: Records = Records.new()
	other.best_score = best_score
	other.best_tile = best_tile
	return other
