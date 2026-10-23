class_name Support
extends RefCounted
## What he carries on his back, beside what's in his paws: one drone and one thing he sets
## down. He starts with neither; each comes with its mount on his pack, and works on its own.
##
## The gun drone docks on his pack. When something comes in reach it lifts off, hovers off his
## shoulder and fires down at it, and when it's quiet it settles back. The meriam bambu, the
## bamboo cannon, rides strapped across the pack until something comes in reach; he sets it down
## where he stands and it lobs heavy stones that burst where they land. A bamboo tube only takes
## so many shots before it cracks, so when it does, he cuts a new one. Mines ride in pouches on
## the straps: while enemies are near, he drops one every few seconds, and the first foot on one
## sets it off, a giant's boot included.

## The net drone fires nets that pin down what they land on. The layang-layang, a fighting kite,
## circles him on its string, and the glass-coated string cuts what it crosses. The ranjau bambu
## is a bed of bamboo spikes he sets down that pricks and slows the horde on it, until it's
## trampled flat. The radio, set down and turned up loud, draws the horde to it instead of him
## until its battery's flat.

## The alarm drum, the kentongan, is set down when the horde crowds him and beaten: each beat a
## shove that throws the horde back off him, until the drum splits. The bee swarm lives in a hive on
## his pack and goes out to sting whatever's nearest, slowing it, and comes home when it's quiet.
## The snare, a jerat of rattan, is set down where he stands, and catches the first foot in it:
## a rat held down, a giant held by the boot, unable to walk off.

## Which slot each takes: a drone, or something set down. One of each.
const SLOTS := {
	"gun_drone": "drone", "net_drone": "drone", "layang_layang": "drone",
	"meriam_bambu": "set_down", "mines": "set_down", "ranjau_bambu": "set_down", "radio": "set_down",
	"bee_swarm": "drone", "alarm_drum": "set_down", "snare": "set_down",
}
## The alarm drum: how many of the horde close by before he sets it down, how wide a beat throws
## them, what a beat does, how often it's beaten, how many beats before it splits, and how long a
## new one takes.
const DRUM_CROWD := 5
const DRUM_REACH := 1.6
const DRUM_DAMAGE := 0.6
const DRUM_KNOCK := 3.6
const DRUM_INTERVAL := 0.6
const DRUM_BEATS := 6
const DRUM_REBUILD := 8.0
## The bee swarm: how far out it goes, how fast it flies, how often it stings, what a sting does,
## and how much a sting slows.
const SWARM_REACH := 5.0
const SWARM_SPEED := 4.0
const STING_INTERVAL := 0.3
const STING_DAMAGE := 0.5
const STING_SLOW := 0.3
## The snare: how far he watches before setting it down, how wide its loop, what catching does,
## how long it holds a rat or a giant, and how long a new one takes to tie.
const SNARE_RADIUS := 0.25
const SNARE_DAMAGE := 2.0
const SNARE_HOLD := 2.5
const SNARE_GIANT_HOLD := 2.0
const SNARE_REBUILD := 7.0
## The kite: how far out it flies, how high, how far its string sags in the middle, how fast it
## circles, and what its string does to what it crosses, and how often to each.
const KITE_REACH := 2.2
const KITE_HEIGHT := 0.8
const STRING_SAG := 0.55
const KITE_TURN := 1.6
const STRING_DAMAGE := 1.4
const STRING_INTERVAL := 0.5
## The spike bed: how wide, what each prick does, how long it lasts, and how long a new one takes.
const SPIKES_RADIUS := 0.8
const SPIKES_DAMAGE := 1.0
const SPIKES_LAST := 12.0
const SPIKES_REBUILD := 6.0
## The radio: how many of the horde close by before he sets it down, how long its battery lasts,
## and how long a fresh one takes.
const RADIO_CROWD := 6
const BATTERY := 7.0
const BATTERY_REBUILD := 10.0

## The drone: where it hovers, off his shoulder and up; how fast it flies and turns; and how long
## it waits with nothing in reach before it docks.
const DRONE_HEIGHT := 1.1
const DRONE_OFFSET := Vector2(-0.45, -0.35)
const DRONE_SPEED := 6.0
const DRONE_GRIP := 14.0
const DRONE_LINGER := 1.5
## Docked, it sits on top of his pack.
const DOCKED_HEIGHT := 0.42

## The meriam bambu: the shots a tube takes before it cracks, and how long a new one takes him.
const TUBE_SHOTS := 8
const REBUILD_TIME := 6.0
## Where the stone leaves the tube, above the ground.
const MOUTH_HEIGHT := 0.18

