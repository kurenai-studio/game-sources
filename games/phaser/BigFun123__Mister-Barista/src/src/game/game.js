import AGame from "./agame.js";
import MenuScene from "./scenes/scene_menu.js";
import MainScene from "./scenes/scene_main.js";
import ScoreScene from "./scenes/scene_scores.js";
import GameServer from "../services/gameserver.js";

var config = {
    type: Phaser.AUTO,
    width: 800,
    height: 600,
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 200 }
        }
    },    
    scene : [MenuScene,MainScene,GameServer,ScoreScene],
    audio: {
        disableWebAudio: false
    }
};

class Game extends AGame {
    constructor(config) {
        super(config);
        this.scene.start("GameServer", "fromStart");
    }
}

new Game(config);


