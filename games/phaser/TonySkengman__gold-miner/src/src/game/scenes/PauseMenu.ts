import { responsiveLayout } from '../ui/ResponsiveLayout';
import { WORLD } from '../state/World';
import { Scene } from 'phaser';
import { addSoundButton } from '../audio/SoundEffects';
import { menuButton } from '../ui/menuButton';

export class PauseMenu extends Scene {
    constructor() { super('PauseMenu'); }

    create(): void {
        this.add.rectangle(WORLD.centerX, 480, WORLD.width, WORLD.height, 0x11151a, 0.78).setData('responsiveFullWidth', true).setInteractive();
        this.add.rectangle(WORLD.centerX, 480, 720, 480, 0xffedbb).setStrokeStyle(4, 0xc29659);
        this.add.text(WORLD.centerX, 310, 'PAUSED', { fontFamily: 'Arial', fontSize: 46, fontStyle: 'bold', color: '#70452a' }).setOrigin(0.5);
        this.add.text(WORLD.centerX, 395, '↓ / CLICK: launch    •    ↑: dynamite\nP / ESC: resume\nThe timer and all movement are stopped.', { fontFamily: 'Arial', fontSize: 22, color: '#483126', align: 'center', lineSpacing: 12 }).setOrigin(0.5);
        let leaving = false;
        const resume = () => {
            if (leaving) return;
            leaving = true;
            this.scene.resume('Game');
            this.scene.stop();
        };
        menuButton(this, WORLD.centerX, 511, 'RESUME', resume);
        menuButton(this, WORLD.centerX, 602, 'END RUN & MAIN MENU', () => {
            if (leaving) return;
            leaving = true;
            this.scene.stop('Game');
            this.scene.start('MainMenu');
        });
        const onKey = (event: KeyboardEvent) => { if (!event.repeat) resume(); };
        this.input.keyboard?.on('keydown-P', onKey);
        this.input.keyboard?.on('keydown-ESC', onKey);
        this.events.once('shutdown', () => {
            this.input.keyboard?.off('keydown-P', onKey);
            this.input.keyboard?.off('keydown-ESC', onKey);
        });
        addSoundButton(this, 32, 24);
        responsiveLayout(this);
    }
}
