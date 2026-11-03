import { COMBAT, CREW, ZONES, type AmmoDef, type ArmorDef, type CrewRole } from '../config'
import type { OBB } from '../world/obb'
import type { Tank } from '../tank/tank'

export type Face = 'front' | 'side' | 'rear' | 'top'
export type Part = 'hull' | 'turret' | 'tracks'
/** A spot inside a part with its own armour: the lower front plate, the gun mantlet, the cupola, Schürzen. */
export type Zone = 'lower' | 'mantlet' | 'cupola' | 'screen' | null

export interface ShellSpec {
	pen: number
	dmg: number
	caliber: number
	ammo: AmmoDef
}

/** Where a segment first enters a tank's boxes. */
export interface BoxHit {
	/** Segment parameter 0..1. */
	t: number
	x: number
	y: number
	z: number
	part: 'hull' | 'turret' | 'cupola'
	/** World normal of the struck face. */
	nx: number
	ny: number
	nz: number
}

export interface HitResult {
	t: number
	x: number
	y: number
	z: number
	part: Part
	face: Face
	zone: Zone
	nominal: number
	effective: number
	angle: number
	penetrated: boolean
	ricochet: boolean
	damage: number
	tracked: boolean
	fire: boolean
	gunHit: boolean
	/** The engine is damaged (slower) and the turret ring jammed (slow traverse). */
	engine: boolean
	ring: boolean
	/** Crew member wounded by this hit. */
	crew: CrewRole | null
	/** The ammunition rack: blown up (the tank is lost) or damaged (slower reload). */
	ammoRack: 'boom' | 'damaged' | null
}

const n = { x: 0, y: 0, z: 0 }
const TOP_NORMAL_Y = 0.7
const FRONT_DOT = 0.6 // |cos| beyond which a vertical face counts as front / rear
const TRACK_MARGIN = 0.1 // m above the running gear still counted as a track hit
const MIN_COS = 0.2 // cap on the slope multiplier (5×)
const OVERMATCH_NORMALIZATION = 1.4

/** Segment vs the tank's hull, turret and cupola boxes: the earliest entry, or null. No armour rolls. */
export function hitBoxes(
	tank: Tank,
	ax: number,
	ay: number,
	az: number,
	bx: number,
	by: number,
	bz: number,
): BoxHit | null {
	let best = -1
	let part: BoxHit['part'] = 'hull'
	let nx = 0
	let ny = 0
	let nz = 0
	const boxes: [OBB | null, BoxHit['part']][] = [
		[tank.hullBox, 'hull'],
		[tank.turretBox, 'turret'],
		[tank.cupolaBox, 'cupola'],
	]
	for (const [box, p] of boxes) {
		const t = box ? box.raySegment(ax, ay, az, bx, by, bz, n) : -1
		if (t < 0 || (best >= 0 && t >= best)) continue
		best = t
		part = p
		;({ x: nx, y: ny, z: nz } = n)
	}
	if (best < 0) return null
	const x = ax + (bx - ax) * best
	const y = ay + (by - ay) * best
	const z = az + (bz - az) * best
	return { t: best, x, y, z, part, nx, ny, nz }
}

/** Which face of the hull (or turret) a box normal belongs to. */
function faceOf(tank: Tank, h: BoxHit): Face {
	if (h.ny > TOP_NORMAL_Y) return 'top'
	const fwd = h.part === 'hull' ? { x: tank.fx, z: tank.fz } : tank.turretForward()
	const d = h.nx * fwd.x + h.nz * fwd.z
	return d > FRONT_DOT ? 'front' : d < -FRONT_DOT ? 'rear' : 'side'
}

/** Nominal plate thickness of a face. The roof is shared by hull and turret. */
export function plateArmor(a: ArmorDef, part: 'hull' | 'turret', face: Face): number {
	if (face === 'top') return a.top
	if (part === 'turret') return face === 'front' ? a.tFront : face === 'rear' ? a.tRear : a.tSide
	return face === 'front' ? a.front : face === 'rear' ? a.rear : a.side
}

