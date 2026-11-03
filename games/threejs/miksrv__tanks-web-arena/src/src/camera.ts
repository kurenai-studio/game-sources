import * as THREE from 'three'
import type { Tank, WorldRefs } from './tank/tank'
import { hitBoxes } from './combat/armor'
import { CAMERA, PLANE } from './config'

export type CamMode = 'chase' | 'sniper' | 'arty' | 'spectate' | 'plane'

/** Wheel pixels per notch (a mouse click is ~100; see `Input`). */
const WHEEL_NOTCH = 90
/** A burst of small wheel deltas ends after this long without wheel input (ms). */
const WHEEL_QUIET_MS = 120
/** After the wheel switched the camera mode, it does not switch again for this long. */
const WHEEL_MODE_LOCK_MS = 350
/** Mouse sensitivity per sniper zoom step. */
const SNIPER_SENSITIVITY = [0.35, 0.18, 0.09]

/**
 * Third-person orbit camera with sniper zoom and the SPG satellite view. The reticle is always the screen centre;
 * `aimPoint` is where that ray meets the world and `aimedTank` is the tank under it (for the armour indicator).
 */
export class CameraRig {
	readonly camera: THREE.PerspectiveCamera
	mode: CamMode = 'chase'
	yaw = 0 // orbit heading (world), forward = (sin, 0, cos)
	pitch = 0.32 // positive = looking down
	distance = CAMERA.distance
	zoomLevel = 0
	aimPoint = new THREE.Vector3()
	aimedTank: Tank | null = null
	artyPoint = new THREE.Vector3()
	sensitivity = 0.0022
	private shake = 0
	private pos = new THREE.Vector3()
	private look = new THREE.Vector3()
	private dir = new THREE.Vector3()
	private smoothPos = new THREE.Vector3()
	private initialized = false
	private wheelAcc = 0
	private wheelAt = 0
	private burstNotched = false
	private wheelLockUntil = 0

	constructor() {
		this.camera = new THREE.PerspectiveCamera(CAMERA.fov, window.innerWidth / window.innerHeight, 0.5, 2500)
	}
	resize(w: number, h: number) {
		this.camera.aspect = w / h
		this.camera.updateProjectionMatrix()
	}
	addShake(a: number) {
		this.shake = Math.min(1.5, this.shake + a)
	}

	/** Mouse input for this frame. */
	turn(dx: number, dy: number, wheel: number, tank: Tank | null) {
		const notches = this.wheelNotches(wheel)
		if (this.mode === 'plane') {
			// The mouse sets the direction the plane flies toward; the wheel moves the camera in and out
			this.yaw -= dx * this.sensitivity
			this.pitch = THREE.MathUtils.clamp(this.pitch + dy * this.sensitivity, -1, 1.3)
			if (wheel) {
				const d = this.distance * (1 + wheel * 0.001)
				this.distance = THREE.MathUtils.clamp(d, PLANE.camera.min, PLANE.camera.max)
			}
			return
		}
		if (this.mode === 'arty') {
			this.dragArtyPoint(dx, dy)
			// Wheel: height; one more notch out at the top returns to the chase view
			if (notches > 0 && this.distance >= CAMERA.artyHeight[1] - 0.5) {
				this.switchByWheel('chase', tank)
				return
			}
			if (wheel) {
				const h = this.distance * (1 + wheel * 0.0012)
				this.distance = THREE.MathUtils.clamp(h, CAMERA.artyHeight[0], CAMERA.artyHeight[1])
			}
			return
		}
		const sens = this.sensitivity * (this.mode === 'sniper' ? SNIPER_SENSITIVITY[this.zoomLevel] : 1)
		const sniper = this.mode === 'sniper'
		this.yaw -= dx * sens
		this.pitch = THREE.MathUtils.clamp(this.pitch + dy * sens, sniper ? -0.3 : -0.15, sniper ? 0.35 : 1.2)
		if (sniper) {
			// Wheel notches step the zoom; one more notch out at the widest returns to the chase view
			if (notches > 0 && this.zoomLevel === 0) this.switchByWheel('chase', tank)
			else if (notches) {
				this.zoomLevel = THREE.MathUtils.clamp(this.zoomLevel - notches, 0, CAMERA.sniperFov.length - 1)
			}
			return
		}
		if (wheel) {
			const d = this.distance * (1 + wheel * 0.001)
			this.distance = THREE.MathUtils.clamp(d, CAMERA.minDistance, CAMERA.maxDistance)
		}
		// A notch in at the closest orbit enters the aiming view: sniper scope, or the satellite view for a howitzer
		if (notches < 0 && this.distance <= CAMERA.minDistance + 0.01) {
			this.switchByWheel(tank?.def.gun.howitzer ? 'arty' : 'sniper', tank)
		}
	}

