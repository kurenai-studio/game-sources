import type { Scene } from 'phaser';
import { WORLD } from '../state/World';
import { findClearAim } from './Aiming';
import { Collectable } from './Collectable';

/** Release treasure after the explosion, so fresh drops survive a TNT chain. */
export function releaseGemDeposit(scene: Scene, deposit: Collectable, objects: Collectable[]): void {
    if (!deposit.gemDeposit) return;
    const released: Collectable[] = [];
    for (const kind of deposit.depositRewards) {
        const radius = kind === 'medium' ? 32 : kind === 'diamond' ? 17 : 15;
        let position: { x: number; y: number; radius: number } | undefined;
        // Search outward from the blast, then across the cave if a nearby spot is crowded.
        const candidates: { x: number; y: number }[] = [];
        for (let ring = 1; ring <= 12; ring++) {
            for (let step = 0; step < 24; step++) {
                const angle = step * Math.PI * 2 / 24;
                candidates.push({ x: deposit.x + Math.cos(angle) * ring * 36,
                    y: deposit.y + Math.sin(angle) * ring * 36 });
            }
        }
        for (let y = 340; y < 880; y += 36) {
            for (let x = 65; x < WORLD.width - 65; x += 36) candidates.push({ x, y });
        }
        const obstacles = objects.filter(object => object !== deposit && (object.available || released.includes(object)));
        for (const candidate of candidates) {
            const { x, y } = candidate;
            if (x < radius + 40 || x > WORLD.width - radius - 40 || y < 320
                || y + radius > WORLD.floorY || Math.hypot(x - WORLD.centerX, y - WORLD.pivotY) > WORLD.spawnRange - radius
                || Math.abs(Math.atan2(x - WORLD.centerX, y - WORLD.pivotY)) > WORLD.maxAngle) continue;
            if (obstacles.some(other => Math.hypot(x - other.x, y - other.y) < radius + other.radius + 10)) continue;
            const target = { x, y, radius };
            // Other treasure can be caught first; only fixed rocks must leave an aiming gap.
            const rocks = obstacles.filter(other => other.kind === 'rock' || other.kind === 'mediumRock' || other.kind === 'heavyRock' || other.kind === 'largeRock');
            if (findClearAim(target, rocks) === null) continue;
            position = target;
            break;
        }
        // The visible gem must survive even if no clear scattering spot exists.
        if (!position && (kind === 'diamond' || kind === 'ruby')) {
            position = { x: deposit.x, y: deposit.y, radius };
        }
        if (!position) continue;
        const drop = new Collectable(scene, position.x, position.y, kind);
        objects.push(drop);
        released.push(drop);
        drop.available = false;
        drop.graphic.setPosition(deposit.x, deposit.y).setScale(0.3).setAlpha(0.4);
        scene.tweens.add({ targets: drop.graphic, x: position.x, y: position.y, scale: 1, alpha: 1,
            duration: 350, ease: 'Cubic.easeOut', onComplete: () => { drop.available = true; } });
    }
    const label = scene.add.text(Math.max(180, Math.min(WORLD.width - 180, deposit.x)), Math.max(320, deposit.y - 65),
        released.length > 0 ? 'GEM DEPOSIT!\nCatch the scattered treasure'
            : 'DEPOSIT CRUMBLED!\nNothing left inside.', {
            fontFamily: 'Arial', fontSize: 20, fontStyle: 'bold', color: '#9ef5ff',
            align: 'center', stroke: '#483126', strokeThickness: 4
        }).setOrigin(0.5).setDepth(10);
    scene.tweens.add({ targets: label, alpha: 0, delay: 1200, duration: 400, onComplete: () => label.destroy() });
}
