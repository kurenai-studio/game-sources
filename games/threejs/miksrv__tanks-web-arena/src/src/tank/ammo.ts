import * as THREE from 'three'
import { AMMO, AMMO_IDS, AMMO_LOAD, type AmmoId, type TankDef } from '../config'
import type { Tank } from './tank'

const { clamp } = THREE.MathUtils

/**
 * Rounds of each shell carried: the whole load from the reload (or the vehicle's own number), a share of APCR and of
 * the other common shell, the stock shell for the rest. Howitzers carry no APCR, rocket launchers HE salvoes only.
 */
export function ammoLoad(def: TankDef): Record<AmmoId, number> {
	const g = def.gun
	const total = g.rounds ?? Math.round(clamp(AMMO_LOAD.fireTime / g.reload, AMMO_LOAD.min, AMMO_LOAD.max))
	if (g.salvo) return { ap: 0, apcr: 0, he: total }
	const alt = Math.round(total * AMMO_LOAD.altShare)
	if (g.howitzer || g.derp) return { ap: alt, apcr: 0, he: total - alt }
	const apcr = Math.min(AMMO.apcr.count, Math.round(total * AMMO_LOAD.apcrShare))
	return { ap: total - apcr - alt, apcr, he: alt }
}

/** The vehicle's ammunition: the full load of each shell, what is left, and topping up at the base. */
export class AmmoRack {
	readonly full: Record<AmmoId, number>
	count: Record<AmmoId, number>
	private timer = 0

	constructor(def: TankDef) {
		this.full = ammoLoad(def)
		this.count = { ...this.full }
	}

	/** Shells left of the whole load, 0..1. */
	get share() {
		let left = 0
		let full = 0
		for (const id of AMMO_IDS) {
			left += this.count[id]
			full += this.full[id]
		}
		return full ? left / full : 0
	}

	refill() {
		this.count = { ...this.full }
		this.timer = 0
	}

	/** `stock` if any are left, otherwise whichever type has the most rounds. */
	fallback(stock: AmmoId): AmmoId {
		if (this.count[stock] > 0) return stock
		return AMMO_IDS.reduce((a, b) => (this.count[b] > this.count[a] ? b : a))
	}

	/** While `at` the base, every shell type gains a little each `resupplyStep`. Returns true while it adds rounds. */
	topUp(dt: number, at: boolean): boolean {
		if (!at || this.share >= 1) {
			this.timer = 0
			return false
		}
		this.timer += dt
		if (this.timer < AMMO_LOAD.resupplyStep) return true
		this.timer -= AMMO_LOAD.resupplyStep
		for (const id of AMMO_IDS) {
			const full = this.full[id]
			this.count[id] = Math.min(full, this.count[id] + Math.max(1, Math.round(full * AMMO_LOAD.resupplyShare)))
		}
		return true
	}
}

/** Used consumables (repair kit, medkit, extinguisher) come back together after `kitTime` at the base. */
function restockKits(t: Tank, dt: number, at: boolean): boolean {
	const used = !t.repairKit || !t.extinguisher || !t.crew.medkit
	if (!at || !used) {
		t.kitTimer = 0
		return false
	}
	t.kitTimer += dt
	if (t.kitTimer < AMMO_LOAD.kitTime) return true
	t.repairKit = t.extinguisher = t.crew.medkit = true
	t.kitTimer = 0
	return false
}

/** Standing (or crawling) inside the own base circle tops up shells and consumables; true while it does. */
export function resupply(t: Tank, dt: number, base: { x: number; z: number }): boolean {
	const near = Math.hypot(t.pos.x - base.x, t.pos.z - base.z) < AMMO_LOAD.resupplyRadius
	const at = t.alive && near && Math.abs(t.speed) <= AMMO_LOAD.resupplyMaxSpeed
	const shells = t.rack.topUp(dt, at)
	return restockKits(t, dt, at) || shells
}

/** Every tank at its own base takes on shells and consumables; true while the first one (the player) does. */
export function resupplyAll(tanks: Tank[], bases: readonly { x: number; z: number }[], dt: number): boolean {
	return tanks.map((t) => resupply(t, dt, bases[t.team]))[0] ?? false
}
