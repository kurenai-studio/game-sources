import * as THREE from 'three'
import { GroundMarks } from './groundMarks'
import { PARTICLE_FRAGMENT, PARTICLE_VERTEX } from './particleShader'

const MAX = 4000
const ATTRIBUTES = [
	['position', 3],
	['aSize', 1],
	['aColor', 3],
	['aAlpha', 1],
] as const

/** Field values of a fresh particle; `emit` overrides what it is given. */
const DEFAULTS = {
	vx: 0,
	vy: 0,
	vz: 0,
	life: 1,
	size: 1,
	grow: 0,
	r: 1,
	g: 1,
	b: 1,
	gravity: 0,
	drag: 0,
	alpha: 1,
}

/** One particle: position, velocity, life, size growth, colour, gravity, drag and opacity. */
interface P {
	x: number
	y: number
	z: number
	vx: number
	vy: number
	vz: number
	life: number
	maxLife: number
	size: number
	grow: number
	r: number
	g: number
	b: number
	gravity: number
	drag: number
	alpha: number
}

/** CPU-simulated point particles (one draw call) plus the ground marks; effect presets are methods. */
export class Particles {
	readonly points: THREE.Points
	/** Particle objects are pooled: the first `live` entries are alive, the rest wait to be reused. */
	private readonly list: P[] = []
	private live = 0
	private pos = new Float32Array(MAX * 3)
	private size = new Float32Array(MAX)
	private col = new Float32Array(MAX * 3)
	private alpha = new Float32Array(MAX)
	private mat: THREE.ShaderMaterial
	/** Splash rings on the ground. */
	readonly marks = new GroundMarks()

	constructor() {
		const geo = new THREE.BufferGeometry()
		geo.setAttribute('position', new THREE.BufferAttribute(this.pos, 3))
		geo.setAttribute('aSize', new THREE.BufferAttribute(this.size, 1))
		geo.setAttribute('aColor', new THREE.BufferAttribute(this.col, 3))
		geo.setAttribute('aAlpha', new THREE.BufferAttribute(this.alpha, 1))
		this.mat = new THREE.ShaderMaterial({
			uniforms: { uScale: { value: 600 } },
			vertexShader: PARTICLE_VERTEX,
			fragmentShader: PARTICLE_FRAGMENT,
			transparent: true,
			depthWrite: false,
		})
		this.points = new THREE.Points(geo, this.mat)
		this.points.frustumCulled = false
	}

	get count() {
		return this.live
	}
	/** `bufferHeight`: drawing-buffer height in pixels (CSS height × pixel ratio). */
	setScale(bufferHeight: number, fovDeg: number) {
		this.mat.uniforms.uScale.value = bufferHeight / (2 * Math.tan((fovDeg * Math.PI) / 360))
	}

	emit(p: Partial<P> & { x: number; y: number; z: number }) {
		let q: P
		if (this.live < MAX) {
			q = this.list[this.live] ??= { ...DEFAULTS, x: 0, y: 0, z: 0, maxLife: 1 }
			this.live++
		} else q = this.list[Math.floor(Math.random() * MAX)]
		Object.assign(q, DEFAULTS, p)
		q.maxLife = q.life
	}

	muzzle(at: THREE.Vector3, dir: THREE.Vector3, caliber: number) {
		const k = caliber / 75
		for (let i = 0; i < 4; i++)
			this.emit({
				x: at.x + dir.x * 0.6,
				y: at.y,
				z: at.z + dir.z * 0.6,
				vx: dir.x * 12,
				vy: 0.5,
				vz: dir.z * 12,
				life: 0.08,
				size: 1.4 * k,
				grow: 18,
				r: 1,
				g: 0.75,
				b: 0.35,
			})
		for (let i = 0; i < 18; i++) {
			const s = 6 + Math.random() * 14
			this.emit({
				x: at.x,
				y: at.y,
				z: at.z,
				vx: dir.x * s + (Math.random() - 0.5) * 4,
				vy: 1 + Math.random() * 2,
				vz: dir.z * s + (Math.random() - 0.5) * 4,
				life: 1.5 + Math.random() * 1.5,
				size: 1.2 * k,
				grow: 2.2,
				r: 0.75,
				g: 0.72,
				b: 0.68,
				drag: 2.5,
				alpha: 0.5,
			})
		}
		for (let i = 0; i < 10; i++)
			this.emit({
				x: at.x,
				y: at.y - 0.5,
				z: at.z,
				vx: dir.x * 8 + (Math.random() - 0.5) * 6,
				vy: 0.5,
				vz: dir.z * 8 + (Math.random() - 0.5) * 6,
				life: 2,
				size: 1.6 * k,
				grow: 2,
				r: 0.6,
				g: 0.5,
				b: 0.38,
				drag: 2,
				alpha: 0.35,
			})
	}

