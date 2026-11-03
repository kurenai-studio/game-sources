import * as THREE from 'three'
import { AXIS_Y } from '../../core/math'
import type { Terrain, TreeSpecies } from '../terrain'
import { crownColor, crownGeometry, mergePositions, SPECIES } from './species'
import type { Fence, Hay, PropSet, Rock, Tree } from './types'

/** Bush: three blobs merged. */
function bushGeometry(): THREE.BufferGeometry {
	const blob = new THREE.SphereGeometry(1, 6, 5)
	const blobs = [
		[0, 0.7, 0, 1],
		[0.9, 0.5, 0.3, 0.75],
		[-0.7, 0.55, -0.5, 0.7],
	].map(([ox, oy, oz, s]) =>
		blob
			.clone()
			.scale(s, s * 0.8, s)
			.translate(ox, oy, oz),
	)
	return mergePositions(blobs)
}

/** Steel hedgehog: three crossed beams. */
function hedgehogGeometry(): THREE.BufferGeometry {
	const beams = [new THREE.Euler(0, 0, 0.78), new THREE.Euler(0.78, 0, 0), new THREE.Euler(0.78, 1.57, 0)].map((e) =>
		new THREE.BoxGeometry(0.16, 2.6, 0.16).rotateX(e.x).rotateY(e.y).rotateZ(e.z),
	)
	return mergePositions(beams)
}

/** Fence segment: two posts and two rails, 3 m long. */
function fenceGeometry(): THREE.BufferGeometry {
	const posts = [-1.4, 1.4].map((px) => new THREE.BoxGeometry(0.16, 1.2, 0.16).translate(px, 0.6, 0))
	const rails = [0.45, 0.95].map((y) => new THREE.BoxGeometry(3, 0.1, 0.08).translate(0, y, 0))
	return mergePositions([...posts, ...rails])
}

const mat = (params: THREE.MeshStandardMaterialParameters) => new THREE.MeshStandardMaterial(params)

/** Instanced meshes of all props, with the per-instance writers the live map needs (falling trees, crushed hay). */
export class PropMeshes {
	readonly group = new THREE.Group()
	/** One trunk mesh for every species (scaled and tinted per instance), one crown mesh per species on the map. */
	private trunks!: THREE.InstancedMesh
	private readonly crowns = new Map<TreeSpecies, THREE.InstancedMesh>()
	/** Instance slot of each tree inside its species' crown mesh (the trunk slot is its index in the list). */
	private readonly crownIndex = new Map<Tree, number>()
	private readonly trunkIndex = new Map<Tree, number>()
	private hayMesh!: THREE.InstancedMesh
	private fenceMesh!: THREE.InstancedMesh
	private readonly tmp = new THREE.Matrix4()
	private readonly q = new THREE.Quaternion()
	private readonly q2 = new THREE.Quaternion()
	private readonly v = new THREE.Vector3()
	private readonly sc = new THREE.Vector3()

	constructor(
		private readonly terrain: Terrain,
		private readonly set: PropSet,
	) {
		this.buildTrees()
		this.buildBushes()
		this.buildRocks()
		this.buildHay()
		this.buildFences()
	}

	private instanced(geo: THREE.BufferGeometry, material: THREE.Material, n: number): THREE.InstancedMesh {
		const m = new THREE.InstancedMesh(geo, material, Math.max(1, n))
		m.count = n
		m.castShadow = true
		return m
	}

	private ground(x: number, z: number) {
		return this.terrain.height(x, z)
	}

	/** Only the species this map plants get a crown mesh, so a map costs one draw call per species plus the trunks. */
	private buildTrees() {
		const { season, rnd } = this.terrain
		const trees = this.set.trees
		const bark = mat({ color: '#ffffff', roughness: 0.95 }) // tinted per instance
		const crownMat = mat({ color: '#ffffff', roughness: 0.9 })
		const trunkGeo = new THREE.CylinderGeometry(0.18, 0.32, 5, 6).translate(0, 2.5, 0)
		this.trunks = this.instanced(trunkGeo, bark, trees.length)
		this.group.add(this.trunks)
		const col = new THREE.Color()
		const species = [...new Set(trees.map((t) => t.species))]
		for (const sp of species) {
			const list = trees.filter((t) => t.species === sp)
			const crown = this.instanced(crownGeometry(sp, season), crownMat, list.length)
			list.forEach((t, i) => {
				this.crownIndex.set(t, i)
				crown.setColorAt(i, crownColor(sp, season, rnd, col))
			})
			this.crowns.set(sp, crown)
			this.group.add(crown)
		}
		trees.forEach((t, i) => {
			this.trunkIndex.set(t, i)
			this.trunks.setColorAt(i, col.set(SPECIES[t.species].bark).offsetHSL(0, 0, (rnd() - 0.5) * 0.06))
			this.writeTree(t)
		})
	}

	private buildBushes() {
		const { season } = this.terrain
		const color = season === 'winter' ? '#6a5e50' : season === 'autumn' ? '#7d7a2e' : '#4a7d2e'
		const bushes = this.set.bushes
		const mesh = this.instanced(bushGeometry(), mat({ color, roughness: 0.95 }), bushes.length)
		bushes.forEach((b, i) => {
			this.tmp.compose(
				this.v.set(b.x, this.ground(b.x, b.z) - 0.2, b.z),
				this.q.setFromAxisAngle(AXIS_Y, i * 1.7),
				this.sc.setScalar(b.r),
			)
			mesh.setMatrixAt(i, this.tmp)
		})
		this.group.add(mesh)
	}

