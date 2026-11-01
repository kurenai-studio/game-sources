import { responsiveLayout } from '../ui/ResponsiveLayout';
import { WORLD } from '../state/World';
import { drawLives } from '../ui/LivesDisplay';
import { Scene } from 'phaser';
import { drawEnvironment } from '../art/drawEnvironment';
import { drawShopProduct } from '../art/drawShop';
import { addSoundButton, soundEffects } from '../audio/SoundEffects';
import { LEVELS } from '../state/Levels';
import { MINES, mineConfig, roundDuration, type MineKind } from '../state/Mines';
import { LAYOUTS } from '../state/Layouts';
import { MILESTONES } from '../state/Milestones';
import { LevelBonuses, ShopItemKind, Upgrades, emptyBonuses } from '../state/Upgrades';
import { menuButton } from '../ui/menuButton';

interface BriefingData {
    mine?: MineKind;
    lives?: number;
    level?: number;
    money?: number;
    upgrades?: Upgrades;
    dynamite?: number;
    bonuses?: LevelBonuses;
    levelSeed?: number;
}

export class LevelBriefing extends Scene {
    constructor() { super('LevelBriefing'); }

    create(data: BriefingData = {}): void {
        const level = Number.isInteger(data.level) ? Math.max(1, Math.min(LEVELS.length, data.level!)) : 1;
        const config = mineConfig(level, data.mine);
        const layout = LAYOUTS[config.layout];
        const bonuses = { ...emptyBonuses(), ...data.bonuses };
        drawEnvironment(this, config.layout, data.mine);
        this.add.rectangle(WORLD.centerX, 480, 840, 820, 0x211f1d, 0.97).setStrokeStyle(4, 0xc29659);
        const text = (y: number, label: string, size = 22, color = '#fff3cc') =>
            this.add.text(WORLD.centerX, y, label, {
                fontFamily: 'Arial', fontSize: size, color, align: 'center',
                wordWrap: { width: 740 }, lineSpacing: 8
            }).setOrigin(0.5);

        text(131, `LEVEL ${level} / ${LEVELS.length}`, 26, '#e5c58f');
        drawLives(this, WORLD.centerX + 288, 131, data.lives ?? 3);
        text(186, `${MINES[data.mine ?? 'quarry'].name} — ${layout.name}`.toUpperCase(), 30, '#ffda69').setFontStyle('bold');
        text(257, 'GOLD TARGET', 21, '#e5c58f');
        text(312, `$${config.target}`, 64, '#ffda69').setFontStyle('bold');
        text(375, `Collect $${config.target} this round to pass. Starting money does not count.`, 20);
        text(428, `${roundDuration(data.mine, bonuses.extraTime)} SECONDS`, 25, '#bcf58b');
        text(480, `${layout.hint}\nBlast gem-studded rocks early. Aim for exposed gems to leave their rocks behind.`, 19);

        const prepared: { kind: ShopItemKind; name: string; detail: string }[] = [
            { kind: 'dynamite', name: 'Dynamite', detail: `${data.dynamite ?? 3} sticks available` }
        ];
        if (bonuses.luck > 0) prepared.push({ kind: 'luck', name: 'Luck potion', detail: 'Money bags $250+' });
        if (bonuses.extraTime > 0) prepared.push({ kind: 'extraTime', name: 'Extra time', detail: '+15 seconds' });
        if (bonuses.lightweightGrip > 0) prepared.push({ kind: 'lightweightGrip', name: 'Lightweight Grip', detail: 'Rock weight\n-40%' });
        if (bonuses.streakVial > 0) prepared.push({ kind: 'streakVial', name: 'Streak vial', detail: 'Streak bonuses x1.5' });
        if (bonuses.strengthPotion > 0) prepared.push({ kind: 'strengthPotion', name: 'Strength', detail: `${2 + (data.upgrades?.vialBelt ?? 0)} catches at x2` });
        if (bonuses.goldRush > 0) prepared.push({ kind: 'goldRush', name: 'Gold Rush', detail: `${2 + (data.upgrades?.vialBelt ?? 0)} gold catches +50%` });
        text(533, 'PREPARED FOR THIS ROUND', 20, '#e5c58f');
        const cardTop = 564;
        const cardHeight = 136;
        const spacing = Math.min(190, 760 / prepared.length);
        prepared.forEach((item, index) => {
            const x = WORLD.centerX + (index - (prepared.length - 1) / 2) * spacing;
            this.add.rectangle(x, cardTop + cardHeight / 2, spacing - 14, cardHeight, 0x3c3329).setStrokeStyle(1, 0x8e603c);
            this.add.text(x, cardTop + 18, item.name, {
                fontFamily: 'Arial', fontSize: prepared.length > 5 ? 14 : 18, fontStyle: 'bold', color: '#ffda69', align: 'center', wordWrap: { width: spacing - 20 }
            }).setOrigin(0.5);
            drawShopProduct(this, x, cardTop + 59, item.kind, 0.4);
            this.add.text(x, cardTop + 106, item.detail, {
                fontFamily: 'Arial', fontSize: prepared.length > 5 ? 13 : 16, color: '#bcf58b', align: 'center', lineSpacing: 2, wordWrap: { width: spacing - 20 }
            }).setOrigin(0.5);
        });
        text(cardTop + cardHeight + 34, 'KEEP MINING FOR BONUSES', 20, '#e5c58f');
        text(775, MILESTONES.map(m => `$${Math.ceil(config.target * m.fraction)}: ${m.label}`).join('   •   '), 20, '#ffda69');

        let starting = false;
        menuButton(this, WORLD.centerX, 840, 'START MINING', () => {
            if (starting) return;
            starting = true;
            soundEffects.unlock();
            this.scene.start('Game', { ...data, level });
        });
        addSoundButton(this, 32, 24);
        responsiveLayout(this);
    }
}
