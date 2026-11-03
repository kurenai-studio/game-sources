window.addEventListener('error', (e) => {
    console.error('[StatQuest] Erro:', e.error || e.message);
    const div = document.createElement('div');
    div.style.cssText = 'position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);background:#220000;color:#ff8888;padding:20px;border:2px solid #ff4444;z-index:9999;font-family:monospace;max-width:600px;font-size:12px;';
    div.textContent = 'Erro: ' + (e.error?.stack || e.message);
    document.body.appendChild(div);
});

import { BootScene }      from './scenes/BootScene.js';
import { MainMenuScene }  from './scenes/MainMenuScene.js';
import { WorldScene }     from './scenes/WorldScene.js';
import { UIScene }        from './scenes/UIScene.js';
import { CombatScene }    from './scenes/CombatScene.js';
import { InventoryScene } from './scenes/InventoryScene.js';
import { CharacterScene } from './scenes/CharacterScene.js';
import { ShopScene }              from './scenes/ShopScene.js';
import { QuestScene }             from './scenes/QuestScene.js';
import { BookScene }              from './scenes/BookScene.js';
import { SkillScene }             from './scenes/SkillScene.js';
import { DialogScene }            from './scenes/DialogScene.js';
import { InferenceScene }         from './scenes/InferenceScene.js';
import { IntroScene }             from './scenes/IntroScene.js';
import { CharacterCreationScene } from './scenes/CharacterCreationScene.js';
import { CompendiumScene }     from './scenes/CompendiumScene.js';
import { ScratchpadScene }     from './scenes/ScratchpadScene.js';
import { GameOverScene }       from './scenes/GameOverScene.js';
import { GambleScene }         from './scenes/GambleScene.js';
import { GAME_WIDTH, GAME_HEIGHT } from './constants.js';

const config = {
    type: Phaser.AUTO,
    parent: 'game-container',
    backgroundColor: '#000000',
    scene: [
        BootScene, MainMenuScene, IntroScene, CharacterCreationScene,
        WorldScene, UIScene, CombatScene,
        InventoryScene, CharacterScene, ShopScene, QuestScene, BookScene, SkillScene,
        DialogScene, InferenceScene, CompendiumScene, ScratchpadScene, GameOverScene,
        GambleScene,
    ],
    scale: {
        mode: Phaser.Scale.NONE,
        width: GAME_WIDTH,
        height: GAME_HEIGHT,
    },
    pixelArt: true,
    render: { antialias: false },
};

new Phaser.Game(config);
