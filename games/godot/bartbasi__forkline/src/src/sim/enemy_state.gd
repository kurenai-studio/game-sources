# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name EnemyState
extends RefCounted
## One creature on the map. Read only outside src/sim/.

var id: int = 0
var type: StringName = &""
var wave: int = 0
var health: int = 1
var max_health: int = 1
var bubble: bool = false                               # the bubble is up
var slow_pct: int = 0
var slow_ticks: int = 0
var flying: bool = false
var breaker: bool = false                              # walks the breaker route (4.5)
var from_cell: Vector2i = Vector2i.ZERO                # walkers: the step being walked
var to_cell: Vector2i = Vector2i.ZERO
var progress: int = 0                                  # sub-units along the step, 0 to UNIT
var fly_from: Vector2i = Vector2i.ZERO                 # flyers: a straight line in sub-units
var fly_to: Vector2i = Vector2i.ZERO
var fly_length: int = 0
var flown: int = 0
var breaking: int = 0                                  # 1/100 ms of breaking left; 0 when not breaking
var pos: Vector2i = Vector2i.ZERO                      # sub-units, after this tick
var prev_pos: Vector2i = Vector2i.ZERO                 # sub-units, after the last tick, or where it last landed
                                                       # after a jump this tick (docs/ARCHITECTURE.md 14.3)
var out_of_reach: bool = false                         # in a tunnel, on a twin step or dug under (RULES 8.8); never saved
var hidden: bool = false                               # on or next to a Mistwisp's tile (RULES 6.2); never saved
var napped: bool = false                               # its one nap is used (RULES 6.2)
var nap_ticks: int = 0                                 # ticks of nap left, above 0 while napping
var dig_ticks: int = 0                                 # ticks left under the ground, above 0 while dug under (RULES 6.3)
var fright_pct: int = 0                                # frightened: it takes this percent more from every hit (RULES 5.13)
var fright_ticks: int = 0                              # ticks of fright left, 0 when not frightened
var low_ticks: int = 0                                 # flyers: ticks it stays low after a lure, 0 when not low (RULES 5.15)
var awake: bool = false                                # near a Hootling or Glimmertoad: no slow this tick (RULES 6.2); never saved
var start_health: int = 1                              # its max health when it appeared, after strength and its wave's
                                                       # effects (RULES 6.2, Grow); worked out at spawn and on load, never saved

## Internal to src/sim/. Worked out at spawn from the type, the wave's strength and
## effects, and again on load, so they are not saved.
var armor: int = 0
var speed: int = 0                                     # hundredths of a tile a second, with speed ups (RULES 6.3)
var speed_pct: int = 100                               # speed_pct effects on its wave (contract 2.8)
var lives: int = 1
var bounty: int = 1
var break_ms: int = 0                                  # a gate breaker's time per gate, 0 for none (RULES 7.7)
var watched: bool = false                              # it has a speed up or a health release (RULES 6.3)
var to_node: int = -1                                  # walkers: the node it is heading to (docs/ARCHITECTURE.md 14.3)
var step_dir: Vector2i = Vector2i.ZERO                 # walkers: to_cell - from_cell, set with the step
var rate: int = 0                                      # speed * 10 * speed_pct: the move a tick is rate * (100 - slow) / 10000
var mist: bool = false                                 # the type's rules (RULES 6.2, 6.3)
var dazzle: bool = false
var regrows: bool = false
var naps: bool = false
var digs: bool = false
var timed: bool = false                                # it regrows, naps or digs: it has timers of its own
var grows: bool = false
var yawns: bool = false
var blinks: bool = false
var wakes: bool = false
var grow_cap: int = 0                                  # growers: start_health * grow_cap_pct / 100, truncated
var grow_step: int = 0                                 # growers: grow_pct of start_health, rounded half up
## Internal and saved: ticks until a popped bubble is back (0 when up), the tick of
## the next summon batch (0 for none), the tick of the next heal (0 for none), the
## speed ups taken so far, whether its health release has begun, and the tick of its
## next regrow, dig, yawn and blink (0 for none).
var bubble_ticks: int = 0
var summon_at: int = 0
var heal_at: int = 0
var ups: int = 0
var released: bool = false
var regrow_at: int = 0
var dig_at: int = 0
var yawn_at: int = 0
var blink_at: int = 0
