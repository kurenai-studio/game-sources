class_name Combat
extends RefCounted
## The fighting rules as pure functions over values. No state lives here.

const K := UnitTypes.Kind

enum Zone { FRONT, SIDE, REAR }

const ZONE_DAMAGE := [1.0, 1.5, 2.2]
const ZONE_MORALE := [1.0, 1.7, 2.5]

const CHARGE_TIME := 2.0
const CHARGE_DAMAGE := 2.5
const CHARGE_SHOCK := 14.0

## Every melee blow is scaled by this; it sets how long a fight lasts.
const MELEE_PACE := 0.42

## Only the first two ranks fight in melee.
const FIGHTING_RANKS := 2

## Morale lost per second simply from being in melee.
const MELEE_STRAIN := 1.0
## Morale lost per soldier lost, as a share of the regiment's full strength.
const LOSS_SHOCK := 65.0
## A spent regiment (stamina 0) strikes at this share of its strength and
## loses morale this many times as fast; a fresh one is at full.
const SPENT_HIT := 0.5
const SPENT_NERVE := 1.5
## Stamina a cavalry charge needs.
const CHARGE_STAMINA := 0.35

## Each veterancy star.
const STAR_BONUS := 0.08


## How much harder `attacker` hits `defender` by type alone.
static func type_mult(attacker: int, defender: int) -> float:
	match attacker:
		K.SWORDS:
			if defender == K.PIKES:
				return 1.5
		K.PIKES:
			if defender == K.CAVALRY or defender == K.GENERAL:
				return 2.5
		K.CAVALRY, K.GENERAL:
			if defender == K.ARCHERS:
				return 1.8
			if defender == K.CANNONS:
				return 2.0
			if defender == K.MUSKETS or defender == K.LINE:
				return 1.8
			if defender == K.RIFLES:
				return 1.3
			if defender == K.PIKES:
				return 0.6
	if defender == K.ARCHERS or UnitTypes.is_shot(defender):
		return 1.2
	if defender == K.CANNONS:
		return 1.5
	return 1.0


## Where `attacker_pos` sits relative to a defender facing `defender_facing`.
static func zone(defender_pos: Vector2, defender_facing: float, attacker_pos: Vector2) -> int:
	var to_attacker := attacker_pos - defender_pos
	if to_attacker.length_squared() < 0.0001:
		return Zone.FRONT
	var angle := absf(angle_difference(defender_facing, to_attacker.angle()))
	if angle < deg_to_rad(60.0):
		return Zone.FRONT
	if angle < deg_to_rad(120.0):
		return Zone.SIDE
	return Zone.REAR


## A charge counts unless pikes take it on their front.
static func charge_lands(defender_kind: int, hit_zone: int) -> bool:
	return not (defender_kind == K.PIKES and hit_zone == Zone.FRONT)


## Soldiers able to strike: the first ranks of the formation.
static func fighting_men(men: int, cols: int) -> int:
	return mini(men, cols * FIGHTING_RANKS)


## Damage per second one regiment deals another in melee.
static func melee_dps(
	attacker_kind: int, attacker_men: int, attacker_cols: int, attacker_atk: float,
	defender_kind: int, defender_def: float, hit_zone: int, charging: bool
) -> float:
	var dps := fighting_men(attacker_men, attacker_cols) * attacker_atk * MELEE_PACE
	dps *= type_mult(attacker_kind, defender_kind)
	dps *= ZONE_DAMAGE[hit_zone]
	if charging and charge_lands(defender_kind, hit_zone):
		dps *= CHARGE_DAMAGE
	return dps * (1.0 - clampf(defender_def, 0.0, 0.9))


static func fatigue_hit(stamina: float) -> float:
	return lerpf(SPENT_HIT, 1.0, clampf(stamina, 0.0, 1.0))


static func fatigue_nerve(stamina: float) -> float:
	return lerpf(SPENT_NERVE, 1.0, clampf(stamina, 0.0, 1.0))


static func fatigue_pace(stamina: float) -> float:
	return lerpf(0.75, 1.0, clampf(stamina, 0.0, 1.0))


## Morale lost when `lost` soldiers die out of a full strength of `men_max`.
static func loss_morale(lost: int, men_max: int) -> float:
	return LOSS_SHOCK * float(lost) / float(maxi(men_max, 1))


## The armour left of `def` once a shot that goes through `pierce` of it
## has struck.
static func pierced(def: float, pierce: float) -> float:
	return def * (1.0 - clampf(pierce, 0.0, 1.0))


## Expected ranged damage of one volley, arrows or shot, before cover.
static func volley_damage(shooters: int, shot: float, accuracy: float, defender_def: float) -> float:
	return shooters * shot * accuracy * (1.0 - clampf(defender_def, 0.0, 0.9))


static func star_mult(stars: int) -> float:
	return 1.0 + STAR_BONUS * stars


## Kills needed for each star.
static func stars_for_kills(kills: int) -> int:
	if kills >= 60:
		return 3
	if kills >= 30:
		return 2
	if kills >= 12:
		return 1
	return 0