	/** Satellite view: the mouse drags the aim point across the ground 1:1 (one pixel = one pixel of ground). */
	private dragArtyPoint(dx: number, dy: number) {
		// Screen right is (−cos yaw, sin yaw) for a camera looking along (sin yaw, cos yaw); screen up is forward
		const k = (2 * this.distance * Math.tan((this.camera.fov * Math.PI) / 360)) / window.innerHeight
		this.artyPoint.x += (-dx * Math.cos(this.yaw) - dy * Math.sin(this.yaw)) * k
		this.artyPoint.z += (dx * Math.sin(this.yaw) - dy * Math.cos(this.yaw)) * k
	}

	/**
	 * Whole wheel notches in this frame's delta (call every frame, also with 0). A big delta is a notch at once; small
	 * deltas — a trackpad stream, or a mouse that reports a few pixels per click — add up, and a short burst that ends
	 * below a notch still counts as one once the wheel has been quiet for a moment. Reversing direction drops the
	 * remainder, and for a moment after a wheel-driven mode switch the wheel only scrolls (trackpad momentum must not
	 * flip modes back).
	 */
	private wheelNotches(wheel: number): number {
		const now = performance.now()
		if (!wheel) {
			if (!this.wheelAcc || now - this.wheelAt < WHEEL_QUIET_MS) return 0
			const n = this.burstNotched ? 0 : Math.sign(this.wheelAcc)
			this.wheelAcc = 0
			this.burstNotched = false
			return now < this.wheelLockUntil ? 0 : n
		}
		if (now - this.wheelAt >= WHEEL_QUIET_MS) this.burstNotched = false
		if (Math.sign(wheel) !== Math.sign(this.wheelAcc)) this.wheelAcc = 0
		this.wheelAcc += wheel
		this.wheelAt = now
		if (now < this.wheelLockUntil) {
			this.wheelAcc = 0
			return 0
		}
		const n = Math.trunc(this.wheelAcc / WHEEL_NOTCH)
		this.wheelAcc -= n * WHEEL_NOTCH
		if (n) this.burstNotched = true
		return n
	}

	private switchByWheel(m: CamMode, tank: Tank | null) {
		this.setMode(m, tank)
		this.wheelAcc = 0
		this.wheelLockUntil = performance.now() + WHEEL_MODE_LOCK_MS
	}

	setMode(m: CamMode, tank: Tank | null) {
		if (m === 'arty' && tank) {
			this.artyPoint.copy(tank.aimTarget)
			this.distance = CAMERA.artyHeight[2]
		}
		if (this.mode === 'arty' && m !== 'arty') this.distance = CAMERA.distance
		if (this.mode === 'plane' && m !== 'plane') this.distance = CAMERA.distance
		if (m === 'plane' && this.mode !== 'plane') this.distance = PLANE.camera.distance
		if (m === 'sniper') {
			this.zoomLevel = 0
			this.pitch = THREE.MathUtils.clamp(this.pitch, -0.3, 0.35)
		}
		if (m === 'chase') this.distance = Math.max(this.distance, CAMERA.distance * 0.8)
		this.mode = m
		this.camera.fov = m === 'sniper' ? CAMERA.sniperFov[this.zoomLevel] : m === 'arty' ? 45 : CAMERA.fov
		this.camera.updateProjectionMatrix()
	}

