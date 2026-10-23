class_name Cat
extends RefCounted
## A player's cat: moves freely, dodges, and fires at the nearest enemy on its own. Over a run his
## dodge takes up to three mutations, each changing what it does, not just its numbers.

const SPEED := 2.6
const RADIUS := 0.15
const TALL := 0.45
const MOST_HEALTH := 10.0
## The dodge: a short roll at this speed, hits don't land for part of it, and it takes a charge,
## which comes back over DODGE_COOLDOWN.
const DODGE_SPEED := 6.5
const DODGE_TIME := 0.22
const DODGE_SAFE_TIME := 0.28
const DODGE_COOLDOWN := 0.9
## Dodge mutations: no more than this many in a run.
const MOST_MUTATIONS := 3
## Rolling slash: what a cut does at a roll's full speed, a common card's worth.
const SLASH_DAMAGE := 3.0
## Pounce: as the roll ends, a leap onto the nearest enemy this close, taking this long in the
## air, and what landing does to what's under him.
const POUNCE_REACH := 3.0
const POUNCE_TIME := 0.4
const POUNCE_DAMAGE := 4.0
const POUNCE_RADIUS := 0.4
## Ankle cutter: rolling between a giant's legs cuts this share of his health.
const ANKLE_SHARE := 0.12
## Land on your feet: the free roll after a knock is safe for this long, and longer for more.
const RECOVER_SAFE_TIME := 0.25
const RECOVER_SAFE_GROWTH := 0.1
## More charges: a card's rarity past common makes charges come back this much faster.
const RECHARGE_GROWTH := 0.25
## Long leap: thrown up this fast, so it clears a rat and the chainsaw's sweep at the top; along
## the ground, a share of the roll's speed that grows with each card.
const LEAP_LIFT := 2.9
const LEAP_SPEED := 0.5
const LEAP_GROWTH := 0.15
## Riposte: a hit dodged as it lands strikes back at everything this close.
const RIPOSTE_REACH := 0.9
const RIPOSTE_DAMAGE := 4.0
## Lick your wounds: each roll heals this much, a common card's worth, but no more than so much in
## a minute.
const LICK_HEAL := 0.6
const LICK_MOST := 3.0
const LICK_WINDOW := 60.0
## Caltrops: each roll scatters this many behind him, each lying so long, pricking and slowing the
## first foot on it.
const CALTROPS := 3
const CALTROP_DAMAGE := 1.5
const CALTROP_LAST := 8.0
## Dust cloud: the roll kicks up dust where it starts, this wide, and the horde in it stops to cough
## for this long.
const DUST_RADIUS := 0.9
const DUST_TIME := 0.7
## Scent trail: where he rolls from, his scent lingers this long, and the horde goes to it instead
## of him.
const SCENT_TIME := 1.2
## Slipstream: rolling past a crewmate this close speeds them up by this share, for this long.
const SLIPSTREAM_REACH := 0.8
const SLIPSTREAM_SPEED := 0.3
const SLIPSTREAM_TIME := 2.0
## Chain roll: a kill during a roll gives back this share of a charge, once a roll.
const CHAIN_SHARE := 0.6
## A knock off its feet takes this long to recover from.
const STAGGER_TIME := 0.25
## Where the gun is held, above the ground.
const GUN_HEIGHT := 0.2

