import * as THREE from 'three'
import { DRIVE, WORLD_HALF } from '../config'
import { wrapAngle } from '../core/math'
import type { Tank, WorldRefs } from '../tank/tank'
import { routeAcross } from './routes'
import type { Pt } from './types'

const tmpPush = { x: 0, z: 0 }
const tmpGrad = new THREE.Vector2()
const STUCK_TIME = 2.5 // s of no progress before backing out
const REVERSE_TIME = 1.8
const STUCK_EVENTS_TO_REROUTE = 3
/** Half-angle of the cone ahead in which another tank counts as being in the way. */
const TANK_CONE = 0.9
/** Longest a bot gives way to the same traffic before it stops waiting and drives around it instead. */
const YIELD_MAX = 3
const YIELD_COOLDOWN = 2.5
/** s a chosen side for swerving around a building or a rock is kept, so the bot does not dither left–right. */
const SIDE_HOLD = 1.5

interface TankInWay {
	o: Tank
	/** Bearing off our hull heading (positive = toward +yaw). */
	bearing: number
	/** Clear distance between the hulls. */
	gap: number
}

/**
 * Obstacle avoidance and unsticking. Terrain, buildings and rocks are probed ahead and to both sides of the hull;
 * other tanks are handled as traffic: swerve away from the side the tank is on, and give way when two tanks are
 * heading into each other (the player always has right of way, between bots the older one does). A bot that wanted
 * to move but did not backs out (unless something is behind it); repeatedly stuck → the route is redirected through
 * the nearest lane point.
 */
export class Avoidance {
	/** Steering override this frame (0 = none). */
	steer = 0
	/** Throttle cap from traffic this frame (≤ 0 = stop / back off, null = none). */
	private throttleCap: number | null = null
	private stuckTimer = 0
	private stuckEvents = 0
	/** s left of backing out (or pivoting, when something is behind too) after getting stuck. */
	private reverseTimer = 0
	private unstickSteer = 0
	private pivot = false
	private lastPos = { x: 0, z: 0 }
	private side = Math.random() < 0.5 ? 1 : -1
	private sideTimer = 0
	private yieldTimer = 0
	private yieldCooldown = 0

	constructor(private readonly me: Tank) {}

	/** Advance the timers (once per frame, before `update`). */
	tick(dt: number) {
		this.sideTimer -= dt
		this.yieldCooldown -= dt
	}

	/** Returns a new route to splice in when the bot keeps getting stuck, else null. */
	update(w: WorldRefs, dt: number, path: Pt[], wp: number): Pt[] | null {
		this.probe(w)
		this.traffic(w, dt)
		return this.checkStuck(w, dt, path, wp)
	}

	/** Apply the override to the planned inputs: back out while reversing, give way, else swerve. */
	apply(dt: number, cmd: { throttle: number; steer: number }) {
		if (this.reverseTimer > 0) {
			this.reverseTimer -= dt
			cmd.throttle = this.pivot ? 0 : -1
			cmd.steer = this.unstickSteer
			return
		}
		if (cmd.throttle <= 0) return
		if (this.steer) cmd.steer = this.steer
		if (this.throttleCap !== null) cmd.throttle = Math.min(cmd.throttle, this.throttleCap)
		else if (this.steer) cmd.throttle = Math.max(cmd.throttle, 0.4)
	}

	/** Keep swerving to one side around the same obstacle; pick a new side only after it has been clear a while. */
	private pickSide(lClear: boolean, rClear: boolean) {
		if (lClear !== rClear && this.sideTimer <= 0) this.side = lClear ? 1 : -1
		this.sideTimer = SIDE_HOLD
		return this.side
	}

	/** Terrain, buildings and rocks. */
	private probe(w: WorldRefs) {
		const L = this.me.def.shape.hullL
		const hard = (ang: number, len: number) => this.hardAt(w, ang, len)
		const ahead = hard(0, L * 1.5) || hard(0, L * 2.5)
		const left = hard(0.5, L * 1.8)
		const right = hard(-0.5, L * 1.8)
		this.steer = 0
		if (ahead) this.steer = this.pickSide(!hard(1.0, L * 1.6), !hard(-1.0, L * 1.6))
		else if (left && !right) this.steer = -0.6
		else if (right && !left) this.steer = 0.6
	}

	/**
	 * Other tanks ahead: give way to one that is driving at us and has right of way (stop, or back off a little when
	 * already touching), slow down behind one going our way, and swerve around anything else — always away from the
	 * side it is on, so two bots meeting head-on both turn to their own side and pass.
	 */
	private traffic(w: WorldRefs, dt: number) {
		this.throttleCap = null
		const t = this.tankInWay(w)
		if (!t) {
			this.yieldTimer = 0
			return
		}
		const me = this.me
		const o = t.o
		const away = -Math.sign(t.bearing) || this.side
		const close = THREE.MathUtils.clamp(1.4 - t.gap / (me.def.shape.hullL * 1.5), 0.4, 1)
		const swerving = !this.steer // terrain and buildings keep priority over traffic
		if (swerving) this.steer = away * close
		const oMoving = o.alive && Math.abs(o.speed) > 1
		// Where we are relative to its heading (it is coming at us when we are in its own cone ahead, or behind it
		// while it reverses)
		const back = wrapAngle(Math.atan2(me.pos.x - o.pos.x, me.pos.z - o.pos.z) - o.yaw)
		const comingAtUs = oMoving && (o.speed > 0 ? Math.abs(back) < TANK_CONE : Math.abs(back) > Math.PI - TANK_CONE)
		if (comingAtUs && this.givesWayTo(o) && this.yieldCooldown <= 0) {
			this.yieldTimer += dt
			if (this.yieldTimer > YIELD_MAX) {
				this.yieldTimer = 0
				this.yieldCooldown = YIELD_COOLDOWN
			}
			this.throttleCap = t.gap < 1.5 ? -0.5 : 0
			if (t.gap < 1.5) this.steer = -away // reversing: the opposite steer swings the nose the same way
			return
		}
		this.yieldTimer = 0
		const sameWay = oMoving && o.speed > 0 && Math.abs(wrapAngle(o.yaw - me.yaw)) < 0.6
		this.throttleCap = sameWay && o.speed >= me.speed * 0.8 ? 0.35 : 0.55
		if (swerving && sameWay && t.gap > 3) this.steer *= 0.3 // follow it rather than weave around it
	}