## Mines: one dropped this often while an enemy is this close, no more than so many down at once.
## Each arms a moment after it lands, and goes off when something is this close to it.
const MINE_INTERVAL := 3.5
const MINE_WATCH := 5.0
const MOST_MINES := 4
const ARM_TIME := 0.5
const TRIGGER_REACH := 0.12
const MINE_BLAST := 1.1
const MINE_DAMAGE := 6.0
const MINE_KNOCK := 3.5
const MINE_LIFT := 2.5

var name := ""
var slot := ""
## Its level, from 1, like a weapon's: past the top, mastery.
var level := 1
var power := 0.0
var tempo := 0.0
## What it fires, for the drone and the cannon.
var weapon: Weapon
## Where it is: the drone in the air, the cannon on the ground. Mines are each their own.
var body := Body.new()
## The drone off his pack, or the cannon set down.
var deployed := false
var _idle_for := 0.0
## The cannon: shots left in this tube, and the time until a cracked one is replaced.
var shots_left := TUBE_SHOTS
var rebuilt_in := 0.0
## Tubes that have cracked, counted, so the view and the sound know when one does.
var cracks := 0
## Mines on the ground, as {body, armed_in}, and the time until he can drop the next.
var mines: Array[Dictionary] = []
var _next_mine_in := 0.0
## Mines that have gone off, and been dropped, counted.
var mines_dropped := 0
## The kite's way round him, and when its string can next cut each creature; the spike bed lying
## down; and the radio's battery and the decoy it puts out.
var _turned := 0.0
var _cut_ready := {}
var _bed = null
var _battery := 0.0
var _decoy: Cat
## The drum's beats left and the time to the next; the swarm's sting ready in, and what it's
## after; the snare lying set, as its spot, or none (INF).
var beats_left := 0
var _next_beat_in := 0.0
var beats := 0
var _sting_in := 0.0
var _stinging: Object
var snare_at := Vector2.INF
var catches := 0


static func named(support_name: String) -> Support:
	var support := Support.new()
	support.name = support_name
	support.slot = SLOTS[support_name]
	match support_name:
		"gun_drone":
			var gun := Weapon.new()
			gun.name = "gun_drone"
			gun.reach = 6.5
			gun.interval = 0.55
			gun.damage = 1.2
			gun.muzzle_speed = 90.0
			# Steadier than a mouth: it hovers still to fire.
			gun.spread = deg_to_rad(1.5)
			gun.knock = 1.0
			gun.lift = 0.6
			support.weapon = gun
			support.body.radius = 0.12
			support.body.tall = 0.1
		"net_drone":
			var nets := Weapon.new()
			nets.name = "net_drone"
			nets.reach = 6.0
			nets.interval = 1.8
			nets.damage = 0.3
			nets.muzzle_speed = 12.0
			nets.lobbed = true
			nets.blast = 0.6
			nets.trips = 1.6
			nets.knock = 0.0
			nets.lift = 0.0
			support.weapon = nets
			support.body.radius = 0.12
			support.body.tall = 0.1
		"layang_layang", "bee_swarm":
			support.body.radius = 0.15
			support.body.tall = 0.2
		"meriam_bambu":
			var cannon := Weapon.new()
			cannon.name = "meriam_bambu"
			cannon.reach = 8.0
			cannon.interval = 1.4
			cannon.damage = 5.0
			cannon.muzzle_speed = 9.0
			cannon.spread = deg_to_rad(4.0)
			cannon.lobbed = true
			cannon.blast = 0.7
			cannon.knock = 3.0
			cannon.lift = 2.0
			support.weapon = cannon
			support.body.radius = 0.2
			support.body.tall = 0.25
	return support


## What a hit from it does, with his stats and its own levels: the same rule as a weapon's.
func hit_for(cat: Cat) -> float:
	return _base_damage() * (1.0 + power + cat.damage_bonus)


func _base_damage() -> float:
	match name:
		"mines": return MINE_DAMAGE
		"layang_layang": return STRING_DAMAGE
		"ranjau_bambu": return SPIKES_DAMAGE
		"radio": return 0.0
		"alarm_drum": return DRUM_DAMAGE
		"bee_swarm": return STING_DAMAGE
		"snare": return SNARE_DAMAGE
	return weapon.damage


