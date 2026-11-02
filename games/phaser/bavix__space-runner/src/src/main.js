import Phaser from 'phaser';
import { GameScene } from './GameScene.js';

// Check if we're being initialized via API (canvas provided)
const canvasFromAPI = window.__spaceRunnerCanvas;
const parentElement = canvasFromAPI ? null : 'phaser-game';

const config = {
  type: Phaser.AUTO,
  ...(canvasFromAPI ? { canvas: canvasFromAPI } : { parent: parentElement }),
  width: canvasFromAPI ? (canvasFromAPI.width || window.innerWidth) : window.innerWidth,
  height: canvasFromAPI ? (canvasFromAPI.height || window.innerHeight) : window.innerHeight,
  pixelArt: true,
  render: {
    antialias: false,
    roundPixels: true,
    powerPreference: 'high-performance'
  },
  physics: {
    default: 'arcade',
    arcade: {
      debug: false,
      gravity: { y: 0 }
    }
  },
  scene: GameScene,
  scale: {
    mode: Phaser.Scale.RESIZE,
    autoCenter: Phaser.Scale.CENTER_BOTH
  },
  disableContextMenu: true,
  banner: false,
  input: {
    keyboard: true
  }
};

let game = null;

if (!canvasFromAPI) {
  game = new Phaser.Game(config);
} else {
  game = new Phaser.Game(config);
}

let gameSceneInstance = null;

if (!canvasFromAPI) {
  let resizeTimeout = null;
  window.addEventListener('resize', () => {
    if (resizeTimeout) {
      clearTimeout(resizeTimeout);
    }
    resizeTimeout = setTimeout(() => {
      if (game && game.scale) {
        const newWidth = window.innerWidth;
        const newHeight = window.innerHeight;
        game.scale.resize(newWidth, newHeight);
        if (gameSceneInstance) {
          gameSceneInstance.updateGameSize();
        }
      }
    }, 100);
  });
}

window.addEventListener('message', (event) => {
  
  const { type, data } = event.data || {};
  
  switch (type) {
    case 'close-game':
      if (window.parent !== window) {
        window.parent.postMessage({ type: 'game-closed' }, '*');
      }
      break;
    case 'get-high-score':
      try {
        const highScore = parseInt(localStorage.getItem('spaceRunnerHighScore') || '0', 10);
        if (window.parent !== window) {
          window.parent.postMessage({ 
            type: 'high-score', 
            data: { highScore } 
          }, '*');
        }
      } catch (e) {
        // Ignore
      }
      break;
    case 'reset-high-score':
      try {
        localStorage.removeItem('spaceRunnerHighScore');
        if (window.parent !== window) {
          window.parent.postMessage({ type: 'high-score-reset' }, '*');
        }
      } catch (e) {
        // Ignore
      }
      break;
    case 'set-theme':
      if (gameSceneInstance) {
        if (gameSceneInstance.themeManager.setTheme(data?.mode || data)) {
          gameSceneInstance.applyTheme();
        }
      }
      break;
    case 'set-colors':
      if (gameSceneInstance && data) {
        gameSceneInstance.themeManager.setCustomColors(data);
        gameSceneInstance.applyTheme();
      }
      break;
    case 'clear-colors':
      if (gameSceneInstance) {
        gameSceneInstance.themeManager.clearCustomColors();
        gameSceneInstance.applyTheme();
      }
      break;
    case 'get-theme':
      if (gameSceneInstance && window.parent !== window) {
        window.parent.postMessage({
          type: 'theme-info',
          data: {
            mode: gameSceneInstance.themeManager.getThemeMode(),
            isDark: gameSceneInstance.themeManager.isDark,
            hasCustomColors: gameSceneInstance.themeManager.customTheme !== null
          }
        }, '*');
      }
      break;
    case 'toggle-fullscreen':
      if (gameSceneInstance) {
        gameSceneInstance.toggleFullscreen();
      }
      break;
    case 'request-fullscreen':
      if (gameSceneInstance) {
        const container = document.getElementById('game-container');
        if (container && !document.fullscreenElement) {
          container.requestFullscreen().then(() => {
            setTimeout(() => {
              gameSceneInstance.updateGameSize();
              gameSceneInstance.scale.resize(gameSceneInstance.gameWidth, gameSceneInstance.gameHeight);
            }, 100);
          });
        }
      }
      break;
    case 'exit-fullscreen':
      if (document.fullscreenElement) {
        document.exitFullscreen().then(() => {
          if (gameSceneInstance) {
            gameSceneInstance.updateGameSize();
            gameSceneInstance.scale.resize(gameSceneInstance.gameWidth, gameSceneInstance.gameHeight);
          }
        });
      }
      break;
  }
});

export function setGameSceneInstance(scene) {
  gameSceneInstance = scene;
  
  if (window.__setGameSceneInstance) {
    window.__setGameSceneInstance(scene);
  }
  
  if (window.parent !== window) {
    setTimeout(() => {
      window.parent.postMessage({ type: 'game-ready' }, '*');
    }, 200);
  }
}

