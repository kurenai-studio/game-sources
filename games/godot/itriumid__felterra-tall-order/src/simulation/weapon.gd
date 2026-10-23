class_name Weapon
extends RefCounted
## A weapon in a cat's paw. Ranged weapons fire rounds; melee weapons swing a blade through an
## arc, and hit whatever the blade passes through on its way.
##
## The arsenal is a table: each weapon its numbers and what sets it apart. Rounds can come several
## to a shot (a shotgun's cone), go through what they hit (a crossbow's bolt), or glance off to the
## next (a ketapel's stone); they can poison and slow, set alight, leave burning oil or nails where
## they land, or pop as firecrackers. Blades can trip, hook a creature in, or break after so many
## hits, and be re-sharpened.

enum Kind { RANGED, MELEE }

var name := ""
var kind := Kind.RANGED
## Paws it takes: a cat has two.
var hands := 1
var reach := 6.0
var interval := 0.45
var damage := 2.0
## How hard a hit shoves what it strikes, along and up, in meters a second. Arcade-strong: a
## real round wouldn't throw a rat, but a thrown rat is how a hit reads.
var knock := 1.4
var lift := 1.0
var ready_in := 0.0
## Its level, from 1 to 5, and what its levels have added: extra damage and extra speed, as
## shares.
var level := 1
var power := 0.0
var tempo := 0.0

# Ranged: muzzle speed in meters a second, spread either side in radians.
var muzzle_speed := 100.0
var spread := deg_to_rad(2.0)
## A lobbed weapon throws its round in an arc that comes down on the target; a blast bursts it
## there, this wide.
var lobbed := false
var blast := 0.0
## Rounds a shot fires at once, across its spread; what a round goes through before it stops; and
## how many times it glances off to the next target.
var pellets := 1
var pierce := 0
var ricochet := 0
## What a hit does after: poison (damage a second, for AFFLICTION_TIME, slowing by a share), fire
## (damage a second), and where a round lands: a patch of burning oil this wide, nails left on the
## ground, or firecrackers popping this many times.
var poison := 0.0
var slow := 0.0
var burn := 0.0
var fire_patch := 0.0
var nails := false
var pops := 0
## Rounds fired, so the view can flash the muzzle and kick the gun back, and the way the last one
## went.
var rounds_fired := 0
var aim := Vector2.RIGHT

# Melee: the arc the blade sweeps, in radians, and how long a swing takes.
var arc := deg_to_rad(110.0)
var swing_time := 0.14
## The blade's height above the ground, from paw to tip.
var blade_low := 0.0
var blade_high := 0.3
## The swing in progress: seconds left, the angle it sweeps from, and what it has hit.
var swinging_for := 0.0
var swing_start := 0.0
var swing_direction := 1.0
var blade_angle := 0.0
var swings := 0
var _struck := {}
## A blade that trips leaves a creature down this long; one that hooks pulls what it hits in; one
## that breaks lasts this many hits, then takes RESHARPEN_TIME to be made sharp again.
var trips := 0.0
var hooks := false
var breaks := 0
var hits_left := 0
var broken_for := 0.0

## How long poison, slowing and fire last once they take.
const AFFLICTION_TIME := 3.0
const RESHARPEN_TIME := 3.0

