import * as THREE from 'three'
import type { CamMode } from '../camera'
import { WEATHER, type Weather } from '../config'
import type { Season } from '../world/terrain'

interface SkyDef {
	bg: string
	fog: string
	fogNear: number
	fogFar: number
	sky: string
	ground: string
	sun: string
	sunI: number
}

/** Sky, haze and light per season. */
const SKY: Record<Season, SkyDef> = {
	summer: {
		bg: '#9fbdd6',
		fog: '#aac4d8',
		fogNear: 250,
		fogFar: 1100,
		sky: '#cfe0f0',
		ground: '#4a5a3a',
		sun: '#fff1dc',
		sunI: 1.9,
	},
	autumn: {
		bg: '#b6c0ca',
		fog: '#c2c9d0',
		fogNear: 220,
		fogFar: 1000,
		sky: '#d8dde3',
		ground: '#5a4a2a',
		sun: '#ffe2bc',
		sunI: 1.6,
	},
	winter: {
		bg: '#c8d1d9',
		fog: '#d5dce3',
		fogNear: 180,
		fogFar: 850,
		sky: '#e2e7ee',
		ground: '#8a8f96',
		sun: '#eef2fa',
		sunI: 1.45,
	},
}

/**
 * How the weather and the hour change the season's sky: a tint mixed into the sky colours (`k` = share), light
 * multipliers and, for dawn and dusk, a low sun on its own bearing.
 */
interface WeatherLook {
	tint?: string
	k?: number
	sun?: string
	sunI: number
	hemiI: number
	sunOffset?: { x: number; y: number; z: number }
	/** Fog colour pulled toward the background (fog banks look solid). */
	fogToBg?: boolean
}
const LOOK: Record<Weather, WeatherLook> = {
	clear: { sunI: 1, hemiI: 1 },
	overcast: { tint: '#9aa3aa', k: 0.55, sunI: 0.45, hemiI: 1.25 },
	dawn: { tint: '#e9b79a', k: 0.4, sun: '#ffc49a', sunI: 1, hemiI: 1.05, sunOffset: { x: 170, y: 62, z: 50 } },
	dusk: { tint: '#c98663', k: 0.45, sun: '#ff9a5a', sunI: 1, hemiI: 1, sunOffset: { x: -165, y: 52, z: -60 } },
	fog: { tint: '#b9c0c5', k: 0.75, sunI: 0.5, hemiI: 1.2, fogToBg: true },
	rain: { tint: '#7f8a92', k: 0.7, sunI: 0.3, hemiI: 1.05 },
	snow: { tint: '#c4cbd2', k: 0.6, sunI: 0.4, hemiI: 1.2, fogToBg: true },
}

/** The satellite view looks down from a few hundred metres: haze that suits the ground view would wash it out. */
const ARTY_FOG = { near: 900, far: 2400 }
/** Sun offset from the camera target; the shadow box travels with it. */
const SUN_OFFSET = { x: 90, y: 180, z: 60 }
const tint = new THREE.Color()
const SHADOW_HALF_SIZE = 110

/** Scene root with the sky light, the shadow-casting sun and the fog of the season and the weather. */
export class Environment {
	readonly scene = new THREE.Scene()
	readonly hemi = new THREE.HemisphereLight('#cfe0f0', '#4a5a3a', 0.7)
	readonly sun = new THREE.DirectionalLight('#fff1dc', 1.9)
	private readonly fog = new THREE.Fog('#aac4d8', 250, 1100)
	private readonly background = new THREE.Color('#9fbdd6')
	private fogBase = { near: 250, far: 1100 }
	private artyFog = ARTY_FOG
	private sunOffset = SUN_OFFSET

	constructor() {
		this.scene.background = this.background
		this.scene.fog = this.fog
		this.scene.add(this.hemi)
		this.configureSun()
		this.scene.add(this.sun, this.sun.target)
	}

	private configureSun() {
		const { sun } = this
		sun.castShadow = true
		sun.shadow.mapSize.set(2048, 2048)
		sun.shadow.camera.near = 20
		sun.shadow.camera.far = 500
		sun.shadow.camera.left = sun.shadow.camera.bottom = -SHADOW_HALF_SIZE
		sun.shadow.camera.right = sun.shadow.camera.top = SHADOW_HALF_SIZE
		sun.shadow.bias = -0.0008
	}

	/** The season's sky, then the weather and the hour on top of it. */
	applyMap(season: Season, weather: Weather) {
		const k = SKY[season]
		const look = LOOK[weather]
		const w = WEATHER[weather]
		const mixed = (c: THREE.Color, hex: string) => {
			c.set(hex)
			if (look.tint) c.lerp(tint.set(look.tint), look.k ?? 0)
			return c
		}
		mixed(this.background, k.bg)
		mixed(this.fog.color, k.fog)
		if (look.fogToBg) this.fog.color.copy(this.background)
		this.fogBase = { near: k.fogNear * w.fog * (look.fogToBg ? 0.3 : 1), far: k.fogFar * w.fog }
		this.fog.near = this.fogBase.near
		this.fog.far = this.fogBase.far
		this.artyFog = { near: ARTY_FOG.near * w.artyFog, far: ARTY_FOG.far * w.artyFog }
		mixed(this.hemi.color, k.sky)
		this.hemi.groundColor.set(k.ground)
		this.hemi.intensity = 0.7 * look.hemiI
		this.sun.color.set(look.sun ?? k.sun)
		this.sun.intensity = k.sunI * look.sunI
		this.sunOffset = look.sunOffset ?? SUN_OFFSET
	}

	/** Weak GPUs: a smaller shadow map for the rest of the session. */
	lowerShadowQuality() {
		this.sun.shadow.mapSize.set(1024, 1024)
		this.sun.shadow.map?.dispose()
		this.sun.shadow.map = null
	}

	/** Per frame: ease the fog toward the camera mode's range and keep the sun over the camera target. */
	update(dt: number, mode: CamMode, target: THREE.Vector3) {
		const want = mode === 'arty' ? this.artyFog : this.fogBase
		const k = Math.min(1, 4 * dt)
		this.fog.near += (want.near - this.fog.near) * k
		this.fog.far += (want.far - this.fog.far) * k
		const o = this.sunOffset
		this.sun.position.set(target.x + o.x, o.y, target.z + o.z)
		this.sun.target.position.set(target.x, 0, target.z)
		this.sun.target.updateMatrixWorld()
	}
}
