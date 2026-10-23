class_name Arena
extends RefCounted
## One fight: the clearing, the cats, the horde, the rounds in the air and the fallen. Runs
## headless at a fixed step, in meters and seconds.

const STEP := 1.0 / 60.0
## The clearing, in meters. The jungle beyond it is a wall.
const SIZE := Vector2(40.0, 24.0)
## The horde comes faster as a run goes on, up to this many at once.
const SPAWN_RATE := 1.5
const SPAWN_GROWTH := 0.05
const MOST_CREATURES := 600
## Giants come out of the jungle from GIANTS_FROM seconds in, one every GIANT_INTERVAL, no
## more than MOST_GIANTS standing at once; the felled lie where they fall for FELLED_LASTS. From
## CHAINSAW_FROM, every CHAINSAW_EVERY-th giant carries a chainsaw.
const GIANTS_FROM := 25.0
const GIANT_INTERVAL := 40.0
const MOST_GIANTS := 3
## The company's guard dogs come in packs from DOGS_FROM seconds in, one pack every DOG_INTERVAL,
## no more than MOST_DOGS at once.
const DOGS_FROM := 50.0
const DOG_INTERVAL := 35.0
const DOG_PACK := 3
const MOST_DOGS := 12
const FELLED_LASTS := 40.0
const CHAINSAW_FROM := 120.0
const CHAINSAW_EVERY := 2
## A machine comes out of the jungle from MACHINE_FROM seconds in, and another every
## MACHINE_INTERVAL after, one working at a time.
const MACHINE_FROM := 300.0
const MACHINE_INTERVAL := 300.0
## Cages with cats in them turn up from CAGES_FROM seconds in, one every CAGE_INTERVAL, no more
## than MOST_CAGES waiting at once, never closer than CAGE_DISTANCE to him.
const CAGES_FROM := 40.0
const CAGE_INTERVAL := 75.0
const MOST_CAGES := 2
const CAGE_DISTANCE := 6.0
## The salvage what he breaks throws out: a giant, a chainsaw worker, a machine.
const SALVAGE := {
	"worker": 2, "chainsaw": 4, "handler": 8, "feller_buncher": 12, "log_loader": 14, "logging_truck": 16,
	"bulldozer": 18, "helicopter": 24,
}
## What spawns, and when: Endless's plan is everything, from these numbers. A liberation area has
## its own (see Areas): only what that place has.
const ENDLESS := {
	"rats": {"rate": SPAWN_RATE, "growth": SPAWN_GROWTH},
	"dogs": {"from": DOGS_FROM, "interval": DOG_INTERVAL, "pack": DOG_PACK, "most": MOST_DOGS},
	"giants": {"from": GIANTS_FROM, "interval": GIANT_INTERVAL, "most": MOST_GIANTS, "chainsaw_from": CHAINSAW_FROM, "chainsaw_every": CHAINSAW_EVERY},
	"machines": {"from": MACHINE_FROM, "interval": MACHINE_INTERVAL, "kind": "feller_buncher"},
	"cages": {"from": CAGES_FROM, "interval": CAGE_INTERVAL, "most": MOST_CAGES},
}
## The log slide's levers take this long to pull, from this close; a released stack waits a moment,
## then rolls down the slope at this pace, its logs this long and this thick, and what it does.
const LEVER_TIME := 2.0
const LEVER_REACH := 0.7
const LOG_WAIT := 0.8
const LOG_SPEED := 3.0
const LOG_LENGTH := 5.0
const LOG_RADIUS := 0.3
const LOG_DAMAGE := 40.0
const LOG_HURT := 3.0
## Afflictions bite this often; burning oil lasts FIRE_TIME, a nail NAIL_TIME; firecrackers pop
## this often, this wide; a ricochet looks this far for its next target; and a decoy draws the
## horde from this far.
const TICK := 0.5
const FIRE_TIME := 4.0
const NAIL_TIME := 8.0
const POP_INTERVAL := 0.15
const POP_RADIUS := 0.45
const RICOCHET_REACH := 3.0
const DECOY_REACH := 9.0
## With an area's goal done on an earlier run, how long before its boss comes.
const BOSS_BUILD_UP := 45.0
## The fallen stay where they lie, up to this many. Past that, the oldest crumble away over
## FADE_TIME seconds rather than vanishing.
const MOST_FALLEN := 600
const FADE_TIME := 1.5
## The cell size of the grid that finds what's near what.
const CELL := 0.2

var cats: Array[Cat] = []
var creatures: Array[Creature] = []
## The giants: walking, falling, or lying where they fell.
var giants: Array[Giant] = []
## The machines, the bosses: working, or wrecked where they stopped.
var machines: Array[Machine] = []
## Cages with cats in them, waiting or opened; salvage lying about; and what the run has brought
## home so far: the cats rescued, as {name, coat}, and the salvage picked up.
var cages: Array[Cage] = []
var pickups: Array[Pickup] = []
var rescued: Array[Dictionary] = []
var salvage := 0
## Fire burning on the ground, as {position, radius, left, dps, by}; hazards left lying, nails,
## caltrops and spike beds, as {position, radius, damage, left, kind, by, ready}; firecrackers still to pop, as
## {position, left, count, damage, by}; and decoys the horde goes for instead of him.
var fires: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var crackers: Array[Dictionary] = []
var decoys: Array[Cat] = []
## What spawns, and the liberation area this run is in (empty in Endless): its structures, its
## caged cats, its levers and the logs they let go; whether its goal is done, how long the clearing
## has been held, its boss once it comes, and whether it's free.
var plan := ENDLESS
var area := {}
var structures: Array[Structure] = []
var goal_cages: Array[Cage] = []
var levers: Array[Dictionary] = []
var logs: Array[Dictionary] = []
var goal_done := false
## With the goal done on an earlier run, the time until the boss comes: long enough for him to grow
## into a fight with it, since every run starts him at the first level.
var boss_in := 0.0
var held_for := 0.0
var boss: Object = null
var liberated := false
## Once an area's free, the company's own go home: the horde and the giants head for the jungle.
var fleeing := false
var shots: Array[Shot] = []
var fallen: Array[Body] = []
## The oldest of the fallen crumbling away, as {body, left}: seconds until it's gone.
var fading: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var time := 0.0
var kills := 0
var giants_felled := 0
var machines_broken := 0
var spawning := true
## The crew's experience, shared: every kill counts for all of them, and every level-up hands
## each cat an offer.
var experience := 0
var level := 1
## What happened this step that the view shows but the simulation doesn't need: hits, as
## {position, height, direction, killed, by}. The view takes them as it draws.
var events: Array[Dictionary] = []
var _since_spawn := 0.0
var _since_giant := GIANT_INTERVAL - GIANTS_FROM
var _giants_sent := 0
var _since_machine := MACHINE_INTERVAL - MACHINE_FROM
var _since_cage := CAGE_INTERVAL - CAGES_FROM
var _since_dogs := DOG_INTERVAL - DOGS_FROM
var _grid := {}


func _init(seed_value := 39) -> void:
	random.seed = seed_value


func add_cat(where: Vector2) -> Cat:
	var cat := Cat.new()
	cat.body.position = where
	cats.append(cat)
	return cat


func add_giant(where: Vector2, kind := "worker") -> Giant:
	var giant := Giant.new(kind)
	giant.body.position = where
	giants.append(giant)
	return giant


