import Phaser from 'phaser';

import config from './config';
import Game from './scenes/game';

const gameConfig = {
    type: Phaser.AUTO,
    scale: {
        mode: Phaser.Scale.FIT,
        autoCenter: Phaser.Scale.CENTER_BOTH
    },
    width: config.width,
    height: config.height,
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 300 },
            debug: false
        }
    },
    scene: [Game]
};
// eslint-disable-next-line no-unused-vars
const game = new Phaser.Game(gameConfig);