	update(dt: number, target: Tank, w: WorldRefs) {
		if (this.mode === 'sniper') {
			const f = CAMERA.sniperFov[this.zoomLevel]
			if (this.camera.fov !== f) {
				this.camera.fov = f
				this.camera.updateProjectionMatrix()
			}
		}
		this.shake = Math.max(0, this.shake - dt * 3)
		const sx = (Math.random() - 0.5) * this.shake
		const sy = (Math.random() - 0.5) * this.shake
		const t = target
		const hullTop = t.pos.y + t.view.hullTop
		if (this.mode === 'arty') {
			this.artyPoint.y = w.terrain.height(this.artyPoint.x, this.artyPoint.z)
			this.pos.set(
				this.artyPoint.x - Math.sin(this.yaw) * this.distance * 0.2,
				this.artyPoint.y + this.distance,
				this.artyPoint.z - Math.cos(this.yaw) * this.distance * 0.2,
			)
			this.look.copy(this.artyPoint)
			this.camera.position.copy(this.pos)
			this.camera.lookAt(this.look)
			this.aimPoint.copy(this.artyPoint)
			this.aimedTank = this.tankAt(this.artyPoint, w)
			this.camera.updateMatrixWorld()
			return
		}
		const cp = Math.cos(this.pitch)
		const sp = Math.sin(this.pitch)
		this.dir.set(Math.sin(this.yaw) * cp, -sp, Math.cos(this.yaw) * cp)
		if (this.mode === 'sniper') {
			this.pos.set(t.pos.x, hullTop + t.def.shape.tH + 0.2, t.pos.z).addScaledVector(this.dir, 1.5)
		} else {
			// Orbit: pull the camera back along -dir; keep it above the ground
			const anchor = this.look.set(t.pos.x, hullTop + CAMERA.height * 0.35, t.pos.z)
			this.pos.copy(anchor).addScaledVector(this.dir, -this.distance)
			this.pos.y += CAMERA.height * 0.5
			// Buildings: stop short of the first wall between the tank and the camera
			const tb = w.buildings.raySegment(anchor.x, anchor.y, anchor.z, this.pos.x, this.pos.y, this.pos.z)
			if (tb >= 0)
				this.pos
					.sub(anchor)
					.multiplyScalar(Math.max(0.12, tb - 0.04))
					.add(anchor)
			const ground = w.terrain.height(this.pos.x, this.pos.z) + 1.2
			if (this.pos.y < ground) this.pos.y = ground
			if (!this.initialized) {
				this.smoothPos.copy(this.pos)
				this.initialized = true
			}
			this.smoothPos.lerp(this.pos, Math.min(1, 12 * dt))
			this.pos.copy(this.smoothPos)
		}
		this.camera.position.set(this.pos.x + sx * 0.3, this.pos.y + sy * 0.3, this.pos.z)
		this.look.copy(this.camera.position).add(this.dir)
		this.camera.lookAt(this.look)
		this.camera.updateMatrixWorld()
		this.raycastAim(w, t)
	}

	/** Chase view behind the plane, looking where the mouse points (the plane turns to follow it). */
	updatePlane(dt: number, at: THREE.Vector3, w: WorldRefs) {
		this.shake = Math.max(0, this.shake - dt * 3)
		const cp = Math.cos(this.pitch)
		this.dir.set(Math.sin(this.yaw) * cp, -Math.sin(this.pitch), Math.cos(this.yaw) * cp)
		this.pos.copy(at).addScaledVector(this.dir, -this.distance)
		this.pos.y += PLANE.camera.height
		const ground = w.terrain.height(this.pos.x, this.pos.z) + 1.5
		if (this.pos.y < ground) this.pos.y = ground
		const s = this.shake * 0.3
		this.camera.position.set(
			this.pos.x + (Math.random() - 0.5) * s,
			this.pos.y + (Math.random() - 0.5) * s,
			this.pos.z,
		)
		this.look.copy(this.camera.position).add(this.dir)
		this.camera.lookAt(this.look)
		this.camera.updateMatrixWorld()
		this.aimedTank = null
	}

	/** Spectator orbit around another tank (same maths, no aiming). */
	updateSpectate(dt: number, target: Tank, w: WorldRefs) {
		this.update(dt, target, w)
	}

	/** Reticle ray from the camera: first tank box, building or ground along it. */
	private raycastAim(w: WorldRefs, self: Tank) {
		const o = this.camera.position
		const d = this.dir
		const maxD = this.mode === 'sniper' ? 1500 : 900
		let bestT = maxD
		this.aimedTank = null
		const ex = o.x + d.x * maxD
		const ey = o.y + d.y * maxD
		const ez = o.z + d.z * maxD
		for (const t of w.tanks) {
			if (t === self || !t.view.group.visible || !t.nearSegment(o.x, o.z, ex, ez)) continue
			const h = hitBoxes(t, o.x, o.y, o.z, ex, ey, ez)
			if (h && h.t * maxD < bestT) {
				bestT = h.t * maxD
				this.aimedTank = t
			}
		}
		const tb = w.buildings.raySegment(o.x, o.y, o.z, ex, ey, ez)
		if (tb >= 0 && tb * maxD < bestT) {
			bestT = tb * maxD
			this.aimedTank = null
		}
		// Ground: coarse march then refine
		let prev = 0
		for (let s = 2; s < bestT; s += s < 60 ? 2 : 6) {
			const x = o.x + d.x * s
			const y = o.y + d.y * s
			const z = o.z + d.z * s
			if (y < w.terrain.height(x, z)) {
				let lo = prev
				let hi = s
				for (let i = 0; i < 6; i++) {
					const m = (lo + hi) / 2
					if (o.y + d.y * m < w.terrain.height(o.x + d.x * m, o.z + d.z * m)) hi = m
					else lo = m
				}
				bestT = hi
				this.aimedTank = null
				break
			}
			prev = s
		}
		this.aimPoint.set(o.x + d.x * bestT, o.y + d.y * bestT, o.z + d.z * bestT)
	}

	private tankAt(p: THREE.Vector3, w: WorldRefs): Tank | null {
		for (const t of w.tanks) if (t.alive && t.view.group.visible && t.hullBox.contains(p.x, p.z, 1.5)) return t
		return null
	}
}
