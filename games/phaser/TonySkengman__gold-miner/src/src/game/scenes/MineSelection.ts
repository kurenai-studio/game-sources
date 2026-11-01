import { Scene } from 'phaser';
import { LEVELS } from '../state/Levels';
import { newLevelSeed } from '../state/Random';
import { MINES, type MineKind } from '../state/Mines';
import { emptyUpgrades, emptyBonuses, type Upgrades, type LevelBonuses } from '../state/Upgrades';
import { WORLD } from '../state/World';
import { responsiveLayout } from '../ui/ResponsiveLayout';
import { addSoundButton, soundEffects } from '../audio/SoundEffects';

interface MineSelectionData {
    levelSeed?: number;
    level: number; money: number; lives: number; upgrades?: Upgrades;
    dynamite: number; bonuses?: LevelBonuses;
}

export class MineSelection extends Scene {
    constructor() { super('MineSelection'); }

    create(data: MineSelectionData): void {
        const prepared = { ...data, levelSeed: data.levelSeed ?? newLevelSeed(), upgrades: { ...emptyUpgrades(), ...data.upgrades }, bonuses: { ...emptyBonuses(), ...data.bonuses } };
        this.cameras.main.setBackgroundColor(0x252a25);
        addSoundButton(this, 32, 16);
        const label = (x: number, y: number, value: string, size = 22, color = '#fff3cc', width = 250) =>
            this.add.text(x, y, value, { fontFamily: 'Arial', fontSize: size, color, align: 'center', wordWrap: { width }, lineSpacing: 8 })
                .setOrigin(0.5).setData('responsiveAnchor', 'center');
        label(WORLD.centerX, 105, 'CHOOSE YOUR GAME MODE', 32, '#ffda69', 900).setFontStyle('bold');
        label(WORLD.centerX, 169, 'Choose once for this run.', 20, '#e5c58f', 900);
        let entering = false;
        const modeOrder: MineKind[] = ['goldBasin', 'quarry', 'gemHollow'];
        modeOrder.forEach((kind, index) => {
            const mine = MINES[kind];
            const standard = kind === 'quarry';
            const x = WORLD.centerX + (index - 1) * 338;
            this.add.rectangle(x, 516, standard ? 350 : 278, standard ? 636 : 576,
                kind === 'gemHollow' ? 0x2a2b45 : kind === 'goldBasin' ? 0x493821 : 0x493d2d)
                .setStrokeStyle(standard ? 4 : 2, standard ? 0xffda69 : mine.color)
                .setData('responsiveAnchor', 'center');
            if (standard) {
                this.add.rectangle(x, 226, 242, 38, 0xffda69)
                    .setData('responsiveAnchor', 'center');
            }
            label(x, standard ? 226 : 246, standard ? 'STANDARD MODE' : 'ALTERNATIVE MODE', standard ? 19 : 13,
                standard ? '#302719' : '#d2c5ad').setFontStyle('bold');
            label(x, 285, mine.name, standard ? 32 : 27, '#ffda69', standard ? 326 : 250).setFontStyle('bold');
            label(x, 315, mine.playstyle, 13, '#bcf58b').setFontStyle('bold');
            const g = this.add.graphics().setPosition(x, standard ? 413 : 403).setData('responsiveAnchor', 'center');
            if (standard) g.setScale(1.12);
            g.fillStyle(kind === 'gemHollow' ? 0x525579 : kind === 'goldBasin' ? 0x9a793e : 0x746351).fillRoundedRect(-92, -66, 184, 132, 53);
            g.fillStyle(kind === 'gemHollow' ? 0x151b38 : 0x111816).fillRoundedRect(-67, -48, 134, 114, 42);
            if (kind === 'gemHollow') {
                for (const side of [-1, 1]) {
                    g.fillStyle(0x77d7e7, 0.12).fillCircle(side * 62, 4, 46);
                    g.fillStyle(0x79cbdc).fillTriangle(side * 74, -40, side * 45, -9, side * 76, 12);
                    g.fillStyle(0xad83dc).fillTriangle(side * 69, 66, side * 43, 15, side * 31, 66);
                    g.lineStyle(2, 0xdcecff, 0.6).lineBetween(side * 69, 61, side * 43, 15);
                }
                g.fillStyle(0x8074b0).fillTriangle(-15, -56, 5, -56, -3, -16);
            } else {
                g.lineStyle(10, 0x9d7041).lineBetween(-75, 65, -75, -55).lineBetween(75, 65, 75, -55).lineBetween(-86, -55, 86, -55);
                g.lineStyle(4, 0x665746).lineBetween(-40, 66, -16, 13).lineBetween(40, 66, 16, 13);
                if (kind === 'goldBasin') {
                    g.lineStyle(4, 0xe9bd5f).beginPath().moveTo(-88, -20).lineTo(-69, -3).lineTo(-89, 21).strokePath();
                    g.fillStyle(0xffca57, 0.12).fillCircle(0, 15, 50);
                    g.fillStyle(0xe9b540).fillEllipse(-20, 46, 35, 25).fillEllipse(20, 53, 42, 28);
                } else {
                    // A warm treasure-filled entrance reflects the standard mode's varied loot.
                    g.fillStyle(0xffcf65, 0.1).fillCircle(0, 20, 46);
                    g.fillStyle(0x090e0c, 0.5).fillEllipse(0, 56, 112, 22);
                    g.fillStyle(0x56321d).fillRoundedRect(-29, 13, 58, 43, 5);
                    g.fillStyle(0xa56730).fillRoundedRect(-29, 13, 58, 21, 5);
                    g.fillStyle(0x78451f).fillRect(-27, 35, 54, 19);
                    g.lineStyle(2, 0xe6b957).strokeRoundedRect(-29, 13, 58, 43, 5);
                    g.fillStyle(0xd7a649).fillRect(-20, 14, 5, 41).fillRect(15, 14, 5, 41);
                    g.lineStyle(2, 0x452818).lineBetween(-28, 34, 28, 34);
                    g.fillStyle(0xffdc79).fillRoundedRect(-5, 29, 10, 13, 2);
                    g.fillStyle(0x56321d).fillCircle(0, 34, 2);
                    g.fillStyle(0xe6ad34).fillEllipse(-48, 51, 27, 19).fillEllipse(-35, 61, 24, 15);
                    g.fillStyle(0xffdc73).fillEllipse(-51, 47, 15, 8);
                    g.fillStyle(0x58c4e6).fillTriangle(36, 44, 55, 44, 45, 64);
                    g.fillStyle(0xc4f5ff).fillTriangle(36, 44, 45, 36, 55, 44);
                    g.fillStyle(0xb63e65).fillTriangle(49, 61, 66, 61, 58, 74);
                    g.fillStyle(0xff8ca8).fillTriangle(49, 61, 57, 53, 66, 61);
                    g.lineStyle(2, 0xffe7a1).lineBetween(-42, 24, -42, 34).lineBetween(-47, 29, -37, 29);
                    g.lineStyle(2, 0xd9faff).lineBetween(48, 9, 48, 19).lineBetween(43, 14, 53, 14);
                }
            }
            for (const side of [-1, 1]) {
                g.fillStyle(mine.color);
                if (kind === 'gemHollow') g.fillTriangle(side * 94, 39, side * 113, 64, side * 74, 64);
                else {
                    g.fillEllipse(side * 91, 57, 38, 27);
                    if (standard) {
                        g.fillStyle(0xffda69).fillEllipse(side * 94, 52, 20, 10);
                    }
                }
            }
            label(x, standard ? 573 : 549, mine.description, standard ? 20 : 18, '#fff3cc', standard ? 294 : 250);
            label(x, 674, mine.subtext, standard ? 16 : 15, '#e5c58f', standard ? 286 : 238);
            const button = this.add.text(x, 765, 'START RUN', {
                fontFamily: 'Arial', fontSize: standard ? 25 : 22, fontStyle: 'bold', color: standard ? '#302719' : '#ffffff',
                backgroundColor: standard ? '#ffda69' : '#547f3b', padding: { x: standard ? 30 : 18, y: 15 }
            }).setOrigin(0.5).setData('responsiveAnchor', 'center');
            button.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
                if (entering) return;
                entering = true;
                soundEffects.unlock();
                this.scene.start('LevelBriefing', { ...prepared, mine: kind });
            });
        });
        label(WORLD.centerX, 870, `Your mode lasts for the full ${LEVELS.length}-level run, including retries.`, 20, '#e5c58f', 900);
        responsiveLayout(this);
    }
}
