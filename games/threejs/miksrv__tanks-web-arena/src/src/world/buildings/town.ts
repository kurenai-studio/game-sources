import * as THREE from 'three'
import { C, frameAt, isWetOrRoad, nearRailway, type BuildContext } from './builder'
import { church } from './village'

type Hall = [along: number, across: number, length: number, depth: number, ruined: boolean]

/** Brick or plaster shell: four walls of random surviving height with window holes, rubble inside. */
function ruin(ctx: BuildContext, x: number, z: number, w: number, d: number, rot: number) {
	const { t, b, rnd } = ctx
	const y = t.height(x, z) - 0.3
	const c = Math.cos(rot)
	const s = Math.sin(rot)
	const col = rnd() < 0.5 ? C.brick : C.plaster
	const toWorld = (lx: number, lz: number): [number, number] => [x + lx * c + lz * s, z - lx * s + lz * c]
	// Four walls [lx, lz, width, depth]; one or two may be gone entirely
	const walls: [number, number, number, number][] = [
		[-w / 2, 0, 0.5, d],
		[w / 2, 0, 0.5, d],
		[0, -d / 2, w, 0.5],
		[0, d / 2, w, 0.5],
	]
	let standing = false
	for (const [lx, lz, ww, dd] of walls) {
		const h = rnd() < 0.2 ? 0.6 : 2 + rnd() * 5
		if (h > 1.5) standing = true
		const [wx, wz] = toWorld(lx, lz)
		b.box(ww, h, dd, col, wx, y + h / 2, wz, rot)
		if (h <= 3) continue
		// Window holes as dark patches along the wall
		const alongX = ww > dd
		for (let k = -1; k <= 1; k += 2) {
			const [hx, hz] = toWorld(lx + (alongX ? k * ww * 0.3 : 0), lz + (alongX ? 0 : k * dd * 0.3))
			b.box(alongX ? 1 : 0.6, 1.2, alongX ? 0.6 : 1, C.window, hx, y + 2, hz, rot)
		}
	}
	for (let k = 0; k < 4; k++) {
		const rx = (rnd() - 0.5) * w * 0.8
		const rz = (rnd() - 0.5) * d * 0.8
		const rs = 0.8 + rnd() * 1.6
		const [px, pz] = toWorld(rx, rz)
		b.rubble(px, y, pz, rs, rnd)
	}
	if (standing) ctx.place('ruin', x, z, w, d, rot, y, 4)
}

/** Ruined town: blocks on a street grid aligned with the main street (the bridge road), skipping the river. */
export function town(ctx: BuildContext, cx: number, cz: number, r: number, rot: number) {
	const { t, rnd } = ctx
	const pitch = 26
	const w = t.riverWidth / 2
	const at = frameAt(cx, cz, rot)
	// The church stands on one bank beside the main street
	const side = rnd() < 0.5 ? 1 : -1
	let [chx, chz] = at((t.hasRiver ? w + 36 : 20) * side, 18)
	// A railway through the middle of the town: the church moves along the main street, off the track
	for (let k = 1; k < 4 && nearRailway(t, chx, chz, 18); k++) [chx, chz] = at((20 + k * 14) * side, 18)
	church(ctx, chx, chz, rot + 0.2, true)
	for (let ga = -3; ga <= 3; ga++) {
		for (let gs = -3; gs <= 3; gs++) {
			if (gs === 0) continue // the main street
			const [x, z] = at(ga * pitch + (rnd() - 0.5) * 4, gs * pitch + (rnd() - 0.5) * 4)
			if (Math.hypot(x - cx, z - cz) > r - 10) continue
			if (Math.abs(t.riverDist(x, z)) < w + 24) continue
			if (Math.hypot(x - chx, z - chz) < 16) continue
			if (isWetOrRoad(t, x, z) || nearRailway(t, x, z, 14) || rnd() < 0.15) continue
			const bw = 8 + rnd() * 7
			const bd = 8 + rnd() * 7
			ruin(ctx, x, z, bw, bd, -rot + (rnd() - 0.5) * 0.2)
		}
	}
}

