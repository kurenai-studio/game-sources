export type DepositRewardKind = 'small' | 'medium' | 'diamond' | 'ruby';

/** Roll at level creation so hauling, blasting and retries cannot reroll the contents. */
export function rollDepositRewards(random: () => number, largeRock = false): readonly DepositRewardKind[] {
    const roll = random();
    const goldChance = largeRock ? 0.2 : 0.55;
    const rubyThreshold = largeRock ? 0.65 : 0.9;
    if (roll < goldChance) {
        const count = random() < 0.5 ? 3 : 4;
        if (!largeRock) return Array<DepositRewardKind>(count).fill('small');
        // Large deposits guarantee at least one medium nugget in gold-only rewards.
        return ['medium', ...Array.from({ length: count - 1 }, (): DepositRewardKind =>
            random() < 0.5 ? 'small' : 'medium')];
    }
    const gold: DepositRewardKind[] = Array(random() < 0.5 ? 2 : 3).fill('small');
    if (roll < rubyThreshold) return ['diamond', ...gold];
    // The extra diamond is a 10% chance within either size’s ruby group.
    return random() < 0.1 ? ['ruby', 'diamond', ...gold] : ['ruby', ...gold];
}