/** A point in a box's frame: across (+ = the vehicle's left), along (+ = forward) and up from the box bottom. */
function localPoint(box: OBB, x: number, y: number, z: number) {
	const dx = x - box.x
	const dz = z - box.z
	return { across: dx * box.cos - dz * box.sin, along: dx * box.sin + dz * box.cos, up: y - box.y0 }
}

/** The plate a box hit lands on: part, face, the zone inside it and its nominal thickness; the modules behind it. */
export interface Plate {
	part: Part
	face: Face
	zone: Zone
	nominal: number
	/** Over the engine compartment (fire and engine damage). */
	engine: boolean
	/** Low on a rotating turret (the ring). */
	ring: boolean
}

export function plateAt(tank: Tank, h: BoxHit): Plate {
	const a = tank.def.armor
	const face = faceOf(tank, h)
	if (h.part === 'cupola') {
		const nominal = face === 'top' ? a.top : a.tSide * ZONES.cupola
		return { part: 'turret', face, zone: 'cupola', nominal, engine: false, ring: false }
	}
	return h.part === 'turret' ? turretPlate(tank, h, face) : hullPlate(tank, h, face)
}

/** Turret (or casemate): the mantlet in the middle of the front, Schürzen around it, the ring low down. */
function turretPlate(tank: Tank, h: BoxHit, face: Face): Plate {
	const a = tank.def.armor
	const s = tank.def.shape
	const p = localPoint(tank.turretBox, h.x, h.y, h.z)
	const look = s.gunLook
	const mountY = s.tH * (s.turretLook?.mountY ?? 0.5)
	const mantlet =
		face === 'front' &&
		!!look &&
		look.mantlet !== 'none' &&
		Math.abs(p.across) < (s.tW * (look.mantletW ?? ZONES.mantletW)) / 2 &&
		Math.abs(p.up - mountY) < s.tH * ZONES.mantletBand
	const screen = !!s.turretLook?.skirts && (face === 'side' || face === 'rear')
	const zone: Zone = mantlet ? 'mantlet' : screen ? 'screen' : null
	const nominal = plateArmor(a, 'turret', face) * (mantlet ? ZONES.mantlet : 1)
	const ring = s.turret && face !== 'top' && p.up < s.tH * COMBAT.ringShare
	return { part: 'turret', face, zone, nominal, engine: false, ring }
}

/** Hull: the lower front plate, the running gear low on the sides, Schürzen, the engine at the back. */
function hullPlate(tank: Tank, h: BoxHit, face: Face): Plate {
	const a = tank.def.armor
	const s = tank.def.shape
	const p = localPoint(tank.hullBox, h.x, h.y, h.z)
	const top = tank.hullBox.y1 - tank.hullBox.y0
	const lower = face === 'front' && p.up < top * ZONES.lowerShare
	// Running gear: low side hits
	const tracks = face === 'side' && p.up < s.trackH + TRACK_MARGIN
	const screen = !!s.hullLook.skirts && face === 'side'
	const zone: Zone = lower ? 'lower' : screen ? 'screen' : null
	const nominal = lower ? (a.lowerFront ?? a.front * ZONES.lowerFront) : plateArmor(a, 'hull', face)
	const engine = face === 'rear' || (face === 'side' && p.along < s.hullL * (COMBAT.engineShare - 0.5))
	return { part: tracks ? 'tracks' : 'hull', face, zone, nominal, engine, ring: false }
}

/**
 * Angle rules: a ricochet beyond the shell's limit unless it overmatches (calibre ≥ 3 × plate); otherwise the angle
 * is normalised toward the plate normal and the effective thickness grows as 1 / cos.
 */
function slopeArmor(nominal: number, angle: number, shell: ShellSpec) {
	const am = shell.ammo
	const overmatch = shell.caliber >= nominal * COMBAT.overmatch
	if (!am.he && angle > am.ricochet && !overmatch) return { ricochet: true, effective: nominal, angle }
	const norm = overmatch ? am.normalization * OVERMATCH_NORMALIZATION : am.normalization
	const a = Math.max(0, angle - norm)
	return { ricochet: false, effective: nominal / Math.max(MIN_COS, Math.cos(a)), angle: a }
}