func add_machine(where: Vector2, heading := 0.0, kind := "feller_buncher") -> Machine:
	var machine := Machine.make(kind)
	machine.body.position = where
	machine.heading = heading
	machine.head = machine.point(Machine.REST_FORWARD, Machine.BOOM_ROOT.y)
	machine.arrived(self)
	machines.append(machine)
	return machine


func add_cage(where: Vector2) -> Cage:
	var cage := Cage.new(random)
	cage.body.position = where
	cages.append(cage)
	return cage


## Salvage thrown out from a point: each piece flies out and up, and lands where it lands.
func drop_salvage(at: Vector2, count: int) -> void:
	for index in count:
		var piece := Pickup.new()
		piece.body.position = at
		piece.body.height = 0.3
		piece.body.push(Vector2.from_angle(random.randf() * TAU) * random.randf_range(0.8, 2.4), random.randf_range(1.5, 3.0))
		pickups.append(piece)


func add_creature(where: Vector2, kind := "rat") -> Creature:
	var creature := Creature.new(kind)
	creature.body.position = where
	creatures.append(creature)
	return creature


func step() -> void:
	time += STEP
	# Who stands where, as the step begins: everything that looks for a creature uses it.
	_build_grid()
	for cat in cats:
		cat.step(STEP, self)
		_keep_inside(cat.body)
	for creature in creatures:
		creature.step(STEP, _prey_for(creature), self)
		_keep_inside(creature.body)
	for giant in giants:
		giant.step(STEP, self)
		_keep_inside(giant.body)
	giants = giants.filter(func(giant: Giant) -> bool: return giant.fallen_for < FELLED_LASTS)
	for machine in machines:
		machine.step(STEP, self)
		_keep_inside(machine.body)
	_separate()
	_shoulder_through()
	_wander()
	_bite()
	_fly_shots()
	for body in fallen:
		if body.resting():
			continue
		body.slide(STEP)
		body.step(STEP)
		_keep_inside(body)
	_crumble()
	_stand_structures()
	_pull_levers()
	_roll_logs()
	_afflict_all()
	_burn_fires()
	_spring_hazards()
	_pop_crackers()
	_pick_locks()
	_pick_up()
	_pursue_goal()
	_spawn()


## What a weapon in reach of a point should go for, by aim mode: a creature or a standing giant,
## or null.
func target_for(where: Vector2, reach: float, mode: String) -> Object:
	var best: Object = null
	var best_score := -INF
	for target in _targets():
		var distance: float = where.distance_to(target.body.position) - target.body.radius
		if distance > reach:
			continue
		# Ties go to the nearer, by a hair.
		var score: float = -distance
		if mode == "toughest":
			score = float(target.health) - distance * 0.001
		elif mode == "crowd":
			score = _crowding(target.body.position) - distance * 0.001
		if score > best_score:
			best_score = score
			best = target
	return best


## Everything there is to fight: the horde and the giants still on their feet.
func _targets() -> Array:
	var targets: Array = []
	targets.append_array(creatures)
	for giant in giants:
		if giant.standing():
			targets.append(giant)
	for machine in machines:
		if machine.standing():
			targets.append(machine)
		if machine.joint.alive():
			targets.append(machine.joint)
	for structure in structures:
		if structure.alive():
			targets.append(structure)
	return targets


## How many creatures stand within a few cells of a point.
func _crowding(where: Vector2) -> int:
	var cell := _cell_of(where)
	var count := 0
	for x in range(cell.x - 2, cell.x + 3):
		for y in range(cell.y - 2, cell.y + 3):
			count += (_grid.get(Vector2i(x, y), []) as Array).size()
	return count


## The creatures a blade cut through as it swept from one angle to the next around a cat: within
## its reach, inside the sweep, and at a height the blade passes.
func cut(center: Vector2, height: float, reach: float, weapon: Weapon, from_angle: float, to_angle: float) -> Array:
	var cut_through: Array = []
	var sweep := angle_difference(from_angle, to_angle)
	var cell := _cell_of(center)
	var cells := ceili((reach + 0.1) / CELL)
	for x in range(cell.x - cells, cell.x + cells + 1):
		for y in range(cell.y - cells, cell.y + cells + 1):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				var offset := creature.body.position - center
				if offset.length() > reach + creature.body.radius:
					continue
				var bottom := creature.body.height
				if bottom > height + weapon.blade_high or bottom + creature.body.tall < height + weapon.blade_low:
					continue
				var into := angle_difference(from_angle, offset.angle())
				# Inside the sweep: the same way round as it, and no further. A creature right
				# against the cat is cut whatever the angle.
				if offset.length() < 0.12 or (signf(into) == signf(sweep) and absf(into) <= absf(sweep)) or absf(into) < 0.05:
					cut_through.append(creature)
	# A giant is cut at whatever of him the blade reaches: at a cat's height, his shins.
	for giant in giants:
		if not giant.standing():
			continue
		var offset := giant.body.position - center
		if offset.length() > reach + giant.body.radius:
			continue
		var into := angle_difference(from_angle, offset.angle())
		if offset.length() < giant.body.radius + 0.12 or (signf(into) == signf(sweep) and absf(into) <= absf(sweep)):
			cut_through.append(giant)
	# A structure is cut like anything standing in the blade's way.
	for structure in structures:
		if not structure.alive():
			continue
		var offset := structure.body.position - center
		if offset.length() > reach + structure.body.radius:
			continue
		var into := angle_difference(from_angle, offset.angle())
		if offset.length() < structure.body.radius + 0.12 or (signf(into) == signf(sweep) and absf(into) <= absf(sweep)):
			cut_through.append(structure)
	# A machine is cut where the blade meets it, and its joint while it's down on the ground.
	for machine in machines:
		for part: Object in [machine, machine.joint]:
			if not part.alive() or (part == machine and not machine.standing()) or part.body.height > height + 0.8:
				continue
			var offset: Vector2 = part.body.position - center
			if offset.length() > reach + part.body.radius:
				continue
			var into := angle_difference(from_angle, offset.angle())
			if offset.length() < part.body.radius + 0.12 or (signf(into) == signf(sweep) and absf(into) <= absf(sweep)):
				cut_through.append(part)
	return cut_through


