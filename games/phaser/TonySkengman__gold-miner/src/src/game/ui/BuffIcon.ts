import { GameObjects, Scene } from 'phaser';
import { drawShopProduct } from '../art/drawShop';

export type BuffKind = 'strength' | 'goldRush' | 'luck' | 'lightweightGrip' | 'streakVial';

export function drawBuffIcon(scene: Scene, kind: BuffKind): GameObjects.Graphics {
    if (kind === 'luck' || kind === 'lightweightGrip' || kind === 'streakVial') {
        return drawShopProduct(scene, 0, 0, kind, 0.25);
    }
    const g = scene.add.graphics();
    g.fillStyle(0x9fc9bd).lineStyle(1.5, 0x365c50);
    g.beginPath().moveTo(-4, -8).lineTo(-4, -3).lineTo(-10, 3)
        .lineTo(-10, 10).lineTo(-6, 13).lineTo(6, 13).lineTo(10, 10)
        .lineTo(10, 3).lineTo(4, -3).lineTo(4, -8).closePath().fillPath().strokePath();
    g.fillStyle(kind === 'goldRush' ? 0xffc52e : 0x79c94c).fillRoundedRect(-7, 3, 14, 7, 2);
    g.fillStyle(0xad7c43).fillRoundedRect(-5, -12, 10, 5, 1);
    g.fillStyle(0xfff1af);
    if (kind === 'goldRush') {
        g.beginPath().moveTo(-5, 5).lineTo(-1, 1).lineTo(4, 3)
            .lineTo(5, 7).lineTo(0, 10).closePath().fillPath();
    } else {
        g.fillTriangle(2, 0, -4, 6, 1, 6).fillTriangle(-1, 5, 4, 5, -2, 11);
    }
    return g;
}
