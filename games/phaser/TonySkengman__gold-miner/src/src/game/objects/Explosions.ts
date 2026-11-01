import type { Scene } from 'phaser';
import { soundEffects } from '../audio/SoundEffects';
import type { Collectable } from './Collectable';

export const TNT_BLAST_RADIUS = 125;

/** Resolve each barrel once; only free objects are affected and no money is awarded. */
export function detonateBarrel(barrel: Collectable, objects: Collectable[], onBlast: (x: number, y: number) => void, onDepositBlast?: (deposit: Collectable) => void): void {
    if (barrel.kind !== 'tnt' || !barrel.available) return;
    const deposits: Collectable[] = [];
    const pending = [barrel];
    const queued = new Set([barrel]);
    while (pending.length) {
        const current = pending.pop()!;
        const { x, y } = current;
        current.destroy();
        for (const object of objects) {
            if (!object.available || Math.hypot(object.x - x, object.y - y) > TNT_BLAST_RADIUS + object.radius) continue;
            if (object.kind === 'tnt') {
                if (!queued.has(object)) { queued.add(object); pending.push(object); }
            } else {
                if (object.gemDeposit) deposits.push(object);
                object.destroy();
            }
        }
        onBlast(x, y);
    }
    deposits.forEach(deposit => onDepositBlast?.(deposit));
}

export function showBarrelExplosion(scene: Scene, x: number, y: number): void {
    soundEffects.play('explosion');
    const burst = scene.add.graphics().setPosition(x, y).setDepth(8);
    burst.fillStyle(0xff9b2f, 0.55).fillCircle(0, 0, TNT_BLAST_RADIUS);
    burst.lineStyle(3, 0xffdd7b).strokeCircle(0, 0, TNT_BLAST_RADIUS);
    burst.fillStyle(0xffe59a).fillCircle(0, 0, 26);
    scene.tweens.add({ targets: burst, alpha: 0, duration: 350, onComplete: () => burst.destroy() });
}