	/** Right of way: the player never gives way, so bots give way to it; between bots the older one goes first. */
	private givesWayTo(o: Tank) {
		if (o.isPlayer) return true
		if (this.me.isPlayer) return false
		return o.uid < this.me.uid
	}

	/** The nearest living or wrecked tank in our path ahead, close enough to matter at our speed. */
	private tankInWay(w: WorldRefs): TankInWay | null {
		const me = this.me
		const look = me.def.shape.hullL * 1.5 + Math.max(0, me.speed) * 0.8
		let best: TankInWay | null = null
		for (const o of w.tanks) {
			if (o === me) continue
			const dx = o.pos.x - me.pos.x
			const dz = o.pos.z - me.pos.z
			const gap = Math.hypot(dx, dz) - o.radius - me.radius
			if (gap > look || (best && gap > best.gap)) continue
			const bearing = wrapAngle(Math.atan2(dx, dz) - me.yaw)
			// Touching: anything off the front quarter; further out: only a hull that overlaps our track corridor
			const lateral = Math.abs(Math.sin(bearing)) * Math.hypot(dx, dz)
			const inCorridor = Math.abs(bearing) < TANK_CONE && lateral < o.radius + me.radius + 1.5
			if (!inCorridor && !(gap < 1 && Math.abs(bearing) < 1.4)) continue
			best = { o, bearing, gap }
		}
		return best
	}

	/** Something within `len` metres behind the hull (a tank or a hard obstacle) that backing out would hit. */
	private blockedBehind(w: WorldRefs) {
		const me = this.me
		const len = me.def.shape.hullL * 1.2
		if (this.hardAt(w, Math.PI, len)) return true
		for (const o of w.tanks) {
			if (o === me) continue
			const dx = o.pos.x - me.pos.x
			const dz = o.pos.z - me.pos.z
			const gap = Math.hypot(dx, dz) - o.radius - me.radius
			if (gap < len && Math.abs(wrapAngle(Math.atan2(dx, dz) - me.yaw)) > Math.PI - 1.0) return true
		}
		return false
	}

	/** Whether terrain or buildings block a probe `len` metres out at `ang` off the hull heading. */
	private hardAt(w: WorldRefs, ang: number, len: number): boolean {
		const me = this.me
		const dx = Math.sin(me.yaw + ang)
		const dz = Math.cos(me.yaw + ang)
		const x = me.pos.x + dx * len
		const z = me.pos.z + dz * len
		if (Math.abs(x) > WORLD_HALF - 20 || Math.abs(z) > WORLD_HALF - 20) return true
		if (w.terrain.waterDepth(x, z) > 1.0) return true
		// Slope: both the average rise to the probe and the local gradient there (the physics uses the local one)
		const h0 = w.terrain.height(me.pos.x, me.pos.z)
		const h1 = w.terrain.height(x, z)
		if ((h1 - h0) / len > DRIVE.maxSlope * 0.8) return true
		w.terrain.gradient(x, z, tmpGrad)
		if (tmpGrad.x * dx + tmpGrad.y * dz > DRIVE.maxSlope * 0.85) return true
		const probeR = me.def.shape.hullW * 0.6
		if (w.buildings.collideCircle(x, z, probeR, tmpPush)) return true
		return w.props.rockAt(x, z, probeR)
	}

	/** Stuck detection: wanted to move but did not. */
	private checkStuck(w: WorldRefs, dt: number, path: Pt[], wp: number): Pt[] | null {
		const me = this.me
		const moved = Math.hypot(me.pos.x - this.lastPos.x, me.pos.z - this.lastPos.z)
		if (Math.abs(me.throttle) > 0.3 && moved < 0.3 * dt * 4) this.stuckTimer += dt
		else this.stuckTimer = 0
		this.lastPos.x = me.pos.x
		this.lastPos.z = me.pos.z
		if (this.stuckTimer <= STUCK_TIME || this.reverseTimer > 0) return null
		this.reverseTimer = REVERSE_TIME
		this.stuckTimer = 0
		// Back out with the nose swinging away from whatever is in front (reverse steering is mirrored); with
		// something behind as well, pivot on the spot instead
		const t = this.tankInWay(w)
		const s = t?.bearing ? Math.sign(t.bearing) : -this.side // side the obstacle is on
		this.pivot = this.blockedBehind(w)
		this.unstickSteer = this.pivot ? -s : s
		if (++this.stuckEvents < STUCK_EVENTS_TO_REROUTE) return null
		// Repeatedly stuck: give up on this leg and head for the nearest lane waypoint (never a base centre) instead
		this.stuckEvents = 0
		let best: Pt | null = null
		let bd = Infinity
		for (const lane of w.terrain.lanes) {
			for (let i = 1; i < lane.length - 1; i++) {
				const p = lane[i]
				const d = Math.hypot(p.x - me.pos.x, p.z - me.pos.z)
				if (d > 25 && d < bd) {
					bd = d
					best = p
				}
			}
		}
		if (!best) return null
		return [...routeAcross(w.terrain, { x: me.pos.x, z: me.pos.z }, best), ...path.slice(wp)]
	}
}
