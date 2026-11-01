import type { GameObjects, Scene } from 'phaser';
import { WORLD } from '../state/World';

/** An analog countdown clock beside the miner, with remaining seconds underneath. */
export class MineClock {
    private readonly hands: GameObjects.Graphics;
    private readonly seconds: GameObjects.Text;
    private capacity: number;
    private displayedSeconds = -1;
    private displayedFinalHaul = false;

    constructor(scene: Scene, startingSeconds: number) {
        this.capacity = startingSeconds;
        const clockX = () => Math.max(372, WORLD.centerX - 210);
        const x = clockX();
        const y = 157;
        const frame = scene.add.graphics().setPosition(x, y).setDepth(7).setData('responsiveAnchor', 'center');
        frame.setData('responsiveRedraw', () => frame.setX(clockX()));
        // Feet and a wooden plinth make the clock part of the mining platform.
        frame.fillStyle(0x151b20, 0.35).fillEllipse(3, 49, 104, 13);
        frame.fillStyle(0x70472e).fillRoundedRect(-51, 47, 102, 10, 3);
        frame.fillStyle(0xbb8750).fillRect(-49, 47, 98, 3);
        frame.lineStyle(6, 0x765126).lineBetween(-22, 31, -29, 46).lineBetween(22, 31, 29, 46);
        // Bell caps, winding key and a shaded brass casing.
        frame.lineStyle(4, 0x79552c).lineBetween(-22, -28, -28, -39).lineBetween(22, -28, 28, -39);
        frame.fillStyle(0xb4833d).lineStyle(2, 0x79552c);
        frame.fillEllipse(-28, -39, 26, 17).strokeEllipse(-28, -39, 26, 17);
        frame.fillEllipse(28, -39, 26, 17).strokeEllipse(28, -39, 26, 17);
        frame.fillRoundedRect(-4, -49, 8, 12, 2);
        frame.fillStyle(0x493528).fillCircle(2, 3, 43);
        frame.fillStyle(0xdfb85e).lineStyle(3, 0x79552c).fillCircle(0, 0, 41).strokeCircle(0, 0, 41);
        frame.fillStyle(0xffedbb).fillCircle(0, 0, 33);
        frame.lineStyle(2, 0x9a7847);
        for (let i = 0; i < 12; i++) {
            const angle = i * Math.PI / 6;
            frame.lineBetween(Math.sin(angle) * 28, Math.cos(angle) * 28,
                Math.sin(angle) * 31, Math.cos(angle) * 31);
        }
        frame.lineStyle(2, 0xfff4cf, 0.8).beginPath().arc(0, 0, 39, Math.PI, Math.PI * 1.5).strokePath();
        this.hands = scene.add.graphics().setPosition(x, y).setDepth(8).setData('responsiveAnchor', 'center');
        this.hands.setData('responsiveRedraw', () => this.hands.setX(clockX()));
        this.seconds = scene.add.text(x, y + 64, '', {
            fontFamily: 'Arial', fontSize: 16, fontStyle: 'bold', color: '#fff3cc',
            backgroundColor: '#302e2b', padding: { x: 8, y: 3 }
        }).setOrigin(0.5, 0).setDepth(9).setData('responsiveAnchor', 'center');
        this.seconds.setData('responsiveRedraw', () => this.seconds.setX(clockX()));
        this.update(startingSeconds);
    }

    update(remaining: number, finalHaul = false): void {
        const seconds = Math.max(0, Math.ceil(remaining));
        this.capacity = Math.max(this.capacity, remaining);
        if (seconds === this.displayedSeconds && finalHaul === this.displayedFinalHaul) return;
        this.displayedSeconds = seconds;
        this.displayedFinalHaul = finalHaul;
        const urgent = remaining <= 10;
        const fraction = Math.max(0, Math.min(1, remaining / Math.max(1, this.capacity)));
        const angle = (1 - fraction) * Math.PI * 2 - Math.PI / 2;
        this.seconds.setText(finalHaul ? 'FINAL HAUL  0s' : `TIME LEFT  ${seconds}s`)
            .setColor(urgent ? '#ff9b7c' : '#fff3cc');
        this.hands.clear();
        if (fraction > 0) {
            this.hands.lineStyle(3, urgent ? 0xd94b52 : 0x72964d).beginPath()
                .arc(0, 0, 37, angle, Math.PI * 1.5).strokePath();
        }
        this.hands.lineStyle(3, urgent ? 0xb12f30 : 0x483126)
            .lineBetween(0, 0, Math.cos(angle) * 25, Math.sin(angle) * 25);
        this.hands.lineStyle(4, 0x79552c).lineBetween(0, 0, 0, -14);
        this.hands.fillStyle(0x79552c).fillCircle(0, 0, 4);
    }
}