## The arsenal: each weapon's numbers and traits, over a blade's or a gun's to start with.
const ARSENAL := {
	# Modern blades.
	"machete": {"melee": true, "reach": 0.6, "interval": 0.45, "damage": 3.5, "arc": 120.0, "knock": 2.0},
	"greatsword": {"melee": true, "hands": 2, "reach": 0.95, "interval": 0.9, "damage": 8.0, "arc": 160.0, "swing_time": 0.22, "knock": 3.5, "lift": 1.4, "blade_high": 0.45},
	# Rifles.
	"rifle": {"reach": 9.0, "interval": 0.7, "damage": 4.0, "muzzle_speed": 140.0, "spread": 1.0, "knock": 2.0},
	"automatic_rifle": {"reach": 9.0, "interval": 0.25, "damage": 2.6, "muzzle_speed": 140.0, "spread": 2.5, "knock": 1.8},
	"assault_rifle": {"hands": 2, "reach": 10.0, "interval": 0.14, "damage": 2.4, "muzzle_speed": 150.0, "spread": 3.0, "knock": 1.8},
	"sniper_rifle": {"hands": 2, "reach": 15.0, "interval": 1.4, "damage": 12.0, "muzzle_speed": 220.0, "spread": 0.3, "pierce": 4, "knock": 3.0},
	# Other guns.
	"shotgun": {"hands": 2, "reach": 4.5, "interval": 0.9, "damage": 1.6, "pellets": 7, "spread": 16.0, "muzzle_speed": 80.0, "knock": 2.6},
	"grenade_launcher": {"hands": 2, "reach": 8.0, "interval": 1.6, "damage": 7.0, "muzzle_speed": 10.0, "lobbed": true, "blast": 1.0, "knock": 3.5, "lift": 2.5},
	"nail_gun": {"reach": 4.0, "interval": 0.16, "damage": 1.0, "muzzle_speed": 60.0, "spread": 6.0, "nails": true, "knock": 0.8},
	"flare_gun": {"reach": 7.0, "interval": 1.3, "damage": 2.0, "muzzle_speed": 30.0, "spread": 1.0, "burn": 2.0, "knock": 1.0},
	"crossbow": {"hands": 2, "reach": 9.0, "interval": 1.0, "damage": 5.0, "muzzle_speed": 90.0, "spread": 0.8, "pierce": 2, "knock": 2.2},
	"lamp_oil": {"reach": 6.0, "interval": 2.0, "damage": 1.0, "muzzle_speed": 8.0, "lobbed": true, "fire_patch": 0.9, "burn": 2.5, "knock": 0.5},
	# Two sticks on a chain, one in his paw: the swing goes most of the way round him, and it's blunt,
	# so it shoves harder than it cuts.
	"nunchaku": {"melee": true, "reach": 0.55, "interval": 0.34, "damage": 1.9, "arc": 220.0, "swing_time": 0.16, "knock": 2.8, "lift": 1.0},
	# Indonesian blades and staffs.
	"golok": {"melee": true, "reach": 0.6, "interval": 0.5, "damage": 4.2, "arc": 110.0, "knock": 2.4},
	"celurit": {"melee": true, "reach": 0.55, "interval": 0.45, "damage": 2.8, "arc": 130.0, "trips": 1.2, "knock": 1.0},
	"rattan_staff": {"melee": true, "hands": 2, "reach": 0.85, "interval": 0.5, "damage": 2.2, "arc": 180.0, "swing_time": 0.18, "knock": 4.5, "lift": 1.6, "blade_high": 0.4},
	"tombak": {"melee": true, "hands": 2, "reach": 1.25, "interval": 0.55, "damage": 4.5, "arc": 20.0, "swing_time": 0.1, "knock": 2.6, "blade_high": 0.35},
	"bambu_runcing": {"melee": true, "hands": 2, "reach": 1.1, "interval": 0.45, "damage": 4.0, "arc": 20.0, "swing_time": 0.1, "breaks": 14, "knock": 2.2, "blade_high": 0.35},
	"mandau": {"melee": true, "reach": 0.7, "interval": 0.6, "damage": 5.2, "arc": 140.0, "swing_time": 0.16, "knock": 2.6},
	"rencong": {"melee": true, "reach": 0.5, "interval": 0.24, "damage": 2.6, "arc": 20.0, "swing_time": 0.08, "knock": 1.2},
	"badik": {"melee": true, "reach": 0.42, "interval": 0.28, "damage": 3.4, "arc": 100.0, "swing_time": 0.1, "knock": 1.4},
	"kujang": {"melee": true, "reach": 0.6, "interval": 0.42, "damage": 3.0, "arc": 120.0, "hooks": true, "knock": 1.6},
	# Indonesian ranged and thrown.
	"ketapel": {"reach": 6.0, "interval": 0.6, "damage": 2.0, "muzzle_speed": 45.0, "spread": 2.0, "ricochet": 2, "knock": 1.8},
	"sumpit": {"reach": 8.0, "interval": 0.9, "damage": 0.8, "muzzle_speed": 50.0, "spread": 0.8, "poison": 1.2, "slow": 0.4, "knock": 0.3},
	"petasan": {"reach": 5.5, "interval": 1.5, "damage": 1.6, "muzzle_speed": 8.0, "lobbed": true, "pops": 4, "knock": 1.6, "lift": 1.4},
	"panah": {"reach": 9.0, "interval": 0.8, "damage": 3.6, "muzzle_speed": 18.0, "lobbed": true, "pierce": 1, "knock": 1.6},
}


