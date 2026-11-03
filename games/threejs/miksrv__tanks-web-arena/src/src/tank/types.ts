import type * as THREE from 'three'
import type { AmmoDef } from '../config'
import type { CaptureZone } from '../game/capture'
import type { Buildings } from '../world/buildings'
import type { Props } from '../world/props'
import type { Terrain } from '../world/terrain'
import type { Tank } from './tank'

/** The world as the simulation sees it. */
export interface WorldRefs {
	terrain: Terrain
	props: Props
	buildings: Buildings
	tanks: Tank[]
	/** Base circles of the battle (empty outside it). */
	zones: CaptureZone[]
}

/** One projectile leaving the muzzle. */
export interface ShotParams {
	origin: THREE.Vector3
	dir: THREE.Vector3
	speed: number
	ammo: AmmoDef
	pen: number
	dmg: number
	caliber: number
	splash: number
	howitzer: boolean
	rocket: boolean
}
