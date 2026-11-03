import { inZone } from '../game/capture'
import { AMMO, BOTS } from '../config'
import { HOWITZER } from '../combat/ballistics'
import { penChance } from '../combat/armor'
import { Spotting } from '../game/spotting'
import type { Tank, WorldRefs } from '../tank/tank'
import { gunHasLos } from './lineOfFire'

const distXZ = (a: Tank, b: Tank) => Math.hypot(a.pos.x - b.pos.x, a.pos.z - b.pos.z)

/** How far a bot looks for targets: the whole map for artillery. */
export function reachOf(me: Tank): number {
	return me.def.gun.howitzer ? HOWITZER.maxRange : BOTS.engageRange
}

/** Effective armour `me` would meet on `t`, from the target's facing relative to us. */
export function facingArmor(me: Tank, t: Tank): number {
	const dx = me.pos.x - t.pos.x
	const dz = me.pos.z - t.pos.z
	const l = Math.hypot(dx, dz) || 1
	const c = (dx * t.fx + dz * t.fz) / l // +1 = we are in front of it
	const a = t.def.armor
	const frontOrRear = c > 0.5 || c < -0.5
	const nominal = c > 0.5 ? (a.front + a.tFront) / 2 : c < -0.5 ? a.rear : a.side
	const angle = Math.acos(Math.min(1, Math.abs(frontOrRear ? c : Math.sqrt(1 - c * c))))
	return nominal / Math.max(0.35, Math.cos(angle))
}

/** The nearest enemy the team can see, or null. */
export function nearestEnemy(w: WorldRefs, me: Tank, time: number): Tank | null {
	let best: Tank | null = null
	let bd = Infinity
	for (const o of w.tanks) {
		if (o.team === me.team || !o.alive || !Spotting.visibleTo(me.team, o, time)) continue
		const d = distXZ(me, o)
		if (d < bd) {
			bd = d
			best = o
		}
	}
	return best
}

/** Distance to the nearest enemy the team can see (∞ when none). */
export function nearestEnemyDist(w: WorldRefs, me: Tank, time: number): number {
	const o = nearestEnemy(w, me, time)
	return o ? distXZ(me, o) : Infinity
}

/** Teammates of `me` within `r` of `o` (the splash would hit them). */
function friendNear(w: WorldRefs, me: Tank, o: Tank, r: number): boolean {
	return w.tanks.some((f) => f !== me && f.alive && f.team === me.team && distXZ(f, o) < r)
}

/** `o` is the one that last hit one of our teammates. */
function shootsAtFriends(w: WorldRefs, me: Tank, o: Tank): boolean {
	return w.tanks.some((f) => f !== me && f.alive && f.team === me.team && f.lastHitBy === o)
}

/**
 * Artillery priorities: a target that has stood still a while (camping, sniping, tracked) is worth far more than a
 * runner — the shell is seconds in the air; thin roofs take the blast.
 */
function artilleryFactor(w: WorldRefs, me: Tank, o: Tank): number {
	const speed = Math.abs(o.speed)
	let k = o.tracked > 0 || o.stillTime > 3 ? 0.25 : speed < 1 ? 0.5 : speed > 4 ? 3 : 1.5
	if (o.def.armor.top <= 15) k *= 0.75
	if (o.def.role === 'spg' || o.def.role === 'td') k *= 0.85
	if (friendNear(w, me, o, (me.def.gun.splash ?? 4) + 4)) k *= 3
	return k
}

/** `o` is in a circle its side is taking. */
const capturing = (w: WorldRefs, o: Tank) => w.zones.some((z) => z.capturing === o.team && inZone(z, o.pos.x, o.pos.z))

/** Lower is better: distance weighted by how much the target matters and how hurtable it is. */
function targetScore(w: WorldRefs, me: Tank, o: Tank, current: Tank | null, d: number): number {
	const howitzer = !!me.def.gun.howitzer
	let score = d
	score *= 0.6 + 0.4 * o.hpFrac // finish the wounded
	if (!howitzer) {
		// prefer what we can actually hurt
		const pen = me.def.gun.pen * (me.ammoCount.apcr > 0 ? AMMO.apcr.penMult : 1)
		score *= 1.6 - penChance(pen, facingArmor(me, o))
	}
	if (o === me.lastHitBy) score *= 0.7 // the one shooting at us
	if (shootsAtFriends(w, me, o)) score *= me.def.role === 'heavy' ? 0.65 : 0.85 // heavies cover the team
	if (o.tracked > 0) score *= 0.8 // a sitting duck
	if (o.def.role === 'spg' && d < 220) score *= 0.7 // artillery within reach: kill it
	if (capturing(w, o)) score *= 0.45 // a hit knocks its capture points off
	if (!howitzer && !gunHasLos(w, me, o)) score *= 2.2 // prefer what we can actually shoot
	if (o === current) score *= 0.8
	if (o.isPlayer) score *= 0.95
	if (howitzer) score *= artilleryFactor(w, me, o)
	return score
}

/** The best visible enemy within reach, or null; `focus` (the target the team was called onto) counts double. */
export function pickTarget(
	w: WorldRefs,
	me: Tank,
	current: Tank | null,
	time: number,
	focus: Tank | null = null,
): Tank | null {
	let best: Tank | null = null
	let bs = Infinity
	const reach = reachOf(me)
	for (const o of w.tanks) {
		if (o.team === me.team || !o.alive || !Spotting.visibleTo(me.team, o, time)) continue
		const d = distXZ(me, o)
		if (d > reach) continue
		const score = targetScore(w, me, o, current, d) * (o === focus ? 0.45 : 1)
		if (score < bs) {
			bs = score
			best = o
		}
	}
	return best
}