var body := Body.new()
## His coat: orange, gray, black or cream. The view draws his fur in it.
var coat := "tompel"
var health := MOST_HEALTH
var max_health := MOST_HEALTH
## Stats, raised by cards and gear. Bonuses are shares added to one: 0.1 is ten percent more.
var armor := 0.0
var regeneration := 0.0
var adrenaline := 0.0
var damage_bonus := 0.0
var attack_speed_bonus := 0.0
var reach_bonus := 0.0
var speed_bonus := 0.0
var luck := 0.0
## The chance a hit lands twice as hard, and how much harder his hits shove.
var critical := 0.0
var knockback_bonus := 0.0
## Offers from level-ups, held until played, oldest first; each is a list of choices.
var offers: Array = []
var rerolls := 2
## Choices banished for the rest of the run, by id.
var banished := {}
## Cards he can't be offered yet, by id: what the village's smith hasn't forged. Empty, anything
## can turn up.
var locked: Array[String] = []
## Where the player is steering, as a direction no longer than 1.
var steering := Vector2.ZERO
## The way he faces and the way his gun points, as unit vectors.
var facing := Vector2.RIGHT
var aim := Vector2.RIGHT
## A cat holds a weapon in his mouth and another in his tail: two one-handed weapons, or one that
## takes both, held in his mouth and braced with his tail. He starts with one, a nunchaku or a
## handgun, and nothing else: armor and accessories are upgrades.
const HOLDS := 2
var weapons: Array[Weapon] = [Weapon.handgun()]
## What he carries on his back, by slot ("drone", "set_down"): one of each at most.
var supports := {}
## How his weapons pick a target: "nearest", "toughest" (the most health left) or "crowd" (the
## thickest cluster).
var aim_mode := "nearest"
## Visible gear, by slot (head, body, neck, eyes, paws, feet, waist), and each piece's level. The
## view draws whatever is named here.
var gear := {}
var gear_levels := {}
var dodging_for := 0.0
var safe_for := 0.0
## Dodges ready, as a stock that refills: one is enough to roll, and More charges holds more.
var dodge_charges := 1.0
var staggered_for := 0.0
## Hits that have landed on him, and dodges, counted, so the view and the sound know when one
## does.
var hits_taken := 0
var dodges := 0
## His dodge mutations, by id, each as its strength: the amounts of every card taken for it added
## up, so a card for one he has strengthens it without taking another. And how many cards each.
var mutations := {}
var mutation_cards := {}
## Mid-pounce: in the air on his way down onto something.
var pouncing := false
var _dodge_direction := Vector2.RIGHT
var _dodge_speed := DODGE_SPEED
## What this roll has cut already, so it cuts each only once, and whether it has struck back.
var _rolled_through := {}
var _riposted := false
var _riposte_due := false
## A knock to roll out of, once he's down, and whether this roll is a leap.
var _knocked := false
var _leaping := false
## A roll just begun, for what happens as it starts; what licking has healed this minute, and how
## long the minute has left; whether this roll's kill gave a charge back; his scents lingering, as
## {decoy, left}; and a crewmate's slipstream speeding him up, by how much and for how long.
var _fresh_roll := false
var _licked := 0.0
var _lick_window := 0.0
var _chained := false
var _scents: Array[Dictionary] = []
var _haste := 0.0
var _hasted_for := 0.0


func _init() -> void:
	body.radius = RADIUS
	body.tall = TALL
	body.restitution = 0.2


## Puts on a set of gear, and takes up the weapons it names, as many as his paws can hold.
func wear(outfit: Dictionary) -> void:
	gear = {}
	for slot: String in outfit:
		if slot != "weapons":
			gear[slot] = outfit[slot]
	weapons.clear()
	var holds_used := 0
	for weapon_name: String in outfit.get("weapons", ["handgun"]):
		var weapon := Weapon.named(weapon_name)
		if holds_used + weapon.hands > HOLDS:
			break
		holds_used += weapon.hands
		weapons.append(weapon)


func alive() -> bool:
	return health > 0.0


## Rolls the way he's steering, or the way he faces if he isn't. Returns false if no charge is
## ready.
func dodge() -> bool:
	if dodge_charges < 1.0 or not alive() or body.airborne():
		return false
	dodge_charges -= 1.0
	_roll(steering.normalized() if steering.length_squared() > 0.01 else facing, DODGE_SAFE_TIME)
	return true


func _roll(direction: Vector2, safe_time: float) -> void:
	_dodge_direction = direction
	dodging_for = DODGE_TIME
	_dodge_speed = DODGE_SPEED
	safe_for = maxf(safe_for, safe_time)
	staggered_for = 0.0
	_rolled_through.clear()
	_riposted = false
	_chained = false
	_fresh_roll = true
	dodges += 1
	_leaping = has("long_leap")
	if _leaping:
		# A real jump: as long in the air as the throw makes it, and the roll lasts until he lands.
		body.push(Vector2.ZERO, LEAP_LIFT)
		dodging_for = 2.0 * LEAP_LIFT / Body.GRAVITY
		_dodge_speed = DODGE_SPEED * (LEAP_SPEED + LEAP_GROWTH * strength("long_leap"))


func has(mutation: String) -> bool:
	return mutations.has(mutation)


## How strong a mutation he has is: 1 for a common card's worth, 0 if he hasn't it.
func strength(mutation: String) -> float:
	return mutations.get(mutation, 0.0)


## The most charges he can hold.
func most_charges() -> int:
	return 1 + mutation_cards.get("more_charges", 0)


## How long a spent charge takes to come back.
func recharge_time() -> float:
	var past_common: float = strength("more_charges") - mutation_cards.get("more_charges", 0)
	return DODGE_COOLDOWN / (1.0 + RECHARGE_GROWTH * past_common)


## Damage from his dodge, at a common card's worth: what his gear adds to his weapons adds to it.
func dodge_damage(base: float, mutation: String) -> float:
	return base * strength(mutation) * (1.0 + damage_bonus)


## Raises a stat by an amount.
func raise(stat: String, amount: float) -> void:
	match stat:
		"health":
			max_health += amount
			health += amount
		"armor": armor += amount
		"regeneration": regeneration += amount
		"adrenaline": adrenaline += amount
		"damage": damage_bonus += amount
		"attack_speed": attack_speed_bonus += amount
		"reach": reach_bonus += amount
		"speed": speed_bonus += amount
		"luck": luck += amount
		"critical": critical += amount
		"knockback": knockback_bonus += amount


