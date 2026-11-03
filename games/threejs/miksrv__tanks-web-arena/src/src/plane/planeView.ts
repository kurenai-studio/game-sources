import * as THREE from 'three'
import type { Nation } from '../config'
import { MergedGeometryBuilder, placeEuler } from '../render/geometryBuilder'
import { cross, star } from '../tank/model/markings'
import type { Terrain } from '../world/terrain'

const COLOR = {
	ussr: new THREE.Color('#4d5a34'),
	germany: new THREE.Color('#5d6457'),
	belly: new THREE.Color('#8fa3ad'),
	glass: new THREE.Color('#2c3640'),
	dark: new THREE.Color('#2a2724'),
	white: new THREE.Color('#e8e8e8'),
	red: new THREE.Color('#c62828'),
}
const RING_N = 48
const BOMB_MESHES = 24

/** A ground-attack monoplane in the Il-2 mould: nose along +z, wings along x, the propeller spins about z. */
function buildCraft(nation: Nation): THREE.BufferGeometry {
	const b = new MergedGeometryBuilder()
	const body = COLOR[nation]
	const part = (g: THREE.BufferGeometry, c: THREE.Color, m: THREE.Matrix4) => {
		b.add(g, c, m)
		g.dispose()
	}
	const along = (x: number, y: number, z: number) => placeEuler(x, y, z, Math.PI / 2, 0, 0)
	part(new THREE.CylinderGeometry(0.62, 0.22, 9.6, 12), body, along(0, 0, 0.2))
	part(new THREE.CylinderGeometry(0.66, 0.64, 1.7, 12), COLOR.dark, along(0, 0, 5.4))
	part(new THREE.ConeGeometry(0.3, 0.6, 10), COLOR.dark, along(0, 0, 6.5))
	part(new THREE.BoxGeometry(0.75, 0.55, 2.2), COLOR.glass, placeEuler(0, 0.62, 1.4, 0, 0, 0))
	part(new THREE.BoxGeometry(14.6, 0.22, 2.4), body, placeEuler(0, -0.3, 1.6, 0, 0, 0))
	part(new THREE.BoxGeometry(14.4, 0.05, 2.3), COLOR.belly, placeEuler(0, -0.43, 1.6, 0, 0, 0))
	part(new THREE.BoxGeometry(4.6, 0.14, 1.3), body, placeEuler(0, 0.15, -4.3, 0, 0, 0))
	part(new THREE.BoxGeometry(0.14, 1.7, 1.4), body, placeEuler(0, 0.9, -4.4, 0, 0, 0))
	// Bombs under the wing roots and the radiator scoop
	for (const side of [1, -1])
		part(new THREE.CylinderGeometry(0.2, 0.2, 1.3, 8), COLOR.dark, along(side * 1.3, -0.6, 1.4))
	part(new THREE.BoxGeometry(0.6, 0.35, 1.4), COLOR.dark, placeEuler(0, -0.65, 2.6, 0, 0, 0))
	// National markings on the fin sides and on top of the wings
	const mark = (m: THREE.Matrix4) => {
		if (nation === 'germany') {
			part(cross(0.45, 0.13), COLOR.white, m)
			part(cross(0.3, 0.07), COLOR.dark, m.clone().multiply(new THREE.Matrix4().makeTranslation(0, 0, 0.01)))
		} else part(star(0.48), COLOR.red, m)
	}
	for (const side of [1, -1]) {
		mark(placeEuler(side * 0.08, 0.95, -4.45, 0, (side * Math.PI) / 2, 0))
		mark(placeEuler(side * 5.3, -0.18, 1.6, -Math.PI / 2, 0, 0))
	}
	return b.build()
}

