import * as THREE from 'three'
import { TERRAIN_RES, WORLD_HALF } from '../../config'
import type { Simplex2D } from '../../core/noise'
import { PALETTE } from './palette'
import { BIOME_ID, WATER_LEVEL, type Biome, type Season } from './types'

const { smoothstep } = THREE.MathUtils

/** What the mesh builder reads from the terrain. */
export interface TerrainGrid {
	heights: Float32Array
	biomes: Uint8Array
	season: Season
	noise: Simplex2D
}

/** Ploughed furrows: the direction changes per 90 m cell. */
function fieldColor(out: THREE.Color, col: Record<string, THREE.Color>, x: number, z: number, g: TerrainGrid) {
	const cell = Math.floor((x + 1000) / 90) * 31 + Math.floor((z + 1000) / 90) * 17
	const dir = (cell % 4) * (Math.PI / 4)
	const u = x * Math.cos(dir) + z * Math.sin(dir)
	const meadowMix = (g.season === 'winter' ? 0.1 : 0.25) * (0.5 + 0.5 * g.noise.noise(x * 0.02, z * 0.02))
	out.copy(col.field)
		.lerp(col.fieldDark, 0.5 + 0.5 * Math.sin(u * 1.4))
		.lerp(col.meadow, meadowMix)
}

/** Ground colour of one vertex: the biome's paint plus a little noise. */
function vertexColor(
	out: THREE.Color,
	col: Record<string, THREE.Color>,
	b: Biome,
	h: number,
	x: number,
	z: number,
	g: TerrainGrid,
) {
	const winter = g.season === 'winter'
	const n = g.noise
	switch (b) {
		case 'field':
			fieldColor(out, col, x, z, g)
			break
		case 'meadow':
			out.copy(col.meadow).lerp(col.meadowLight, 0.5 + 0.5 * n.noise(x * 0.05, z * 0.05))
			break
		case 'mountain':
			out.copy(col.mountain).lerp(col.snow, winter ? smoothstep(h, 20, 40) : smoothstep(h, 48, 62))
			break
		case 'town':
			out.copy(col.town).lerp(col.mud, 0.4 * (0.5 + 0.5 * n.noise(x * 0.1, z * 0.1)))
			break
		default: // forest, road, water, mud, village, base: flat paint
			out.copy(col[b])
	}
	out.multiplyScalar(winter ? 0.96 + 0.04 * n.noise(x * 0.3, z * 0.3) : 0.9 + 0.1 * n.noise(x * 0.3, z * 0.3))
}

/** The ground mesh: one vertex per heightmap cell, vertex-coloured by biome. */
export function buildTerrainMesh(g: TerrainGrid): THREE.Mesh {
	const size = WORLD_HALF * 2
	const n = TERRAIN_RES - 1
	const geo = new THREE.PlaneGeometry(size, size, n, n)
	geo.rotateX(-Math.PI / 2)
	const pos = geo.attributes.position as THREE.BufferAttribute
	const colors = new Float32Array(pos.count * 3)
	const col = Object.fromEntries(Object.entries(PALETTE[g.season]).map(([k, v]) => [k, new THREE.Color(v)]))
	const c = new THREE.Color()
	for (let i = 0; i < pos.count; i++) {
		const x = pos.getX(i)
		const z = pos.getZ(i)
		// Grid vertex: read the baked arrays directly so bridge decks never lift the ground mesh
		const gi = Math.round(((x + WORLD_HALF) / size) * n)
		const gj = Math.round(((z + WORLD_HALF) / size) * n)
		const h = g.heights[gj * TERRAIN_RES + gi]
		pos.setY(i, h)
		vertexColor(c, col, BIOME_ID[g.biomes[gj * TERRAIN_RES + gi]], h, x, z, g)
		colors[i * 3] = c.r
		colors[i * 3 + 1] = c.g
		colors[i * 3 + 2] = c.b
	}
	geo.setAttribute('color', new THREE.BufferAttribute(colors, 3))
	geo.computeVertexNormals()
	const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.95 }))
	mesh.receiveShadow = true
	mesh.castShadow = false // self-shadowing of gentle hills is invisible under a high sun; skipping it saves a 130k-triangle pass
	return mesh
}

const WATER_STYLE: Record<Season, { color: string; roughness: number }> = {
	summer: { color: '#2f6a8a', roughness: 0.25 },
	autumn: { color: '#3f6478', roughness: 0.25 },
	winter: { color: '#4a5f70', roughness: 0.6 },
}

/** Marsh water: dark and green, whatever the season. */
const BOG_WATER = { color: '#3b5238', roughness: 0.5 }
/** The water plane reaches well past the map edge, so a coast map's sea runs to the horizon. */
const WATER_SIZE = WORLD_HALF * 6

/** One translucent plane at the water level under the whole map (and the sea beyond it). */
export function buildWaterMesh(season: Season, marsh = false): THREE.Mesh {
	const geo = new THREE.PlaneGeometry(WATER_SIZE, WATER_SIZE)
	geo.rotateX(-Math.PI / 2)
	const style = marsh ? BOG_WATER : WATER_STYLE[season]
	const material = new THREE.MeshStandardMaterial({ ...style, metalness: 0.1, transparent: true, opacity: 0.8 })
	const mesh = new THREE.Mesh(geo, material)
	mesh.position.y = WATER_LEVEL
	mesh.receiveShadow = true
	return mesh
}
