import { responsiveLayout } from '../ui/ResponsiveLayout';
import { WORLD } from '../state/World';
import { Scene } from 'phaser';
import { drawEnvironment } from '../art/drawEnvironment';
import { MinerAnimator } from '../art/MinerAnimator';
import { addSoundButton, soundEffects } from '../audio/SoundEffects';
import { LEVELS } from '../state/Levels';
import { menuButton } from '../ui/menuButton';

export class MainMenu extends Scene {
    constructor() { super('MainMenu'); }

    create(): void {
        drawEnvironment(this);
        new MinerAnimator(this);
        this.add.rectangle(WORLD.centerX, 570, 820, 640, 0x211f1d, 0.96).setStrokeStyle(4, 0xc29659);
        this.add.text(WORLD.centerX, 320, 'GOLD MINER', { fontFamily: 'Arial', fontSize: 64, fontStyle: 'bold', color: '#ffda69', stroke: '#483126', strokeThickness: 6 }).setOrigin(0.5);
        this.add.text(WORLD.centerX, 385, `${LEVELS.length} caves. One fortune to make.`, { fontFamily: 'Arial', fontSize: 25, color: '#fff3cc' }).setOrigin(0.5);
        this.add.text(WORLD.centerX, 450, 'HOW TO PLAY', { fontFamily: 'Arial', fontSize: 25, fontStyle: 'bold', color: '#ffda69' }).setOrigin(0.5);
        this.add.text(WORLD.centerX, 605,
            '↓ / CLICK    Launch the claw\n↑    Throw dynamite at a caught object\nP / ESC    Pause or resume\n\nReach the level target before time runs out.\nFinish Level ends the round early. Below target means a loss.\nBlast gem-studded rocks to scatter treasure you can catch.\nYou have 3 lives per run. Each failed level costs one.',
            { fontFamily: 'Arial', fontSize: 21, color: '#fff3cc', align: 'center', lineSpacing: 10 }
        ).setOrigin(0.5);
        let starting = false;
        menuButton(this, WORLD.centerX, 817, 'START NEW GAME', () => {
            if (starting) return;
            starting = true;
            soundEffects.unlock();
            this.scene.start('MineSelection', { level: 1, money: 0, dynamite: 3, lives: 3 });
        });
        addSoundButton(this, 32, 24);
        responsiveLayout(this);
    }
}