	/** Rocks, steel hedgehogs and concrete dragon's teeth (truncated pyramids). */
	private buildRocks() {
		const winter = this.terrain.season === 'winter'
		const of = (kind: Rock['kind']) => this.set.rocks.filter((r) => r.kind === kind)
		const stones = of('rock')
		const hogs = of('hedgehog')
		const teeth = of('tooth')
		const rockMat = mat({ color: winter ? '#9a9ca0' : '#6e6a62', roughness: 0.95, flatShading: true })
		const rockMesh = this.instanced(new THREE.DodecahedronGeometry(1, 0), rockMat, stones.length)
		stones.forEach((r, i) => {
			this.tmp.compose(
				this.v.set(r.x, this.ground(r.x, r.z) + r.r * 0.3, r.z),
				this.q.setFromEuler(new THREE.Euler(i * 0.7, i * 1.3, i * 0.4)),
				this.sc.set(r.r * 1.2, r.r * 0.8, r.r),
			)
			rockMesh.setMatrixAt(i, this.tmp)
		})
		this.group.add(rockMesh)
		if (hogs.length) {
			const m = mat({ color: '#4a4440', roughness: 0.7, metalness: 0.3 })
			this.group.add(this.uprightInstances(hedgehogGeometry(), m, hogs, 0.9, 0.9))
		}
		if (teeth.length) {
			const geo = new THREE.CylinderGeometry(0.45, 0.8, 1.3, 4).translate(0, 0.65, 0)
			const m = mat({ color: '#9a9890', roughness: 0.95, flatShading: true })
			this.group.add(this.uprightInstances(geo, m, teeth, -0.1, 0.3))
		}
	}

	/** Unscaled instances standing on the ground, `lift` above it, each turned `turn` × index about the vertical. */
	private uprightInstances(geo: THREE.BufferGeometry, m: THREE.Material, items: Rock[], lift: number, turn: number) {
		const mesh = new THREE.InstancedMesh(geo, m, items.length)
		items.forEach((r, i) => {
			this.tmp.compose(
				this.v.set(r.x, this.ground(r.x, r.z) + lift, r.z),
				this.q.setFromAxisAngle(AXIS_Y, i * turn),
				this.sc.setScalar(1),
			)
			mesh.setMatrixAt(i, this.tmp)
		})
		mesh.castShadow = true
		return mesh
	}

	private buildHay() {
		const color = this.terrain.season === 'winter' ? '#b8ad8a' : '#c9a84c'
		const geo = new THREE.ConeGeometry(2.2, 3.2, 9).translate(0, 1.6, 0)
		this.hayMesh = this.instanced(geo, mat({ color, roughness: 1 }), this.set.hay.length)
		this.set.hay.forEach((h, i) => this.writeHay(h, i))
		this.group.add(this.hayMesh)
	}

	private buildFences() {
		const m = mat({ color: '#8a7050', roughness: 0.95 })
		this.fenceMesh = this.instanced(fenceGeometry(), m, this.set.fences.length)
		this.set.fences.forEach((f, i) => this.writeFence(f, i))
		this.group.add(this.fenceMesh)
	}

	/** A standing or falling tree: rotated about its base toward its fall direction (fallT 0..1 eases to 85°). */
	writeTree(t: Tree) {
		const ang = t.fallT * t.fallT * 1.48
		const axis = this.v.set(-t.dirZ, 0, t.dirX).normalize()
		this.q.setFromAxisAngle(axis, -ang)
		this.q.multiply(this.q2.setFromAxisAngle(AXIS_Y, (t.x * 13.1 + t.z * 7.7) % 6.28))
		this.v.set(t.x, t.h - 0.2, t.z)
		this.tmp.compose(this.v, this.q, this.sc.setScalar(t.s))
		this.crowns.get(t.species)?.setMatrixAt(this.crownIndex.get(t) ?? 0, this.tmp)
		const [girth, height] = SPECIES[t.species].trunk
		this.tmp.compose(this.v, this.q, this.sc.set(t.s * girth, t.s * height, t.s * girth))
		this.trunks.setMatrixAt(this.trunkIndex.get(t) ?? 0, this.tmp)
	}

	writeHay(h: Hay, i: number) {
		this.tmp.compose(
			this.v.set(h.x, this.ground(h.x, h.z) - 0.1, h.z),
			this.q.identity(),
			this.sc.set(1, h.crushed ? 0.15 : 1, 1),
		)
		this.hayMesh.setMatrixAt(i, this.tmp)
		this.hayMesh.instanceMatrix.needsUpdate = true
	}

	writeFence(f: Fence, i: number) {
		this.tmp.compose(
			this.v.set(f.x, this.ground(f.x, f.z) - 0.1, f.z),
			this.q.setFromEuler(new THREE.Euler(f.down ? 1.5 : 0, f.rot, 0)),
			this.sc.setScalar(f.down ? 0.95 : 1),
		)
		this.fenceMesh.setMatrixAt(i, this.tmp)
		this.fenceMesh.instanceMatrix.needsUpdate = true
	}

	/** Upload the instance matrices of the trunks and of the crowns of the species that changed this frame. */
	markTreesDirty(species: ReadonlySet<TreeSpecies>) {
		if (!species.size) return
		this.trunks.instanceMatrix.needsUpdate = true
		for (const sp of species) {
			const crown = this.crowns.get(sp)
			if (crown) crown.instanceMatrix.needsUpdate = true
		}
	}

	dispose() {
		this.group.traverse((o) => {
			const m = o as THREE.Mesh
			if (!m.isMesh) return
			m.geometry.dispose()
			;(m.material as THREE.Material).dispose()
		})
	}
}
