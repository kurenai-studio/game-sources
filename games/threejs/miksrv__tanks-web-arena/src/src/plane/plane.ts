import * as THREE from 'three'
import type { Shells } from '../combat/shells'
import { AMMO, GRAVITY, PLANE, WORLD_HALF, type Nation } from '../config'
import { headingTo, wrapAngle } from '../core/math'
import type { Tank, WorldRefs } from '../tank/tank'
import { PlaneView } from './planeView'

const { clamp } = THREE.MathUtils
const SIGHT_STEP = 0.1 // s per step of the bomb sight's fall prediction
const SIGHT_STEPS = 300
const PROP_SPIN = 60 // rad/s at full throttle

const BOMB_SPEC = {
	pen: PLANE.bomb.pen,
	dmg: PLANE.bomb.dmg,
	caliber: PLANE.bomb.caliber,
	ammo: AMMO.he,
}

/**
 * The player's aircraft: arcade flight toward the mouse direction, a bomb load that restocks in the air, and a bomb
 * sight. Bots never use it; while it flies, the player's tank stands where it was left.
 */
export class Plane {
	readonly view = new PlaneView()
	active = false
	readonly pos = new THREE.Vector3()
	readonly vel = new THREE.Vector3()
	yaw = 0
	pitch = 0
	roll = 0
	speed = 0
	throttle = PLANE.cruise
	bombs = PLANE.bomb.max
	/** s until the plane can be called in again after a crash. */
	cooldown = 0
	/** Where a bomb dropped now would land, or null when it would not land on the map. */
	readonly sight = new THREE.Vector3()
	sightOk = false
	/** m above the ground right below the plane. */
	altitude = 0

	// Controls, written by the player controller every frame
	aimYaw = 0
	aimPitch = 0
	throttleAxis = 0

	private rearm = 0
	private dropWait = 0
	private spin = 0
	private readonly prev = new THREE.Vector3()
	private readonly p = new THREE.Vector3()
	private readonly v = new THREE.Vector3()
	private readonly at = new THREE.Vector3()

	/** Called in: appears above the tank, flying along `heading`. */
	launch(from: Tank, heading: number, nation: Nation) {
		this.active = true
		this.pos.set(from.pos.x, from.pos.y + PLANE.spawnHeight, from.pos.z)
		this.yaw = this.aimYaw = heading
		this.pitch = this.aimPitch = this.roll = 0
		this.throttle = PLANE.cruise
		this.speed = PLANE.minSpeed + PLANE.cruise * (PLANE.maxSpeed - PLANE.minSpeed)
		this.throttleAxis = 0
		this.dropWait = 0
		this.view.show(true, nation)
	}

	/** Back to the tank (the plane leaves the battle). */
	land() {
		this.active = false
		this.sightOk = false
		this.view.show(false, 'ussr')
	}

	/** A new round: the plane is on the ground with full bays. */
	reset() {
		this.land()
		this.cooldown = 0
		this.bombs = PLANE.bomb.max
		this.rearm = 0
	}

	/** One flight step. Returns true when the plane has just crashed (into the ground, water, a house or a tree). */
	update(dt: number, w: WorldRefs): boolean {
		this.cooldown = Math.max(0, this.cooldown - dt)
		if (!this.active) return false
		this.steer(dt)
		this.prev.copy(this.pos)
		this.pos.addScaledVector(this.vel, dt)
		this.restock(dt)
		if (this.collides(w)) {
			this.land()
			this.cooldown = PLANE.cooldown
			return true
		}
		this.altitude = this.pos.y - w.terrain.height(this.pos.x, this.pos.z)
		this.updateSight(w)
		this.spin = (this.spin + PROP_SPIN * (0.4 + this.throttle * 0.6) * dt) % (Math.PI * 2)
		this.view.place(this.pos, this.yaw, this.pitch, this.roll, this.spin)
		this.view.sight(this.sightOk ? this.sight : null, PLANE.bomb.splash, w.terrain)
		return false
	}