func step(delta: float, cat: Cat, arena: Arena) -> void:
	if weapon != null:
		# Its levels and his gear count, as for anything he fights with.
		weapon.power = power
		weapon.tempo = tempo
	match name:
		"gun_drone", "net_drone": _fly(delta, cat, arena)
		"layang_layang": _kite(delta, cat, arena)
		"meriam_bambu": _cannon(delta, cat, arena)
		"mines": _mines(delta, cat, arena)
		"ranjau_bambu": _spikes(delta, cat, arena)
		"radio": _radio(delta, cat, arena)
		"alarm_drum": _drum(delta, cat, arena)
		"bee_swarm": _swarm(delta, cat, arena)
		"snare": _snare(delta, cat, arena)


## The drone: off the pack while there's something to shoot, docked when there isn't.
func _fly(delta: float, cat: Cat, arena: Arena) -> void:
	var in_reach := arena.target_for(cat.body.position, weapon.reach_for(cat), cat.aim_mode) != null
	_idle_for = 0.0 if in_reach else _idle_for + delta
	if not deployed:
		body.position = cat.body.position
		body.height = cat.body.height + DOCKED_HEIGHT
		body.velocity = cat.body.velocity
		if in_reach and cat.alive():
			deployed = true
		return
	var docking := _idle_for >= DRONE_LINGER or not cat.alive()
	var goal := cat.body.position if docking else cat.body.position + DRONE_OFFSET
	var goal_height := cat.body.height + (DOCKED_HEIGHT if docking else DRONE_HEIGHT)
	# Thrust toward where it wants to be, capped: it trails him a little, the way a drone does.
	var wanted := (goal - body.position) * 4.0
	body.velocity = body.velocity.move_toward(wanted.limit_length(DRONE_SPEED), DRONE_GRIP * delta)
	body.position += body.velocity * delta
	body.height = move_toward(body.height, goal_height, 2.0 * delta)
	if docking and body.position.distance_to(goal) < 0.08 and absf(body.height - goal_height) < 0.03:
		deployed = false
		return
	if not docking:
		weapon.step(delta, cat, arena, body, 0.0)


## The cannon: set down when something comes in reach, firing until its tube cracks, then a new
## tube for the pack.
func _cannon(delta: float, cat: Cat, arena: Arena) -> void:
	if rebuilt_in > 0.0:
		rebuilt_in = maxf(rebuilt_in - delta, 0.0)
		return
	if not deployed:
		if not cat.alive() or cat.body.airborne():
			return
		if arena.target_for(cat.body.position, weapon.reach_for(cat), cat.aim_mode) == null:
			return
		deployed = true
		shots_left = TUBE_SHOTS
		body.position = cat.body.position
		body.height = 0.0
		body.velocity = Vector2.ZERO
		weapon.ready_in = 0.3
		arena.events.append({"position": body.position, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "set_down", "giant": false, "kind": name})
		return
	if weapon.step(delta, cat, arena, body, MOUTH_HEIGHT):
		shots_left -= 1
		if shots_left <= 0:
			deployed = false
			rebuilt_in = REBUILD_TIME
			cracks += 1
			arena.events.append({"position": body.position, "height": 0.1, "direction": Vector2.ZERO, "killed": false, "by": "crack", "giant": false, "kind": name})


## The kite: up and circling him while anything's near, its string cutting what it crosses; down
## and folded in his pack when it's quiet.
func _kite(delta: float, cat: Cat, arena: Arena) -> void:
	deployed = cat.alive() and arena.target_for(cat.body.position, KITE_REACH + 2.0, "nearest") != null
	if not deployed:
		body.position = cat.body.position
		body.height = cat.body.height + DOCKED_HEIGHT
		return
	_turned += KITE_TURN * (1.0 + tempo + cat.attack_speed_bonus) * delta
	body.position = cat.body.position + Vector2.from_angle(_turned) * KITE_REACH
	body.height = KITE_HEIGHT
	var holder := cat.body.position
	for creature: Creature in arena.creatures.duplicate():
		if _cut_ready.get(creature, 0.0) > arena.time:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(creature.body.position, holder, body.position)
		# The string runs from his paw up to the kite, sagging in the middle: it cuts what reaches
		# up to it where it passes.
		var along := holder.distance_to(closest) / KITE_REACH
		var string_height := string_height_at(along)
		if closest.distance_to(creature.body.position) <= creature.body.radius + 0.05 and creature.body.height + creature.body.tall >= string_height:
			_cut_ready[creature] = arena.time + STRING_INTERVAL
			arena.strike(creature, hit_for(cat), (creature.body.position - holder).normalized().orthogonal(), 1.0, 0.4, "string", cat)