## What every cat may start with: a short blade, quick and close.
static func knife() -> Weapon:
	var weapon := Weapon.new()
	weapon.name = "knife"
	weapon.kind = Kind.MELEE
	weapon.reach = 0.45
	weapon.interval = 0.38
	weapon.damage = 2.0
	weapon.knock = 1.8
	weapon.lift = 0.8
	return weapon


## The knife grown up: the cats' heritage blade, its wavy edge longer and harder.
static func keris() -> Weapon:
	var weapon := knife()
	weapon.name = "keris"
	weapon.reach = 0.55
	weapon.damage = 3.2
	weapon.interval = 0.34
	weapon.arc = deg_to_rad(125.0)
	weapon.knock = 2.0
	return weapon


## And the keris's own heir: the curved claw blade, very fast, very close.
static func kerambit() -> Weapon:
	var weapon := knife()
	weapon.name = "kerambit"
	weapon.reach = 0.5
	weapon.damage = 3.0
	weapon.interval = 0.2
	weapon.arc = deg_to_rad(140.0)
	weapon.swing_time = 0.1
	return weapon


## Or a handgun: slow, short, but every round tells.
static func handgun() -> Weapon:
	var weapon := Weapon.new()
	weapon.name = "handgun"
	return weapon


static func submachine_gun() -> Weapon:
	var weapon := Weapon.new()
	weapon.name = "submachine_gun"
	weapon.reach = 7.0
	weapon.interval = 0.12
	weapon.muzzle_speed = 120.0
	weapon.spread = deg_to_rad(3.0)
	weapon.damage = 1.0
	weapon.knock = 1.6
	weapon.lift = 1.2
	return weapon


static func named(weapon_name: String) -> Weapon:
	if ARSENAL.has(weapon_name):
		return _built(weapon_name, ARSENAL[weapon_name])
	match weapon_name:
		"knife": return knife()
		"keris": return keris()
		"kerambit": return kerambit()
		"submachine_gun": return submachine_gun()
	return handgun()


## A weapon from its row in the arsenal: a blade's or a gun's defaults, with the row on top.
## Arcs and spreads are written in degrees.
static func _built(weapon_name: String, row: Dictionary) -> Weapon:
	var weapon := knife() if row.get("melee", false) else Weapon.new()
	weapon.name = weapon_name
	for key: String in row:
		if key == "melee":
			continue
		var value: Variant = row[key]
		if key in ["arc", "spread"]:
			value = deg_to_rad(value)
		weapon.set(key, value)
	weapon.hits_left = weapon.breaks
	return weapon


func swinging() -> bool:
	return swinging_for > 0.0


## What it does in this cat's paw, with his stats and its own levels.
func hit_for(cat: Cat) -> float:
	return damage * (1.0 + power + cat.damage_bonus)


func interval_for(cat: Cat) -> float:
	return interval / (1.0 + tempo + cat.attack_speed_bonus)


func reach_for(cat: Cat) -> float:
	return reach * (1.0 + cat.reach_bonus)


