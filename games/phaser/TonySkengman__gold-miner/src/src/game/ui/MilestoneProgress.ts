import { WORLD } from '../state/World';
import { GameObjects, Scene } from 'phaser';
import { RoundState } from '../state/RoundState';

export class MilestoneProgress {
    private readonly label: GameObjects.Text;
    private readonly bar: GameObjects.Graphics;

    constructor(scene: Scene) {
        this.label = scene.add.text(WORLD.centerX, 59, '', {
            fontFamily: 'Arial', fontSize: 16, color: '#ffe4a0'
        }).setOrigin(0.5, 0);
        this.bar = scene.add.graphics();
    }

    update(round: RoundState): void {
        const next = round.nextMilestone;
        this.label.setText(!round.won ? 'Reach the target to clear the level'
            : next ? `Target reached! Next bonus: ${next.label} at $${Math.ceil(round.target * next.fraction)}`
            : 'All bonus rewards earned! Keep mining to grow your fortune.');
        this.bar.clear();
        if (!round.won) return;
        this.bar.fillStyle(0x261f1a).fillRoundedRect(WORLD.centerX - 160, 80, 320, 5, 2);
        this.bar.fillStyle(0xffd266).fillRoundedRect(WORLD.centerX - 160, 80, 320 * round.milestoneProgress, 5, 2);
    }
}
