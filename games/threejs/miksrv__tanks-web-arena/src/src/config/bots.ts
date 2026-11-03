export const BOTS = {
	skillMin: 0.2,
	skillMax: 0.85,
	aimErrorMax: 1.6, // m at skill 0 (×(1 − skill))
	/** Reticle bloom a bot fires at: aimBloomMax − aimBloomSkill × skill (skill 0.2 → 0.65, 0.85 → 0.33). */
	aimBloomMax: 0.75,
	aimBloomSkill: 0.5,
	reactionMin: 0.4, // s before a bot fires once the reticle has settled
	reactionMax: 1.8,
	/** s before a bot reacts to a broken track / an engine fire with its consumable, × (1.3 − skill). */
	repairDelay: [1.5, 4] as const,
	extinguishDelay: [1, 3] as const,
	medkitDelay: [3, 8] as const,
	engageRange: 330,
	retreatHp: 0.28,
}