	/** Shell strikes armour: sparks, and a flash when it went in. */
	armorHit(x: number, y: number, z: number, penetrated: boolean, ricochet: boolean) {
		const n = ricochet ? 10 : penetrated ? 26 : 16
		for (let i = 0; i < n; i++) {
			const a = Math.random() * Math.PI * 2
			const s = 4 + Math.random() * 10
			const e = Math.random() * 1.2
			this.emit({
				x,
				y,
				z,
				vx: Math.cos(a) * s * Math.cos(e),
				vy: Math.sin(e) * s + 2,
				vz: Math.sin(a) * s * Math.cos(e),
				life: 0.3 + Math.random() * 0.4,
				size: 0.22,
				r: 1,
				g: 0.8 + Math.random() * 0.2,
				b: 0.4,
				gravity: 15,
				drag: 1,
			})
		}
		if (penetrated) {
			for (let i = 0; i < 3; i++) this.emit({ x, y, z, life: 0.12, size: 2.2, grow: 14, r: 1, g: 0.85, b: 0.5 })
			for (let i = 0; i < 12; i++)
				this.emit({
					x,
					y,
					z,
					vx: (Math.random() - 0.5) * 3,
					vy: 1.5 + Math.random() * 2,
					vz: (Math.random() - 0.5) * 3,
					life: 1.6,
					size: 0.9,
					grow: 1.6,
					r: 0.2,
					g: 0.2,
					b: 0.2,
					drag: 1,
					alpha: 0.6,
				})
		}
	}

	/** Shell into the ground or a wall. */
	impact(x: number, y: number, z: number, big: number) {
		const n = Math.floor(12 + big * 16)
		for (let i = 0; i < n; i++) {
			const a = Math.random() * Math.PI * 2
			const s = 2 + Math.random() * (5 + big * 6)
			this.emit({
				x,
				y: y + 0.2,
				z,
				vx: Math.cos(a) * s,
				vy: 4 + Math.random() * (6 + big * 8),
				vz: Math.sin(a) * s,
				life: 0.8 + Math.random() * 0.7,
				size: 0.35 + big * 0.3,
				r: 0.45,
				g: 0.38,
				b: 0.28,
				gravity: 18,
			})
		}
		for (let i = 0; i < 8 + big * 8; i++)
			this.emit({
				x,
				y: y + 0.5,
				z,
				vx: (Math.random() - 0.5) * 4,
				vy: 1.5 + Math.random() * 3,
				vz: (Math.random() - 0.5) * 4,
				life: 1.6 + big,
				size: 1.2 + big,
				grow: 2 + big * 1.5,
				r: 0.55,
				g: 0.48,
				b: 0.38,
				drag: 1.2,
				alpha: 0.55,
			})
		if (big > 0.5) {
			for (let i = 0; i < 3; i++)
				this.emit({ x, y: y + 1, z, life: 0.15, size: 3 + big * 3, grow: 25, r: 1, g: 0.7, b: 0.3 })
		}
	}

	/** Tank destroyed: fireball, debris, a lingering column of smoke (the wreck keeps smoking via `smoke`). */
	explosion(x: number, y: number, z: number) {
		for (let i = 0; i < 6; i++)
			this.emit({ x, y: y + 1, z, life: 0.25, size: 5, grow: 30, r: 1, g: 0.6 + Math.random() * 0.3, b: 0.2 })
		for (let i = 0; i < 40; i++) {
			const a = Math.random() * Math.PI * 2
			const s = 3 + Math.random() * 12
			this.emit({
				x,
				y: y + 1,
				z,
				vx: Math.cos(a) * s,
				vy: 6 + Math.random() * 14,
				vz: Math.sin(a) * s,
				life: 1 + Math.random() * 1.5,
				size: 0.4,
				r: 0.3,
				g: 0.25,
				b: 0.2,
				gravity: 16,
			})
		}
		for (let i = 0; i < 30; i++)
			this.emit({
				x: x + (Math.random() - 0.5) * 3,
				y: y + 1,
				z: z + (Math.random() - 0.5) * 3,
				vx: (Math.random() - 0.5) * 3,
				vy: 3 + Math.random() * 5,
				vz: (Math.random() - 0.5) * 3,
				life: 3 + Math.random() * 3,
				size: 2.5,
				grow: 2.5,
				r: 0.12,
				g: 0.11,
				b: 0.1,
				drag: 0.8,
				alpha: 0.7,
			})
	}

