import * as THREE from 'three'
import { MergedGeometryBuilder, placeY } from '../../render/geometryBuilder'
import type { OBB } from '../obb'
import type { Terrain } from '../terrain'

export type BuildingKind =
	| 'house'
	| 'brickHouse'
	| 'church'
	| 'chapel'
	| 'ruin'
	| 'barn'
	| 'warehouse'
	| 'tower'
	| 'factory'
	| 'bunker'
	| 'wall'
	| 'mill'
	| 'well'
	| 'wagon'

export interface Building {
	box: OBB
	kind: BuildingKind
}

/** Building palette. */
export const C = {
	wall: new THREE.Color('#c9b89a'),
	wallDark: new THREE.Color('#9a8a6c'),
	log: new THREE.Color('#7a5a3a'),
	roof: new THREE.Color('#7a3a2a'),
	roofGrey: new THREE.Color('#5a5a5a'),
	brick: new THREE.Color('#8a5a48'),
	brickDark: new THREE.Color('#5a3a30'),
	rubble: new THREE.Color('#6d6760'),
	plaster: new THREE.Color('#b8aa98'),
	window: new THREE.Color('#2a2a30'),
	church: new THREE.Color('#e0dcd0'),
	dome: new THREE.Color('#2a6a9a'),
	concrete: new THREE.Color('#9a9890'),
	stone: new THREE.Color('#6c6760'),
	plank: new THREE.Color('#8a6a44'),
	timber: new THREE.Color('#5e4228'),
}

/** Merged-geometry builder with the shapes buildings are made of. */
export class BuildingBuilder extends MergedGeometryBuilder {
	/** Box centred at (x, y, z), turned by `rot` about the vertical. */
	box(w: number, h: number, d: number, color: THREE.Color, x: number, y: number, z: number, rot = 0) {
		this.addTemp(new THREE.BoxGeometry(w, h, d), color, placeY(x, y, z, rot))
	}

	/** Gable roof: triangular prism along the depth axis, its base at y. */
	prism(w: number, h: number, d: number, color: THREE.Color, x: number, y: number, z: number, rot = 0) {
		const shape = new THREE.Shape()
		shape.moveTo(-w / 2, 0)
		shape.lineTo(w / 2, 0)
		shape.lineTo(0, h)
		shape.closePath()
		const ext = new THREE.ExtrudeGeometry(shape, { depth: d, bevelEnabled: false })
		ext.translate(0, 0, -d / 2)
		this.addTemp(ext, color, placeY(x, y, z, rot))
	}

	/** Any temporary geometry under a matrix (disposed after it is merged). */
	shape(geo: THREE.BufferGeometry, color: THREE.Color, m: THREE.Matrix4) {
		this.addTemp(geo, color, m)
	}

	/** A rubble lump: a squashed dodecahedron at a random tilt. */
	rubble(x: number, y: number, z: number, size: number, rnd: () => number) {
		const m = new THREE.Matrix4().compose(
			new THREE.Vector3(x, y + size * 0.25, z),
			new THREE.Quaternion().setFromEuler(new THREE.Euler(rnd(), rnd() * 6, rnd())),
			new THREE.Vector3(size * 1.3, size * 0.5, size),
		)
		this.addTemp(new THREE.DodecahedronGeometry(1, 0), C.rubble, m)
	}
}

/** What a structure generator needs: the map, the geometry sink, the map's RNG and a way to register a collider. */
export interface BuildContext {
	t: Terrain
	b: BuildingBuilder
	rnd: () => number
	/** Solid footprint: w × d centred at (x, z), turned by `rot`, from y0 − 0.5 up to y0 + h. */
	place(kind: BuildingKind, x: number, z: number, w: number, d: number, rot: number, y0: number, h: number): void
	/** Colliders placed so far. */
	readonly list: readonly Building[]
}

/** Local (along, across) offsets → world, for a frame at (cx, cz) turned by `rot`. */
export function frameAt(cx: number, cz: number, rot: number) {
	const sx = Math.cos(rot)
	const sz = Math.sin(rot)
	return (a: number, s: number): [number, number] => [cx + sx * a - sz * s, cz + sz * a + sx * s]
}

/** Biome check shared by the generators: houses and walls never stand on water, a road or the railway. */
export function isWetOrRoad(t: Terrain, x: number, z: number): boolean {
	const bm = t.biome(x, z)
	return bm === 'water' || bm === 'road' || bm === 'rail' || nearRailway(t, x, z, RAIL_CLEAR)
}

/** m kept clear on each side of the track centre */
const RAIL_CLEAR = 6

/** Within `d` of the railway's centre line (false on a map without one). */
export function nearRailway(t: Terrain, x: number, z: number, d: number): boolean {
	return !!t.railway && t.railway.dist(x, z) < d
}
