import * as THREE from 'three'
import type { Tank, WorldRefs } from '../tank/tank'

const from = new THREE.Vector3()
const to = new THREE.Vector3()

/** Can `me`'s gun see `t` — terrain, buildings and wrecks in the way? (from the gun, not the cupola) */
export function gunHasLos(w: WorldRefs, me: Tank, t: Tank): boolean {
	from.set(me.pos.x, me.pos.y + me.view.hullTop + me.view.gun.position.y, me.pos.z)
	to.set(t.pos.x, t.pos.y + t.view.hullTop * 0.7, t.pos.z)
	if (!w.terrain.lineOfSight(from.x, from.y, from.z, to.x, to.y, to.z)) return false
	if (w.buildings.blocksLos(from.x, from.y, from.z, to.x, to.y, to.z)) return false
	// Wrecks stop shells too: a burnt-out hull between us and the target is not a shot
	for (const o of w.tanks) {
		if (o.alive || o === t || !o.nearSegment(from.x, from.z, to.x, to.z)) continue
		if (o.hullBox.raySegment(from.x, from.y, from.z, to.x, to.y, to.z) >= 0) return false
		if (o.turretBox.raySegment(from.x, from.y, from.z, to.x, to.y, to.z) >= 0) return false
	}
	return true
}

/** Why there is no line of fire, for the debug readout (call after `gunHasLos` returned false). */
export function losBlocker(w: WorldRefs, me: Tank, t: Tank): 'los-bldg' | 'los-terrain' {
	from.set(me.pos.x, me.pos.y + me.view.hullTop + me.view.gun.position.y, me.pos.z)
	to.set(t.pos.x, t.pos.y + t.view.hullTop * 0.7, t.pos.z)
	return w.buildings.blocksLos(from.x, from.y, from.z, to.x, to.y, to.z) ? 'los-bldg' : 'los-terrain'
}

/** A living teammate of `me` on the line to `t`, nearer than `t`. */
export function friendInLine(w: WorldRefs, me: Tank, t: Tank, dist: number): boolean {
	from.set(me.pos.x, me.pos.y + me.view.hullTop + me.view.gun.position.y, me.pos.z)
	to.set(t.pos.x, t.pos.y + t.view.hullTop * 0.7, t.pos.z)
	for (const f of w.tanks) {
		if (f === me || f.team !== me.team || !f.alive) continue
		if (f.nearSegment(from.x, from.z, to.x, to.z) && Math.hypot(f.pos.x - me.pos.x, f.pos.z - me.pos.z) < dist) {
			return true
		}
	}
	return false
}