	fire(x: number, y: number, z: number) {
		this.emit({
			x: x + (Math.random() - 0.5) * 1.5,
			y,
			z: z + (Math.random() - 0.5) * 1.5,
			vx: Math.random() - 0.5,
			vy: 2.5 + Math.random() * 2,
			vz: Math.random() - 0.5,
			life: 0.4 + Math.random() * 0.3,
			size: 1.6,
			grow: -1.2,
			r: 1,
			g: 0.5 + Math.random() * 0.3,
			b: 0.1,
			alpha: 0.95,
		})
		if (Math.random() < 0.6) this.smoke(x, y + 0.8, z, 1.2)
	}
	smoke(x: number, y: number, z: number, s = 1) {
		this.emit({
			x,
			y,
			z,
			vx: (Math.random() - 0.5) * 0.8,
			vy: 1.6 + Math.random() * 1.2,
			vz: (Math.random() - 0.5) * 0.8,
			life: 2.5 + Math.random() * 2,
			size: 1.2 * s,
			grow: 1.8 * s,
			r: 0.18,
			g: 0.17,
			b: 0.16,
			drag: 0.5,
			alpha: 0.5,
		})
	}
	/** Dust kicked up by the tracks. */
	dust(x: number, y: number, z: number, vx: number, vz: number, k: number) {
		this.emit({
			x,
			y: y + 0.3,
			z,
			vx: vx * 0.2 + (Math.random() - 0.5) * 1.5,
			vy: 0.8 + Math.random(),
			vz: vz * 0.2 + (Math.random() - 0.5) * 1.5,
			life: 1.2 + k,
			size: 1.1 + k * 0.6,
			grow: 2.4,
			r: 0.62,
			g: 0.55,
			b: 0.42,
			drag: 1.5,
			alpha: 0.3 + k * 0.15,
		})
	}
	exhaust(x: number, y: number, z: number) {
		this.emit({
			x,
			y,
			z,
			vx: (Math.random() - 0.5) * 0.5,
			vy: 1 + Math.random(),
			vz: (Math.random() - 0.5) * 0.5,
			life: 1,
			size: 0.5,
			grow: 1.2,
			r: 0.3,
			g: 0.3,
			b: 0.3,
			drag: 1,
			alpha: 0.35,
		})
	}

	update(dt: number) {
		const l = this.list
		for (let i = this.live - 1; i >= 0; i--) {
			const p = l[i]
			p.life -= dt
			if (p.life <= 0) {
				// Swap the dead one past the live end, where `emit` picks it up again
				this.live--
				l[i] = l[this.live]
				l[this.live] = p
				continue
			}
			p.vy -= p.gravity * dt
			const d = Math.max(0, 1 - p.drag * dt)
			p.vx *= d
			p.vy *= d
			p.vz *= d
			p.x += p.vx * dt
			p.y += p.vy * dt
			p.z += p.vz * dt
			p.size = Math.max(0.05, p.size + p.grow * dt)
		}
		for (let i = 0; i < this.live; i++) {
			const p = l[i]
			const t = p.life / p.maxLife
			this.pos[i * 3] = p.x
			this.pos[i * 3 + 1] = p.y
			this.pos[i * 3 + 2] = p.z
			this.size[i] = p.size
			this.col[i * 3] = p.r
			this.col[i * 3 + 1] = p.g
			this.col[i * 3 + 2] = p.b
			this.alpha[i] = p.alpha * Math.min(1, t * 3)
		}
		const g = this.points.geometry
		g.setDrawRange(0, this.live)
		// Upload only the live part of each buffer
		for (const [name, itemSize] of ATTRIBUTES) {
			const a = g.attributes[name] as THREE.BufferAttribute
			a.clearUpdateRanges()
			a.addUpdateRange(0, this.live * itemSize)
			a.needsUpdate = true
		}
		this.marks.update(dt)
	}

	clear() {
		this.live = 0
		this.marks.clear()
	}
}
