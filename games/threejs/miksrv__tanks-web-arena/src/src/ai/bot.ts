import * as THREE from 'three'
import { AMMO_LOAD, BOTS } from '../config'
import type { Shells } from '../combat/shells'
import { wrapAngle } from '../core/math'
import { Spotting } from '../game/spotting'
import type { Tank, WorldRefs } from '../tank/tank'
import { Avoidance } from './avoidance'
import { Fighter } from './fight'
import { BotGunner, type HoldFire } from './gunner'
import { gunHasLos } from './lineOfFire'
import { vantage } from './positions'
import { createRoleAi, type Bot, type RoleAi } from './roles'
import { routeAcross } from './routes'
import { driveToSpot, faceToward, friendSpots, occupied, steerTo } from './steering'
import { nearestEnemyDist, pickTarget, reachOf } from './targeting'
import { inZone, type CaptureZone } from '../game/capture'
import { spotInZone, type TeamTactics } from './team'
import type { BotMode, DriveCommand, Pt } from './types'

const { clamp } = THREE.MathUtils
const RETARGET = 1.2 // s between target re-evaluations
const RETARGET_AFTER_HIT = 1.5
const WAYPOINT_RADIUS = 10
const EVADE_TIME = 2.2
/** s the target may stay hidden from a holding bot's gun before it shifts toward it. */
const HOLD_BLIND_SHIFT = 6
/** Share of the load at which a bot topping up at the base goes back to the fight. */
const RESUPPLY_DONE = 0.9
const RESUPPLY_SPOT = 20 // m around the base centre

/**
 * A bot's core: targeting, gunnery, driving, consumables, reacting to hits and the hunt for the last enemy. What a
 * vehicle class does on top of that — where it goes, when it fights, waits or falls back — is its role module
 * (`roles/`: light, medium, heavy, td, spg), asked every frame through `RoleAi`.
 */
export class BotBrain implements Bot {
	readonly skill: number
	mode: BotMode = 'advance'
	target: Tank | null = null
	holdSpot: Pt | null = null
	readonly gunner: BotGunner
	readonly fighter: Fighter
	private readonly role: RoleAi
	private readonly avoidance: Avoidance
	private team: TeamTactics | null = null
	private retarget = 0
	private path: Pt[] = []
	private wp = 0
	private lastHp: number
	/** Game time before which the bot waits at the base (staggered departure). */
	private departAt = 0
	/** s left of backing away from an unseen attacker, hull toward the blow. */
	private evadeTimer = 0
	private evadeFrom: Pt = { x: 0, z: 0 }
	/** Game time at which the pending repair / extinguishing happens. */
	private repairAt: number | null = null
	private extinguishAt: number | null = null
	private medkitAt: number | null = null
	/** This bot's place among the team's hunters (each searches its own sector). */
	private slot = 0
	private slots = 1
	/** Game time until which the player's order holds, and the clock as of the last update. */
	private orderUntil = -Infinity
	private now = 0
	/** The base circle this bot is on its way to take (or taking), until a fight or a retreat takes over. */
	private captureZone: CaptureZone | null = null
	/** Driving back to the base for shells, or taking them on there. */
	private resupplying = false
	/** The circle this bot was last sent to defend (counts while the team keeps it among its defenders). */
	private defendZone: CaptureZone | null = null

	constructor(readonly tank: Tank) {
		this.avoidance = new Avoidance(tank)
		this.skill = BOTS.skillMin + Math.random() * (BOTS.skillMax - BOTS.skillMin)
		this.lastHp = tank.hp
		this.gunner = new BotGunner(tank, this.skill)
		this.fighter = new Fighter(tank, this.gunner)
		this.role = createRoleAi(tank)
	}

	/** Debug: why the last gunnery pass did not fire. */
	get why(): HoldFire {
		return this.gunner.why
	}

	get tactics(): TeamTactics {
		if (!this.team) throw new Error('BotBrain used before plan()')
		return this.team
	}

	get pathDone() {
		return this.wp >= this.path.length
	}

	get hunting() {
		return !!this.team?.lastEnemy
	}

	/** Sent somewhere by the team (to break up a capture, or by the player's order): stays put there. */
	get defending() {
		return !!this.team?.defenders.has(this.tank) || this.now < this.orderUntil
	}

	/** Taking a base or sent to defend one: it fights from there instead of going off after the enemy. */
	get onObjective() {
		return this.captureZone !== null || (this.defendZone !== null && !!this.team?.defenders.has(this.tank))
	}

