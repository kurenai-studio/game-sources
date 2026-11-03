import { generateTextures } from '../utils/Draw.js';

export class BootScene extends Phaser.Scene {
    constructor() { super('Boot'); }

    create() {
        generateTextures(this);
        this.scene.start('MainMenu');
    }
}
