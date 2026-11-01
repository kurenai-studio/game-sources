# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Sim
extends RefCounted
## Constants and integer helpers for the rules engine (docs/ARCHITECTURE.md 3.1).
## Everything in src/sim/ uses whole numbers only.

const TICKS_PER_SECOND: int = 20
const MS_PER_TICK: int = 50
const UNIT: int = 20000
const MAP_COLUMNS: int = 7
const MAP_ROWS_MIN: int = 8
const MAP_ROWS_MAX: int = 13
const MAX_ENTRANCES: int = 4


## Floor of the square root of n. n must be 0 or more.
static func isqrt(n: int) -> int:
	if n <= 0:
		return 0
	var x: int = n
	var y: int = (x + 1) / 2
	while y < x:
		x = y
		y = (x + n / x) / 2
	return x


## The sub-unit position of a cell center.
static func center(cell: Vector2i) -> Vector2i:
	return Vector2i(cell.x * UNIT + UNIT / 2, cell.y * UNIT + UNIT / 2)


## The cell that holds a sub-unit position.
static func cell_of(pos: Vector2i) -> Vector2i:
	return Vector2i(_floor_div(pos.x, UNIT), _floor_div(pos.y, UNIT))


## Half up rounding of value * pct / 100, for values of 0 or more (RULES 2).
static func pct_half_up(value: int, pct: int) -> int:
	return (value * pct + 50) / 100


## Upward rounding of value * pct / 100, for values of 0 or more (RULES 2).
static func pct_up(value: int, pct: int) -> int:
	return (value * pct + 99) / 100


## True when cell a comes before cell b in cell order: row, then column.
static func cell_before(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)


static func _floor_div(a: int, b: int) -> int:
	var q: int = a / b
	if (a % b != 0) and ((a < 0) != (b < 0)):
		q -= 1
	return q
