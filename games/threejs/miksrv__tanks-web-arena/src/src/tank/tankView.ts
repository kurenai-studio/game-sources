import * as THREE from 'three'
import type { Nation, TankDef } from '../config'
import { AXIS_X, AXIS_Y } from '../core/math'
import { MergedGeometryBuilder } from '../render/geometryBuilder'
import { C, TankBuilder, camoPainter, hullDims } from './model/builder'
import { buildGun } from './model/gun'
import { buildHull } from './model/hull'
import { addMarkings } from './model/markings'
import { buildCasemate, buildTurret, turretLook } from './model/turret'
import { wheelLayout, type Wheel } from './model/wheels'

const HIT_FLASH = 0.12 // s
const WRECK_COLOR = '#2e2a26'
const GRAVITY = 9.8
const BLOWN_UP = [9, 13] as const // m/s: launch speed of a turret thrown by its ammunition
const BLOWN_OUT = [1.5, 4] as const // m/s sideways
const WHEEL_SEGMENTS = 10

/**
 * Procedural WW2 tank: hull from a side profile, turret or casemate, gun, running gear, nation paint and markings.
 * Scene graph: group (hull, casemate) → turret (yaws; on a casemate only the gun's pivot) → gun (pitches).
 * One material per tank (hit flash, wreck paint).
 */
