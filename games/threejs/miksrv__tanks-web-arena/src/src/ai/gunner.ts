import { AMMO, BOTS, type AmmoId } from '../config'
import { HOWITZER, flightTime, howitzerSolve, solveElevation } from '../combat/ballistics'
import { penChance } from '../combat/armor'
import type { Shells } from '../combat/shells'
import { wrapAngle } from '../core/math'
import type { Tank, WorldRefs } from '../tank/tank'
import { friendInLine, gunHasLos, losBlocker } from './lineOfFire'
import { facingArmor } from './targeting'
import type { Pt } from './types'

const AIM_ERROR_REROLL = 1.5 // s
const MIN_REACTION = 0.3 // s after a target appears
const ARTY_MIN_RANGE = 60
const ARTY_MAX_MOVING_SPEED = 2.5 // m/s: faster targets are not worth a slow shell
const HOPELESS_PEN_CHANCE = 0.12
/** rad: a long arc magnifies elevation errors, so a howitzer waits until the barrel is right on. */
const ARTY_PITCH_TOLERANCE = 0.006

/** Scouts give their position away for a target this weak: it may die. */
const SCOUT_FINISH_HP = 0.25
/** |cos| of our bearing off the target's heading below which its side (and running gear) faces us. */
const SIDE_ON = 0.75

/** Which side of `t` faces `me` (+1 right, −1 left), or 0 when we see its front or rear. */
function trackSide(me: Tank, t: Tank): number {
	const dx = me.pos.x - t.pos.x
	const dz = me.pos.z - t.pos.z
	const l = Math.hypot(dx, dz) || 1
	if (Math.abs((dx * t.fx + dz * t.fz) / l) > SIDE_ON) return 0
	return dx * t.fz - dz * t.fx > 0 ? 1 : -1
}

/** Why the last gunnery pass did not fire (debugging aid). */
export type HoldFire =
	| 'no-target'
	| 'arty-range'
	| 'moving'
	| 'friend-near'
	| 'reload'
	| 'bloom'
	| 'reaction'
	| 'los-bldg'
	| 'los-terrain'
	| 'friend'
	| 'hopeless'
	| 'stealth'
	| 'turret'
	| 'laying'
	| 'elev'
	| 'fire'

/** Bot gunnery: lead and aim error by skill, shell choice by the armour it faces, and the checks before a shot. */
export class BotGunner {
	why: HoldFire = 'no-target'
	/** s the current target has been hidden from our own gun. */
	noLosTimer = 0
	/** s the gun has been unable to reach the elevation the target needs (the hull is tilted too far). */
	elevTimer = 0
	/** Where the last shot was taken: the spot to come back to after reloading in cover. */
	fireSpot: Pt | null = null
	/** Shots fired this round (the driver reacts to each new one). */
	shots = 0
	/** Scout discipline: shoot only to break a track (or to finish a weak target), otherwise stay hidden. */
	trackHunter = false
	private aimErr = { x: 0, y: 0, z: 0 }
	private aimErrTimer = 0
	private reaction = 0

	constructor(
		private readonly me: Tank,
		private readonly skill: number,
	) {}

	/** Count down the timers (once per frame, before anything reads them). */
	tick(dt: number) {
		this.aimErrTimer -= dt
		this.reaction -= dt
	}

	resetRound() {
		this.fireSpot = null
		this.elevTimer = 0
	}

	update(w: WorldRefs, shells: Shells, target: Tank | null, dt: number) {
		if (!target) {
			this.reaction = Math.max(this.reaction, MIN_REACTION)
			this.why = 'no-target'
			this.noLosTimer = 0
			this.elevTimer = 0
			return
		}
		const me = this.me
		const g = me.def.gun
		const d = Math.hypot(target.pos.x - me.pos.x, target.pos.z - me.pos.z)
		const side = this.trackHunter ? trackSide(me, target) : 0
		this.lay(target, d, side)
		if (this.trackHunter && !(side && target.tracked <= 0) && target.hpFrac > SCOUT_FINISH_HP) {
			this.why = 'stealth'
			return
		}
		if (g.howitzer) {
			const hold = this.artilleryHold(w, target, d)
			if (hold) {
				this.why = hold
				return
			}
		}
		const facing = facingArmor(me, target)
		if (!g.howitzer) this.chooseAmmo(facing)
		const hold = this.readiness() ?? (g.howitzer ? null : this.lineOfFireHold(w, target, d, facing, dt))
		if (hold) {
			this.why = hold
			return
		}
		// The turret must actually be on target
		const want = wrapAngle(Math.atan2(me.aimTarget.x - me.pos.x, me.aimTarget.z - me.pos.z) - me.worldTurretYaw)
		if (Math.abs(want) > 0.03 + 2 / d) {
			this.why = 'turret'
			return
		}
		// …and so must the elevation: a howitzer lobbing with the barrel stuck at its stop lands far off
		const laying = this.elevationHold(d, dt)
		if (laying) {
			this.why = laying
			return
		}
		this.why = 'fire'
		const shot = me.fire()
		if (shot) {
			shells.fire(me, shot)
			this.fireSpot = { x: me.pos.x, z: me.pos.z }
			this.shots++
		}
	}

