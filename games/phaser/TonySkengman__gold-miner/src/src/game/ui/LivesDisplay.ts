import { GameObjects, Scene } from 'phaser';

/** Five heart slots; spent lives remain visible as muted hearts. */
export function drawLives(scene: Scene, x: number, y: number, lives: number): GameObjects.Graphics {
    const g = scene.add.graphics().setData('responsiveAnchor', 'center');
    for (let i = 0; i < 5; i++) {
        const filled = i < lives;
        g.fillStyle(filled ? 0xd94b52 : 0x8b796c);
        g.lineStyle(2, filled ? 0x792e37 : 0x594c43);
        g.beginPath();
        for (let step = 0; step <= 64; step++) {
            const t = step / 64 * Math.PI * 2;
            const px = x + (i - 2) * 36 + 0.8 * 16 * Math.pow(Math.sin(t), 3);
            const py = y - 0.8 * (13 * Math.cos(t) - 5 * Math.cos(2 * t)
                - 2 * Math.cos(3 * t) - Math.cos(4 * t)) - 2;
            if (step === 0) g.moveTo(px, py);
            else g.lineTo(px, py);
        }
        g.closePath();
        g.fillPath();
        g.strokePath();
    }
    return g;
}
