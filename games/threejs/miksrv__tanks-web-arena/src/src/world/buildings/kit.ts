import * as THREE from 'three'
import { placeY } from '../../render/geometryBuilder'
import type { Terrain } from '../terrain'
import { C, isWetOrRoad, type BuildContext } from './builder'

// Building variants a map may roll (BUILDING_KIT): brick houses, kolkhoz warehouses, chapels and water towers.

/** Local (lx, lz) → world for a box turned by `rot` (the builder's convention). */
function boxFrame(x: number, z: number, rot: number) {
	const c = Math.cos(rot)
	const s = Math.sin(rot)
	return (lx: number, lz: number): [number, number] => [x + lx * c + lz * s, z - lx * s + lz * c]
}

/** The centre and the four corners of a w × d footprint are on dry ground off the roads and the railway. */
export function footprintClear(t: Terrain, x: number, z: number, w: number, d: number, rot: number): boolean {
	const at = boxFrame(x, z, rot)
	const pts: [number, number][] = [
		[0, 0],
		[w / 2, d / 2],
		[-w / 2, d / 2],
		[w / 2, -d / 2],
		[-w / 2, -d / 2],
	]
	return pts.every(([lx, lz]) => !isWetOrRoad(t, ...at(lx, lz)))
}

/** Two-storey brick or plaster house: two rows of windows, a cornice between the floors, a chimney. */
export function brickHouse(ctx: BuildContext, x: number, z: number, rot: number) {
	const { t, b, rnd } = ctx
	const y = t.height(x, z) - 0.3
	const w = 7 + rnd() * 1.5
	const d = 9 + rnd() * 2
	const h = 6
	const at = boxFrame(x, z, rot)
	b.box(w, h, d, rnd() < 0.6 ? C.brick : C.plaster, x, y + h / 2, z, rot)
	b.box(w + 0.2, 0.2, d + 0.2, C.brickDark, x, y + 3.1, z, rot) // cornice
	b.prism(w + 0.8, 2.4, d + 0.6, rnd() < 0.5 ? C.roof : C.roofGrey, x, y + h, z, rot)
	for (const side of [1, -1]) {
		for (const fy of [1.6, 4.5]) {
			for (let k = -1; k <= 1; k++) {
				const [wx, wz] = at(side * (w / 2 + 0.03), k * d * 0.3)
				b.box(0.05, 1.1, 0.8, C.window, wx, y + fy, wz, rot)
			}
		}
	}
	const [cx, cz] = at(-w * 0.2, d * 0.3)
	b.box(0.7, 1.6, 0.7, C.brickDark, cx, y + h + 1.8, cz, rot) // chimney
	ctx.place('brickHouse', x, z, w, d, rot, y, h + 2.4)
}

/** Kolkhoz warehouse: long and low, plank or brick walls, wide doors in both gable ends. */
export function warehouse(ctx: BuildContext, x: number, z: number, rot: number, w: number, d: number) {
	const { t, b, rnd } = ctx
	const y = t.height(x, z) - 0.3
	const h = 4
	const at = boxFrame(x, z, rot)
	b.box(w, h, d, rnd() < 0.5 ? C.plank : C.brick, x, y + h / 2, z, rot)
	b.prism(w + 0.8, 2.6, d + 0.6, C.roofGrey, x, y + h, z, rot)
	for (const end of [1, -1]) {
		const [dx, dz] = at(0, end * (d / 2 + 0.03))
		b.box(3.2, 3, 0.05, C.window, dx, y + 1.5, dz, rot)
	}
	for (const side of [1, -1]) {
		for (let k = -2; k <= 2; k++) {
			const [wx, wz] = at(side * (w / 2 + 0.03), k * d * 0.2)
			b.box(0.05, 0.5, 1.0, C.window, wx, y + 3.1, wz, rot)
		}
	}
	ctx.place('warehouse', x, z, w, d, rot, y, h + 2.6)
}

/** Small chapel: plastered walls, a gable roof and a belfry with a spire over the door. */
export function chapel(ctx: BuildContext, x: number, z: number, rot: number) {
	const { t, b } = ctx
	const y = t.height(x, z) - 0.3
	const w = 5
	const d = 7.5
	const h = 4.2
	const at = boxFrame(x, z, rot)
	b.box(w, h, d, C.church, x, y + h / 2, z, rot)
	b.prism(w + 0.6, 2.2, d + 0.4, C.roofGrey, x, y + h, z, rot)
	const [bx, bz] = at(0, -d / 2 + 1.2)
	b.box(2, 2.6, 2, C.church, bx, y + h + 1.3, bz, rot)
	b.shape(new THREE.ConeGeometry(1.4, 2.6, 4), C.dome, placeY(bx, y + h + 3.9, bz, rot + Math.PI / 4))
	b.box(0.12, 1.4, 0.12, C.church, bx, y + h + 5.9, bz)
	b.box(0.7, 0.12, 0.12, C.church, bx, y + h + 6.2, bz, rot)
	const [dx, dz] = at(0, -d / 2 - 0.03)
	b.box(1.2, 2.1, 0.05, C.window, dx, y + 1.05, dz, rot) // door
	ctx.place('chapel', x, z, w, d, rot, y, h + 2.2)
	ctx.place('chapel', bx, bz, 2, 2, rot, y, h + 5.2)
}

/** Water tower: a brick shaft with a timber tank and a conical roof on top, 15 m tall. */
export function waterTower(ctx: BuildContext, x: number, z: number, rot: number) {
	const { t, b } = ctx
	const y = t.height(x, z) - 0.3
	const shaft = 10
	b.shape(new THREE.CylinderGeometry(2.0, 2.4, shaft, 8), C.brick, placeY(x, y + shaft / 2, z, rot))
	b.shape(new THREE.CylinderGeometry(3.2, 3.0, 3.6, 10), C.timber, placeY(x, y + shaft + 1.8, z, rot))
	b.shape(new THREE.ConeGeometry(3.6, 1.8, 10), C.roofGrey, placeY(x, y + shaft + 4.5, z, rot))
	const at = boxFrame(x, z, rot)
	const [dx, dz] = at(0, 2.3)
	b.box(1.1, 2.1, 0.3, C.window, dx, y + 1.05, dz, rot) // door
	ctx.place('tower', x, z, 5.6, 5.6, rot, y, shaft + 5.4)
}
