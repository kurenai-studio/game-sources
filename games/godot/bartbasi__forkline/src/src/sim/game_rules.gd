# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name GameRules
extends RefCounted
## data/stats/rules.json, one field per key (docs/ARCHITECTURE.md 2.6). Read only.

var start_lives: int = 20
var relaxed_lives_pct: int = 200
var relaxed_gold_pct: int = 150
var refund_pct: int = 70
var early_bonus_pct: int = 50
var clear_bonus: int = 20
var clear_bonus_per_wave: int = 5
var star2_lives: int = 15
var max_waves_running: int = 2
var max_gates: int = 3
var bubble_ms: int = 2000
var region_stars: Array[int] = []
var run_stars: int = 12
