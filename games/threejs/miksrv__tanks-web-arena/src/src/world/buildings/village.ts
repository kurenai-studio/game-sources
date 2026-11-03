import * as THREE from 'three'
import type { Settlement } from '../terrain'
import { C, isWetOrRoad, type BuildContext } from './builder'
import { brickHouse, chapel, footprintClear, warehouse, waterTower } from './kit'

/** Log house or barn with a gable roof, windows on the long sides and a chimney. */
export function house(ctx: BuildContext, x: number, z: number, rot: number, kind: 'house' | 'barn') {
	const { t, b, rnd } = ctx
	const barn = kind === 'barn'
	const y = t.height(x, z) - 0.3
	const w = barn ? 7 + rnd() * 3 : 5 + rnd() * 2.5
	const d = barn ? 10 + rnd() * 4 : 6 + rnd() * 3
	const h = barn ? 3.2 : 2.8
	b.box(w, h, d, barn ? C.wallDark : C.log, x, y + h / 2, z, rot)
	b.prism(w + 0.8, barn ? 2.2 : 2, d + 0.6, barn ? C.roofGrey : C.roof, x, y + h, z, rot)
	const c = Math.cos(rot)
	const s = Math.sin(rot)
	for (const side of [1, -1]) {
		for (let k = -1; k <= 1; k++) {
			const lx = side * (w / 2 + 0.03)
			const lz = k * d * 0.3
			b.box(0.05, 0.9, 0.8, C.window, x + lx * c + lz * s, y + 1.6, z - lx * s + lz * c, rot)
		}
	}
	b.box(0.6, 1.2, 0.6, C.wallDark, x + w * 0.25 * c, y + h + 1.6, z - w * 0.25 * s, rot) // chimney
	ctx.place(kind, x, z, w, d, rot, y, h + 2)
}

/** Church with a bell tower; a ruined one has no roof, no dome and a broken tower. */
export function church(ctx: BuildContext, x: number, z: number, rot: number, ruined: boolean) {
	const { t, b } = ctx
	const y = t.height(x, z) - 0.3
	const w = 8
	const d = 14
	const h = ruined ? 4.5 : 6
	const wallColor = ruined ? C.brickDark : C.church
	b.box(w, h, d, wallColor, x, y + h / 2, z, rot)
	if (!ruined) b.prism(w + 0.6, 3, d + 0.4, C.roofGrey, x, y + h, z, rot)
	const tz = -d / 2 + 2
	const tx = x + tz * Math.sin(rot)
	const tzw = z + tz * Math.cos(rot)
	const th = ruined ? 9 : 13
	b.box(4, th, 4, wallColor, tx, y + th / 2, tzw, rot)
	if (!ruined) {
		b.shape(new THREE.SphereGeometry(2.2, 8, 6), C.dome, new THREE.Matrix4().makeTranslation(tx, y + th + 1.2, tzw))
		b.box(0.15, 2, 0.15, C.church, tx, y + th + 4, tzw)
		b.box(1, 0.15, 0.15, C.church, tx, y + th + 4.4, tzw, rot)
	}
	ctx.place('church', x, z, w, d, rot, y, h + 3)
	ctx.place('church', tx, tzw, 4, 4, rot, y, th)
}

/** Low dry-stone wall, length `len` along `rot`; skipped where it would cross a road or water. */
export function stoneWall(ctx: BuildContext, x: number, z: number, rot: number, len: number) {
	const { t, b } = ctx
	const c = Math.cos(rot)
	const s = Math.sin(rot)
	for (let d = -len / 2; d <= len / 2; d += len / 4) if (isWetOrRoad(t, x + c * d, z + s * d)) return
	const y = t.height(x, z) - 0.2
	b.box(len, 1.1, 0.5, C.stone, x, y + 0.55, z, -rot)
	b.box(len, 0.12, 0.6, C.stone, x, y + 1.12, z, -rot)
	ctx.place('wall', x, z, len, 0.5, -rot, y, 1.1)
}

function well(ctx: BuildContext, x: number, z: number, rot: number) {
	const { t, b } = ctx
	const y = t.height(x, z) - 0.2
	b.box(1.6, 1.0, 1.6, C.stone, x, y + 0.5, z, rot)
	for (const s of [-1, 1]) {
		b.box(0.12, 2.2, 0.12, C.timber, x + s * 0.7 * Math.cos(rot), y + 1.6, z - s * 0.7 * Math.sin(rot), rot)
	}
	b.prism(2.2, 0.7, 2.2, C.roof, x, y + 2.6, z, rot)
	ctx.place('well', x, z, 1.6, 1.6, rot, y, 2.6)
}