/** Armour a shell along (dx, dy, dz) meets at a box hit, without dice: a Schürzen plate adds to it against AP. */
export function armorAt(tank: Tank, h: BoxHit, dx: number, dy: number, dz: number, shell: ShellSpec) {
	const plate = plateAt(tank, h)
	const len = Math.hypot(dx, dy, dz) || 1
	const cosA = Math.min(1, Math.abs((dx * h.nx + dy * h.ny + dz * h.nz) / len))
	const slope = slopeArmor(plate.nominal, Math.acos(cosA), shell)
	const screened = plate.zone === 'screen' && !slope.ricochet
	const effective = slope.effective + (screened && !shell.ammo.he ? ZONES.screen : 0)
	// HE bursts on the screen and never goes through
	const blocked = screened && shell.ammo.he
	return { ...plate, ...slope, effective, blocked }
}

const roll = (k: number) => 1 + (Math.random() * 2 - 1) * k
const pick = <T>(a: readonly T[]): T => a[Math.floor(Math.random() * a.length)]

/** Who sits behind the struck plate: the turret crew, the driver up front, driver and loader along the sides. */
function crewBehind(part: Part, face: Face, zone: Zone): readonly CrewRole[] {
	if (zone === 'cupola') return ['commander']
	if (part === 'turret') return ['commander', 'gunner', 'loader']
	if (part === 'tracks' || face === 'rear') return []
	if (face === 'front') return ['driver']
	if (face === 'top') return ['commander', 'gunner', 'loader', 'driver']
	return ['driver', 'loader']
}

/** The rack sits low along the hull sides and in the turret bustle. */
function rackRoll(part: Part, face: Face, zone: Zone): HitResult['ammoRack'] {
	const turret = part === 'turret' && zone !== 'cupola' && (face === 'side' || face === 'rear')
	const exposed = (part === 'hull' && face === 'side') || turret
	if (!exposed) return null
	const r = Math.random()
	return r < COMBAT.ammoRackChance ? 'boom' : r < COMBAT.ammoRackChance + COMBAT.rackDamageChance ? 'damaged' : null
}

/** Segment vs the tank's boxes. Returns the earliest hit and resolves armour (with dice rolls). */
export function testShell(
	tank: Tank,
	ax: number,
	ay: number,
	az: number,
	bx: number,
	by: number,
	bz: number,
	shell: ShellSpec,
): HitResult | null {
	const h = hitBoxes(tank, ax, ay, az, bx, by, bz)
	if (!h) return null
	const plate = armorAt(tank, h, bx - ax, by - ay, bz - az, shell)
	const { part, face, zone, nominal, ricochet, effective, angle, blocked } = plate
	const pen = shell.pen * roll(COMBAT.penRng)
	const penetrated = !ricochet && !blocked && pen >= effective
	let damage = 0
	if (penetrated) damage = shell.dmg * roll(COMBAT.dmgRng)
	else if (shell.ammo.he && !ricochet) {
		const raw = shell.dmg * COMBAT.heNonPenFactor * roll(COMBAT.dmgRng) - effective * 1.1
		damage = Math.max(0, raw) * (blocked ? ZONES.screenHe : 1)
	}
	let tracked = false
	if (part === 'tracks') {
		damage *= COMBAT.trackAbsorb
		tracked = Math.random() < COMBAT.trackHitChance
	}
	const engineHit = penetrated && plate.engine
	const fire = engineHit && Math.random() < COMBAT.engineFireChance
	const engine = engineHit && !fire && Math.random() < COMBAT.engineHitChance
	const ring = penetrated && plate.ring && Math.random() < COMBAT.ringChance
	const gunChance = zone === 'mantlet' ? COMBAT.mantletGunChance : COMBAT.gunDamageChance
	const gunHit = penetrated && part === 'turret' && face === 'front' && Math.random() < gunChance
	const seats = penetrated ? crewBehind(part, face, zone) : []
	const crewChance = zone === 'cupola' ? ZONES.cupolaWound : CREW.hitChance
	const crew = seats.length && Math.random() < crewChance ? pick(seats) : null
	const ammoRack = penetrated ? rackRoll(part, face, zone) : null
	return {
		t: h.t,
		x: h.x,
		y: h.y,
		z: h.z,
		part,
		face: part === 'tracks' ? 'side' : face,
		zone,
		nominal,
		effective,
		angle,
		penetrated,
		ricochet,
		damage,
		tracked,
		fire,
		gunHit,
		engine,
		ring,
		crew,
		ammoRack,
	}
}