## How high the kite's string is, a share of the way from his paw to the kite.
static func string_height_at(along: float) -> float:
	return maxf(lerpf(0.3, KITE_HEIGHT, along) - STRING_SAG * sin(PI * along), 0.02)


## The spike bed: set down where he stands when the horde closes, pricking what's on it until it's
## trampled flat; then a new one's cut.
func _spikes(delta: float, cat: Cat, arena: Arena) -> void:
	if _bed != null and not _bed in arena.hazards:
		_bed = null
		deployed = false
		rebuilt_in = SPIKES_REBUILD
	if deployed:
		return
	if rebuilt_in > 0.0:
		rebuilt_in = maxf(rebuilt_in - delta, 0.0)
		return
	if not cat.alive() or cat.body.airborne() or arena.target_for(cat.body.position, MINE_WATCH, "nearest") == null:
		return
	deployed = true
	body.position = cat.body.position
	_bed = {"position": body.position, "radius": SPIKES_RADIUS, "damage": hit_for(cat), "left": SPIKES_LAST * (1.0 + tempo), "kind": "spikes", "by": cat, "ready": {}}
	arena.hazards.append(_bed)
	arena.events.append({"position": body.position, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "set_down", "giant": false, "kind": name})


## The radio: set down when the horde crowds him, playing loud enough that it goes for the radio
## instead, until the battery's flat; then a fresh one takes a while.
func _radio(delta: float, cat: Cat, arena: Arena) -> void:
	if deployed:
		_battery -= delta
		if _battery <= 0.0:
			deployed = false
			arena.decoys.erase(_decoy)
			_decoy = null
			rebuilt_in = BATTERY_REBUILD
		return
	if rebuilt_in > 0.0:
		rebuilt_in = maxf(rebuilt_in - delta, 0.0)
		return
	if not cat.alive() or cat.body.airborne():
		return
	var crowd := arena.creatures.filter(func(creature: Creature) -> bool: return creature.body.position.distance_to(cat.body.position) < MINE_WATCH).size()
	if crowd < RADIO_CROWD:
		return
	deployed = true
	body.position = cat.body.position
	_battery = BATTERY * (1.0 + power)
	# What the horde goes for: something where the radio is, that it can't actually bite.
	_decoy = Cat.new()
	_decoy.weapons.clear()
	_decoy.body.position = body.position
	arena.decoys.append(_decoy)
	arena.events.append({"position": body.position, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "set_down", "giant": false, "kind": name})


## Mines: dropped where he stands while enemies are near, armed a moment later, and set off by
## the first foot close enough.
func _mines(delta: float, cat: Cat, arena: Arena) -> void:
	_next_mine_in = maxf(_next_mine_in - delta, 0.0)
	var cadence := MINE_INTERVAL / (1.0 + tempo + cat.attack_speed_bonus)
	if _next_mine_in <= 0.0 and mines.size() < MOST_MINES and cat.alive() and not cat.body.airborne() \
			and arena.target_for(cat.body.position, MINE_WATCH, "nearest") != null:
		var mine := Body.new()
		mine.position = cat.body.position
		mine.radius = 0.06
		mine.tall = 0.04
		mines.append({"body": mine, "armed_in": ARM_TIME})
		mines_dropped += 1
		_next_mine_in = cadence
	var left: Array[Dictionary] = []
	for mine in mines:
		mine.armed_in = maxf(mine.armed_in - delta, 0.0)
		var at: Vector2 = mine.body.position
		if mine.armed_in <= 0.0 and arena.stepped_on(at, TRIGGER_REACH):
			arena.blast(at, MINE_BLAST, hit_for(cat), MINE_KNOCK, MINE_LIFT, "mines", cat)
		else:
			left.append(mine)
	mines = left


