import * as THREE from 'three'
import { SPOTTING } from '../config'
import type { Tank, WorldRefs } from '../tank/tank'

const eyeA = new THREE.Vector3()
const eyeB = new THREE.Vector3()

/**
 * WoT-style spotting: a tank is visible to a team when any teammate sees it; the team remembers it for a short while.
 * A bush hides a tank completely, unless it has just fired or an enemy has come right up to it.
 */
export class Spotting {
	private timer = 0

	update(dt: number, w: WorldRefs, time: number) {
		this.timer -= dt
		if (this.timer > 0) return
		this.timer = SPOTTING.interval
		const tanks = w.tanks
		for (const t of tanks) {
			t.spottedBy[0] = t.team === 0
			t.spottedBy[1] = t.team === 1
		}
		const inBush = tanks.map((t) => t.alive && t.camoFire <= 0 && w.props.bushAt(t.pos.x, t.pos.z))
		for (const a of tanks) {
			if (!a.alive) continue
			a.eye(eyeA)
			for (const [i, b] of tanks.entries()) {
				if (b.team === a.team || b.spottedBy[a.team]) continue
				if (!b.alive) {
					b.spottedBy[a.team] = true
					continue
				} // wrecks are common knowledge
				const d = Math.hypot(a.pos.x - b.pos.x, a.pos.z - b.pos.z)
				if (d > a.viewRange || (inBush[i] && d > SPOTTING.minRange)) continue
				const range = a.viewRange * (1 - b.camo(w.props, w.terrain))
				if (d > Math.max(SPOTTING.minRange, range)) continue
				b.eye(eyeB)
				if (d > SPOTTING.minRange) {
					if (!w.terrain.lineOfSight(eyeA.x, eyeA.y, eyeA.z, eyeB.x, eyeB.y, eyeB.z)) continue
					if (w.buildings.blocksLos(eyeA.x, eyeA.y, eyeA.z, eyeB.x, eyeB.y, eyeB.z)) continue
				}
				if (time - b.lastSeen[a.team] > SPOTTING.memory + 1) a.spots++
				b.spottedBy[a.team] = true
				b.spotter[a.team] = a
				b.lastSeen[a.team] = time
			}
		}
	}

	/** Visible (drawn, targetable) to `team` right now, including the fade-out memory. */
	static visibleTo(team: 0 | 1, t: Tank, time: number): boolean {
		return t.team === team || !t.alive || t.spottedBy[team] || time - t.lastSeen[team] < SPOTTING.memory
	}
}