	/** On an objective and inside its circle: leaving it (for cover, a better spot, a retreat) throws the capture away. */
	get holdingCircle() {
		const z = this.captureZone ?? (this.onObjective ? this.defendZone : null)
		return !!z && inZone(z, this.tank.pos.x, this.tank.pos.z)
	}

	/** Called at round start: the role plans the route from our base. */
	plan(w: WorldRefs, tactics: TeamTactics, slot: number, slots: number, departDelay = 0, time = 0) {
		this.team = tactics
		this.slot = slot
		this.slots = slots
		this.departAt = time + departDelay
		this.target = null
		this.gunner.resetRound()
		this.evadeTimer = 0
		this.fighter.reset()
		this.resupplying = false
		const p = this.role.plan(w, this)
		this.mode = p.mode
		this.setPath(p.path, p.holdSpot)
		this.lastHp = this.tank.hp
	}

	update(dt: number, w: WorldRefs, shells: Shells, time: number) {
		const me = this.tank
		if (!me.alive) return
		this.now = time
		this.retarget -= dt
		this.gunner.tick(dt)
		this.fighter.tick(dt)
		this.avoidance.tick(dt)
		this.updateTarget(w, time)
		this.useConsumables(time)
		const hurt = me.hp < this.lastHp - 1
		this.lastHp = me.hp

		const enemyNear = nearestEnemyDist(w, me, time)
		if (this.mode === 'advance' && this.pathDone) this.mode = this.holdSpot ? 'hold' : 'engage'
		const resupplying = this.resupply(w)
		if (!resupplying) this.role.think(this, { w, dt, time, enemyNear, hurt })
		if (this.mode === 'engage' && !this.target) this.mode = this.pathDone ? 'hold' : 'advance'
		if (!resupplying) this.shiftWhenBlind(w)
		if (this.mode === 'engage' || this.mode === 'retreat' || this.mode === 'relocate') this.captureZone = null
		// Arrived short of the circle (the spot was blocked): give the plan up, the idle clock picks a new one
		const cz = this.captureZone
		if (cz && this.mode === 'hold' && this.pathDone && !inZone(cz, me.pos.x, me.pos.z)) this.captureZone = null
		if (!resupplying) this.updateHunt(w, time)
		if (hurt) this.reactToHit(w, time)

		const cmd = this.drive(w, time)
		this.evade(dt, cmd)
		const reroute = this.avoidance.update(w, dt, this.path, this.wp)
		if (reroute) this.setPath(reroute, this.holdSpot)
		this.avoidance.apply(dt, cmd)
		me.throttle = cmd.throttle
		me.steer = cmd.steer

		this.gunner.update(w, shells, this.target, dt)
	}

	// ---------------------------------------------------------------- moves the roles use

	dist(o: Pt | Tank) {
		const p = 'pos' in o ? o.pos : o
		return Math.hypot(p.x - this.tank.pos.x, p.z - this.tank.pos.z)
	}

	setPath(path: Pt[], holdSpot: Pt | null) {
		this.path = path
		this.wp = 0
		this.holdSpot = holdSpot
	}

	/** Drive to `spot` and stop there; a role's move like this replaces any capture plan. */
	goTo(w: WorldRefs, spot: Pt) {
		this.setPath(routeAcross(w.terrain, { x: this.tank.pos.x, z: this.tank.pos.z }, spot), spot)
		this.mode = 'advance'
		this.captureZone = null
	}

	seek(w: WorldRefs, time: number) {
		const tac = this.tactics
		if (this.capture(w, false)) return
		const prey = tac.lastEnemy ?? tac.freshestSighting(w, time)
		const p = tac.searchPoint(w, prey, this.slot, this.slots, time)
		this.setPath(routeAcross(w.terrain, { x: this.tank.pos.x, z: this.tank.pos.z }, p), null)
		this.mode = 'hunt'
	}

	/**
	 * Take a base: stay in the circle we are in, or drive into it — always with `force`, otherwise by the team's odds
	 * (instead of looking for the enemy). True when that is the plan now.
	 */
	capture(w: WorldRefs, force: boolean): boolean {
		const me = this.tank
		const z = this.tactics.zoneToTake(w, me)
		if (!z) return false
		const here = inZone(z, me.pos.x, me.pos.z)
		if (!here && !force && Math.random() >= this.tactics.captureChance(w)) return false
		const spot = here ? { x: me.pos.x, z: me.pos.z } : spotInZone(w, z)
		this.setPath(here ? [] : routeAcross(w.terrain, { x: me.pos.x, z: me.pos.z }, spot), spot)
		this.mode = here ? 'hold' : 'advance'
		this.captureZone = z
		return true
	}

	/** On the way to a base circle or in it. */
	get capturing() {
		return this.captureZone !== null
	}

