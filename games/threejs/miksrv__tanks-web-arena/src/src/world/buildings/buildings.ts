import * as THREE from 'three'
import { OBB } from '../obb'
import type { Terrain } from '../terrain'
import { BoxGrid } from './boxGrid'
import { BuildingBuilder, type BuildContext, type Building, type BuildingKind } from './builder'
import { bridge, bunker, windmill } from './landmarks'
import { railway } from './railway'
import { revetments } from './revetments'
import { factory, town } from './town'
import { village } from './village'

interface Normal {
	x: number
	y: number
	z: number
}

/**
 * Villages (log houses, barns, a church), the ruined town at the middle bridge (brick shells, rubble, a church tower),
 * the river bridges, the railway with its goods trains and the tank revetments. Every solid building piece is an OBB for driving, shells and line of sight; a bridge deck
 * is driven on through the terrain's height override instead. All geometry is merged into one mesh.
 */
export class Buildings {
	readonly group = new THREE.Group()
	readonly list: Building[] = []
	private readonly pushOut = { x: 0, z: 0 }
	private readonly tmpN: Normal = { x: 0, y: 0, z: 0 }
	private readonly grid: BoxGrid
	private readonly found: number[] = []

	constructor(terrain: Terrain) {
		const b = new BuildingBuilder()
		const ctx: BuildContext = { t: terrain, b, rnd: terrain.rnd, list: this.list, place: this.place }
		for (const s of terrain.settlements) {
			if (s.kind === 'village') village(ctx, s)
			else if (s.variant === 'factory') factory(ctx, s.x, s.z, s.r, s.rot)
			else town(ctx, s.x, s.z, s.r, s.rot)
		}
		for (const c of terrain.crossings) if (c.kind === 'bridge') bridge(ctx, c)
		for (const bk of terrain.bunkers) bunker(ctx, bk.x, bk.z, bk.rot)
		if (terrain.windmill) windmill(ctx, terrain.windmill.x, terrain.windmill.z, terrain.windmill.rot)
		if (terrain.railway) railway(ctx, terrain.railway)
		if (terrain.features.revetments) revetments(ctx)
		const mesh = new THREE.Mesh(b.build(), new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.9 }))
		mesh.castShadow = mesh.receiveShadow = true
		this.group.add(mesh)
		this.grid = new BoxGrid(this.list.map((bd) => bd.box))
	}

	private readonly place = (
		kind: BuildingKind,
		x: number,
		z: number,
		w: number,
		d: number,
		rot: number,
		y0: number,
		h: number,
	) => {
		this.list.push({ box: new OBB(x, z, w / 2, d / 2, rot, y0 - 0.5, y0 + h), kind })
	}

	/** Push a circle (tank footprint sample) out of every solid box. */
	collideCircle(x: number, z: number, r: number, out: { x: number; z: number }): boolean {
		out.x = out.z = 0
		let hit = false
		for (const i of this.grid.near(x, z, r, this.found)) {
			if (this.list[i].box.pushCircle(x, z, r, this.pushOut)) {
				out.x += this.pushOut.x
				out.z += this.pushOut.z
				hit = true
			}
		}
		return hit
	}

	/** Nearest building hit along the segment: returns t ∈ [0,1] and the normal, or -1. */
	raySegment(ax: number, ay: number, az: number, bx: number, by: number, bz: number, n?: Normal): number {
		let best = -1
		for (const i of this.grid.along(ax, az, bx, bz, this.found)) {
			const t = this.list[i].box.raySegment(ax, ay, az, bx, by, bz, this.tmpN)
			if (t < 0 || (best >= 0 && t >= best)) continue
			best = t
			if (n) Object.assign(n, this.tmpN)
		}
		return best
	}

	blocksLos(ax: number, ay: number, az: number, bx: number, by: number, bz: number): boolean {
		return this.raySegment(ax, ay, az, bx, by, bz) >= 0
	}

	/** Nearest building centre within `maxDist` (bots use it to find cover). */
	nearest(x: number, z: number, maxDist: number): Building | null {
		let best: Building | null = null
		let bd = maxDist
		for (const b of this.list) {
			const d = Math.hypot(b.box.x - x, b.box.z - z)
			if (d < bd) {
				bd = d
				best = b
			}
		}
		return best
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
