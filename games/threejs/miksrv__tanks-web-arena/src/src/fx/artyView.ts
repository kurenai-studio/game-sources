import * as THREE from 'three'
import { HOWITZER, howitzerSolve } from '../combat/ballistics'
import { traceShot } from '../combat/trace'
import type { WorldRefs } from '../tank/tank'
import { reticleClass } from '../combat/armor'
import type { Tank } from '../tank/tank'
import type { CameraRig } from '../camera'
import type { Shells } from '../combat/shells'

const RING_N = 64
const ARC_N = 48
const GUN_N = 32
const MARKERS = 16
/** m: the planned arc counts as blocked when it comes down further than this (or the splash) from the aim point. */
const BLOCK_SLACK = 5
const COLORS = {
	white: new THREE.Color('#f4f1e8'),
	green: new THREE.Color('#7fe07f'),
	yellow: new THREE.Color('#f2d65a'),
	orange: new THREE.Color('#f0b040'),
	red: new THREE.Color('#ff5a5a'),
}
const ARC_COLOR = new THREE.Color('#ffd080')

/**
 * Artillery (satellite) view, WoT-style: the reticle is the dispersion circle drawn on the ground (shells land inside
 * it), coloured by convergence, with a faint ring for its fully converged size and one for the splash; the
 * crosshair takes the colour of the enemy under it. The planned trajectory is drawn as an arc from the muzzle and
 * turns red when a hill or a house is in its way; the player's shells in flight carry a bright marker so the fall of
 * shot is easy to follow.
 */
export class ArtyView {
	readonly group = new THREE.Group()
	/** The planned arc comes down short of the aim point (a hill or a house in the way). */
	blocked = false
	private ring: THREE.Line
	private minRing: THREE.Line // the reticle once fully converged
	private splashRing: THREE.Line
	private cross: THREE.LineSegments
	private arc: THREE.Line
	private ringMat: THREE.LineBasicMaterial
	private crossMat: THREE.LineBasicMaterial
	private arcMat: THREE.LineBasicMaterial
	private markers: THREE.Mesh[] = []
	private gunRing: THREE.Line // where the barrel, as it points right now, would actually drop the shell
	private muzzle = new THREE.Vector3()
	private muzzleDir = new THREE.Vector3()
	private land = new THREE.Vector3()
	private planDir = new THREE.Vector3()

	constructor() {
		const geo = (n: number) => {
			const g = new THREE.BufferGeometry()
			g.setAttribute('position', new THREE.BufferAttribute(new Float32Array(n * 3), 3))
			return g
		}
		const line = <T extends THREE.Line>(l: T): T => {
			l.frustumCulled = false
			l.renderOrder = 20
			return l
		}
		const mat = (color: THREE.ColorRepresentation, opacity: number) =>
			new THREE.LineBasicMaterial({ color, transparent: true, opacity, depthTest: false })
		this.ringMat = mat(COLORS.white, 0.95)
		this.crossMat = mat(COLORS.white, 0.8)
		this.arcMat = mat(ARC_COLOR, 0.45)
		this.ring = line(new THREE.Line(geo(RING_N + 1), this.ringMat))
		this.minRing = line(new THREE.Line(geo(RING_N + 1), mat(COLORS.white, 0.35)))
		this.splashRing = line(new THREE.Line(geo(RING_N + 1), mat('#ff9a40', 0.3)))
		this.cross = line(new THREE.LineSegments(geo(4), this.crossMat))
		this.arc = line(new THREE.Line(geo(ARC_N + 1), this.arcMat))
		this.gunRing = line(new THREE.Line(geo(GUN_N + 1), mat('#ffdc96', 0.95)))
		this.group.add(this.ring, this.minRing, this.splashRing, this.cross, this.arc, this.gunRing)
		const mg = new THREE.SphereGeometry(1, 10, 8)
		const mm = new THREE.MeshBasicMaterial({ color: '#ffb347', depthTest: false, transparent: true, opacity: 0.95 })
		for (let i = 0; i < MARKERS; i++) {
			const m = new THREE.Mesh(mg, mm)
			m.renderOrder = 21
			m.visible = false
			this.markers.push(m)
			this.group.add(m)
		}
		this.group.visible = false
	}

