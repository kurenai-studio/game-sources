import type { DepositRewardKind } from './DepositRewards';

/** Distance thresholds keep strength upgrades from changing how much hauling is safe. */
export class DepositIntegrity {
    private hauled = 0;
    private trip = 1;
    private lostGold = 0;
    private gemChecked = false;
    private readonly loseGem: boolean;
    readonly rewards: DepositRewardKind[];

    constructor(rewards: readonly DepositRewardKind[], random: () => number) {
        this.rewards = [...rewards];
        this.loseGem = random() < 0.5;
    }

    begin(distance: number): void { this.trip = Math.max(1, distance); }
    get progress(): number { return Math.min(1, this.hauled / this.trip); }
    get stage(): number { return this.progress >= 0.65 ? 2 : this.progress >= 0.3 ? 1 : 0; }

    advance(distance: number): DepositRewardKind[] {
        this.hauled += Math.max(0, distance);
        const lost: DepositRewardKind[] = [];
        const goldLosses = this.stage;
        while (this.lostGold < goldLosses) {
            const index = this.rewards.findIndex(kind => kind === 'small' || kind === 'medium');
            if (index >= 0) lost.push(...this.rewards.splice(index, 1));
            this.lostGold++;
        }
        // The risk is fixed when the level is created, never rerolled during hauling.
        if (this.progress >= 0.85 && !this.gemChecked) {
            this.gemChecked = true;
            let index = -1;
            for (let i = 0; i < this.rewards.length; i++) {
                if (this.rewards[i] === 'diamond' || this.rewards[i] === 'ruby') index = i;
            }
            if (this.loseGem && index >= 0) lost.push(...this.rewards.splice(index, 1));
        }
        return lost;
    }
}