/** Factory district in the centre: brick halls with window rows and a chimney, a yard wall, one hall in ruins. */
export function factory(ctx: BuildContext, cx: number, cz: number, r: number, rot: number) {
	const { t, rnd } = ctx
	const w = t.riverWidth / 2
	const at = frameAt(cx, cz, rot)
	const halls: Hall[] = [
		[-34, 30, 30, 15, false],
		[-34, -30, 24, 14, true],
		[34, 32, 28, 15, false],
		[34, -28, 26, 13, rnd() < 0.5],
		[0, 55, 22, 12, false],
	]
	const fits = (x: number, z: number, hl: number, hd: number) => {
		if (Math.hypot(x - cx, z - cz) > r - 8 || Math.abs(t.riverDist(x, z)) < w + hd / 2 + 10) return false
		// Every corner and the centre must be on dry ground off the roads
		const corner = frameAt(x, z, rot)
		const corners = [
			[0, 0],
			[hl / 2, hd / 2],
			[-hl / 2, hd / 2],
			[hl / 2, -hd / 2],
			[-hl / 2, -hd / 2],
		]
		if (corners.some(([ca, cs]) => isWetOrRoad(t, ...corner(ca, cs)))) return false
		if (nearRailway(t, x, z, Math.hypot(hl, hd) / 2 + 6)) return false
		return ctx.list.every((o) => o.kind !== 'factory' || Math.hypot(o.box.x - x, o.box.z - z) > (hl + hd) / 2 + 4)
	}
	let any = false
	for (const [a0, s0, hl, hd, ruined] of halls) {
		if (rnd() < 0.2) continue
		// Slide the hall away from the river (and sideways) until it fits; a meander or a road may be in the way
		let spot: [number, number] | null = null
		for (let k = 0; k < 6 && !spot; k++) {
			const p = at(a0 + Math.sign(a0 || 1) * k * 10, s0 + (k % 2 ? 8 : 0))
			if (fits(p[0], p[1], hl, hd)) spot = p
		}
		if (!spot) continue
		hall(ctx, spot[0], spot[1], hl, hd, rot, ruined)
		any = true
	}
	if (any) chimney(ctx, at, w)
	yardWalls(ctx, at, w, rot)
}

function hall(ctx: BuildContext, x: number, z: number, hl: number, hd: number, rot: number, ruined: boolean) {
	const { t, b, rnd } = ctx
	const y = t.height(x, z) - 0.3
	const h = ruined ? 4 : 8
	const col = rnd() < 0.5 ? C.brick : C.brickDark
	const local = frameAt(x, z, rot)
	// `rot` is the district's heading in the frameAt convention; boxes and colliders turn the other way (see yardWalls)
	b.box(hl, h, hd, col, x, y + h / 2, z, -rot)
	if (!ruined) {
		b.prism(hl + 0.6, 2.2, hd + 0.4, C.roofGrey, x, y + h, z, -rot)
		for (const side of [1, -1]) {
			for (let k = -2; k <= 2; k++) {
				const [wx, wz] = local(k * hl * 0.17, side * (hd / 2 + 0.03))
				b.box(2.0, 2.4, 0.05, C.window, wx, y + h * 0.55, wz, -rot)
			}
		}
	} else {
		for (let k = 0; k < 3; k++) {
			const rx = (rnd() - 0.5) * hl * 0.8
			const rz = (rnd() - 0.5) * hd * 0.8
			const rs = 1 + rnd() * 1.8
			const [px, pz] = local(rx, rz)
			b.rubble(px, y, pz, rs, rnd)
		}
	}
	ctx.place('factory', x, z, hl, hd, -rot, y, h + (ruined ? 0 : 2))
}

/** Chimney beside the main hall, moved along until it is clear of the river and the roads. */
function chimney(ctx: BuildContext, at: (a: number, s: number) => [number, number], riverHalf: number) {
	const { t, b } = ctx
	const blocked = (x: number, z: number) => Math.abs(t.riverDist(x, z)) < riverHalf + 12 || isWetOrRoad(t, x, z)
	let [x, z] = at(-50, 12)
	for (let k = 0; k < 4 && blocked(x, z); k++) [x, z] = at(-50 - k * 10, 12 + k * 6)
	if (Math.abs(t.riverDist(x, z)) <= riverHalf + 12 || t.biome(x, z) === 'water') return
	const y = t.height(x, z) - 0.3
	b.shape(
		new THREE.CylinderGeometry(1.0, 1.5, 24, 10),
		C.brickDark,
		new THREE.Matrix4().makeTranslation(x, y + 12, z),
	)
	ctx.place('factory', x, z, 3, 3, 0, y, 24)
}

/** Yard wall with gaps along the main street on both sides. */
function yardWalls(ctx: BuildContext, at: (a: number, s: number) => [number, number], riverHalf: number, rot: number) {
	const { t, b, rnd } = ctx
	for (const s of [-1, 1]) {
		for (let a = -70; a <= 70; a += 24) {
			if (rnd() < 0.3) continue
			const [x, z] = at(a, s * 14)
			if (Math.abs(t.riverDist(x, z)) < riverHalf + 20 || isWetOrRoad(t, x, z)) continue
			const y = t.height(x, z) - 0.3
			b.box(16, 2.0, 0.5, C.brick, x, y + 1.0, z, -rot)
			ctx.place('wall', x, z, 16, 0.5, -rot, y, 2.0)
		}
	}
}