	/** Heading and pitch follow the mouse direction at limited rates; the speed follows the throttle and the climb. */
	private steer(dt: number) {
		this.throttle = clamp(this.throttle + this.throttleAxis * PLANE.throttleRate * dt, 0, 1)
		// Past the edge of the map the plane turns back toward the centre whatever the mouse says
		const outside = Math.hypot(this.pos.x, this.pos.z) > PLANE.edge
		const wantYaw = outside ? headingTo(-this.pos.x, -this.pos.z) : this.aimYaw
		const dy = wrapAngle(wantYaw - this.yaw)
		this.yaw = wrapAngle(this.yaw + clamp(dy, -PLANE.turnRate * dt, PLANE.turnRate * dt))
		let wantPitch = clamp(this.aimPitch, -PLANE.maxDive, PLANE.maxClimb)
		if (this.pos.y > PLANE.ceiling) wantPitch = Math.min(wantPitch, 0)
		this.pitch += clamp(wantPitch - this.pitch, -PLANE.pitchRate * dt, PLANE.pitchRate * dt)
		// Bank into the turn: a left turn (heading growing) drops the left (+x) wing
		const bank = clamp(-dy * 1.5, -PLANE.maxBank, PLANE.maxBank)
		this.roll += (bank - this.roll) * Math.min(1, 3 * dt)
		const target = PLANE.minSpeed + this.throttle * (PLANE.maxSpeed - PLANE.minSpeed)
		this.speed += (target - this.speed) * PLANE.accel * dt - Math.sin(this.pitch) * GRAVITY * PLANE.climbDrag * dt
		this.speed = clamp(this.speed, PLANE.minSpeed * 0.8, PLANE.maxSpeed * 1.3)
		const cp = Math.cos(this.pitch)
		this.vel.set(Math.sin(this.yaw) * cp, Math.sin(this.pitch), Math.cos(this.yaw) * cp).multiplyScalar(this.speed)
	}

	private restock(dt: number) {
		this.dropWait = Math.max(0, this.dropWait - dt)
		if (this.bombs >= PLANE.bomb.max) {
			this.rearm = 0
			return
		}
		this.rearm += dt
		if (this.rearm < PLANE.bomb.rearm) return
		this.rearm -= PLANE.bomb.rearm
		this.bombs++
	}

	private collides(w: WorldRefs): boolean {
		const { x, y, z } = this.pos
		if (y < w.terrain.height(x, z) + w.terrain.waterDepth(x, z) + 1) return true
		const a = this.prev
		if (w.buildings.raySegment(a.x, a.y, a.z, x, y, z) >= 0) return true
		return w.props.blocksSegment(a.x, a.y, a.z, x, y, z)
	}

	/** Free fall from the plane with its velocity until the path meets the ground. */
	private updateSight(w: WorldRefs) {
		const { p, v } = this
		p.copy(this.pos)
		v.copy(this.vel)
		this.sightOk = false
		for (let i = 0; i < SIGHT_STEPS; i++) {
			v.y -= GRAVITY * SIGHT_STEP
			p.addScaledVector(v, SIGHT_STEP)
			if (p.y < w.terrain.height(p.x, p.z)) {
				this.sight.copy(p)
				this.sightOk = Math.max(Math.abs(p.x), Math.abs(p.z)) < WORLD_HALF
				return
			}
		}
	}

	/** Releases a bomb (owned by the player's tank, which gets the credit). False while the bays are empty. */
	drop(owner: Tank, shells: Shells): boolean {
		if (!this.active || this.dropWait > 0 || this.bombs <= 0) return false
		this.bombs--
		this.dropWait = PLANE.bomb.interval
		this.at.set(this.pos.x, this.pos.y - 1, this.pos.z)
		shells.drop(owner, this.at, this.vel, BOMB_SPEC, PLANE.bomb.splash, PLANE.bomb.life)
		return true
	}

	/** Everything on the ground near the plane is spotted for the team (no line of sight needed from the air). */
	spot(tanks: Tank[], team: 0 | 1, time: number) {
		if (!this.active) return
		for (const t of tanks) {
			if (t.team === team || !t.alive) continue
			if (Math.hypot(t.pos.x - this.pos.x, t.pos.z - this.pos.z) > PLANE.spotRadius) continue
			t.spottedBy[team] = true
			t.lastSeen[team] = time
		}
	}
}
