# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EnemyType
extends RefCounted
## One creature or boss from data/stats/enemies.json, in the file's units
## (docs/ARCHITECTURE.md 2.6). Numbers are at strength 100. Read only.

var id: StringName = &""
var name: String = ""
var info: String = ""
var health: int = 1
var armor: int = 0
var speed: int = 0
var lives: int = 1
var bounty: int = 1
var flying: bool = false
var boss: bool = false
var bubble: bool = false
var heal: int = 0
var heal_reach: int = 0
var heal_ms: int = 0
var split_into: StringName = &""
var split_count: int = 0
var split_gap_ms: int = 0
var break_ms: int = 0
var regrow: int = 0                                    # RULES 6.2: regrow this much every regrow_ms; 0 for none
var regrow_ms: int = 0
var mist: bool = false                                 # RULES 6.2: hides the creatures on its tile and the four next to it
var dazzle: bool = false                               # RULES 6.2: towers that can aim at it aim at it first
var nap_ms: int = 0                                    # RULES 6.2: naps this long instead of its first defeat; 0 for none
var dig_first_ms: int = 0                              # RULES 6.3: digs under dig_first_ms after it appears, then every
var dig_every_ms: int = 0                              # dig_every_ms, for dig_ms each time; 0 for none
var dig_ms: int = 0
var grow_pct: int = 0                                  # RULES 6.2: grows by grow_pct of its starting max health at each
var grow_cap_pct: int = 0                              # tile center, up to grow_cap_pct of it; 0 for none
var yawn_ms: int = 0                                   # RULES 6.2: every yawn_ms, attacking towers within yawn_reach
var yawn_reach: int = 0                                # doze for doze_ms; 0 for none
var doze_ms: int = 0
var blink_ms: int = 0                                  # RULES 6.2: every blink_ms it moves blink_tiles along its route
var blink_tiles: int = 0                               # at once; 0 for none
var wake_reach: int = 0                                # RULES 6.2: it and every creature within this reach are awake; 0 for none
## {"enemy": StringName, "count": int, "every_ms": int, "gap_ms": int}, or {} for none.
var summon: Dictionary = {}
## {"at_pct": Array[int], "add": int}, or {} for none.
var speed_up: Dictionary = {}
## {"at_pct": int, "enemy": StringName, "count": int, "gap_ms": int}, or {} for none.
var release: Dictionary = {}
