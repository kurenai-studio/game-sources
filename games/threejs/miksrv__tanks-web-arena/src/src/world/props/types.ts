import type { TreeSpecies } from '../../config'

export interface Tree {
	x: number
	z: number
	/** Ground height at the trunk. */
	h: number
	/** Scale. */
	s: number
	species: TreeSpecies
	fallen: boolean
	/** 0..1 progress of the fall. */
	fallT: number
	dirX: number
	dirZ: number
}
export interface Bush {
	x: number
	z: number
	r: number
}
export interface Rock {
	x: number
	z: number
	r: number
	kind: 'rock' | 'hedgehog' | 'tooth'
}
export interface Hay {
	x: number
	z: number
	crushed: boolean
}
export interface Fence {
	x: number
	z: number
	rot: number
	down: boolean
}

/** Everything scattered over one map. */
export interface PropSet {
	trees: Tree[]
	bushes: Bush[]
	rocks: Rock[]
	hay: Hay[]
	fences: Fence[]
}