export class TankView {
	readonly group = new THREE.Group()
	readonly turret = new THREE.Group()
	readonly gun = new THREE.Group()
	/** Muzzle point in the gun frame. */
	readonly muzzleLocal: THREE.Vector3
	readonly hullTop: number
	readonly turretY: number
	private readonly material = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.8, metalness: 0.15 })
	private readonly wheels: THREE.InstancedMesh
	private readonly wheelList: Wheel[]
	private readonly owned: THREE.BufferGeometry[] = []
	private readonly tmpM = new THREE.Matrix4()
	private readonly tmpQ = new THREE.Quaternion()
	private readonly tmpV = new THREE.Vector3()
	private readonly tmpS = new THREE.Vector3()
	private readonly flipQ = new THREE.Quaternion().setFromAxisAngle(AXIS_Y, Math.PI)
	private travelled = 0
	private flashTimer = 0
	private spun = false
	/** Where the turret sits on the hull. */
	private readonly turretHome = new THREE.Vector3()
	/** A turret in the air after the ammunition went up (velocity and spin in the hull frame). */
	private flight: { v: THREE.Vector3; w: THREE.Vector3 } | null = null

	constructor(
		readonly def: TankDef,
		nation: Nation,
		seed: number,
	) {
		const s = def.shape
		const base = C[nation]
		const paint = camoPainter(nation, seed)
		const dims = hullDims(s)
		const layout = wheelLayout(dims)
		this.hullTop = dims.top
		this.turretY = dims.top

		const body = new TankBuilder(paint)
		const turret = new TankBuilder(paint)
		const gun = new TankBuilder(paint)
		buildHull(body, dims, base, layout)
		this.muzzleLocal = buildGun(gun, def, base)
		addMarkings(body, turret, dims, nation)

		// A turret carries the gun round; a casemate is part of the hull and only the gun traverses, about its mount.
		if (s.turret || s.launcher) {
			const mount = buildTurret(turret, s, base)
			this.turret.position.set(s.turret ? (turretLook(s).x ?? 0) : 0, dims.top, s.tZ)
			this.gun.position.set(0, mount.y, mount.z)
			this.turret.add(this.mesh(turret))
		} else {
			const mount = buildCasemate(body, s, dims.top, base)
			this.turret.position.set(0, dims.top, mount.z)
			this.gun.position.set(0, mount.y - dims.top, 0)
		}
		this.turretHome.copy(this.turret.position)
		this.turret.add(this.gun)
		this.gun.add(this.mesh(gun))
		this.group.add(this.mesh(body, true), this.turret)

		this.wheelList = layout.wheels
		this.wheels = this.buildWheels(base)
		this.group.add(this.wheels)
		this.spin(0)
	}

	private mesh(b: TankBuilder, receiveShadow = false): THREE.Mesh {
		const m = new THREE.Mesh(b.build(), this.material)
		m.castShadow = true
		m.receiveShadow = receiveShadow
		this.owned.push(m.geometry)
		return m
	}

	/**
	 * Road wheels, sprockets and idlers as one instanced mesh: a unit wheel with a rubber tyre and a painted hub on its
	 * outer face; each instance is scaled to its radius and width and turned to face its side.
	 */
	private buildWheels(base: THREE.Color): THREE.InstancedMesh {
		const b = new MergedGeometryBuilder()
		const tyre = new THREE.CylinderGeometry(1, 1, 1, WHEEL_SEGMENTS, 1, true).rotateZ(Math.PI / 2)
		const face = new THREE.CircleGeometry(1, WHEEL_SEGMENTS).rotateY(Math.PI / 2)
		const hub = new THREE.CircleGeometry(0.72, WHEEL_SEGMENTS).rotateY(Math.PI / 2)
		b.add(tyre, C.rubber)
		b.add(face, C.rubber, new THREE.Matrix4().makeTranslation(0.5, 0, 0))
		b.add(hub, base, new THREE.Matrix4().makeTranslation(0.52, 0, 0))
		for (const g of [tyre, face, hub]) g.dispose()
		const geo = b.build()
		this.owned.push(geo)
		const wheels = new THREE.InstancedMesh(geo, this.material, this.wheelList.length)
		wheels.castShadow = true
		return wheels
	}

	/** Advance the wheels by `dist` metres. A standing tank costs nothing: the buffer is rewritten only when they turn. */
	spin(dist: number) {
		if (dist === 0 && this.spun) return
		this.spun = true
		this.travelled += dist
		this.wheelList.forEach((w, i) => {
			this.tmpQ.setFromAxisAngle(AXIS_X, this.travelled / w.r)
			if (w.side < 0) this.tmpQ.premultiply(this.flipQ)
			this.tmpM.compose(this.tmpV.set(w.x, w.y, w.z), this.tmpQ, this.tmpS.set(w.w, w.r, w.r))
			this.wheels.setMatrixAt(i, this.tmpM)
		})
		this.wheels.instanceMatrix.needsUpdate = true
	}

	setTurret(yaw: number, pitch: number) {
		this.turret.rotation.y = yaw
		this.gun.rotation.x = -pitch
	}

	/** World muzzle position and forward direction (the gun's world matrix must be current). */
	muzzle(out: THREE.Vector3, dir?: THREE.Vector3) {
		out.copy(this.muzzleLocal).applyMatrix4(this.gun.matrixWorld)
		if (dir) dir.set(0, 0, 1).transformDirection(this.gun.matrixWorld)
		return out
	}

	hitFlash() {
		this.flashTimer = HIT_FLASH
		this.material.emissive.set('#ff9955')
		this.material.emissiveIntensity = 0.6
	}

	update(dt: number) {
		if (this.flight) this.fly(dt)
		if (this.flashTimer <= 0) return
		this.flashTimer -= dt
		if (this.flashTimer <= 0) this.material.emissiveIntensity = 0
	}

	/** Burnt-out wreck: dark paint, turret knocked askew. */
	setWreck(on: boolean) {
		this.material.color.set(on ? WRECK_COLOR : '#ffffff')
		this.flight = null
		if (this.def.shape.turret) {
			this.turret.position.copy(this.turretHome)
			this.turret.rotation.set(0, this.turret.rotation.y, on ? 0.12 : 0)
			this.turret.position.y = this.turretY + (on ? 0.25 : 0)
		}
		if (on) this.gun.rotation.x = 0.25
	}

	/** The ammunition rack went up: the turret flies off, tumbling (a casemate has nothing to throw). */
	blowTurret() {
		if (!this.def.shape.turret) return
		const a = Math.random() * Math.PI * 2
		const out = BLOWN_OUT[0] + Math.random() * (BLOWN_OUT[1] - BLOWN_OUT[0])
		const up = BLOWN_UP[0] + Math.random() * (BLOWN_UP[1] - BLOWN_UP[0])
		const spin = () => (Math.random() - 0.5) * 7
		this.flight = {
			v: new THREE.Vector3(Math.cos(a) * out, up, Math.sin(a) * out),
			w: new THREE.Vector3(spin(), spin(), spin()),
		}
	}

	/** Ballistic tumble until the turret comes down on the hull roof or on the ground beside it. */
	private fly(dt: number) {
		const f = this.flight
		if (!f) return
		const t = this.turret
		const s = this.def.shape
		f.v.y -= GRAVITY * dt
		t.position.addScaledVector(f.v, dt)
		t.rotation.x += f.w.x * dt
		t.rotation.y += f.w.y * dt
		t.rotation.z += f.w.z * dt
		const overHull = Math.abs(t.position.x) < s.hullW / 2 && Math.abs(t.position.z) < s.hullL / 2
		const floor = overHull ? this.hullTop : 0
		if (f.v.y > 0 || t.position.y > floor + s.tH) return
		// Down: settle on its roof or on its ring, whichever way up it landed
		const flipped = Math.cos(t.rotation.x) * Math.cos(t.rotation.z) < 0
		t.rotation.x = (flipped ? Math.PI : 0) + 0.15 * Math.sign(Math.sin(t.rotation.x))
		t.rotation.z = 0.2 * Math.sign(Math.sin(t.rotation.z))
		t.position.y = floor + (flipped ? s.tH : 0)
		this.flight = null
	}

	dispose() {
		for (const g of this.owned) g.dispose()
		this.material.dispose()
		this.wheels.dispose()
	}
}