func heal(amount: float) -> void:
	if alive() and amount > 0.0 and health < max_health:
		health = minf(health + amount, max_health)


## Plays a choice from the oldest offer held. Returns false if there's no such choice.
func play(index: int) -> bool:
	if offers.is_empty() or index >= (offers[0] as Array).size():
		return false
	var offer: Array = offers.pop_front()
	Upgrades.apply(self, offer[index])
	return true


## Swaps the oldest offer for a fresh one, if a reroll is left.
func reroll(random: RandomNumberGenerator) -> bool:
	if offers.is_empty() or rerolls <= 0:
		return false
	rerolls -= 1
	offers[0] = Upgrades.offer(self, random)
	return true


## Banishes a choice from the oldest offer for the rest of the run, and puts another in its place.
func banish(index: int, random: RandomNumberGenerator) -> bool:
	if offers.is_empty() or index >= (offers[0] as Array).size():
		return false
	var offer: Array = offers[0]
	banished[offer[index].id] = true
	var showing: Array[String] = []
	for choice: Dictionary in offer:
		showing.append(choice.id)
	var replacement := Upgrades.offer(self, random, showing)
	if replacement.is_empty():
		offer.remove_at(index)
	else:
		offer[index] = replacement[0]
	return true


func hurt(damage: float, knock: Vector2) -> bool:
	if not alive():
		return false
	if safe_for > 0.0:
		# Dodged just as it landed: he strikes back, once a roll.
		if has("riposte") and not _riposted:
			_riposte_due = true
		return false
	# Armor takes a flat amount off each hit, but never all of it.
	health = maxf(health - maxf(damage - armor, damage * 0.2), 0.0)
	hits_taken += 1
	# Knocked off his feet only from his feet: a cat already in the air isn't thrown higher.
	if not body.airborne():
		body.push(knock, 0.8)
		_knocked = has("land_on_feet")
	staggered_for = STAGGER_TIME
	return true


func step(delta: float, arena: Arena) -> void:
	var was_dodging := dodging_for > 0.0
	dodging_for = maxf(dodging_for - delta, 0.0)
	# A leap is a roll until he's down.
	if _leaping and body.airborne():
		dodging_for = maxf(dodging_for, delta)
	safe_for = maxf(safe_for - delta, 0.0)
	dodge_charges = minf(dodge_charges + delta / recharge_time(), most_charges())
	staggered_for = maxf(staggered_for - delta, 0.0)
	_lick_window = maxf(_lick_window - delta, 0.0)
	if _lick_window <= 0.0:
		_licked = 0.0
	_hasted_for = maxf(_hasted_for - delta, 0.0)
	_fade_scents(delta, arena)
	if not alive():
		body.slide(delta)
		body.step(delta)
		return
	_mutate(arena, was_dodging)
	if dodging_for > 0.0:
		body.velocity = _dodge_direction * _dodge_speed
	elif body.airborne() or staggered_for > 0.0:
		body.slide(delta)
	else:
		body.velocity = steering.limit_length(1.0) * SPEED * (1.0 + speed_bonus + (_haste if _hasted_for > 0.0 else 0.0))
	heal(regeneration * delta)
	if steering.length_squared() > 0.01:
		facing = steering.normalized()
	body.step(delta)
	var longest := 0.0
	for weapon in weapons:
		longest = maxf(longest, weapon.reach_for(self))
	var target := arena.target_for(body.position, longest, aim_mode)
	if target != null:
		aim = (target.body.position - body.position).normalized()
		# Standing still, he turns to face what he's fighting.
		if steering.length_squared() <= 0.01 and dodging_for <= 0.0:
			facing = aim
	for weapon in weapons:
		weapon.step(delta, self, arena)
	for slot: String in supports:
		(supports[slot] as Support).step(delta, self, arena)


## A crewmate's slipstream: he runs faster for a while.
func hasten(share: float, time: float) -> void:
	_haste = maxf(_haste if _hasted_for > 0.0 else 0.0, share)
	_hasted_for = maxf(_hasted_for, time)


## Whether a crewmate's slipstream is speeding him up.
func hasted() -> bool:
	return _hasted_for > 0.0


## Something he hit is down: in a roll, Chain roll gives a charge back, once a roll.
func killed_one() -> void:
	if has("chain_roll") and dodging_for > 0.0 and not _chained:
		_chained = true
		dodge_charges = minf(dodge_charges + CHAIN_SHARE * strength("chain_roll"), most_charges())


