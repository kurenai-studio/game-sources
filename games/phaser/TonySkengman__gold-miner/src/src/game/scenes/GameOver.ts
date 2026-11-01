import type { MineKind } from '../state/Mines';
import { responsiveLayout } from '../ui/ResponsiveLayout';
import { WORLD } from '../state/World';
import { menuButton } from '../ui/menuButton';
import { LEVELS } from '../state/Levels';
import { addSoundButton } from '../audio/SoundEffects';
import { LevelBonuses, Upgrades, remainingBonuses } from '../state/Upgrades';
import { Scene } from 'phaser';

export interface Result { mine: MineKind; lives: number; levelSeed: number; bonuses: LevelBonuses; dynamite: number; startingDynamite: number; upgrades: Upgrades; money: number; startingMoney: number; score: number; target: number; won: boolean; level: number; finalLevel: boolean; }

export class GameOver extends Scene {
    constructor() { super('GameOver'); }

    create(result: Result): void {
        const runOver = !result.won && result.lives === 0;
        this.cameras.main.setBackgroundColor(0x483126);
        addSoundButton(this, 32, 16);
        this.add.rectangle(WORLD.centerX, 374, 660, 440, 0xffedbb).setStrokeStyle(6, 0xc58b47);
        this.add.text(WORLD.centerX, 245, result.won ? (result.finalLevel ? 'MINE MASTER!' : `LEVEL ${result.level} CLEARED!`) : (runOver ? 'GAME OVER' : `LEVEL ${result.level} FAILED`), { fontFamily: 'Arial', fontSize: 48, fontStyle: 'bold', color: '#70452a' }).setOrigin(0.5);
        this.add.text(WORLD.centerX, 340, `Level gold: $${result.score} / $${result.target}\nTotal money: $${result.money}  •  Lives: ${result.lives}`, { fontFamily: 'Arial', fontSize: 30, color: '#483126', align: 'center', lineSpacing: 12 }).setOrigin(0.5);
        this.add.text(WORLD.centerX, 422, result.won ? (result.finalLevel ? `You cleared all ${LEVELS.length} levels!` : 'Next level: a higher target and more rocks!') : (runOver ? 'No lives left. Start a new run from level 1.' : 'Life lost! Retry restores your starting money.'), { fontFamily: 'Arial', fontSize: 21, color: '#70452a' }).setOrigin(0.5);
        const button = this.add.rectangle(WORLD.centerX, 510, 250, 66, 0x547f3b).setStrokeStyle(3, 0x365725).setInteractive({ useHandCursor: true });
        this.add.text(WORLD.centerX, 510, result.won ? (result.finalLevel ? 'PLAY AGAIN' : 'UPGRADE SHOP') : (runOver ? 'NEW GAME' : 'RETRY LEVEL'), { fontFamily: 'Arial', fontSize: 26, fontStyle: 'bold', color: '#ffffff' }).setOrigin(0.5);
        menuButton(this, WORLD.centerX, 620, 'MAIN MENU', () => this.scene.start('MainMenu'));
        button.on('pointerover', () => button.setFillStyle(0x659b47));
        button.on('pointerout', () => button.setFillStyle(0x547f3b));
        button.once('pointerdown', () => {
            if (runOver) {
                this.scene.start('MineSelection', { level: 1, money: 0, dynamite: 3, lives: 3 });
                return;
            }
            this.scene.start(result.won ? (result.finalLevel ? 'MineSelection' : 'UpgradeShop') : 'LevelBriefing', {
                mine: result.won && result.finalLevel ? undefined : result.mine,
                lives: result.won && result.finalLevel ? 3 : result.lives,
                levelSeed: result.won ? undefined : result.levelSeed,
                bonuses: result.won ? (result.finalLevel ? undefined : remainingBonuses(result.bonuses)) : result.bonuses,
                dynamite: result.won ? (result.finalLevel ? 3 : result.dynamite) : result.startingDynamite,
                upgrades: result.won && result.finalLevel ? undefined : result.upgrades,
                level: result.won ? (result.finalLevel ? 1 : result.level + 1) : result.level,
                money: result.won ? (result.finalLevel ? 0 : result.money) : result.startingMoney
            });
        });
        responsiveLayout(this);
    }
}