## Fires at what's in reach, from his paw, or from somewhere else that carries it (a drone, a
## turret): from that body, at that height. Returns whether it fired.
func step(delta: float, cat: Cat, arena: Arena, from: Body = null, muzzle_height := Cat.GUN_HEIGHT) -> bool:
	ready_in = maxf(ready_in - delta, 0.0)
	if kind == Kind.MELEE:
		if broken_for > 0.0:
			# Broken: he's sharpening a new one.
			broken_for = maxf(broken_for - delta, 0.0)
			if broken_for <= 0.0:
				hits_left = breaks
			return false
		_swing(delta, cat, arena)
		return false
	var origin := cat.body if from == null else from
	var target := arena.target_for(origin.position, reach_for(cat), cat.aim_mode)
	if target == null or ready_in > 0.0:
		return false
	ready_in += interval_for(cat)
	var toward: Vector2 = (target.body.position - origin.position).normalized()
	var distance := origin.position.distance_to(target.body.position)
	for pellet in pellets:
		_fire(toward.rotated(arena.random.randf_range(-spread, spread)), distance, target, cat, arena, origin, muzzle_height)
	rounds_fired += 1
	return true


func _fire(direction: Vector2, distance: float, target: Object, cat: Cat, arena: Arena, origin: Body, muzzle_height: float) -> void:
	var shot := Shot.new()
	shot.position = origin.position + direction * (origin.radius + 0.05)
	shot.height = origin.height + muzzle_height
	shot.velocity = direction * muzzle_speed
	var time_to_target := maxf(distance / muzzle_speed, 0.001)
	var aim_height: float = target.body.height + target.body.tall * 0.5
	if lobbed:
		# Thrown up enough that gravity brings it down on the target, arriving as it does.
		shot.vertical_speed = (aim_height - shot.height) / time_to_target + 0.5 * Body.GRAVITY * time_to_target
		shot.falls = true
		shot.life = time_to_target * 2.0 + 0.5
	else:
		# Aimed down at the middle of the target: a round fired level would pass over a rat.
		shot.vertical_speed = (aim_height - shot.height) / time_to_target
		shot.life = reach_for(cat) * 1.3 / muzzle_speed
	shot.blast = blast
	shot.pierce_left = pierce
	shot.ricochet_left = ricochet
	aim = direction
	shot.weapon = self
	shot.damage = hit_for(cat)
	shot.shooter = cat
	arena.shots.append(shot)


## A swing starts when something is in reach, centered on it, and sweeps across. Each step, the
## blade's sweep from where it was to where it is now finds what it cut through.
func _swing(delta: float, cat: Cat, arena: Arena) -> void:
	if not swinging():
		var target := arena.target_for(cat.body.position, reach_for(cat) + 0.1, cat.aim_mode)
		if target == null or ready_in > 0.0:
			return
		ready_in = interval_for(cat)
		swinging_for = swing_time
		# Alternate forehand and backhand, as a blade is swung.
		swing_direction = -swing_direction
		swing_start = (target.body.position - cat.body.position).angle() - swing_direction * arc * 0.5
		blade_angle = swing_start
		swings += 1
		_struck.clear()
	var before := blade_angle
	swinging_for = maxf(swinging_for - delta, 0.0)
	var done := 1.0 - swinging_for / swing_time
	blade_angle = swing_start + swing_direction * arc * done
	for creature in arena.cut(cat.body.position, cat.body.height, reach_for(cat), self, before, blade_angle):
		if _struck.has(creature):
			continue
		_struck[creature] = true
		var outward: Vector2 = (creature.body.position - cat.body.position).normalized()
		var along_blade := outward.orthogonal() * swing_direction
		# A hooked blade pulls what it catches in, toward him.
		var pushed := -outward if hooks else (outward + along_blade * 0.6).normalized()
		arena.strike(creature, hit_for(cat), pushed, knock, lift, "blade", cat)
		arena.afflict(creature, self, cat)
		if breaks > 0:
			hits_left -= 1
			if hits_left <= 0:
				broken_for = RESHARPEN_TIME
				swinging_for = 0.0
				arena.events.append({"position": cat.body.position, "height": 0.3, "direction": outward, "killed": false, "by": "snap", "giant": false, "kind": name})
				return