## His scents fade: once one's gone, the horde comes back to him.
func _fade_scents(delta: float, arena: Arena) -> void:
	var lingering: Array[Dictionary] = []
	for scent in _scents:
		scent.left -= delta
		if scent.left > 0.0:
			lingering.append(scent)
		else:
			arena.decoys.erase(scent.decoy)
	_scents = lingering


## As a roll starts: licking his wounds, caltrops scattered behind him, dust kicked up, his scent
## left where he was.
func _start_roll(arena: Arena) -> void:
	_fresh_roll = false
	var from := body.position
	if has("lick_your_wounds") and _licked < LICK_MOST:
		var licked := minf(LICK_HEAL * strength("lick_your_wounds"), LICK_MOST - _licked)
		if _licked <= 0.0:
			_lick_window = LICK_WINDOW
		_licked += licked
		heal(licked)
	if has("caltrops"):
		var across := _dodge_direction.orthogonal()
		for index in CALTROPS:
			var spread := (index - (CALTROPS - 1) / 2.0) * 0.25
			arena.hazards.append({"position": from - _dodge_direction * 0.2 + across * spread, "radius": 0.08, "damage": dodge_damage(CALTROP_DAMAGE, "caltrops"), "left": CALTROP_LAST, "kind": "caltrop", "by": self, "ready": {}})
	if has("dust_cloud"):
		arena.dust(from, DUST_RADIUS, DUST_TIME * strength("dust_cloud"))
	if has("scent_trail"):
		var decoy := Cat.new()
		decoy.weapons.clear()
		decoy.body.position = from
		arena.decoys.append(decoy)
		_scents.append({"decoy": decoy, "left": SCENT_TIME * strength("scent_trail")})


## What his mutations do this step: what a roll does as it starts, cuts and strikes from the roll,
## the slipstream it leaves crewmates, the pounce at its end, the roll out of a knock.
func _mutate(arena: Arena, was_dodging: bool) -> void:
	if _fresh_roll:
		_start_roll(arena)
	if _riposte_due:
		_riposte_due = false
		_riposted = true
		arena.riposte(self, dodge_damage(RIPOSTE_DAMAGE, "riposte"))
	if dodging_for > 0.0:
		if has("rolling_slash"):
			var at_speed := _dodge_speed / DODGE_SPEED
			for creature in arena.rolled_into(self):
				if not _rolled_through.has(creature):
					_rolled_through[creature] = true
					arena.strike(creature, dodge_damage(SLASH_DAMAGE, "rolling_slash") * at_speed, _dodge_direction, 1.2, 0.6, "slash", self)
		if has("slipstream"):
			for crewmate in arena.cats:
				if crewmate != self and crewmate.alive() and not _rolled_through.has(crewmate) \
						and crewmate.body.position.distance_to(body.position) <= SLIPSTREAM_REACH:
					_rolled_through[crewmate] = true
					crewmate.hasten(SLIPSTREAM_SPEED * strength("slipstream"), SLIPSTREAM_TIME)
					arena.events.append({"position": crewmate.body.position, "height": 0.1, "direction": _dodge_direction, "killed": false, "by": "slipstream", "giant": false, "kind": "cat"})
		if has("ankle_cutter"):
			for giant in arena.legs_rolled_between(self):
				if not _rolled_through.has(giant):
					_rolled_through[giant] = true
					arena.strike(giant, giant.most_health * ANKLE_SHARE * strength("ankle_cutter") * (1.0 + damage_bonus), _dodge_direction, 0.0, 0.0, "ankles", self)
	if pouncing and body.height <= 0.0:
		pouncing = false
		body.velocity = Vector2.ZERO
		arena.land_pounce(self, dodge_damage(POUNCE_DAMAGE, "pounce"))
	elif dodging_for <= 0.0 and was_dodging and has("pounce") and not body.airborne():
		var target: Object = arena.target_for(body.position, POUNCE_REACH, aim_mode)
		if target != null:
			# A throw that comes down on it: up for half the time, down for the other half, to where
			# it will be by then, the way a cat leads what he jumps at.
			var toward: Vector2 = target.body.position + target.body.velocity * POUNCE_TIME - body.position
			body.velocity = toward / POUNCE_TIME
			body.vertical_speed = Body.GRAVITY * POUNCE_TIME * 0.5
			facing = toward.normalized() if toward.length_squared() > 0.0001 else facing
			pouncing = true
			arena.events.append({"position": body.position, "height": 0.0, "direction": facing, "killed": false, "by": "leap", "giant": false, "kind": "cat"})
	if _knocked and not body.airborne():
		# Down from the knock, he rolls on the way it threw him, for free.
		_knocked = false
		var thrown := body.velocity.normalized() if body.velocity.length_squared() > 0.01 else -facing
		_roll(thrown, RECOVER_SAFE_TIME + RECOVER_SAFE_GROWTH * strength("land_on_feet"))
