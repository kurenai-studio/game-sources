/**
 * Space Runner Game API
 * 
 * Direct canvas integration without iframe
 * 
 * Usage:
 *   import { createSpaceRunner } from './SpaceRunnerAPI.js';
 *   
 *   const canvas = document.getElementById('my-canvas');
 *   const game = createSpaceRunner(canvas, {
 *     width: 800,
 *     height: 600,
 *     onReady: () => console.log('Game ready'),
 *     onClose: () => console.log('Game closed')
 *   });
 *   
 *   // Control game
 *   game.setTheme('dark');
 *   game.getHighScore();
 *   game.destroy();
 */

import Phaser from 'phaser';
import { GameScene } from './GameScene.js';

let gameInstance = null;
let gameSceneInstance = null;

export function createSpaceRunner(canvasOrId, options = {}) {
  if (gameInstance) {
    console.warn('SpaceRunner: Game instance already exists. Destroying previous instance.');
    gameInstance.destroy(true);
  }

  const canvas = typeof canvasOrId === 'string' 
    ? document.getElementById(canvasOrId)
    : canvasOrId;

  if (!canvas) {
    throw new Error('SpaceRunner: Canvas element or ID not found');
  }

  if (!(canvas instanceof HTMLCanvasElement)) {
    throw new Error('SpaceRunner: Provided element is not a canvas');
  }

  const {
    width = canvas.width || 800,
    height = canvas.height || 600,
    onReady = () => {},
    onClose = () => {},
    onHighScore = () => {},
    theme = null,
    customColors = null
  } = options;

  const config = {
    type: Phaser.AUTO,
    canvas: canvas,
    width: width,
    height: height,
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

  window.__spaceRunnerCanvas = canvas;
  gameInstance = new Phaser.Game(config);

  const resizeHandler = () => {
    if (gameInstance && gameInstance.scale) {
      const newWidth = canvas.width || canvas.clientWidth || width;
      const newHeight = canvas.height || canvas.clientHeight || height;
      gameInstance.scale.resize(newWidth, newHeight);
      if (gameSceneInstance) {
        gameSceneInstance.gameWidth = newWidth;
        gameSceneInstance.gameHeight = newHeight;
        gameSceneInstance.updateGameSize();
      }
    }
  };

  const observer = new ResizeObserver(resizeHandler);
  observer.observe(canvas);

  window.addEventListener('resize', resizeHandler);

  const api = {
    get game() {
      return gameInstance;
    },

    get scene() {
      return gameSceneInstance;
    },

    setTheme(mode) {
      if (gameSceneInstance && gameSceneInstance.themeManager) {
        if (gameSceneInstance.themeManager.setTheme(mode)) {
          gameSceneInstance.applyTheme();
          return true;
        }
      }
      return false;
    },

    getTheme() {
      if (gameSceneInstance && gameSceneInstance.themeManager) {
        return {
          mode: gameSceneInstance.themeManager.getThemeMode(),
          isDark: gameSceneInstance.themeManager.isDark,
          hasCustomColors: gameSceneInstance.themeManager.customTheme !== null
        };
      }
      return null;
    },

    setCustomColors(colors) {
      if (gameSceneInstance && gameSceneInstance.themeManager) {
        gameSceneInstance.themeManager.setCustomColors(colors);
        gameSceneInstance.applyTheme();
        return true;
      }
      return false;
    },

    clearCustomColors() {
      if (gameSceneInstance && gameSceneInstance.themeManager) {
        gameSceneInstance.themeManager.clearCustomColors();
        gameSceneInstance.applyTheme();
        return true;
      }
      return false;
    },

    getHighScore() {
      try {
        const highScore = parseInt(localStorage.getItem('spaceRunnerHighScore') || '0', 10);
        if (onHighScore) {
          onHighScore(highScore);
        }
        return highScore;
      } catch (e) {
        return 0;
      }
    },

    resetHighScore() {
      try {
        localStorage.removeItem('spaceRunnerHighScore');
        if (onHighScore) {
          onHighScore(0);
        }
        return true;
      } catch (e) {
        return false;
      }
    },

    getScore() {
      return gameSceneInstance ? gameSceneInstance.score : 0;
    },

    getLives() {
      return gameSceneInstance ? gameSceneInstance.lives : 0;
    },

    getLevel() {
      return gameSceneInstance ? gameSceneInstance.level : 1;
    },

    isGameOver() {
      return gameSceneInstance ? gameSceneInstance.gameOver : false;
    },

    isPaused() {
      return gameSceneInstance ? gameSceneInstance.isPaused : false;
    },

    pause() {
      if (gameSceneInstance) {
        gameSceneInstance.isPaused = true;
        return true;
      }
      return false;
    },

    resume() {
      if (gameSceneInstance) {
        gameSceneInstance.isPaused = false;
        return true;
      }
      return false;
    },

    restart() {
      if (gameSceneInstance) {
        gameSceneInstance.restart();
        return true;
      }
      return false;
    },

    resize(newWidth, newHeight) {
      if (gameInstance && gameInstance.scale) {
        gameInstance.scale.resize(newWidth, newHeight);
        if (gameSceneInstance) {
          gameSceneInstance.gameWidth = newWidth;
          gameSceneInstance.gameHeight = newHeight;
          gameSceneInstance.updateGameSize();
        }
        return true;
      }
      return false;
    },

    toggleFullscreen() {
      if (gameSceneInstance) {
        gameSceneInstance.toggleFullscreen();
        return true;
      }
      return false;
    },

    requestFullscreen() {
      if (canvas && !document.fullscreenElement) {
        return canvas.requestFullscreen().then(() => {
          if (gameSceneInstance) {
            setTimeout(() => {
              gameSceneInstance.updateGameSize();
              const width = canvas.width || canvas.clientWidth;
              const height = canvas.height || canvas.clientHeight;
              gameSceneInstance.scale.resize(width, height);
            }, 100);
          }
        });
      }
      return Promise.resolve();
    },

    exitFullscreen() {
      if (document.fullscreenElement) {
        return document.exitFullscreen().then(() => {
          if (gameSceneInstance) {
            gameSceneInstance.updateGameSize();
            const width = canvas.width || canvas.clientWidth;
            const height = canvas.height || canvas.clientHeight;
            gameSceneInstance.scale.resize(width, height);
          }
        });
      }
      return Promise.resolve();
    },

    destroy() {
      if (observer) {
        observer.disconnect();
      }
      window.removeEventListener('resize', resizeHandler);
      
      if (gameInstance) {
        gameInstance.destroy(true);
        gameInstance = null;
      }
      
      gameSceneInstance = null;
      
      if (onClose) {
        onClose();
      }
    }
  };

  const handleSceneReady = (scene) => {
    gameSceneInstance = scene;
    
    if (theme) {
      api.setTheme(theme);
    }
    
    if (customColors) {
      api.setCustomColors(customColors);
    }
    
    if (onReady) {
      setTimeout(() => onReady(api), 200);
    }
  };

  window.__setGameSceneInstance = handleSceneReady;
  
  gameInstance.scene.start('GameScene');
  
  setTimeout(() => {
    const scene = gameInstance.scene.getScene('GameScene');
    if (scene) {
      handleSceneReady(scene);
    }
  }, 100);

  return api;
}

export default createSpaceRunner;

