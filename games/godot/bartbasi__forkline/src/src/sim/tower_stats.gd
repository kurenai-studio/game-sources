# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name TowerStats
extends RefCounted
## One stat block of a tower tier or tier 3 path, in the file's units
## (docs/ARCHITECTURE.md 2.6, 14.4). Read only.

var cost: int = 0
var reach: int = 0
var hits_ground: bool = false
var hits_air: bool = false
var damage: int = 0
var reload_ms: int = 0
var splash: int = 0
var targets: int = 1
var pierce: bool = false
var slow_pct: int = 0
var slow_ms: int = 0
var boost_pct: int = 0
var boost_damage: int = 0
var pulse: bool = false                                # hits every creature it can hit in reach, no aim (RULES 5.12)
var line: int = 0                                      # line width in hundredths of a tile, 0 for none (RULES 5.14)
var lure_ms: int = 0                                   # a flyer it hits is low this long, 0 for none (RULES 5.15)
var fright_pct: int = 0                                # a fright tower's fright, with fright_ms left (RULES 5.13)
var fright_ms: int = 0


## The tower numbers the UI shows (docs/ARCHITECTURE.md 3.1, 14.6).
func numbers() -> Dictionary:
	return {
		"damage": damage, "reload_ms": reload_ms, "reach": reach, "splash": splash,
		"targets": targets, "pierce": pierce, "slow_pct": slow_pct, "slow_ms": slow_ms,
		"hits_ground": hits_ground, "hits_air": hits_air,
		"boost_pct": boost_pct, "boost_damage": boost_damage,
		"pulse": pulse, "line": line, "lure_ms": lure_ms, "fright_pct": fright_pct, "fright_ms": fright_ms,
	}


## A copy with the same numbers.
func copy() -> TowerStats:
	var out: TowerStats = new()
	out.cost = cost
	out.reach = reach
	out.hits_ground = hits_ground
	out.hits_air = hits_air
	out.damage = damage
	out.reload_ms = reload_ms
	out.splash = splash
	out.targets = targets
	out.pierce = pierce
	out.slow_pct = slow_pct
	out.slow_ms = slow_ms
	out.boost_pct = boost_pct
	out.boost_damage = boost_damage
	out.pulse = pulse
	out.line = line
	out.lure_ms = lure_ms
	out.fright_pct = fright_pct
	out.fright_ms = fright_ms
	return out
