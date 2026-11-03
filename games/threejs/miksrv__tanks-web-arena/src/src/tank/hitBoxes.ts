import { ZONES, type TankDef } from '../config'
import { OBB } from '../world/obb'
import type { Tank } from './tank'

/** A vehicle's hit boxes: hull, turret (or casemate) and the commander's cupola on its roof, if it has one. */
export function createBoxes(def: TankDef, hullTop: number) {
	const s = def.shape
	const r = ZONES.cupolaR
	return {
		hull: new OBB(0, 0, s.hullW / 2, s.hullL / 2, 0, 0, hullTop),
		turret: new OBB(0, 0, s.tW / 2, s.tL / 2, 0, hullTop, hullTop + s.tH),
		cupola: s.turretLook?.cupola && !s.openTop ? new OBB(0, 0, r, r, 0, 0, ZONES.cupolaH) : null,
	}
}

/** Move the boxes onto the tank's pose (hull heading, turret traverse). */
export function placeBoxes(t: Tank) {
	const s = t.def.shape
	const top = t.view.hullTop
	t.hullBox.set(t.pos.x, t.pos.z, t.yaw)
	t.hullBox.y0 = t.pos.y
	t.hullBox.y1 = t.pos.y + top
	// The turret ring may sit off the centre line (+x = the hull's left, i.e. (fz, −fx) in the world).
	const side = s.turret ? (s.turretLook?.x ?? 0) : 0
	const cx = t.pos.x + t.fx * s.tZ + t.fz * side
	const cz = t.pos.z + t.fz * s.tZ - t.fx * side
	t.turretBox.set(cx, cz, s.turret ? t.worldTurretYaw : t.yaw)
	t.turretBox.y0 = t.pos.y + top
	t.turretBox.y1 = t.pos.y + top + s.tH
	const cup = t.cupolaBox
	const at = s.turretLook?.cupola
	if (cup && at) {
		// Cupola at (x, z) as shares of the turret width and length from its centre, +x = the left
		const [ax, az] = t.turretBox.toWorld(at[0] * s.tW, at[1] * s.tL)
		cup.set(ax, az, t.turretBox.rot)
		cup.y0 = t.turretBox.y1 - 0.05
		cup.y1 = t.turretBox.y1 + ZONES.cupolaH
	}
}
