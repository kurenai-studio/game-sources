class_name Structure
extends RefCounted
## Something an area's goal asks him to break: a rat nest in a split supply crate, a saw on its
## bench, a generator, a drum of fuel. Each stands where the area puts it, is solid, can be struck
## by anything that reaches it, and does what it does while it stands: a nest breeds rats, a saw
## cuts what comes too close, a fuel drum, broken, goes up in flames.

## Each kind: its health, how wide it is and how tall, and what it does while it stands.
const KINDS := {
	"nest": {"health": 40.0, "radius": 0.45, "tall": 0.5},
	"saw": {"health": 60.0, "radius": 0.55, "tall": 0.6},
	"generator": {"health": 70.0, "radius": 0.5, "tall": 0.8},
	"fuel": {"health": 45.0, "radius": 0.35, "tall": 0.6},
}
## A nest breeds a rat this often. A saw's blade reaches this far, and bites this hard, this often.
const BREED_INTERVAL := 2.5
const SAW_REACH := 0.75
const SAW_DAMAGE := 2.0
const SAW_INTERVAL := 0.7
## A broken fuel drum burns this wide.
const SPILL := 1.4

var kind := ""
var body := Body.new()
var health := 0.0
var most_health := 0.0
## How far its saw has spun, for the view, and when it next breeds or bites.
var spun := 0.0
var _next_in := 0.0


func _init(structure_kind := "nest") -> void:
	kind = structure_kind
	most_health = KINDS[kind].health
	health = most_health
	body.radius = KINDS[kind].radius
	body.tall = KINDS[kind].tall
	body.kind = kind
	_next_in = BREED_INTERVAL if kind == "nest" else SAW_INTERVAL


func alive() -> bool:
	return health > 0.0


func step(delta: float, arena: Arena) -> void:
	if not alive():
		return
	_next_in = maxf(_next_in - delta, 0.0)
	spun += delta * 20.0
	match kind:
		"nest":
			if _next_in <= 0.0 and arena.creatures.size() < Arena.MOST_CREATURES:
				_next_in = BREED_INTERVAL
				arena.add_creature(body.position + Vector2.from_angle(arena.random.randf() * TAU) * (body.radius + 0.15))
		"saw":
			if _next_in <= 0.0:
				_next_in = SAW_INTERVAL
				for cat in arena.cats:
					var apart := cat.body.position - body.position
					if cat.body.height < 0.4 and apart.length() <= SAW_REACH + cat.body.radius:
						cat.hurt(SAW_DAMAGE, apart.normalized() * 2.0)
				for creature: Creature in arena.creatures.duplicate():
					if creature.body.position.distance_to(body.position) <= SAW_REACH + creature.body.radius:
						arena.strike(creature, 100.0, (creature.body.position - body.position).normalized(), 2.0, 1.0, "saw")


## Broken: a fuel drum's spill catches.
func broken(arena: Arena) -> void:
	if kind == "fuel":
		arena.fires.append({"position": body.position, "radius": SPILL, "left": Arena.FIRE_TIME * 2.0, "dps": 3.0, "by": null})
		arena.events.append({"position": body.position, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "ignite", "giant": false, "kind": kind})