	/** Keep a player's order for `hold` seconds from `time` (roles do not move the bot on meanwhile). */
	holdOrder(time: number, hold: number) {
		this.orderUntil = time + hold
	}

	/**
	 * Back to a base to stop its capture: into the circle — alone there, the defenders knock the capture down; with
	 * the capturers in it, they hold it still.
	 */
	defend(w: WorldRefs, z: CaptureZone) {
		this.goTo(w, spotInZone(w, z))
		this.defendZone = z
		if (z.owner === -1) this.captureZone = z // holding a neutral circle is taking it too
	}

	/** The player's order: go to `spot` (ground with a view around it) and hold there for `hold` seconds. */
	order(w: WorldRefs, spot: Pt, time: number, hold: number) {
		const me = this.tank
		const watch = w.terrain.bases[1 - me.team]
		this.goTo(
			w,
			vantage(w, spot, 30, {
				watch: { x: watch.x, y: w.terrain.height(watch.x, watch.z) + 2, z: watch.z },
				avoid: friendSpots(w, me),
			}),
		)
		this.holdOrder(time, hold)
	}

	// ---------------------------------------------------------------- decisions

	/**
	 * Nearly out of shells (and not hunting the last enemy, taking or defending a base, or on the player's order): back
	 * to our base to take on more; once the rack is nearly full again the role plans the battle anew from there. True
	 * while that is what the bot is doing.
	 */
	private resupply(w: WorldRefs): boolean {
		const me = this.tank
		const busy = this.onObjective || this.defending
		if (this.resupplying) {
			// Sent elsewhere on the way (a capture, a base to defend, an order), or the last enemy turned up: that first
			if (busy || (this.hunting && me.ammoShare > 0)) {
				this.resupplying = false
				return false
			}
			if (me.ammoShare < RESUPPLY_DONE) return true
			this.resupplying = false
			const p = this.role.plan(w, this)
			this.mode = p.mode
			this.setPath(p.path, p.holdSpot)
			return false
		}
		if (me.ammoShare >= AMMO_LOAD.lowShare || this.hunting || busy) return false
		this.resupplying = true
		const base = w.terrain.bases[me.team]
		this.goTo(w, w.terrain.findSpot(base.x, base.z, RESUPPLY_SPOT))
		return true
	}

	/** A human-like moment to notice the broken track or the fire before reaching for the kit. */
	private consumableDelay([min, max]: readonly [number, number]) {
		return (min + Math.random() * (max - min)) * (1.3 - this.skill)
	}

	private useConsumables(time: number) {
		const me = this.tank
		if ((me.tracked > 0 || me.engineDamaged > 0) && me.repairKit) {
			this.repairAt ??= time + this.consumableDelay(BOTS.repairDelay)
			if (time >= this.repairAt) me.useRepairKit()
		} else this.repairAt = null
		if (me.burning > 0 && me.extinguisher) {
			this.extinguishAt ??= time + this.consumableDelay(BOTS.extinguishDelay)
			if (time >= this.extinguishAt) me.useExtinguisher()
		} else this.extinguishAt = null
		if (me.crew.any && me.crew.medkit) {
			this.medkitAt ??= time + this.consumableDelay(BOTS.medkitDelay)
			if (time >= this.medkitAt) me.crew.treat()
		} else this.medkitAt = null
	}

	/** Re-pick the target periodically, and at once when it dies or drops out of sight. */
	private updateTarget(w: WorldRefs, time: number) {
		const me = this.tank
		const t = this.target
		const lost = t && (!t.alive || !Spotting.visibleTo(me.team, t, time))
		if (this.retarget > 0 && !lost) return
		const focus = this.tactics.focused(time)
		this.target = this.role.preferTarget?.(this, w, time) ?? pickTarget(w, me, t, time, focus)
		this.retarget = RETARGET
		if (this.target !== t) this.fighter.retarget()
	}

	/**
	 * One enemy left: everyone combs its last known area (or its half of the map), each bot on its own sector; roles
	 * also send bots looking (`seek`). A hunter that finds its prey fights it (artillery stops and shoots).
	 */
	private updateHunt(w: WorldRefs, time: number) {
		const me = this.tank
		if (this.mode === 'hunt' && this.target) {
			if (me.def.gun.howitzer) {
				this.holdSpot = { x: me.pos.x, z: me.pos.z }
				this.mode = 'hold'
			} else this.mode = 'engage'
			return
		}
		// Taking a base wins the battle as surely as finding the last enemy: a capturer keeps at it
		if (this.target || this.mode === 'relocate' || this.captureZone) return
		if ((this.hunting && this.mode !== 'hunt') || (this.mode === 'hunt' && this.pathDone)) this.seek(w, time)
	}

