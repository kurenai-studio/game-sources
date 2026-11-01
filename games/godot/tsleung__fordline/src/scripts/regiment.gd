class_name Regiment
extends RefCounted
## One regiment on the field. Only Battle writes these fields.

enum State { IDLE, MOVING, ENGAGED, ROUTING, GONE }

var id := 0
var team := 0
var kind := 0
## Index into the campaign roster, or -1 for an enemy regiment.
var roster_index := -1
## Grand battles: the block's historical name ("Iron Brigade"), the
## division it belongs to, and that division's objectives in order, which
## the AI takes one after another. Set once, when the block is raised.
var name := ""
var formation := ""
var objectives := PackedVector2Array()
## Battle time before which the block keeps to its ground: its historical
## orders start later in the day.
var holds_until := 0.0
## Line infantry formed in square against horse. Written by Battle.
var square := false

var men_max := 1
## One position per living soldier; slot i is soldier i, front rank first.
var soldiers := PackedVector2Array()
## Damage taken that hasn't yet killed a soldier.
var wound := 0.0

var pos := Vector2.ZERO
var facing := 0.0
var state := State.IDLE
var morale := 0.0
var morale_max := 0.0

## Orders. Waypoints lead to the destination; target_id is an enemy to
## attack (melee units close in, ranged units shoot from range).
var waypoints := PackedVector2Array()
var final_facing := NAN
var target_id := -1
## A gate to batter with shot (guns only), or -1.
var target_gate := -1
## A point to pass through before closing on the target (a flank).
var via := Vector2(NAN, NAN)
var repath := 0.0
## Set by an explicit order; idle units only pick fights at close range.
var ordered := false

var reload := 0.0
var charge_t := 0.0
var march_t := 0.0
var kills := 0
var stars := 0
var routed_once := false
## Ran off the field rather than died; survivors return to the roster.
var fled := false
## Distance covered last step, per second; a fast hit is a charge.
var last_speed := 0.0
## 1 fresh, 0 spent. Fighting wears it down; standing clear restores it.
var stamina := 1.0
## Ids of enemies in contact this step, nearest first.
var contacts: Array[int] = []

# Stats after upgrades and stars.
var hp := 10.0
var atk := 1.0
var def := 0.0
var speed := 30.0
var cols := 8
var spacing := 7.0
var fire_range := 0.0
var reload_time := 0.0
var shot := 0.0
var accuracy := 0.0
var pierce := 0.0
var shock := 0.0


static func create(
	new_id: int, new_team: int, new_kind: int, men: int, at: Vector2, face: float,
	new_stars: int, doctrine: Dictionary
) -> Regiment:
	var r := Regiment.new()
	r.id = new_id
	r.team = new_team
	r.kind = new_kind
	r.stars = new_stars
	var s: Dictionary = UnitTypes.STATS[new_kind]
	r.men_max = s.men
	var star := Combat.star_mult(new_stars)
	r.hp = s.hp
	r.atk = s.atk * star * doctrine.get("atk_" + str(new_kind), 1.0)
	r.def = minf(0.85, s.def + 0.04 * new_stars + doctrine.get("def_" + str(new_kind), 0.0))
	r.speed = s.speed * doctrine.get("speed_" + str(new_kind), 1.0)
	r.cols = s.cols
	r.spacing = s.spacing
	r.morale_max = s.morale + 8.0 * new_stars + doctrine.get("morale", 0.0)
	r.morale = r.morale_max
	if UnitTypes.is_ranged(new_kind):
		r.fire_range = s.range * doctrine.get("range_" + str(new_kind), 1.0)
		r.reload_time = s.reload * doctrine.get("reload_" + str(new_kind), 1.0)
		r.shot = s.shot * star
		r.accuracy = s.get("accuracy", 1.0)
		r.pierce = s.get("pierce", 0.0)
		r.shock = s.get("shock", 0.0)
		# Stagger the first shot by id, so volleys fall out of step without
		# a random reload deciding who wins.
		r.reload = r.reload_time * (0.3 + 0.12 * (new_id % 5))
	r.pos = at
	r.facing = face
	r.final_facing = face
	for i in clampi(men, 1, r.men_max):
		r.soldiers.append(r.slot_world(i, men))
	return r


func men() -> int:
	return soldiers.size()


func alive() -> bool:
	return state != State.GONE


func fighting() -> bool:
	return state != State.GONE and state != State.ROUTING


func strength() -> float:
	return float(men()) / float(men_max)


func forward() -> Vector2:
	return Vector2.from_angle(facing)


func formation_cols(count: int) -> int:
	if square:
		return square_side(count)
	return clampi(cols, 1, maxi(count, 1))


## Men along each face of a square.
static func square_side(count: int) -> int:
	return maxi(1, ceili(count / 4.0))


func formation_rows(count: int) -> int:
	return int(ceil(float(count) / float(formation_cols(count))))


func width() -> float:
	return formation_cols(men()) * spacing


func depth() -> float:
	if square:
		return width()
	return formation_rows(men()) * spacing


## How far the regiment's edge reaches in world direction `dir_angle`:
## half its depth straight ahead or behind, half its width to the sides.
func reach(dir_angle: float) -> float:
	var s := absf(sin(angle_difference(facing, dir_angle)))
	return lerpf(depth() * 0.5, width() * 0.5, s) + 3.0


## Where soldier `i` stands in a formation of `count` soldiers.
func slot_world(i: int, count: int) -> Vector2:
	if square:
		return _square_slot(i, count)
	var c := formation_cols(count)
	var rows := formation_rows(count)
	var row := i / c
	var col := i % c
	var in_row := c if row < rows - 1 else count - row * c
	var x := (col - (in_row - 1) * 0.5) * spacing
	var y := (row - (rows - 1) * 0.5) * spacing
	var fwd := forward()
	var right := fwd.orthogonal() * -1.0
	return pos + right * x - fwd * y


## The farthest its edge reaches in any direction: no reach() is longer.
func radius() -> float:
	return maxf(depth(), width()) * 0.5 + 3.0


## Every soldier's slot at once, as slot_world gives them one by one.
func slots(count: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(count)
	if square:
		for i in count:
			out[i] = _square_slot(i, count)
		return out
	var c := formation_cols(count)
	var rows := formation_rows(count)
	var fwd := forward()
	var right := fwd.orthogonal() * -1.0
	for i in count:
		var row := i / c
		var col := i % c
		var in_row := c if row < rows - 1 else count - row * c
		var x := (col - (in_row - 1) * 0.5) * spacing
		var y := (row - (rows - 1) * 0.5) * spacing
		out[i] = pos + right * x - fwd * y
	return out


func hit_test(p: Vector2) -> bool:
	var local := (p - pos).rotated(-facing)
	return absf(local.x) <= depth() * 0.5 + 8.0 and absf(local.y) <= width() * 0.5 + 8.0


## A square: the men in turn on its four faces, each face square to one way.
func _square_slot(i: int, count: int) -> Vector2:
	var per := square_side(count)
	var half := per * spacing * 0.5
	var face := i % 4
	var k := i / 4
	var along := (k - (per - 1) * 0.5) * spacing
	var fwd := forward().rotated(face * PI * 0.5)
	return pos + fwd * half + fwd.orthogonal() * along
