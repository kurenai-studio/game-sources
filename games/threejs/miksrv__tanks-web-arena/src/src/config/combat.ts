import type { Role } from './types'

// Combat, driving and spotting tunables. Units: metres, seconds, millimetres of armour, hit points.

export const COMBAT = {
	penRng: 0.25, // ±25 % on penetration
	dmgRng: 0.25, // ±25 % on damage
	overmatch: 3, // caliber ≥ 3 × plate thickness: no ricochet, no slope bonus
	heNonPenFactor: 0.5, // HE that fails to penetrate: dmg × 0.5 − armour × 1.1
	trackHitChance: 0.6, // side/low hit on the running gear breaks a track
	trackRepair: 45, // s to put a track back on without a repair kit
	trackAbsorb: 0.5, // hull damage multiplier when the running gear is struck
	engineFireChance: 0.25, // penetrating hit on the engine compartment
	engineHitChance: 0.4, // …otherwise the engine may be damaged: top speed and acceleration × engineSpeed
	engineSpeed: 0.5,
	engineTime: 15, // s, unless repaired
	engineShare: 0.3, // rear share of the hull length over the engine (side hits there reach it)
	fireDps: 25, // hp/s while burning
	fireTime: 8, // s, unless extinguished
	gunDamageChance: 0.15, // penetrating hit on the turret front: dispersion ×1.5 for a while
	mantletGunChance: 0.5, // …through the mantlet itself
	gunDamageTime: 12,
	ringChance: 0.35, // penetrating hit low on the turret: traverse × ringTurn
	ringTurn: 0.4,
	ringTime: 15,
	ringShare: 0.3, // lower share of the turret height around the ring
	ammoRackChance: 0.045, // penetrating side hit on the hull or a turret hit from the side or rear: the rack detonates
	rackDamageChance: 0.18, // …otherwise it may only be damaged: reload ×rackReload for rackDamageTime
	rackReload: 1.35,
	rackDamageTime: 15,
	ramDamageMult: 1.4, // × relative speed × mass ratio (wrecks stay as cover until the round ends)
	shellLife: 6, // s, max flight
	howitzerShellLife: 12, // s, howitzer shells fly longer arcs
	tracerLen: 10, // m
	maxShells: 128,
}

/** Weak and strong spots inside the hull and turret boxes. */
export const ZONES = {
	lowerFront: 0.75, // lower front plate × the front armour (unless the vehicle sets `armor.lowerFront`)
	lowerShare: 0.45, // lower share of the hull box height that is the lower plate
	mantlet: 1.3, // × the turret front
	mantletW: 0.35, // default mantlet width as a share of the turret width
	mantletBand: 0.3, // share of the turret height above and below the trunnions
	cupola: 0.7, // × the turret side
	cupolaR: 0.3, // m, half-size of the cupola box
	cupolaH: 0.3, // m above the roof
	cupolaWound: 0.6, // chance a penetrated cupola wounds the commander
	screen: 8, // mm a Schürzen plate adds against AP
	screenHe: 0.35, // HE damage × when it bursts on the screen
}

/** Rounds carried: enough for `fireTime` seconds of steady fire, within limits; topped up at the team's own base. */
export const AMMO_LOAD = {
	fireTime: 240, // s
	min: 8,
	max: 250,
	apcrShare: 0.2, // of the load, at most AMMO.apcr.count (howitzers carry none)
	altShare: 0.25, // the other common shell (HE for guns, AP for howitzers)
	resupplyRadius: 35, // m around the base centre
	resupplyMaxSpeed: 2, // m/s
	resupplyStep: 0.5, // s between top-ups
	resupplyShare: 0.05, // of each shell type's full load per top-up
	kitTime: 5, // s at the base to get used consumables (repair kit, medkit, extinguisher) back
	lowShare: 0.15, // the player is warned (and bots go back) below this share of the whole load
}

export type CrewRole = 'commander' | 'gunner' | 'driver' | 'loader'
export const CREW_ROLES: CrewRole[] = ['commander', 'gunner', 'driver', 'loader']

/** Crew injuries: a penetrating hit may wound one member in the struck compartment; a medkit (E) treats them all. */
export const CREW = {
	hitChance: 0.3,
	splashChance: 0.12, // HE splash through the roof (× 2.5 on open-topped vehicles)
	openTopSplash: 2.5,
	view: 0.85, // commander wounded: view range ×
	dispersion: 1.25, // gunner: dispersion and aim time ×
	speed: 0.85, // driver: top speed, acceleration and hull traverse ×
	reload: 1.25, // loader: reload ×
	label: {
		commander: 'командир',
		gunner: 'наводчик',
		driver: 'мехвод',
		loader: 'заряжающий',
	} as Record<CrewRole, string>,
}

// Movement feel
export const DRIVE = {
	bloomMove: 0.19, // reticle bloom per m/s of hull speed (fraction of base dispersion)
	bloomTurn: 0.95, // per rad/s of hull turn
	bloomTurret: 0.4, // per rad/s of turret traverse, and of laying the gun for range
	bloomShot: 2.5, // after firing
	aimedBloom: 0.12, // at or under this the reticle counts as converged (green, the "aimed" cue)
	looseBloom: 0.9, // over this it is wide open (red); yellow in between
	slopeSpeed: 0.045, // speed loss per degree of uphill slope (fraction)
	maxSlope: 0.6, // rad; steeper terrain is a wall
	treeKnock: 2.5, // m/s needed to push a tree over; slower than that a trunk just stops the hull
	treeSlow: 0.7, // speed multiplier while flattening trees
}
// Ground speed per surface lives in BIOME_SPEED (src/world/terrain/types.ts).

export const SPOTTING = {
	interval: 0.3, // s between spotting checks
	minRange: 50, // always seen inside this; a tank in a bush is seen only inside this or after its own shot
	bushCamo: 0.35, // concealment bonus standing in a bush
	forestCamo: 0.18,
	movingPenalty: { light: 0, medium: 0.05, heavy: 0.08, td: 0.08, spg: 0.05 } as Record<Role, number>,
	firePenalty: 0.85, // concealment lost for firePenaltyTime after a shot
	firePenaltyTime: 5, // also how long a shot gives away a tank in a bush
	losStep: 6, // m, line-of-sight sampling step over the heightmap
	memory: 2.0, // s a spotted tank stays drawn after it is lost (fades)
}
