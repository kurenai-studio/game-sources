import type { Role } from './types'

/** Standard: both bases can be captured; encounter: one neutral base in the middle; assault: one side defends. */
export type BattleMode = 'standard' | 'encounter' | 'assault'

export const MATCH = {
	teamSize: 7,
	roundTime: 360, // s
	countdown: 4, // s before tanks may move
	resultTime: 11, // s showing the result before the next round
	composition: { light: 1, medium: 2, heavy: 2, td: 1, spg: 1 } as Record<Role, number>,
	ratingSpread: 1.5, // bots' vehicles are rated within this of the player's (the nearest when none is)
	ratingTolerance: 0.5, // team rating sums may differ by this much
	modeOdds: { standard: 0.6, encounter: 0.25, assault: 0.15 } as Record<BattleMode, number>,
}

export const MODE_LABEL: Record<BattleMode, string> = {
	standard: 'стандартный бой',
	encounter: 'встречный бой',
	assault: 'штурм',
}

/** Base capture. Units: metres, capture points (100 = captured), seconds. */
export const CAPTURE = {
	radius: 30,
	points: 100,
	rate: 1.25, // points per second per tank in the circle: alone, a base takes 80 s
	maxTanks: 3, // more than this many capturers do not speed it up
	/** Neutral base: flat ground and the base biome around it. */
	flatRadius: 60,
	biomeRadius: 36,
}
