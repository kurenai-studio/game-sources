import * as THREE from 'three'
import type { Season, TreeSpecies } from '../terrain'

/** One geometry from several parts, positions only (normals recomputed). */
export function mergePositions(parts: THREE.BufferGeometry[]): THREE.BufferGeometry {
	const pos: number[] = []
	for (const g of parts) pos.push(...(g.toNonIndexed().attributes.position.array as Float32Array))
	const geo = new THREE.BufferGeometry()
	geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3))
	geo.computeVertexNormals()
	return geo
}

const ellipsoid = (r: number, seg: number, sy: number, y: number) =>
	new THREE.SphereGeometry(r, seg, seg - 1).scale(1, sy, 1).translate(0, y, 0)

interface SpeciesDef {
	conifer: boolean
	/** Scale of the shared 5 m trunk: [girth, height]. */
	trunk: readonly [number, number]
	bark: string
	/** Summer crown colour (conifers: also autumn). */
	leaf: string
	/** Autumn leaves: hue range and lightness of the HSL colour. */
	autumn: readonly [h0: number, h1: number, l: number]
	/** Winter: the snow-dusted needles or the bare branches. */
	winter: string
	crown(): THREE.BufferGeometry
	/** Winter crown of a leafy species: smaller, branches only (conifers keep their needles). */
	bare?: () => THREE.BufferGeometry
}

/** Tree species: the trunk is shared (scaled and tinted per instance), each species has its own crown mesh. */
export const SPECIES: Record<TreeSpecies, SpeciesDef> = {
	pine: {
		conifer: true,
		trunk: [1, 1],
		bark: '#6a4630',
		leaf: '#2d5a2a',
		autumn: [0, 0, 0],
		winter: '#4f6a52',
		crown: () => new THREE.ConeGeometry(2.4, 7, 7).translate(0, 7.5, 0),
	},
	spruce: {
		conifer: true,
		trunk: [0.9, 0.8],
		bark: '#4a3a2e',
		leaf: '#22432a',
		autumn: [0, 0, 0],
		winter: '#4a6252',
		crown: spruce,
	},
	linden: {
		conifer: false,
		trunk: [1, 1],
		bark: '#5a4030',
		leaf: '#4f8a33',
		autumn: [0.02, 0.14, 0.4],
		winter: '#5a4a3c',
		crown: () => ellipsoid(2.8, 7, 1.15, 6.6),
		bare: () => ellipsoid(2.2, 6, 1.3, 6.4),
	},
	birch: {
		conifer: false,
		trunk: [0.7, 1.1],
		bark: '#e4e0d6',
		leaf: '#76a03e',
		autumn: [0.11, 0.15, 0.5],
		winter: '#6a5654',
		crown: () => ellipsoid(1.9, 7, 1.7, 7.4),
		bare: () => ellipsoid(1.5, 6, 1.8, 7.2),
	},
	oak: {
		conifer: false,
		trunk: [1.5, 0.75],
		bark: '#4a3c30',
		leaf: '#3c6a2a',
		autumn: [0.05, 0.09, 0.32],
		winter: '#4e4034',
		crown: () => mergePositions([ellipsoid(3.4, 8, 0.75, 5.4), ellipsoid(2.2, 6, 0.8, 6.9)]),
		bare: () => ellipsoid(2.9, 6, 0.8, 5.3),
	},
	poplar: {
		conifer: false,
		trunk: [0.9, 1.4],
		bark: '#6a6458',
		leaf: '#557f30',
		autumn: [0.12, 0.15, 0.45],
		winter: '#5e5040',
		crown: () => ellipsoid(1.4, 6, 4.2, 8.6),
		bare: () => ellipsoid(1.1, 6, 4.2, 8.6),
	},
	willow: {
		conifer: false,
		trunk: [1.4, 0.6],
		bark: '#5a5040',
		leaf: '#7f9a52',
		autumn: [0.13, 0.16, 0.45],
		winter: '#7a6a48',
		crown: () => willow(1),
		bare: () => willow(0.82),
	},
	apple: {
		conifer: false,
		trunk: [0.9, 0.45],
		bark: '#5a4636',
		leaf: '#5a8f36',
		autumn: [0.06, 0.2, 0.38],
		winter: '#5a4a3c',
		crown: () => ellipsoid(2.6, 7, 0.8, 3.6),
		bare: () => ellipsoid(2.1, 6, 0.85, 3.5),
	},
}

/** Spruce: three stacked cones, narrow and dark. */
function spruce(): THREE.BufferGeometry {
	return mergePositions([
		new THREE.ConeGeometry(2.4, 5, 7).translate(0, 4.6, 0),
		new THREE.ConeGeometry(1.8, 4.4, 7).translate(0, 7.4, 0),
		new THREE.ConeGeometry(1.1, 3.6, 7).translate(0, 10, 0),
	])
}

/** Willow: a drooping skirt of branches under a low dome, scaled `k`. */
function willow(k: number): THREE.BufferGeometry {
	return mergePositions([
		new THREE.CylinderGeometry(2.3, 3.5, 4.2, 8, 1, true).translate(0, 3.5, 0),
		ellipsoid(2.6, 8, 0.7, 5.4),
	]).scale(k, k, k)
}

/** Crown colour of one tree: summer greens with a little spread, autumn yellow to red, winter needles or branches. */
/** The crown a species wears in a season. */
export function crownGeometry(sp: TreeSpecies, season: Season): THREE.BufferGeometry {
	const d = SPECIES[sp]
	return season === 'winter' && d.bare ? d.bare() : d.crown()
}

export function crownColor(sp: TreeSpecies, season: Season, rnd: () => number, out: THREE.Color): THREE.Color {
	const d = SPECIES[sp]
	if (season === 'autumn' && !d.conifer) {
		const [h0, h1, l] = d.autumn
		return out.setHSL(h0 + rnd() * (h1 - h0), 0.65, l + rnd() * 0.12)
	}
	if (season === 'winter') return out.set(d.winter).offsetHSL(0, 0, (rnd() - 0.5) * 0.1)
	return out.set(d.leaf).offsetHSL((rnd() - 0.5) * 0.04, 0, (rnd() - 0.5) * 0.1)
}