/** A house and a barn facing each other across the yard. */
function farm(ctx: BuildContext, s: Settlement) {
	const { x: cx, z: cz, rot } = s
	const { rnd } = ctx
	const c = Math.cos(rot)
	const sn = Math.sin(rot)
	const hrot = rot + (rnd() - 0.5) * 0.2
	if (rnd() < ctx.t.kit.brick) brickHouse(ctx, cx + c * 9, cz + sn * 9, hrot)
	else house(ctx, cx + c * 9, cz + sn * 9, hrot, 'house')
	house(ctx, cx - c * 10, cz - sn * 10, rot + Math.PI / 2 + (rnd() - 0.5) * 0.2, 'barn')
	if (s.walls) stoneWall(ctx, cx - sn * 12, cz + c * 12, rot, 18)
}

/** Village: houses along two crossing lanes through the centre, a church or a well in the middle, garden walls. */
export function village(ctx: BuildContext, s: Settlement) {
	if (s.variant === 'farm') {
		farm(ctx, s)
		return
	}
	const { t, rnd } = ctx
	const { kit } = t
	const { x: cx, z: cz, r, rot } = s
	if (s.church && kit.chapel) chapel(ctx, cx, cz, rot)
	else if (s.church) church(ctx, cx, cz, rot, false)
	else well(ctx, cx, cz, rot)
	// Each placed building keeps `room` metres to the next one's (houses 7, a warehouse 11)
	const placed: { x: number; z: number; room: number }[] = [{ x: cx, z: cz, room: 7 }]
	const n = 8 + Math.floor(rnd() * 4)
	for (let k = 0; k < n * 4 && placed.length < n + 1; k++) {
		const lane = rnd() < 0.5 ? rot : rot + Math.PI / 2
		const along = (rnd() * 2 - 1) * r * 0.85
		const side = (rnd() < 0.5 ? 1 : -1) * (9 + rnd() * 6)
		const x = cx + Math.cos(lane) * along - Math.sin(lane) * side
		const z = cz + Math.sin(lane) * along + Math.cos(lane) * side
		const hrot = lane + (rnd() - 0.5) * 0.3
		const barn = rnd() < 0.25
		const store = barn && kit.warehouse
		const room = store ? 11 : 7
		const crowded = placed.some((p) => Math.hypot(p.x - x, p.z - z) < p.room + room)
		if (crowded || isWetOrRoad(t, x, z)) continue
		if (store) {
			const w = 9 + rnd()
			const d = 17 + rnd() * 4
			if (!footprintClear(t, x, z, w, d, hrot)) continue
			warehouse(ctx, x, z, hrot, w, d)
		} else if (barn) house(ctx, x, z, hrot, 'barn')
		else if (rnd() < kit.brick) brickHouse(ctx, x, z, hrot)
		else house(ctx, x, z, hrot, 'house')
		placed.push({ x, z, room })
	}
	if (kit.waterTower && !ctx.list.some((b) => b.kind === 'tower')) villageTower(ctx, s, placed)
	// Stone garden walls: low, solid, good for hull-down shooting
	if (!s.walls) return
	for (let k = 0; k < 3; k++) {
		const a = rot + k * 2.1 + rnd()
		const d = r * (0.6 + rnd() * 0.3)
		stoneWall(
			ctx,
			cx + Math.cos(a) * d,
			cz + Math.sin(a) * d,
			a + Math.PI / 2 + (rnd() - 0.5) * 0.5,
			12 + rnd() * 8,
		)
	}
}

/** The map's water tower at the edge of a village, clear of its houses and lanes. */
function villageTower(ctx: BuildContext, s: Settlement, placed: readonly { x: number; z: number; room: number }[]) {
	const { t, rnd } = ctx
	const a0 = rnd() * Math.PI * 2
	for (let k = 0; k < 8; k++) {
		const a = a0 + k * 0.8
		const d = s.r * (0.65 + (k % 2) * 0.2)
		const x = s.x + Math.cos(a) * d
		const z = s.z + Math.sin(a) * d
		if (placed.some((p) => Math.hypot(p.x - x, p.z - z) < p.room + 5)) continue
		if (!footprintClear(t, x, z, 6, 6, a)) continue
		waterTower(ctx, x, z, a)
		return
	}
}
