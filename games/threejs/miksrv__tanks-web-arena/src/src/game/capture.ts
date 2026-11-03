import * as THREE from 'three'
import { CAPTURE, type BattleMode } from '../config'
import type { Tank } from '../tank/tank'
import type { Terrain } from '../world/terrain'

/**
 * A base circle. `owner` is the side whose base it is (−1: neutral, either side may take it). The capture points
 * belong to the capturing side: they stay when its tanks leave the circle or are hit, and are lost only when the
 * other side stands in the circle with none of the capturers left in it.
 */
export interface CaptureZone {
	x: number
	z: number
	owner: 0 | 1 | -1
	/** 0…CAPTURE.points. */
	points: number
	/** The side taking it right now, or null. */
	capturing: 0 | 1 | null
	/** Capturers in the circle, but no more of them than of the other side: the capture stands still. */
	contested: boolean
}

const TEAM_FLAG = ['#b8312a', '#4a6d8c'] as const
const NEUTRAL_FLAG = '#e8e2cc'
const POLE_H = 9
const STAKES = 28

/** The base circles of a map for its battle mode. */
export function zonesFor(t: Terrain, mode: BattleMode): CaptureZone[] {
	const zone = (x: number, z: number, owner: CaptureZone['owner']): CaptureZone => ({
		x,
		z,
		owner,
		points: 0,
		capturing: null,
		contested: false,
	})
	if (mode === 'encounter' && t.neutral) return [zone(t.neutral.x, t.neutral.z, -1)]
	if (mode === 'assault') {
		const b = t.bases[t.defender]
		return [zone(b.x, b.z, t.defender)]
	}
	return t.bases.map((b, i) => zone(b.x, b.z, i as 0 | 1))
}

/** Can `team` take this circle? */
export const capturableBy = (z: CaptureZone, team: 0 | 1) => z.owner === -1 || z.owner !== team

export const inZone = (z: CaptureZone, x: number, zz: number) => Math.hypot(x - z.x, zz - z.z) < CAPTURE.radius

/**
 * Base capture for one battle. Capturers outnumbering the other side in the circle add points at `rate` per tank of
 * the difference (up to `maxTanks`); with as many or more of the other side the capture stands still; the other side
 * alone in the circle knocks it down to zero. The side that completes a capture wins.
 */
export class Capture {
	/** A capture was knocked down by `by` standing in the circle (who earns the defence points). */
	onReset?: (zone: CaptureZone, by: Tank, points: number) => void

	constructor(readonly zones: CaptureZone[]) {}

	/** Advance every circle; returns the side that has just captured one, else null. */
	update(dt: number, tanks: Tank[]): 0 | 1 | null {
		for (const z of this.zones) {
			const won = this.updateZone(z, dt, tanks)
			if (won !== null) return won
		}
		return null
	}

	private updateZone(z: CaptureZone, dt: number, tanks: Tank[]): 0 | 1 | null {
		const inside = tanks.filter((t) => t.alive && inZone(z, t.pos.x, t.pos.z))
		const count = [0, 0]
		for (const t of inside) count[t.team]++
		z.capturing ??= challenger(z, count)
		z.contested = false
		const side = z.capturing
		if (side === null) return null
		const attackers = count[side]
		const defenders = count[1 - side]
		if (attackers > defenders) {
			const gain = CAPTURE.rate * dt * Math.min(attackers - defenders, CAPTURE.maxTanks)
			z.points = Math.min(CAPTURE.points, z.points + gain)
			for (const t of inside) if (t.team === side) t.stats.capture += gain / attackers
		} else if (attackers > 0) z.contested = true
		else if (defenders > 0) {
			// Only the other side in the circle: the capture is knocked down, the defenders share the credit
			const lost = z.points
			z.points = 0
			z.capturing = null
			if (lost > 0) {
				for (const t of inside) {
					t.stats.defense += lost / defenders
					this.onReset?.(z, t, lost / defenders)
				}
			}
		}
		return z.points >= CAPTURE.points ? side : null
	}
}