	update(active: boolean, player: Tank, rig: CameraRig, w: WorldRefs, shells: Shells) {
		this.group.visible = active
		if (!active) {
			this.blocked = false
			return
		}
		const terrain = w.terrain
		const aim = rig.aimPoint
		player.view.muzzle(this.muzzle, this.muzzleDir)
		const dx = aim.x - player.pos.x
		const dz = aim.z - player.pos.z
		const d = Math.max(5, Math.hypot(dx, dz))
		const ux = dx / d
		const uz = dz / d
		const sol = howitzerSolve(d, aim.y - this.muzzle.y)
		const inRange = sol !== null
		// Reticle: radius = reticle (m at 100 m) scaled to the range, now and once fully converged; and the splash
		const r = (player.reticle / 100) * d
		this.circle(this.ring, terrain, aim.x, aim.z, r, 0.4)
		this.circle(this.minRing, terrain, aim.x, aim.z, r / (1 + player.bloom), 0.35)
		this.circle(this.splashRing, terrain, aim.x, aim.z, player.def.gun.splash ?? 0, 0.3)
		this.minRing.visible = player.bloom > 0.05
		const cp = this.cross.geometry.attributes.position as THREE.BufferAttribute
		const c = Math.max(1.5, r * 0.35)
		const y = aim.y + 0.4
		cp.setXYZ(0, aim.x - c * uz, y, aim.z + c * ux)
		cp.setXYZ(1, aim.x + c * uz, y, aim.z - c * ux)
		cp.setXYZ(2, aim.x - c * ux, y, aim.z - c * uz)
		cp.setXYZ(3, aim.x + c * ux, y, aim.z + c * uz)
		cp.needsUpdate = true
		const at = rig.aimedTank
		this.ringMat.color.copy(inRange ? COLORS[player.aimClass] : COLORS.red)
		this.crossMat.color.copy(
			!inRange
				? COLORS.red
				: at && at.alive && at.team !== player.team
					? COLORS[reticleClass(player, at)]
					: COLORS.white,
		)
		// Planned trajectory from the muzzle to the aim point; does it get there, or is a hill or a house in the way?
		const mx = aim.x - this.muzzle.x
		const mz = aim.z - this.muzzle.z
		const md = Math.max(5, Math.hypot(mx, mz))
		const plan = howitzerSolve(md, aim.y - this.muzzle.y)
		this.arc.visible = plan !== null
		this.blocked = false
		if (plan) {
			const px = (mx / md) * plan.vx
			const pz = (mz / md) * plan.vx
			const ap = this.arc.geometry.attributes.position as THREE.BufferAttribute
			for (let i = 0; i <= ARC_N; i++) {
				const t = (i / ARC_N) * plan.time
				ap.setXYZ(
					i,
					this.muzzle.x + px * t,
					this.muzzle.y + plan.vy * t - 0.5 * HOWITZER.gravity * t * t,
					this.muzzle.z + pz * t,
				)
			}
			ap.needsUpdate = true
			this.planDir.set(px, plan.vy, pz).normalize()
			traceShot(w, this.muzzle, this.planDir, plan.speed, HOWITZER.gravity, plan.time + 2, player, this.land)
			const miss = Math.hypot(this.land.x - aim.x, this.land.z - aim.z)
			this.blocked = miss > Math.max(BLOCK_SLACK, player.def.gun.splash ?? 0)
		}
		this.arcMat.color.copy(this.blocked ? COLORS.red : ARC_COLOR)
		this.arcMat.opacity = this.blocked ? 0.8 : 0.45
		// Gun marker: the real fall of shot for the barrel's current lay (the turret and the gun lag behind the aim point)
		traceShot(w, this.muzzle, this.muzzleDir, sol?.speed ?? 100, HOWITZER.gravity, 12, player, this.land)
		const gp = this.gunRing.geometry.attributes.position as THREE.BufferAttribute
		const gr = Math.max(2, r * 0.25)
		for (let i = 0; i <= GUN_N; i++) {
			const a = (i / GUN_N) * Math.PI * 2
			const x = this.land.x + Math.cos(a) * gr
			const z = this.land.z + Math.sin(a) * gr
			gp.setXYZ(i, x, terrain.height(x, z) + 0.5, z)
		}
		gp.needsUpdate = true
		// The player's shells in flight: a marker whose size holds steady on screen
		let k = 0
		for (const s of shells.list) {
			if (s.owner !== player || k >= MARKERS) continue
			const m = this.markers[k++]
			m.visible = true
			m.position.set(s.x, s.y, s.z)
			m.scale.setScalar(Math.max(0.6, m.position.distanceTo(rig.camera.position) * 0.0045))
		}
		for (; k < MARKERS; k++) this.markers[k].visible = false
	}

	/** A ring of radius `r` around (x, z) laid on the ground, `lift` m above it. */
	private circle(l: THREE.Line, terrain: WorldRefs['terrain'], x: number, z: number, r: number, lift: number) {
		const p = l.geometry.attributes.position as THREE.BufferAttribute
		for (let i = 0; i <= RING_N; i++) {
			const a = (i / RING_N) * Math.PI * 2
			const px = x + Math.cos(a) * r
			const pz = z + Math.sin(a) * r
			p.setXYZ(i, px, terrain.height(px, pz) + lift, pz)
		}
		p.needsUpdate = true
	}
}