	/** Gun not yet at the elevation the shot needs, or unable to get there from this slope. */
	private elevationHold(d: number, dt: number): HoldFire | null {
		const me = this.me
		const g = me.def.gun
		const tol = g.howitzer ? ARTY_PITCH_TOLERANCE : 0.004 + 1.5 / d
		if (Math.abs(me.pitchWant - me.gunPitch) <= tol) {
			this.elevTimer = 0
			return null
		}
		if (me.pitchWant >= g.elevMin && me.pitchWant <= g.elevMax) return 'laying'
		this.elevTimer += dt // the driver looks for another spot once this builds up
		return 'elev'
	}

	/** Aim at the target centre with a lead and a skill-scaled error that is re-rolled every 1.5 s. */
	private lay(t: Tank, d: number, trackSide: number) {
		const me = this.me
		const g = me.def.gun
		if (this.aimErrTimer <= 0) {
			this.aimErrTimer = AIM_ERROR_REROLL
			const e = BOTS.aimErrorMax * (1 - this.skill) * (g.howitzer ? 0.4 : 1)
			this.aimErr = {
				x: (Math.random() - 0.5) * 2 * e,
				y: (Math.random() - 0.5) * e,
				z: (Math.random() - 0.5) * 2 * e,
			}
		}
		const v = g.shellSpeed * me.ammoDef.speedMult
		const tf = g.howitzer ? (howitzerSolve(d, 0)?.time ?? 0) : flightTime(d, solveElevation(d, 0, v) ?? 0, v)
		const lead = g.howitzer ? 1 : this.skill * 0.9
		const tx = t.pos.x + t.fx * t.speed * tf * lead
		const tz = t.pos.z + t.fz * t.speed * tf * lead
		// Smart gunners aim at the lower hull / side; greener ones at the middle
		if (trackSide) {
			// The running gear on the side facing us: low, at the outer edge of the hull
			const k = trackSide * t.def.shape.hullW * 0.45
			const y = t.pos.y + t.def.shape.trackH * 0.5
			me.aimTarget.set(tx + t.fz * k + this.aimErr.x, y + this.aimErr.y * 0.3, tz - t.fx * k + this.aimErr.z)
			return
		}
		const aimY = t.pos.y + (this.skill > 0.6 ? t.view.hullTop * 0.7 : t.view.hullTop * 0.9)
		me.aimTarget.set(tx + this.aimErr.x, aimY + this.aimErr.y, tz + this.aimErr.z)
	}

	/**
	 * Artillery: shells take seconds to arrive, so only a target that is still (or immobilised) is worth a round;
	 * and never drop a salvo on a friend standing next to it.
	 */
	private artilleryHold(w: WorldRefs, t: Tank, d: number): HoldFire | null {
		const me = this.me
		if (d > HOWITZER.maxRange * 0.95 || d < ARTY_MIN_RANGE) return 'arty-range'
		if (Math.abs(t.speed) > ARTY_MAX_MOVING_SPEED && t.tracked <= 0) return 'moving'
		const r = (me.def.gun.splash ?? 4) + 4
		const friend = w.tanks.some(
			(f) => f !== me && f.alive && f.team === me.team && Math.hypot(f.pos.x - t.pos.x, f.pos.z - t.pos.z) < r,
		)
		return friend ? 'friend-near' : null
	}

	/** Ammo choice from the plate we are most likely to hit. */
	private chooseAmmo(facing: number) {
		const me = this.me
		const g = me.def.gun
		let want: AmmoId = g.derp ? 'he' : 'ap'
		if (!g.derp) {
			if (facing <= g.pen * AMMO.he.penMult * 0.85)
				want = 'he' // thin plate: HE goes through and hits 45 % harder
			else if (penChance(g.pen, facing) < 0.35 && me.ammoCount.apcr > 0) want = 'apcr'
		}
		if (want !== me.ammo && me.reload <= 0.1) me.setAmmo(want)
	}

	/** Loaded, settled and past the reaction delay? */
	private readiness(): HoldFire | null {
		const me = this.me
		const g = me.def.gun
		if (me.reload > 0) {
			this.reaction =
				(BOTS.reactionMin + Math.random() * (BOTS.reactionMax - BOTS.reactionMin)) * (1.3 - this.skill)
			return 'reload'
		}
		// Aimed fire: the better the gunner, the further it lets the reticle settle (artillery a little further still)
		if (me.bloom > (BOTS.aimBloomMax - BOTS.aimBloomSkill * this.skill) * (g.howitzer ? 0.85 : 1)) return 'bloom'
		if (this.reaction > 0) return 'reaction'
		return null
	}

	/** Direct fire: our muzzle to the target through buildings or terrain = no shot; no friends in the line. */
	private lineOfFireHold(w: WorldRefs, t: Tank, d: number, facing: number, dt: number): HoldFire | null {
		const me = this.me
		const clear = gunHasLos(w, me, t)
		this.noLosTimer = clear ? 0 : this.noLosTimer + dt
		if (!clear) return losBlocker(w, me, t)
		if (friendInLine(w, me, t, d)) return 'friend'
		// Wait for a better angle
		if (penChance(me.shellPen, facing) < HOPELESS_PEN_CHANCE && !me.ammoDef.he && this.skill > 0.5 && d > 120) {
			return 'hopeless'
		}
		return null
	}
}