/** Who starts taking a circle nobody is taking: the enemy of its owner if in it; in a neutral one, the side with more tanks there. */
function challenger(z: CaptureZone, count: number[]): 0 | 1 | null {
	if (z.owner !== -1) return count[1 - z.owner] > 0 ? ((1 - z.owner) as 0 | 1) : null
	return count[0] > count[1] ? 0 : count[1] > count[0] ? 1 : null
}

/** The base markers of the current battle in the scene: shown at round start, freed at the next. */
export class ZoneMarkers {
	private group: THREE.Group | null = null

	constructor(private readonly parent: THREE.Object3D) {}

	show(zones: CaptureZone[], t: Terrain) {
		this.clear()
		this.group = buildZoneMeshes(zones, t)
		this.parent.add(this.group)
	}

	clear() {
		if (!this.group) return
		this.parent.remove(this.group)
		disposeZoneMeshes(this.group)
		this.group = null
	}
}

/** Flags and the ring of stakes for each circle; the ring band lies on the ground. */
function buildZoneMeshes(zones: CaptureZone[], t: Terrain): THREE.Group {
	const g = new THREE.Group()
	const pole = new THREE.CylinderGeometry(0.08, 0.1, POLE_H, 6).translate(0, POLE_H / 2, 0)
	const flag = new THREE.PlaneGeometry(2.6, 1.6).translate(1.3, POLE_H - 1, 0)
	const stake = new THREE.CylinderGeometry(0.07, 0.07, 1.2, 5).translate(0, 0.6, 0)
	const wood = new THREE.MeshStandardMaterial({ color: '#5a4a36', roughness: 0.9 })
	for (const z of zones) {
		const y = t.height(z.x, z.z)
		const colour = z.owner === -1 ? NEUTRAL_FLAG : TEAM_FLAG[z.owner]
		const p = new THREE.Mesh(pole, wood)
		p.position.set(z.x, y, z.z)
		p.castShadow = true
		const cloth = new THREE.MeshStandardMaterial({ color: colour, side: THREE.DoubleSide, roughness: 0.9 })
		const f = new THREE.Mesh(flag, cloth)
		f.position.copy(p.position)
		f.rotation.y = Math.random() * Math.PI * 2
		f.castShadow = true
		const stakes = new THREE.InstancedMesh(stake, wood, STAKES)
		const m = new THREE.Matrix4()
		for (let i = 0; i < STAKES; i++) {
			const a = (i / STAKES) * Math.PI * 2
			const sx = z.x + Math.cos(a) * CAPTURE.radius
			const sz = z.z + Math.sin(a) * CAPTURE.radius
			stakes.setMatrixAt(i, m.makeTranslation(sx, t.height(sx, sz), sz))
		}
		stakes.castShadow = true
		g.add(p, f, stakes, groundRing(z, t, colour))
	}
	return g
}

/** A painted band on the ground along the circle, each vertex set onto the terrain. */
function groundRing(z: CaptureZone, t: Terrain, colour: string): THREE.Mesh {
	const geo = new THREE.RingGeometry(CAPTURE.radius - 0.5, CAPTURE.radius + 0.5, 72, 1).rotateX(-Math.PI / 2)
	const pos = geo.attributes.position as THREE.BufferAttribute
	for (let i = 0; i < pos.count; i++) {
		const x = z.x + pos.getX(i)
		const zz = z.z + pos.getZ(i)
		pos.setXYZ(i, x, t.height(x, zz) + 0.12, zz)
	}
	const mat = new THREE.MeshBasicMaterial({ color: colour, transparent: true, opacity: 0.55, depthWrite: false })
	return new THREE.Mesh(geo, mat)
}

/** Free the zone meshes' GPU buffers. */
function disposeZoneMeshes(g: THREE.Group) {
	g.traverse((o) => {
		if (!(o instanceof THREE.Mesh)) return
		;(o.geometry as THREE.BufferGeometry).dispose()
		;(o.material as THREE.Material).dispose()
	})
}