## The alarm drum: set down when the horde crowds him, and beaten, each beat throwing what's close
## back off him, until it splits; then a new one takes a while.
func _drum(delta: float, cat: Cat, arena: Arena) -> void:
	if deployed:
		_next_beat_in -= delta
		if _next_beat_in > 0.0:
			return
		_next_beat_in += DRUM_INTERVAL / (1.0 + tempo + cat.attack_speed_bonus)
		beats_left -= 1
		beats += 1
		arena.events.append({"position": body.position, "height": 0.1, "direction": Vector2.ZERO, "killed": false, "by": "beat", "giant": false, "kind": name, "radius": DRUM_REACH})
		for creature in arena.creatures.duplicate():
			var away: Vector2 = creature.body.position - body.position
			if away.length() <= DRUM_REACH:
				arena.strike(creature, hit_for(cat), away.normalized() if away.length_squared() > 0.0001 else Vector2.RIGHT, DRUM_KNOCK, 0.6, "alarm_drum", cat)
		if beats_left <= 0:
			deployed = false
			rebuilt_in = DRUM_REBUILD
			cracks += 1
			arena.events.append({"position": body.position, "height": 0.1, "direction": Vector2.ZERO, "killed": false, "by": "crack", "giant": false, "kind": name})
		return
	if rebuilt_in > 0.0:
		rebuilt_in = maxf(rebuilt_in - delta, 0.0)
		return
	if not cat.alive() or cat.body.airborne():
		return
	var crowd := arena.creatures.filter(func(creature: Creature) -> bool: return creature.body.position.distance_to(cat.body.position) < DRUM_REACH * 1.5).size()
	if crowd < DRUM_CROWD:
		return
	deployed = true
	body.position = cat.body.position
	body.height = 0.0
	beats_left = DRUM_BEATS
	_next_beat_in = 0.2
	arena.events.append({"position": body.position, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "set_down", "giant": false, "kind": name})


## The bee swarm: out of its hive on his pack after whatever's nearest, stinging it and slowing it,
## on to the next when it's down, and home when there's nothing left in reach.
func _swarm(delta: float, cat: Cat, arena: Arena) -> void:
	_sting_in = maxf(_sting_in - delta, 0.0)
	var gone: bool = _stinging == null or not _stinging.alive() or not (_stinging in arena.creatures or _stinging in arena.giants or _stinging in arena.machines or _stinging in arena.structures)
	if gone or _stinging.body.position.distance_to(cat.body.position) > SWARM_REACH:
		_stinging = arena.target_for(cat.body.position, SWARM_REACH, "nearest") if cat.alive() else null
	var home := cat.body.position
	if not deployed:
		# Out of the hive on his pack: that's where it sets off from.
		body.position = home
		body.height = cat.body.height + DOCKED_HEIGHT
	var goal := home if _stinging == null else (_stinging.body.position as Vector2)
	deployed = _stinging != null or body.position.distance_to(home) > 0.1
	if not deployed:
		body.position = home
		body.height = cat.body.height + DOCKED_HEIGHT
		return
	var toward := goal - body.position
	body.position += toward.limit_length(SWARM_SPEED * delta)
	body.height = move_toward(body.height, 0.35 if _stinging != null else cat.body.height + DOCKED_HEIGHT, 2.0 * delta)
	if _stinging != null and toward.length() < 0.3 and _sting_in <= 0.0:
		_sting_in = STING_INTERVAL / (1.0 + tempo + cat.attack_speed_bonus)
		if _stinging is Creature:
			_stinging.afflictions.slow = {"share": STING_SLOW, "left": 1.0}
		arena.strike(_stinging, hit_for(cat), Vector2.ZERO, 0.0, 0.0, "sting", cat)


## The snare: set down where he stands while something's near, it catches the first foot in its
## loop, a rat's or a giant's, and holds it; then he ties another.
func _snare(delta: float, cat: Cat, arena: Arena) -> void:
	if deployed:
		var caught: Object = null
		for creature in arena.creatures:
			if not creature.body.airborne() and creature.body.position.distance_to(snare_at) <= SNARE_RADIUS + creature.body.radius:
				caught = creature
				break
		if caught == null:
			for giant in arena.giants:
				if giant.standing() and giant.body.position.distance_to(snare_at) <= SNARE_RADIUS + giant.body.radius:
					caught = giant
					break
		if caught == null:
			return
		if caught is Giant:
			caught.snared_for = SNARE_GIANT_HOLD * (1.0 + power)
		else:
			caught.tripped_for = SNARE_HOLD * (1.0 + power)
			caught.body.velocity = Vector2.ZERO
		arena.strike(caught, hit_for(cat), Vector2.ZERO, 0.0, 0.0, "snare", cat)
		arena.events.append({"position": snare_at, "height": 0.05, "direction": Vector2.ZERO, "killed": false, "by": "snared", "giant": caught is Giant, "kind": name})
		catches += 1
		deployed = false
		snare_at = Vector2.INF
		rebuilt_in = SNARE_REBUILD
		return
	if rebuilt_in > 0.0:
		rebuilt_in = maxf(rebuilt_in - delta, 0.0)
		return
	if not cat.alive() or cat.body.airborne() or arena.target_for(cat.body.position, MINE_WATCH, "nearest") == null:
		return
	deployed = true
	snare_at = cat.body.position
	body.position = snare_at
	body.height = 0.0
	arena.events.append({"position": snare_at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "set_down", "giant": false, "kind": name})