/** The player's aircraft, the bomb sight ring on the ground and every bomb in flight. */
export class PlaneView {
	/** World-space root: add it to the scene once. */
	readonly group = new THREE.Group()
	/** The aircraft itself (placed and oriented by `place`). */
	readonly craft = new THREE.Group()
	private readonly material = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.7, metalness: 0.2 })
	private readonly bodies: Record<Nation, THREE.Mesh>
	private readonly prop: THREE.Mesh
	private readonly ring: THREE.Line
	private readonly bombs: THREE.Mesh[] = []

	constructor() {
		this.bodies = {
			ussr: new THREE.Mesh(buildCraft('ussr'), this.material),
			germany: new THREE.Mesh(buildCraft('germany'), this.material),
		}
		for (const m of Object.values(this.bodies)) {
			m.castShadow = true
			this.craft.add(m)
		}
		const blades = new THREE.BoxGeometry(0.22, 3.3, 0.06)
		this.prop = new THREE.Mesh(blades, new THREE.MeshStandardMaterial({ color: '#1c1b1a', roughness: 0.6 }))
		this.prop.position.set(0, 0, 6.85)
		this.craft.add(this.prop)
		this.craft.rotation.order = 'YXZ'

		const geo = new THREE.BufferGeometry()
		geo.setAttribute('position', new THREE.BufferAttribute(new Float32Array((RING_N + 1) * 3), 3))
		this.ring = new THREE.Line(
			geo,
			new THREE.LineBasicMaterial({ color: '#f0b040', transparent: true, opacity: 0.95, depthTest: false }),
		)
		this.ring.frustumCulled = false
		this.ring.renderOrder = 20

		const bombGeo = new THREE.CylinderGeometry(0.2, 0.2, 1.3, 8).rotateX(Math.PI / 2)
		const bombMat = new THREE.MeshStandardMaterial({ color: '#2f3326', roughness: 0.6 })
		for (let i = 0; i < BOMB_MESHES; i++) {
			const m = new THREE.Mesh(bombGeo, bombMat)
			m.visible = false
			this.bombs.push(m)
		}
		this.group.add(this.craft, this.ring, ...this.bombs)
		this.show(false, 'ussr')
	}

	show(on: boolean, nation: Nation) {
		this.craft.visible = on
		this.ring.visible = on
		this.bodies.ussr.visible = nation === 'ussr'
		this.bodies.germany.visible = nation === 'germany'
	}

	/** Pose the aircraft; `spin` is the propeller angle. */
	place(pos: THREE.Vector3, yaw: number, pitch: number, roll: number, spin: number) {
		this.craft.position.copy(pos)
		this.craft.rotation.set(-pitch, yaw, roll)
		this.prop.rotation.z = spin
	}

	/** The sight: a ring of the blast radius draped over the ground where a bomb dropped now would land. */
	sight(at: THREE.Vector3 | null, radius: number, terrain: Terrain) {
		this.ring.visible = this.craft.visible && !!at
		if (!at) return
		const arr = (this.ring.geometry.attributes.position as THREE.BufferAttribute).array as Float32Array
		for (let i = 0; i <= RING_N; i++) {
			const a = (i / RING_N) * Math.PI * 2
			const x = at.x + Math.cos(a) * radius
			const z = at.z + Math.sin(a) * radius
			arr[i * 3] = x
			arr[i * 3 + 1] = terrain.height(x, z) + 0.4
			arr[i * 3 + 2] = z
		}
		this.ring.geometry.attributes.position.needsUpdate = true
	}

	/** Bombs in flight, nose along their velocity. */
	drawBombs(list: readonly { x: number; y: number; z: number; vx: number; vy: number; vz: number; bomb: boolean }[]) {
		let k = 0
		for (const s of list) {
			if (!s.bomb || k >= this.bombs.length) continue
			const m = this.bombs[k++]
			m.visible = true
			m.position.set(s.x, s.y, s.z)
			m.lookAt(s.x + s.vx, s.y + s.vy, s.z + s.vz)
		}
		for (; k < this.bombs.length; k++) this.bombs[k].visible = false
	}
}
