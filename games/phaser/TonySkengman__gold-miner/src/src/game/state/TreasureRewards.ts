export type TreasureReward = { kind: 'money' | 'dynamite' | 'luck' | 'lightweightGrip' | 'life'; amount: number };

/** Life vials have a 15% chance; the other four rewards share 85% equally. */
export function rollTreasureReward(random: () => number = Math.random): TreasureReward {
    const roll = random();
    const amount = random();
    if (roll < 0.2125) return { kind: 'money', amount: 320 + Math.floor(amount * 11) * 40 };
    if (roll < 0.425) return { kind: 'dynamite', amount: 1 + Math.floor(amount * 2) };
    if (roll < 0.6375) return { kind: 'luck', amount: 1 + Math.floor(amount * 2) };
    if (roll >= 0.85) return { kind: 'life', amount: 1 };
    return { kind: 'lightweightGrip', amount: 1 + Math.floor(amount * 2) };
}

export function treasureRewardLabel(reward: TreasureReward): string {
    switch (reward.kind) {
        case 'life': return '+1 LIFE';
        case 'money': return `$${reward.amount} GOLD`;
        case 'dynamite': return `${reward.amount} DYNAMITE`;
        case 'luck': return `${reward.amount} LUCK ${reward.amount === 1 ? 'POTION' : 'POTIONS'}`;
        case 'lightweightGrip': return `${reward.amount} LIGHTWEIGHT GRIP`;
    }
}

export function treasureRewardValue(reward: TreasureReward): number {
    if (reward.kind === 'life') return 1000;
    return reward.amount * (reward.kind === 'money' ? 1 : reward.kind === 'dynamite' ? 750 : reward.kind === 'luck' ? 500 : 250);
}
