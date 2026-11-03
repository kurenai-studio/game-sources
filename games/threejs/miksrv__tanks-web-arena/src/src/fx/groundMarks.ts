import * as THREE from 'three'

const MAX_RINGS = 32
const RING_LIFE = 0.9 // s

interface Ring {
	x: number
	y: number
	z: number
	r: number
	life: number
}

/** Decals on the ground: expanding HE splash rings. */
export class GroundMarks {
	/** HE splash rings: expand to the blast radius and fade, so the fall of shot reads from any distance. */
	readonly rings: THREE.InstancedMesh
	private ringList: Ring[] = []
	private readonly tmp = new THREE.Matrix4()

	constructor() {
		const rg = new THREE.RingGeometry(0.86, 1, 40).rotateX(-Math.PI / 2)
		const ringMat = new THREE.MeshBasicMaterial({
			color: '#ffb060',
			transparent: true,
			opacity: 0.7,
			depthTest: false,
			depthWrite: false,
		})
		this.rings = new THREE.InstancedMesh(rg, ringMat, MAX_RINGS)
		this.rings.count = 0
		this.rings.frustumCulled = false
		this.rings.renderOrder = 19
	}

	/** Expanding ring on the ground at (x,y,z) reaching radius r. */
	splashRing(x: number, y: number, z: number, r: number) {
		if (this.ringList.length >= MAX_RINGS) this.ringList.shift()
		this.ringList.push({ x, y: y + 0.3, z, r, life: RING_LIFE })
	}

	update(dt: number) {
		if (!this.ringList.length && !this.rings.count) return
		for (let i = this.ringList.length - 1; i >= 0; i--) {
			const q = this.ringList[i]
			q.life -= dt
			if (q.life <= 0) {
				this.ringList.splice(i, 1)
				continue
			}
			const k = 1 - q.life / RING_LIFE
			const s = q.r * Math.min(1, k * 2.2 + 0.15)
			this.tmp.makeScale(s, 1, s).setPosition(q.x, q.y, q.z)
			this.rings.setMatrixAt(i, this.tmp)
		}
		this.rings.count = this.ringList.length
		this.rings.instanceMatrix.needsUpdate = true
	}

	clear() {
		this.ringList.length = 0
		this.rings.count = 0
	}
}
