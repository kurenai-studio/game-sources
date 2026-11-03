// Shared data types of the vehicle and ammunition tables.

export type Nation = 'ussr' | 'germany'
export type Role = 'light' | 'medium' | 'heavy' | 'td' | 'spg'
export type AmmoId = 'ap' | 'apcr' | 'he'

export interface GunDef {
	caliber: number // mm, cosmetic + overmatch
	pen: number // mm at 100 m with the stock shell
	dmg: number // hp per penetrating hit
	reload: number // s
	dispersion: number // m at 100 m when fully aimed
	aimTime: number // s to shrink the reticle to its minimum
	shellSpeed: number // m/s
	arc: number // rad, horizontal gun traverse (π for a full turret)
	elevMin: number // rad, depression (negative)
	elevMax: number // rad, elevation
	howitzer?: boolean // indirect fire (SPG): HE by default, satellite view, high arc
	derp?: boolean // direct-fire howitzer (KV-2, StuH 42): HE by default, big splash, no indirect view
	salvo?: number // rocket launcher: one trigger pull fires this many rockets in a ripple (HE only)
	salvoInterval?: number // s between rockets of a salvo
	bloomShot?: number // reticle bloom per shot (default DRIVE.bloomShot); small for autocannons
	splash?: number // m, HE splash radius
	rounds?: number // rounds carried (default from the reload, AMMO_LOAD)
}

export interface ArmorDef {
	front: number
	side: number
	rear: number
	top: number
	tFront: number
	tSide: number
	tRear: number
	lowerFront?: number // lower front plate (default ZONES.lowerFront × front)
}

/** A corner of a part's side outline, normalised: z 0 = rear … 1 = front, y 0 = bottom … 1 = top. */
export type OutlinePoint = readonly [z: number, y: number]

/** The armoured hull over the tracks (or the lorry body). */
export interface HullLook {
	/** Side outline of the upper hull, normalised to hullL × hullH (bottom = the fender line, top = the roof). */
	outline: OutlinePoint[]
	/** Roof width as a fraction of hullW: below 1 for sloped side plates (T-34, Panther). */
	roofW?: number
	/** Run (m) of the lower nose plate between the tracks; long on the pointed Soviet noses. */
	lowerNose?: number
	/** External fuel drums per side on the rear hull. */
	drums?: number
	/** Spare track links hung on the nose. */
	spareTracks?: boolean
	/** Schürzen side plates. */
	skirts?: boolean
}

/**
 * Turret or casemate. `welded`: the side outline extruded across the width, narrowing to `roofW` at the roof.
 * `round`: a cast or faceted turret, a `facets`-sided cylinder in plan (6 = the T-34 "nut", 12 = cast).
 */
export interface TurretLook {
	kind: 'welded' | 'round'
	/** Side outline normalised to tL × tH (welded turrets and every casemate). */
	outline?: OutlinePoint[]
	/** Roof width as a fraction of the base: sloped side plates. */
	roofW?: number
	/** Sides of a round turret in plan. */
	facets?: number
	/** Rear overhang of a round turret, m. */
	bustle?: number
	/** Turret ring offset sideways, m (+ = to the left; the T-60 and T-70 turrets sit left of the centre line). */
	x?: number
	/** Commander's cupola at (x, z) as fractions of tW and tL from the centre (+x = left); none = a plain hatch. */
	cupola?: readonly [number, number]
	/** Two round roof hatches side by side ("Mickey Mouse", T-34 1942). */
	twinHatches?: boolean
	/** Stowage bin on the turret rear. */
	stowage?: boolean
	/** Schürzen around the turret sides and rear (Pz. IV H). */
	skirts?: boolean
	/** Spare track links on the turret sides (Tiger). */
	sideTracks?: boolean
	/** Gun trunnion height as a fraction of tH. */
	mountY?: number
}

export type Mantlet = 'box' | 'round' | 'ball' | 'saukopf' | 'shield' | 'none'
export type MuzzleBrake = 'none' | 'single' | 'double' | 'multi'

export interface GunLook {
	/** Box plate (Pz. III/IV, Tiger), round casting (Panther, IS-2), ball mount, Saukopf cone, open gun shield. */
	mantlet: Mantlet
	/** Mantlet width as a fraction of the turret width (box, round, shield). */
	mantletW?: number
	brake: MuzzleBrake
	/** Thick recoil sleeve in front of the mantlet, m (howitzers, ML-20S). */
	sleeve?: number
}

export interface RunningGear {
	kind: 'tracks' | 'halftrack' | 'truck'
	/** Road wheels per side; a lorry has one wheel per entry of `axles`. */
	wheels: number
	wheelR: number
	/** Spread of the road wheels from first to last centre, as a fraction of hullL. */
	span?: number
	/** Shift of the road wheel group forward, fraction of hullL. */
	shift?: number
	/** Even spacing, pairs on bogies (Pz. IV, Ferdinand) or overlapping rows (Tiger, Panther, Luchs). */
	layout?: 'even' | 'paired' | 'interleaved'
	/** Return rollers per side under the top run. */
	rollers?: number
	/** Drive sprocket: front (German, T-60/70, SU-76) or rear (T-34, KV, IS, Ferdinand). */
	sprocket?: 'front' | 'rear'
	/** Lorry axles (z as a fraction of hullL); every axle behind the first carries twin wheels. */
	axles?: number[]
	/** Half-track: z of the steered front axle; the track runs under the rear half. */
	frontAxle?: number
}

/**
 * The vehicle's size and silhouette. The top-level numbers are also the hit boxes and the collision footprint;
 * the `*Look` parts only shape the model. Model frame: +z forward, +y up, +x the left side.
 */
export interface ShapeDef {
	hullL: number
	hullW: number
	hullH: number // upper hull above the fender line
	trackH: number // height of the running gear
	turret: boolean // false = casemate (fixed superstructure; only the gun traverses)
	tW: number
	tL: number
	tH: number
	tZ: number // turret / casemate size and fore-aft offset
	gunLen: number
	gunR: number
	openTop: boolean // fighting compartment without a roof
	launcher?: 'rails' | 'tubes' // rocket launcher instead of a gun: Katyusha rails or Nebelwerfer tubes
	hullLook: HullLook
	turretLook?: TurretLook // not used by rocket launchers
	gunLook?: GunLook
	running: RunningGear
}

export interface TankDef {
	id: string
	nation: Nation
	role: Role
	name: string
	hp: number
	rating: number // battle rating for team balancing (≈ 2 light 1941 … 7 heavy 1944)
	speed: number // m/s forward
	reverse: number // m/s
	accel: number // m/s²
	hullTurn: number // rad/s
	turretTurn: number // rad/s
	gun: GunDef
	armor: ArmorDef
	viewRange: number // m
	camo: number // 0..1 base concealment
	shape: ShapeDef
}

// Shells: multipliers on the gun's stock values. Howitzers treat HE as stock and AP as the alternative.
export interface AmmoDef {
	id: AmmoId
	label: string
	key: string
	penMult: number
	dmgMult: number
	speedMult: number
	normalization: number
	ricochet: number
	he: boolean
	count: number
}
