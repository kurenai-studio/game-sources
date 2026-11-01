import { GameObjects, Scene } from 'phaser';

/** One drawn stick per owned dynamite, with a compact grid for larger supplies. */
export class DynamiteInventory {
    private readonly icons: GameObjects.Graphics;
    private readonly empty: GameObjects.Text;
    private previousCount = -1;

    constructor(scene: Scene, x: number, y: number) {
        scene.add.rectangle(x, y, 300, 58, 0xffedbb).setOrigin(0);
        scene.add.text(x + 10, y + 5, 'DYNAMITE  [↑]', {
            fontFamily: 'Arial', fontSize: 14, fontStyle: 'bold', color: '#483126'
        });
        this.icons = scene.add.graphics().setPosition(x + 10, y + 23);
        this.empty = scene.add.text(x + 10, y + 28, 'EMPTY', {
            fontFamily: 'Arial', fontSize: 18, fontStyle: 'bold', color: '#a1382a'
        }).setVisible(false);
    }

    update(count: number): void {
        if (count === this.previousCount) return;
        this.previousCount = count;
        this.empty.setVisible(count === 0);
        const g = this.icons.clear();
        if (count <= 0) return;
        const columns = Math.min(count, Math.max(10, Math.ceil(Math.sqrt(count * 7))));
        const rows = Math.ceil(count / columns);
        const scale = Math.min(1, 280 / (columns * 24), 32 / (rows * 34));
        for (let i = 0; i < count; i++) {
            const x = (i % columns) * 24 * scale + 8 * scale;
            const y = Math.floor(i / columns) * 34 * scale + 18 * scale;
            g.fillStyle(0xc43c2f).lineStyle(scale, 0x783026)
                .fillRoundedRect(x - 5 * scale, y - 10 * scale, 10 * scale, 23 * scale, 2 * scale)
                .strokeRoundedRect(x - 5 * scale, y - 10 * scale, 10 * scale, 23 * scale, 2 * scale);
            g.fillStyle(0xed7755).fillRect(x - 3 * scale, y - 8 * scale, 2 * scale, 18 * scale);
            g.fillStyle(0xe5bd7b).fillRect(x - 5 * scale, y - 2 * scale, 10 * scale, 4 * scale);
            g.lineStyle(2 * scale, 0x735332).lineBetween(x, y - 10 * scale, x + 3 * scale, y - 16 * scale);
            g.fillStyle(0xf0b834).fillCircle(x + 3 * scale, y - 16 * scale, 2 * scale);
        }
    }
}