/** Armour `me`'s shell would meet at tank `t`, from the facing (hull and turret plates averaged). */
export function estimateArmor(me: Tank, t: Tank): number {
	const dx = me.pos.x - t.pos.x
	const dz = me.pos.z - t.pos.z
	const l = Math.hypot(dx, dz) || 1
	const c = (dx * t.fx + dz * t.fz) / l
	const a = t.def.armor
	const nominal = c > 0.5 ? (a.front + a.tFront) / 2 : c < -0.5 ? (a.rear + a.tRear) / 2 : (a.side + a.tSide) / 2
	const cosA = c > 0.5 || c < -0.5 ? Math.abs(c) : Math.sqrt(Math.max(0, 1 - c * c))
	return nominal / Math.max(0.35, cosA)
}

/** Reticle colour class for `me` aiming at `t`: green / orange / red by the chance to penetrate. */
export function reticleClass(me: Tank, t: Tank): 'green' | 'orange' | 'red' {
	const eff = estimateArmor(me, t)
	const p = me.ammoDef.he ? (me.shellPen >= eff ? 1 : 0.5) : penChance(me.shellPen, eff)
	return p > 0.7 ? 'green' : p > 0.3 ? 'orange' : 'red'
}

interface Point {
	x: number
	y: number
	z: number
}
const AIM_PAST = 2 // m the aim ray runs on past the reticle point, to be sure to enter the box

/**
 * The plate under the reticle: a shell from `from` (the muzzle) toward `at` (where the reticle sits on `t`),
 * with `me`'s current shell. Null when that line misses `t` (then the facing estimate stands in).
 */
export function aimedArmor(me: Tank, t: Tank, from: Point, at: Point) {
	const dx = at.x - from.x
	const dy = at.y - from.y
	const dz = at.z - from.z
	const k = 1 + AIM_PAST / (Math.hypot(dx, dy, dz) || 1)
	const h = hitBoxes(t, from.x, from.y, from.z, from.x + dx * k, from.y + dy * k, from.z + dz * k)
	if (!h) return null
	const shell = { pen: me.shellPen, dmg: me.shellDmg, caliber: me.def.gun.caliber, ammo: me.ammoDef }
	return armorAt(t, h, dx, dy, dz, shell)
}

/** Reticle colour class from the plate under the reticle (see `aimedArmor`). */
export function plateClass(me: Tank, plate: NonNullable<ReturnType<typeof aimedArmor>>): 'green' | 'orange' | 'red' {
	if (plate.ricochet || plate.blocked) return me.ammoDef.he && !plate.ricochet ? 'orange' : 'red'
	const p = me.ammoDef.he ? (me.shellPen >= plate.effective ? 1 : 0.5) : penChance(me.shellPen, plate.effective)
	return p > 0.7 ? 'green' : p > 0.3 ? 'orange' : 'red'
}

/** Rough chance (0..1) that a shell with `pen` beats `effective` armour, for the reticle colour. */
export function penChance(pen: number, effective: number): number {
	const lo = pen * (1 - COMBAT.penRng)
	const hi = pen * (1 + COMBAT.penRng)
	if (effective <= lo) return 1
	if (effective >= hi) return 0
	return (hi - effective) / (hi - lo)
}