	/** Holding a spot, target known but hidden from our gun for a while: shift toward it, onto ground that sees it. */
	private shiftWhenBlind(w: WorldRefs) {
		const me = this.tank
		const t = this.target
		if (this.mode !== 'hold' || !t || !this.holdSpot || me.def.gun.howitzer || this.holdingCircle) return
		if (this.fighter.blind <= HOLD_BLIND_SHIFT) return
		const dx = t.pos.x - me.pos.x
		const dz = t.pos.z - me.pos.z
		const l = Math.hypot(dx, dz) || 1
		const around = { x: me.pos.x + (dx / l) * 25, z: me.pos.z + (dz / l) * 25 }
		this.holdSpot = vantage(w, around, 20, {
			watch: { x: t.pos.x, y: t.pos.y + 1.5, z: t.pos.z },
			bushes: me.def.role === 'td' || me.def.role === 'light',
			avoid: friendSpots(w, me),
		})
		this.gunner.noLosTimer = this.gunner.elevTimer = 0
	}

	/** An attacker we can see and reach becomes the target; an unseen one makes us back off facing the blow. */
	private reactToHit(w: WorldRefs, time: number) {
		const me = this.tank
		const by = me.lastHitBy
		if (!by?.alive || by.team === me.team) return
		const seen = Spotting.visibleTo(me.team, by, time)
		if (seen && this.dist(by) <= reachOf(me) && this.target !== by && (!this.target || gunHasLos(w, me, by))) {
			this.target = by
			this.retarget = RETARGET_AFTER_HIT
			this.fighter.retarget()
		} else if (!seen && !me.def.gun.howitzer && this.evadeTimer <= 0) {
			if (this.mode === 'retreat' || this.mode === 'relocate') return
			// Backing out of the circle would throw the capture (or its defence) away
			if (this.holdingCircle) return
			this.evadeTimer = EVADE_TIME
			this.evadeFrom = { x: by.pos.x, z: by.pos.z }
		}
	}

	// ---------------------------------------------------------------- driving

	private drive(w: WorldRefs, time: number): DriveCommand {
		const cmd: DriveCommand = { throttle: 0, steer: 0 }
		const waiting = this.mode === 'advance' && time < this.departAt && !this.target // the row ahead clears the base
		if (waiting) return cmd
		if (this.role.drive?.(this, w, cmd)) return cmd
		const m = this.mode
		if (m === 'advance' || m === 'retreat' || m === 'relocate' || m === 'hunt') this.followPath(w, cmd)
		else if (m === 'engage' && this.target) {
			const late = this.tactics.late
			const holdBack = !late && (this.role.aheadBy?.(this, w, true) ?? -Infinity) > 0
			this.fighter.engage(w, cmd, this.target, time, holdBack, late)
		} else if (m === 'hold') this.hold(w, cmd, time)
		return cmd
	}

	private followPath(w: WorldRefs, cmd: DriveCommand) {
		const me = this.tank
		const p = this.path[Math.min(this.wp, this.path.length - 1)]
		if (!p) return
		const d = Math.hypot(p.x - me.pos.x, p.z - me.pos.z)
		if (d < WAYPOINT_RADIUS || (d < WAYPOINT_RADIUS * 2.5 && occupied(w, me, p))) this.wp++
		else steerTo(me, cmd, p, 1)
	}

	private hold(w: WorldRefs, cmd: DriveCommand, time: number) {
		const me = this.tank
		// In a base circle it shoots from where it stands: ducking out of it would give the capture up
		if (this.target && !this.holdingCircle && this.fighter.duck(w, cmd, this.target, time)) return
		if (driveToSpot(w, me, cmd, this.holdSpot, 8, 0.7)) return
		if (!me.def.gun.howitzer && me.def.shape.turret) return
		// Turn the hull so the gun arc covers the target (or the enemy base)
		faceToward(me, cmd, this.target ? this.target.pos : w.terrain.bases[1 - me.team])
	}

	/** Backing away from an unseen attacker, hull toward it (heavies just turn to face it: the armour is the answer). */
	private evade(dt: number, cmd: DriveCommand) {
		if (this.evadeTimer <= 0) return
		const me = this.tank
		this.evadeTimer -= dt
		const want = wrapAngle(Math.atan2(this.evadeFrom.x - me.pos.x, this.evadeFrom.z - me.pos.z) - me.yaw)
		cmd.throttle = me.def.role === 'heavy' ? 0 : -0.8
		cmd.steer = clamp(want * 2, -1, 1) * (me.speed < -0.5 ? -1 : 1)
	}
}