## The nearest living creature within reach of a point, or null.
func nearest_creature(where: Vector2, reach: float) -> Creature:
	var nearest: Creature = null
	var nearest_distance := reach * reach
	for creature in creatures:
		var distance := where.distance_squared_to(creature.body.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = creature
	return nearest


## Giants wade through the horde: rats in a giant's way are shoved aside, all the way.
func _shoulder_through() -> void:
	for giant in giants:
		if not giant.standing():
			continue
		var cell := _cell_of(giant.body.position)
		for x in range(cell.x - 2, cell.x + 3):
			for y in range(cell.y - 2, cell.y + 3):
				for creature: Creature in _grid.get(Vector2i(x, y), []):
					var apart := creature.body.position - giant.body.position
					var reach := giant.body.radius + creature.body.radius
					if apart.length() < reach:
						creature.body.position = giant.body.position + (apart.normalized() if apart.length() > 0.001 else Vector2.RIGHT) * reach


## A stomp lands: whatever is under the boot is crushed, and the shockwave throws what's near.
func stomp(giant: Giant, at: Vector2) -> void:
	for creature in creatures.duplicate():
		var apart: Vector2 = creature.body.position - at
		if apart.length() <= Giant.CRUSH_RADIUS:
			strike(creature, 100.0, Vector2.ZERO, 0.0, 0.0, "boot")
		elif apart.length() <= Giant.SHOCK_RADIUS:
			creature.body.push(apart.normalized() * Giant.SHOCK_KNOCK, 1.5)
	for cat in cats:
		var apart := cat.body.position - at
		if apart.length() <= Giant.CRUSH_RADIUS + cat.body.radius:
			cat.hurt(Giant.CRUSH_DAMAGE, apart.normalized() * Giant.SHOCK_KNOCK)
		elif apart.length() <= Giant.SHOCK_RADIUS:
			cat.hurt(Giant.SHOCK_DAMAGE, apart.normalized() * Giant.SHOCK_KNOCK)
	events.append({"position": at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "stomp", "giant": true})


## A chainsaw sweeping across the ground, from one angle to the next around the giant holding it:
## anything in its reach that it passes, at a cat's height, is cut. His own horde too.
func saw(giant: Giant, from_angle: float, to_angle: float) -> void:
	var sweep := angle_difference(from_angle, to_angle)
	var passes := func(offset: Vector2, radius: float) -> bool:
		if offset.length() > Giant.SAW_REACH + radius or offset.length() < Giant.RADIUS:
			return false
		var into := angle_difference(from_angle, offset.angle())
		return signf(into) == signf(sweep) and absf(into) <= absf(sweep) + 0.02
	for creature in creatures.duplicate():
		if creature.body.height < Giant.SAW_HEIGHT and passes.call(creature.body.position - giant.body.position, creature.body.radius):
			strike(creature, 100.0, (creature.body.position - giant.body.position).normalized(), 2.0, 0.6, "saw")
	for cat in cats:
		var offset := cat.body.position - giant.body.position
		if cat.body.height < Giant.SAW_HEIGHT and passes.call(offset, cat.body.radius):
			if cat.hurt(Giant.SAW_DAMAGE, offset.normalized() * Giant.SAW_KNOCK):
				events.append({"position": cat.body.position, "height": 0.2, "direction": offset.normalized(), "killed": false, "by": "saw", "giant": false, "kind": "cat"})


## A feller buncher's jaws shutting on a point: what's between them is cut, cats, giants and its
## own horde alike.
func jaws(machine: Machine, at: Vector2, radius := Machine.JAW_RADIUS, by := "jaws_shut") -> void:
	events.append({"position": at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": by, "giant": true, "kind": machine.kind, "radius": radius})
	for creature: Creature in creatures.duplicate():
		if creature.body.position.distance_to(at) <= radius + creature.body.radius and creature.body.height < 1.0:
			strike(creature, 100.0, Vector2.ZERO, 0.0, 0.0, "jaws")
	for giant in giants:
		if giant.standing() and giant.body.position.distance_to(at) <= radius + giant.body.radius:
			strike(giant, 30.0, (giant.body.position - at).normalized(), 0.0, 0.0, "jaws")
	for cat in cats:
		var apart := cat.body.position - at
		if apart.length() <= radius + cat.body.radius and cat.body.height < 0.6:
			cat.hurt(Machine.BITE_DAMAGE, (apart.normalized() if apart.length() > 0.001 else Vector2.DOWN) * Machine.BITE_KNOCK)


## Whether anything is standing on a point: a creature on the ground, or a giant's boot.
func stepped_on(at: Vector2, reach: float) -> bool:
	var cell := _cell_of(at)
	for x in range(cell.x - 2, cell.x + 3):
		for y in range(cell.y - 2, cell.y + 3):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				if not creature.body.airborne() and creature.body.position.distance_to(at) <= reach + creature.body.radius:
					return true
	for giant in giants:
		if giant.standing() and giant.body.position.distance_to(at) <= reach + giant.body.radius:
			return true
	for machine in machines:
		if machine.covers(at, reach):
			return true
	return false


## A burst on the ground: everything within its radius is struck and thrown outward, the giants
## at their feet. What set it off names it, for the view and the sound.
## Dust kicked up: the horde in it stops to cough a while, down in the dust, and loses him.
func dust(at: Vector2, radius: float, time: float) -> void:
	events.append({"position": at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "dust", "giant": false, "kind": "cat", "radius": radius})
	for creature in _near(at, radius + 0.3):
		if creature.alive() and creature.body.position.distance_to(at) <= radius + creature.body.radius:
			creature.tripped_for = maxf(creature.tripped_for, time)
			creature.body.velocity *= 0.3


func blast(at: Vector2, radius: float, damage: float, knock: float, lift: float, by: String, attacker: Cat = null, afflicting: Weapon = null) -> void:
	events.append({"position": at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "blast", "giant": false, "kind": by, "radius": radius})
	for creature: Creature in creatures.duplicate():
		var apart := creature.body.position - at
		if apart.length() <= radius + creature.body.radius and creature.body.height < radius:
			strike(creature, damage, apart.normalized() if apart.length() > 0.001 else Vector2.RIGHT, knock, lift, by, attacker)
			if afflicting != null:
				afflict(creature, afflicting, attacker)
	for giant in giants:
		var apart := giant.body.position - at
		if giant.standing() and apart.length() <= radius + giant.body.radius:
			strike(giant, damage, apart.normalized() if apart.length() > 0.001 else Vector2.RIGHT, knock, 0.0, by, attacker)
	_strike_machines(at, radius, damage, by, attacker)
	for structure in structures:
		if structure.alive() and structure.body.position.distance_to(at) <= radius + structure.body.radius:
			strike(structure, damage, Vector2.ZERO, 0.0, 0.0, by, attacker)


## Strikes every machine within reach of a point, and its joint if that's in reach too.
func _strike_machines(at: Vector2, reach: float, damage: float, by: String, attacker: Cat) -> void:
	for machine in machines:
		if machine.joint.alive() and machine.joint.body.position.distance_to(at) <= reach + machine.joint.body.radius:
			strike(machine.joint, damage, Vector2.ZERO, 0.0, 0.0, by, attacker)
		elif machine.standing() and machine.covers(at, reach):
			strike(machine, damage, Vector2.ZERO, 0.0, 0.0, by, attacker)


## The creatures a rolling cat is touching, at heights he passes: what a rolling slash cuts.
func rolled_into(cat: Cat) -> Array[Creature]:
	var touching: Array[Creature] = []
	var cell := _cell_of(cat.body.position)
	for x in range(cell.x - 2, cell.x + 3):
		for y in range(cell.y - 2, cell.y + 3):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				if creature.alive() and _touching(cat.body, creature.body, 0.06):
					touching.append(creature)
	return touching


## The giants standing over a rolling cat: he's between his legs.
func legs_rolled_between(cat: Cat) -> Array[Giant]:
	var over: Array[Giant] = []
	for giant in giants:
		if giant.standing() and cat.body.height < Giant.TALL * 0.4 \
				and cat.body.position.distance_to(giant.body.position) <= giant.body.radius + cat.body.radius:
			over.append(giant)
	return over


## A riposte: a hit dodged as it landed, answered at once against everything around him.
func riposte(cat: Cat, damage: float) -> void:
	events.append({"position": cat.body.position, "height": 0.2, "direction": cat.facing, "killed": false, "by": "strike_back", "giant": false, "kind": "cat"})
	for creature: Creature in creatures.duplicate():
		var apart := creature.body.position - cat.body.position
		if apart.length() <= Cat.RIPOSTE_REACH + creature.body.radius:
			strike(creature, damage, apart.normalized(), 2.0, 1.0, "riposte", cat)
	for giant in giants:
		var apart := giant.body.position - cat.body.position
		if giant.standing() and apart.length() <= Cat.RIPOSTE_REACH + giant.body.radius:
			strike(giant, damage, apart.normalized(), 0.0, 0.0, "riposte", cat)
	_strike_machines(cat.body.position, Cat.RIPOSTE_REACH, damage, "riposte", cat)


## A pounce comes down: what's under him takes it, and what's around is thrown.
func land_pounce(cat: Cat, damage: float) -> void:
	events.append({"position": cat.body.position, "height": 0.0, "direction": cat.facing, "killed": false, "by": "landing", "giant": false, "kind": "cat"})
	for creature: Creature in creatures.duplicate():
		var apart := creature.body.position - cat.body.position
		if apart.length() <= Cat.POUNCE_RADIUS + creature.body.radius:
			strike(creature, damage, apart.normalized() if apart.length() > 0.001 else cat.facing, 1.6, 1.2, "pounce", cat)
	for giant in giants:
		var apart := giant.body.position - cat.body.position
		if giant.standing() and apart.length() <= Cat.POUNCE_RADIUS + giant.body.radius:
			strike(giant, damage, cat.facing, 0.0, 0.0, "pounce", cat)
	_strike_machines(cat.body.position, Cat.POUNCE_RADIUS, damage, "pounce", cat)


## Whether two bodies overlap, along the ground and in height, with a little give.
func _touching(a: Body, b: Body, give: float) -> bool:
	return a.position.distance_to(b.position) <= a.radius + b.radius + give \
			and a.height <= b.height + b.tall and b.height <= a.height + a.tall


## A felled giant hits the ground along his length: everything in that strip is crushed.
func land(giant: Giant) -> void:
	var feet := giant.body.position
	var head := feet + giant.fall_direction * Giant.TALL
	for creature in creatures.duplicate():
		var closest := Geometry2D.get_closest_point_to_segment(creature.body.position, feet, head)
		if closest.distance_to(creature.body.position) <= Giant.FALLEN_WIDTH:
			strike(creature, 100.0, Vector2.ZERO, 0.0, 0.0, "fall")
	for cat in cats:
		var closest := Geometry2D.get_closest_point_to_segment(cat.body.position, feet, head)
		var apart := cat.body.position - closest
		if apart.length() <= Giant.FALLEN_WIDTH:
			cat.hurt(Giant.FALL_DAMAGE, (apart.normalized() if apart.length() > 0.001 else giant.fall_direction.orthogonal()) * Giant.SHOCK_KNOCK)
	events.append({"position": (feet + head) / 2.0, "height": 0.0, "direction": giant.fall_direction, "killed": false, "by": "fall", "giant": true})


## Which way something walking through a spot pushes it: toward +1 if it's on the left of the
## spot, -1 if on the right, 0 if nothing is that close. Grass and ferns bend to it.
func brushing(where: Vector2, reach: float) -> int:
	for cat in cats:
		if cat.body.position.distance_to(where) < reach + cat.body.radius and not cat.body.airborne():
			return 1 if cat.body.position.x < where.x else -1
	var cell := _cell_of(where)
	for x in range(cell.x - 1, cell.x + 2):
		for y in range(cell.y - 1, cell.y + 2):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				if creature.body.position.distance_to(where) < reach + creature.body.radius:
					return 1 if creature.body.position.x < where.x else -1
	return 0


func nearest_cat(where: Vector2) -> Cat:
	if fleeing:
		return null
	var nearest: Cat = null
	var nearest_distance := INF
	for cat in cats:
		if not cat.alive():
			continue
		var distance := where.distance_squared_to(cat.body.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = cat
	return nearest


func _cell_of(where: Vector2) -> Vector2i:
	return Vector2i(floori(where.x / CELL), floori(where.y / CELL))


func _build_grid() -> void:
	_grid.clear()
	for creature in creatures:
		var cell := _cell_of(creature.body.position)
		if _grid.has(cell):
			_grid[cell].append(creature)
		else:
			_grid[cell] = [creature]


## Creatures on the ground can't stand in each other: overlapping pairs are pushed apart, half
## each. The grid keeps it to neighbors, so a big horde costs what its crowding costs.
func _separate() -> void:
	for creature in creatures:
		if creature.body.airborne():
			continue
		var cell := _cell_of(creature.body.position)
		# A dog is wider than a cell: it looks two round, a rat one.
		var span := 2 if creature.body.radius > CELL / 2.0 else 1
		for x in range(cell.x - span, cell.x + span + 1):
			for y in range(cell.y - span, cell.y + span + 1):
				for other: Creature in _grid.get(Vector2i(x, y), []):
					if other == creature or other.body.airborne():
						continue
					var apart := creature.body.position - other.body.position
					var reach := creature.body.radius + other.body.radius
					var distance := apart.length()
					if distance >= reach:
						continue
					var push := (apart / distance if distance > 0.0001 else Vector2.RIGHT) * (reach - distance) * 0.5
					creature.body.position += push
					other.body.position -= push


func _bite() -> void:
	for cat in cats:
		if not cat.alive():
			continue
		var cell := _cell_of(cat.body.position)
		# Two cells round: a dog is wider than a cell.
		for x in range(cell.x - 2, cell.x + 3):
			for y in range(cell.y - 2, cell.y + 3):
				for creature: Creature in _grid.get(Vector2i(x, y), []):
					var apart := cat.body.position - creature.body.position
					# It bites what it can reach: along the ground and up off it, on its feet or in
					# the middle of a lunge.
					if creature.bite_ready_in > 0.0 or (creature.body.airborne() and not creature.lunging()) \
							or apart.length() > cat.body.radius + creature.body.radius + 0.02 \
							or cat.body.height > creature.body.height + creature.body.tall \
							or creature.body.height > cat.body.height + Cat.TALL:
						continue
					creature.bite_ready_in = creature.stat("bite_interval")
					if cat.hurt(creature.stat("bite"), apart.normalized() * 0.6):
						events.append({"position": cat.body.position, "height": 0.15, "direction": apart.normalized(), "killed": false, "by": "bite", "giant": false, "kind": creature.kind})


## What a creature runs at: a decoy close enough, or the nearest cat; nothing, once they've fled.
func _prey_for(creature: Creature) -> Cat:
	if fleeing:
		return null
	for decoy in decoys:
		if decoy.alive() and decoy.body.position.distance_to(creature.body.position) < DECOY_REACH:
			return decoy
	return nearest_cat(creature.body.position)


func _fly_shots() -> void:
	var flying: Array[Shot] = []
	for shot in shots:
		shot.previous = shot.position
		shot.previous_height = shot.height
		if shot.falls:
			shot.vertical_speed -= Body.GRAVITY * STEP
		shot.position += shot.velocity * STEP
		shot.height += shot.vertical_speed * STEP
		shot.life -= STEP
		var hit := _first_hit(shot)
		# A round that goes through can cross several in one step: each is hit in turn.
		while hit != null and not shot.spent and shot.pierce_left > 0 and shot.blast <= 0.0:
			_strike(hit, shot)
			afflict(hit, shot.weapon, shot.shooter)
			shot.struck[hit] = true
			_after_hit(shot, hit)
			hit = _first_hit(shot)
		if hit != null:
			if shot.blast > 0.0:
				blast(hit.body.position, shot.blast, shot.damage, shot.weapon.knock, shot.weapon.lift, shot.weapon.name, shot.shooter, shot.weapon)
				shot.spent = true
			else:
				_strike(hit, shot)
				afflict(hit, shot.weapon, shot.shooter)
				shot.struck[hit] = true
				_after_hit(shot, hit)
			if shot.spent:
				_landed(shot, hit.body.position)
		elif shot.height <= 0.0 or shot.life <= 0.0:
			if shot.height <= 0.0:
				if shot.blast > 0.0:
					blast(shot.position, shot.blast, shot.damage, shot.weapon.knock, shot.weapon.lift, shot.weapon.name, shot.shooter, shot.weapon)
				_landed(shot, shot.position)
			shot.spent = true
		if not shot.spent:
			flying.append(shot)
	shots = flying


## After a round hits: it goes on through if it pierces, glances off to the next target if it
## ricochets, and otherwise stops.
func _after_hit(shot: Shot, hit: Object) -> void:
	if shot.pierce_left > 0:
		shot.pierce_left -= 1
		# Through, it carries on level: it was aimed down at the first, not the ground behind it.
		if not shot.falls:
			shot.vertical_speed = 0.0
		return
	if shot.ricochet_left > 0:
		shot.ricochet_left -= 1
		var next: Creature = null
		for creature in creatures:
			if creature.alive() and not shot.struck.has(creature) and creature.body.position.distance_to(hit.body.position) < RICOCHET_REACH:
				if next == null or creature.body.position.distance_to(hit.body.position) < next.body.position.distance_to(hit.body.position):
					next = creature
		if next != null:
			# Off toward the next, a little spent.
			# From where the stone is now: within a step it's already past what it hit.
			shot.velocity = (next.body.position - shot.position).normalized() * shot.velocity.length() * 0.8
			shot.vertical_speed = 0.0
			shot.falls = false
			shot.damage *= 0.8
			shot.life = RICOCHET_REACH / shot.velocity.length() * 1.5
			return
	shot.spent = true


## Where a round comes to rest, what it carries is left: burning oil, nails, or firecrackers.
func _landed(shot: Shot, at: Vector2) -> void:
	var weapon := shot.weapon
	if weapon.fire_patch > 0.0:
		fires.append({"position": at, "radius": weapon.fire_patch, "left": FIRE_TIME, "dps": weapon.burn, "by": shot.shooter})
		events.append({"position": at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "ignite", "giant": false, "kind": weapon.name})
	if weapon.nails:
		hazards.append({"position": at, "radius": 0.08, "damage": shot.damage, "left": NAIL_TIME, "kind": "nail", "by": shot.shooter, "ready": {}})
	if weapon.pops > 0:
		crackers.append({"position": at, "left": 0.0, "count": weapon.pops, "damage": shot.damage, "by": shot.shooter})


## A weapon's hit taking hold: poison, slowing and fire, and a trip, on what can take them.
func afflict(target: Object, weapon: Weapon, attacker: Cat) -> void:
	if not (target is Creature or target is Giant) or not target.alive():
		return
	var share := 1.0 + weapon.power + (attacker.damage_bonus if attacker != null else 0.0)
	if weapon.poison > 0.0:
		target.afflictions.poison = {"dps": weapon.poison * share, "left": Weapon.AFFLICTION_TIME, "by": attacker, "tick": 0.0}
	if weapon.burn > 0.0 and weapon.fire_patch <= 0.0:
		target.afflictions.burn = {"dps": weapon.burn * share, "left": Weapon.AFFLICTION_TIME, "by": attacker, "tick": 0.0}
	if weapon.slow > 0.0 and target is Creature:
		target.afflictions.slow = {"share": weapon.slow, "left": Weapon.AFFLICTION_TIME}
	if weapon.trips > 0.0 and target is Creature:
		target.tripped_for = weapon.trips
		target.body.velocity *= 0.3


## Poison and fire bite on a tick, every TICK seconds, and wear off.
func _afflict_all() -> void:
	var afflicted: Array = []
	afflicted.append_array(creatures)
	for giant in giants:
		if giant.standing():
			afflicted.append(giant)
	for target: Object in afflicted:
		var afflictions: Dictionary = target.afflictions
		for kind: String in afflictions.keys():
			var affliction: Dictionary = afflictions[kind]
			affliction.left -= STEP
			if affliction.has("dps"):
				affliction.tick += STEP
				if affliction.tick >= TICK:
					affliction.tick -= TICK
					strike(target, affliction.dps * TICK, Vector2.ZERO, 0.0, 0.0, "poison" if kind == "poison" else "fire", affliction.by)
			if affliction.left <= 0.0:
				afflictions.erase(kind)


## Burning oil on the ground sets alight what stands in it, and burns down.
func _burn_fires() -> void:
	var burning: Array[Dictionary] = []
	for fire in fires:
		fire.left -= STEP
		var standing_in: Array = []
		for creature in creatures:
			if not creature.body.airborne():
				standing_in.append(creature)
		for giant in giants:
			if giant.standing():
				standing_in.append(giant)
		for target: Object in standing_in:
			if target.body.position.distance_to(fire.position) > fire.radius + target.body.radius:
				continue
			var burn: Dictionary = target.afflictions.get("burn", {"tick": 0.0, "left": 0.0})
			target.afflictions.burn = {"dps": fire.dps, "left": maxf(burn.left, 1.0), "by": fire.by, "tick": burn.tick}
		if fire.left > 0.0:
			burning.append(fire)
	fires = burning


## Hazards lying on the ground: a nail or a caltrop goes into the first foot on it, and is gone (a
## caltrop slowing it); a spike bed
## pricks everything on it every TICK, slowing it, until it's trampled flat.
func _spring_hazards() -> void:
	var lying: Array[Dictionary] = []
	for hazard in hazards:
		hazard.left -= STEP
		var used := false
		for creature in _near(hazard.position, hazard.radius + 0.25):
			if not creature.alive() or creature.body.airborne() or creature.body.position.distance_to(hazard.position) > hazard.radius + creature.body.radius:
				continue
			if hazard.kind in ["nail", "caltrop"]:
				# A caltrop lames what treads on it, too.
				if hazard.kind == "caltrop":
					creature.afflictions.slow = {"share": 0.5, "left": 1.5}
				strike(creature, hazard.damage, Vector2.ZERO, 0.0, 0.0, hazard.kind, hazard.by)
				used = true
				break
			if hazard.ready.get(creature, 0.0) <= time:
				hazard.ready[creature] = time + TICK
				creature.afflictions.slow = {"share": 0.5, "left": 0.6}
				strike(creature, hazard.damage, Vector2.ZERO, 0.0, 0.0, "spikes", hazard.by)
		if not used and hazard.left > 0.0:
			lying.append(hazard)
		elif hazard.kind == "spikes":
			events.append({"position": hazard.position, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "trampled", "giant": false, "kind": "ranjau_bambu"})
	hazards = lying


## The creatures in the grid's cells within reach of a point: what's near, without looking at all.
func _near(where: Vector2, reach: float) -> Array[Creature]:
	var near: Array[Creature] = []
	var lowest := _cell_of(where - Vector2.ONE * reach)
	var highest := _cell_of(where + Vector2.ONE * reach)
	for x in range(lowest.x, highest.x + 1):
		for y in range(lowest.y, highest.y + 1):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				near.append(creature)
	return near


## Firecrackers, popping one after another where they landed, each a small blast.
func _pop_crackers() -> void:
	var left: Array[Dictionary] = []
	for cracker in crackers:
		cracker.left -= STEP
		if cracker.left <= 0.0:
			cracker.left = POP_INTERVAL
			cracker.count -= 1
			var at: Vector2 = cracker.position + Vector2(random.randf_range(-0.3, 0.3), random.randf_range(-0.3, 0.3))
			blast(at, POP_RADIUS, cracker.damage, 1.6, 1.4, "petasan", cracker.by)
		if cracker.count > 0:
			left.append(cracker)
	crackers = left


## The first creature along the path a round moved this step, at the height it passed.
func _first_hit(shot: Shot) -> Object:
	var from := shot.previous
	var to := shot.position
	# Widened by the widest creature, so a round grazing a dog's edge isn't missed.
	var lowest := _cell_of(Vector2(minf(from.x, to.x), minf(from.y, to.y)) - Vector2.ONE * (CELL + 0.25))
	var highest := _cell_of(Vector2(maxf(from.x, to.x), maxf(from.y, to.y)) + Vector2.ONE * (CELL + 0.25))
	var first: Object = null
	var first_along := INF
	for x in range(lowest.x, highest.x + 1):
		for y in range(lowest.y, highest.y + 1):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				if not creature.alive() or shot.struck.has(creature):
					continue
				var closest := Geometry2D.get_closest_point_to_segment(creature.body.position, from, to)
				if closest.distance_to(creature.body.position) > creature.body.radius:
					continue
				var along := from.distance_to(closest)
				var share := along / maxf(from.distance_to(to), 0.0001)
				var passing := lerpf(shot.previous_height, shot.height, share)
				if passing < creature.body.height or passing > creature.body.height + creature.body.tall:
					continue
				if along < first_along:
					first_along = along
					first = creature
	for giant in giants:
		if not giant.standing() or shot.struck.has(giant):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(giant.body.position, from, to)
		if closest.distance_to(giant.body.position) > giant.body.radius:
			continue
		var along := from.distance_to(closest)
		var passing := lerpf(shot.previous_height, shot.height, along / maxf(from.distance_to(to), 0.0001))
		if passing >= 0.0 and passing <= Giant.TALL and along < first_along:
			first_along = along
			first = giant
	for structure in structures:
		if not structure.alive() or shot.struck.has(structure):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(structure.body.position, from, to)
		if closest.distance_to(structure.body.position) > structure.body.radius:
			continue
		var along := from.distance_to(closest)
		var passing := lerpf(shot.previous_height, shot.height, along / maxf(from.distance_to(to), 0.0001))
		if passing <= structure.body.tall + 0.1 and along < first_along:
			first_along = along
			first = structure
	# A machine stops a round where the round meets its steel, its joint where that's open.
	for machine in machines:
		for part: Object in [machine.joint, machine]:
			if not part.alive() or (part == machine and not machine.standing()):
				continue
			var closest := Geometry2D.get_closest_point_to_segment(part.body.position, from, to)
			var inside: bool = (machine.covers(closest) if not machine.flying else closest.distance_to(machine.body.position) <= machine.body.radius) if part == machine else closest.distance_to(part.body.position) <= part.body.radius
			if not inside:
				continue
			var along := from.distance_to(closest)
			var passing := lerpf(shot.previous_height, shot.height, along / maxf(from.distance_to(to), 0.0001))
			if passing >= part.body.height - 0.1 and passing <= part.body.height + part.body.tall and along < first_along:
				first_along = along
				first = part
	return first


func _strike(creature: Object, shot: Shot) -> void:
	strike(creature, shot.damage, shot.velocity.normalized(), shot.weapon.knock, shot.weapon.lift, "round", shot.shooter)


## A hit on a creature, from a round or a blade: it's hurt, thrown, and falls if it's done for.
func strike(target: Object, damage: float, direction: Vector2, knock: float, lift: float, by: String, attacker: Cat = null) -> void:
	if not target.alive():
		return
	# His own hits: some land twice as hard, and his gear can make them shove harder.
	if attacker != null:
		if attacker.critical > 0.0 and random.randf() < attacker.critical:
			damage *= 2.0
		knock *= 1.0 + attacker.knockback_bonus
	if target is Structure:
		var structure: Structure = target
		structure.health -= damage
		events.append({"position": structure.body.position, "height": structure.body.tall * 0.6, "direction": direction, "killed": not structure.alive(), "by": by, "giant": true, "kind": "structure"})
		if not structure.alive():
			structure.broken(self)
			drop_salvage(structure.body.position, 2)
			events.append({"position": structure.body.position, "height": 0.0, "direction": Vector2.ZERO, "killed": true, "by": "structure_down", "giant": false, "kind": structure.kind})
		return
	if target is Machine or target is Machine.Joint:
		var on_joint: bool = target is Machine.Joint
		var machine: Machine = target.machine if on_joint else target
		var through := machine.take(damage, on_joint)
		if attacker != null:
			attacker.heal(through * attacker.adrenaline)
		events.append({"position": target.body.position, "height": minf(0.6, target.body.height + 0.2), "direction": direction, "killed": not machine.alive(), "by": by, "giant": true, "kind": "joint" if on_joint else "machine"})
		if not machine.alive():
			kills += 1
			machines_broken += 1
			if attacker != null:
				attacker.killed_one()
			_gain_experience(machine.worth)
			drop_salvage(machine.body.position, SALVAGE.get(machine.kind, 0))
		return
	var dealt: float = minf(damage, target.health)
	if attacker != null:
		attacker.heal(dealt * attacker.adrenaline)
	if target is Giant:
		var giant: Giant = target
		giant.take(damage, direction)
		# A push is shared over his mass: a round that throws a rat barely moves him.
		giant.body.velocity += direction * knock / Giant.HEFT
		events.append({"position": giant.body.position, "height": minf(0.3, Giant.TALL), "direction": direction, "killed": not giant.alive(), "by": by, "giant": true})
		if not giant.alive():
			kills += 1
			giants_felled += 1
			if attacker != null:
				attacker.killed_one()
			_gain_experience(giant.worth)
			drop_salvage(giant.body.position, SALVAGE.get(giant.kind, 0))
		return
	var creature: Creature = target
	creature.health -= damage
	# A push is shared over its mass: a dog takes a hit a rat would fly from.
	var heft: float = creature.stat("heft")
	creature.body.push(direction * knock / heft, lift / heft)
	# The view drains these as it draws; headless, nothing does, so the oldest go.
	if events.size() >= 256:
		events.pop_front()
	events.append({
		"position": creature.body.position, "height": creature.body.height + creature.body.tall * 0.5,
		"direction": direction, "killed": not creature.alive(), "by": by, "giant": false, "kind": creature.kind,
	})
	if creature.alive():
		return
	kills += 1
	if attacker != null:
		attacker.killed_one()
	_gain_experience(creature.worth)
	creatures.erase(creature)
	# It falls where it was hit, and keeps the way the hit sent it.
	var body := creature.body
	body.restitution = 0.3
	body.push(Vector2.ZERO, 1.2)
	fallen.append(body)


func _crumble() -> void:
	while fallen.size() > MOST_FALLEN:
		fading.append({"body": fallen.pop_front(), "left": FADE_TIME})
	var lasting: Array[Dictionary] = []
	for remains in fading:
		remains.left -= STEP
		if remains.left > 0.0:
			lasting.append(remains)
	fading = lasting


## Cats by a cage pick its lock; leave it and the pick slips back. Opened, its cat runs home.
func _pick_locks() -> void:
	for cage in cages:
		var picking := cats.any(func(cat: Cat) -> bool: return cat.alive() and not cat.body.airborne() and cat.body.position.distance_to(cage.body.position) <= Cage.PICK_REACH + cage.body.radius)
		if cage.pick(STEP, picking):
			rescued.append(cage.prisoner)
			events.append({"position": cage.body.position, "height": 0.2, "direction": Vector2.ZERO, "killed": false, "by": "cage_open", "giant": false, "kind": "cage"})
		cage.throw_at(self)
		cage.run_home(STEP, SIZE)
	cages = cages.filter(func(cage: Cage) -> bool: return not cage.home)


## Salvage on the move flies and slides; a cat walking over a piece takes it.
func _pick_up() -> void:
	var lying: Array[Pickup] = []
	for piece in pickups:
		if not piece.body.resting():
			piece.body.slide(STEP)
			piece.body.step(STEP)
			_keep_inside(piece.body)
		var taken := false
		for cat in cats:
			if cat.alive() and piece.body.height < 0.3 and cat.body.position.distance_to(piece.body.position) <= Pickup.REACH:
				salvage += piece.amount
				taken = true
				events.append({"position": piece.body.position, "height": 0.1, "direction": Vector2.ZERO, "killed": false, "by": "pickup", "giant": false, "kind": "salvage"})
				break
		if not taken:
			lying.append(piece)
	pickups = lying


## Experience needed to go from this level to the next.
static func experience_needed(at_level: int) -> int:
	return 4 + at_level * 3


func _gain_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_needed(level):
		experience -= experience_needed(level)
		level += 1
		for cat in cats:
			var offer := Upgrades.offer(cat, random)
			# Never an empty card: with mastery there's always something, but if not, no card.
			if not offer.is_empty():
				cat.offers.append(offer)


## With no cat in the clearing (behind the title, say) the horde and the giants amble about: each
## picks somewhere and goes there, then somewhere else. Fleeing, each makes for the jungle's edge
## nearest it, and is gone into it.
func _wander() -> void:
	if fleeing:
		for walker: Object in creatures + giants:
			if not walker.wander_to.is_finite():
				var at: Vector2 = walker.body.position
				var edges := [Vector2(at.x, -1.0), Vector2(at.x, SIZE.y + 1.0), Vector2(-1.0, at.y), Vector2(SIZE.x + 1.0, at.y)]
				edges.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(at) < b.distance_to(at))
				walker.wander_to = edges[0]
		creatures = creatures.filter(func(creature: Creature) -> bool: return creature.body.position.distance_to(creature.wander_to) > 1.6)
		giants = giants.filter(func(giant: Giant) -> bool: return not giant.standing() or giant.body.position.distance_to(giant.wander_to) > 1.8)
		return
	if not cats.is_empty():
		return
	for creature in creatures:
		if not creature.wander_to.is_finite() or creature.body.position.distance_to(creature.wander_to) < 0.4:
			creature.wander_to = Vector2(random.randf_range(1.0, SIZE.x - 1.0), random.randf_range(1.0, SIZE.y - 1.0))
	for giant in giants:
		if not giant.wander_to.is_finite() or giant.body.position.distance_to(giant.wander_to) < 1.0:
			giant.wander_to = Vector2(random.randf_range(3.0, SIZE.x - 3.0), random.randf_range(3.0, SIZE.y - 3.0))


func _keep_inside(body: Body) -> void:
	var inside := body.position.clamp(Vector2.ONE * body.radius, SIZE - Vector2.ONE * body.radius)
	if inside.x != body.position.x:
		body.velocity.x = 0.0
	if inside.y != body.position.y:
		body.velocity.y = 0.0
	body.position = inside


## The horde comes out of the jungle all around the clearing, and now and then, a giant: what the
## plan has, when it says.
func _spawn() -> void:
	if not spawning:
		return
	var giants_plan: Dictionary = plan.get("giants", {})
	if not giants_plan.is_empty():
		_since_giant += STEP
		if _since_giant >= giants_plan.interval and giants.filter(func(giant: Giant) -> bool: return giant.standing()).size() < giants_plan.most:
			_since_giant = 0.0
			_giants_sent += 1
			var chainsaw: bool = time >= giants_plan.chainsaw_from and _giants_sent % int(giants_plan.chainsaw_every) == 0
			add_giant(edge_point(), "chainsaw" if chainsaw else "worker")
	var machines_plan: Dictionary = plan.get("machines", {})
	if not machines_plan.is_empty():
		_since_machine += STEP
		if _since_machine >= machines_plan.interval and not machines.any(func(machine: Machine) -> bool: return machine.standing()):
			_since_machine = 0.0
			# It drives in out of the jungle, facing the clearing.
			var gate := edge_point()
			add_machine(gate.clamp(Vector2.ONE * 1.6, SIZE - Vector2.ONE * 1.6), (SIZE / 2.0 - gate).angle(), machines_plan.kind)
	var cages_plan: Dictionary = plan.get("cages", {})
	if not cages_plan.is_empty():
		_since_cage += STEP
		if _since_cage >= cages_plan.interval and cages.filter(func(cage: Cage) -> bool: return not cage.opened).size() < cages_plan.most + goal_cages.filter(func(cage: Cage) -> bool: return not cage.opened).size():
			var spot := _cage_spot()
			if spot.is_finite():
				_since_cage = 0.0
				add_cage(spot)
	var dogs_plan: Dictionary = plan.get("dogs", {})
	if not dogs_plan.is_empty():
		_since_dogs += STEP
		if _since_dogs >= dogs_plan.interval:
			_since_dogs = 0.0
			var dogs := creatures.filter(func(creature: Creature) -> bool: return creature.kind == "dog").size()
			# A pack comes out of the jungle together.
			var gate := edge_point()
			for index in mini(dogs_plan.pack, dogs_plan.most - dogs):
				add_creature((gate + Vector2(random.randf_range(-0.6, 0.6), random.randf_range(-0.6, 0.6))).clamp(Vector2.ONE * 0.3, SIZE - Vector2.ONE * 0.3), "dog")
	var rats_plan: Dictionary = plan.get("rats", {})
	if rats_plan.is_empty() or creatures.size() >= MOST_CREATURES:
		return
	_since_spawn += STEP
	var interval: float = 1.0 / (rats_plan.rate + rats_plan.growth * time)
	while _since_spawn >= interval and creatures.size() < MOST_CREATURES:
		_since_spawn -= interval
		add_creature(edge_point())


## Into an area of the forest: its plan for what spawns, and its goal's things where it puts them.
func begin_area(area_id: String, goal_kept := false) -> void:
	area = Areas.named(area_id)
	plan = area.plan
	_reset_spawning()
	if goal_kept:
		# Done on an earlier run, and it stays done: what was broken stays broken, the caged stay
		# free. Only the boss is left, once he's had time to grow.
		goal_done = true
		boss_in = BOSS_BUILD_UP
		return
	var goal: Dictionary = area.goal
	match goal.kind:
		"structures":
			for spot: Vector2 in goal.at:
				var structure := Structure.new(goal.structure)
				structure.body.position = spot
				structures.append(structure)
		"cages":
			for spot: Vector2 in goal.at:
				goal_cages.append(add_cage(spot))
		"levers":
			for spot: Vector2 in goal.at:
				levers.append({"position": spot, "picked": 0.0, "pulled": false})


## The timers for what the plan spawns, set so each first comes when the plan says.
func _reset_spawning() -> void:
	_since_spawn = 0.0
	_since_giant = _first("giants")
	_since_dogs = _first("dogs")
	_since_machine = _first("machines")
	_since_cage = _first("cages")


func _first(key: String) -> float:
	var part: Dictionary = plan.get(key, {})
	return part.interval - part.from if not part.is_empty() else 0.0


## Where the goal stands, for the view: how much of it is done, and how much there is.
func goal_progress() -> Vector2:
	if area.is_empty():
		return Vector2.ZERO
	match area.goal.kind:
		"structures":
			return Vector2(structures.filter(func(structure: Structure) -> bool: return not structure.alive()).size(), structures.size())
		"cages":
			return Vector2(goal_cages.filter(func(cage: Cage) -> bool: return cage.opened).size(), goal_cages.size())
		"levers":
			return Vector2(levers.filter(func(lever: Dictionary) -> bool: return lever.pulled).size(), levers.size())
		"hold":
			return Vector2(minf(held_for, area.goal.seconds), area.goal.seconds)
	return Vector2.ZERO


## The area's goal, then its boss: once the goal's done, the boss comes; once the boss is beaten,
## the area is free.
func _pursue_goal() -> void:
	if area.is_empty() or liberated:
		return
	if not goal_done:
		if area.goal.kind == "hold" and cats.any(func(cat: Cat) -> bool: return cat.alive()):
			held_for += STEP
		var progress := goal_progress()
		if progress.y > 0.0 and progress.x >= progress.y:
			goal_done = true
			events.append({"position": SIZE / 2.0, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "goal_done", "giant": false, "kind": area.id})
			_bring_in_the_boss()
		return
	if boss == null and boss_in > 0.0:
		boss_in -= STEP
		if boss_in <= 0.0:
			_bring_in_the_boss()
		return
	if boss != null and not (boss.standing() if boss is Machine or boss is Giant else boss.alive()):
		liberated = true
		events.append({"position": boss.body.position, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "liberated", "giant": false, "kind": area.id})


func _bring_in_the_boss() -> void:
	var coming: Dictionary = area.boss
	var at: Vector2 = coming.at
	match coming.kind:
		"creature": boss = add_creature(at, coming.type)
		"giant": boss = add_giant(at, coming.type)
		"machine": boss = add_machine(at, (SIZE / 2.0 - at).angle(), coming.type)
	events.append({"position": at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "boss_arrives", "giant": true, "kind": coming.type})


## Structures stand where they are: they act, and nothing walks through them.
func _stand_structures() -> void:
	for structure in structures:
		if not structure.alive():
			continue
		structure.step(STEP, self)
		var walkers: Array = []
		walkers.append_array(cats)
		walkers.append_array(_near(structure.body.position, structure.body.radius + 0.4))
		for walker: Object in walkers:
			var apart: Vector2 = walker.body.position - structure.body.position
			var reach: float = structure.body.radius + walker.body.radius
			if apart.length() < reach and walker.body.height < structure.body.tall:
				walker.body.position = structure.body.position + (apart.normalized() if apart.length() > 0.001 else Vector2.DOWN) * reach


## Levers at the top of the slide: standing by one pulls it, a little at a time, and when it goes,
## its stack of logs comes rolling down the slope, crushing what's in the way.
func _pull_levers() -> void:
	for lever in levers:
		if lever.pulled:
			continue
		var pulling := cats.any(func(cat: Cat) -> bool: return cat.alive() and cat.body.position.distance_to(lever.position) <= LEVER_REACH)
		lever.picked = clampf(lever.picked + (STEP / LEVER_TIME if pulling else -STEP * 0.3), 0.0, 1.0)
		if lever.picked >= 1.0:
			lever.pulled = true
			logs.append({"y": lever.position.y + 0.8, "from": lever.position.x - LOG_LENGTH / 2.0, "to": lever.position.x + LOG_LENGTH / 2.0, "wait": LOG_WAIT, "struck": {}})
			events.append({"position": lever.position, "height": 0.0, "direction": Vector2.DOWN, "killed": false, "by": "lever", "giant": false, "kind": "lever"})


func _roll_logs() -> void:
	var rolling: Array[Dictionary] = []
	for log in logs:
		if log.wait > 0.0:
			# The stack shifts and groans before it lets go: the warning.
			log.wait -= STEP
			rolling.append(log)
			continue
		log.y += LOG_SPEED * STEP
		var crushing := func(where: Vector2, reach: float) -> bool: return where.x >= log.from - reach and where.x <= log.to + reach and absf(where.y - log.y) <= LOG_RADIUS + reach
		for creature: Creature in creatures.duplicate():
			if not creature.body.airborne() and crushing.call(creature.body.position, creature.body.radius):
				strike(creature, 100.0, Vector2.DOWN, 2.0, 1.0, "log")
		for target: Object in giants + machines:
			if target.standing() and not log.struck.has(target) and crushing.call(target.body.position, target.body.radius):
				log.struck[target] = true
				strike(target, LOG_DAMAGE, Vector2.DOWN, 0.0, 0.0, "log")
		for cat in cats:
			if not log.struck.has(cat) and cat.body.height < LOG_RADIUS * 2.0 and crushing.call(cat.body.position, cat.body.radius):
				if cat.hurt(LOG_HURT, Vector2.DOWN * 3.0):
					log.struck[cat] = true
		if log.y < SIZE.y + 1.0:
			rolling.append(log)
	logs = rolling


## Somewhere in the clearing for a cage: away from the edge, and far enough from every cat that
## getting to it is a choice. INF if a few tries find nowhere.
func _cage_spot() -> Vector2:
	for attempt in 12:
		var spot := Vector2(random.randf_range(3.0, SIZE.x - 3.0), random.randf_range(3.0, SIZE.y - 3.0))
		if cats.all(func(cat: Cat) -> bool: return cat.body.position.distance_to(spot) >= CAGE_DISTANCE):
			return spot
	return Vector2.INF


## A random point just inside the jungle's edge.
func edge_point() -> Vector2:
	var along := random.randf() * 2.0 * (SIZE.x + SIZE.y)
	if along < SIZE.x:
		return Vector2(along, 0.2)
	along -= SIZE.x
	if along < SIZE.y:
		return Vector2(SIZE.x - 0.2, along)
	along -= SIZE.y
	if along < SIZE.x:
		return Vector2(along, SIZE.y - 0.2)
	return Vector2(0.2, along - SIZE.x)
