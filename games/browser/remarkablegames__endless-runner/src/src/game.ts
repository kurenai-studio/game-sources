import type { Engine } from '@babylonjs/core/Engines/engine';
import type { Scene } from '@babylonjs/core/scene';

import { MusicManager, SoundManager } from './audio';
import { DIFFICULTY_CONFIG } from './config/game-constants';
import { GameState } from './core/game-state';
import { Player, PlayerVisual } from './entities';
import { UIManager } from './scenes/ui-manager';
import {
  CollisionDetector,
  DifficultyManager,
  InputHandler,
  InputSystem,
  ObstaclePool,
  ObstacleSpawner,
  ObstacleSystem,
  RenderSystem,
} from './systems';
import { GameStateEnum } from './types/game-state';

/**
 * Game - Orchestrates all game systems and manages the update loop.
 */
export class Game {
  private readonly gameState = new GameState();
  private readonly difficultyManager = new DifficultyManager(DIFFICULTY_CONFIG);
  private readonly inputHandler = new InputHandler();
  private readonly player = new Player();
  private readonly collisionDetector = new CollisionDetector();
  private readonly playerVisual: PlayerVisual;
  private readonly obstaclePool: ObstaclePool;
  private readonly obstacleSystem: ObstacleSystem;
  private readonly musicManager: MusicManager;
  private readonly soundManager: SoundManager;
  private readonly uiManager: UIManager;
  private readonly renderSystem: RenderSystem;
  private readonly inputSystem: InputSystem;

  constructor(engine: Engine, scene: Scene) {
    this.musicManager = new MusicManager(scene);
    this.soundManager = new SoundManager(scene);
    this.inputSystem = new InputSystem(this.player, this.soundManager);
    this.playerVisual = new PlayerVisual(this.player, scene);
    this.obstaclePool = new ObstaclePool(scene);
    const obstacleSpawner = new ObstacleSpawner(this.obstaclePool);
    this.obstacleSystem = new ObstacleSystem(obstacleSpawner);
    this.renderSystem = new RenderSystem(engine, scene);

    this.uiManager = new UIManager(
      this.soundManager,
      () => {
        this.startRun();
      },
      () => {
        this.resumeRun();
      },
    );

    this.inputHandler.initialize();

    scene.onReadyObservable.addOnce(() => {
      document.getElementById('spinner')?.remove();
      this.uiManager.render(
        this.gameState.getState(),
        this.gameState.getScore(),
      );
    });
  }

  start() {
    this.renderSystem.startRenderLoop((deltaTime) => {
      this.update(deltaTime);
    });
  }

  private update(deltaTime: number) {
    this.handlePauseInput();
    this.handleStartRestartInput();

    if (this.gameState.isRunning()) {
      this.updateRunning(deltaTime);
    } else {
      this.playerVisual.update();
    }

    this.uiManager.render(this.gameState.getState(), this.gameState.getScore());
  }

  private handlePauseInput() {
    if (this.inputHandler.consumePauseRequested()) {
      if (this.gameState.getState() === GameStateEnum.Running) {
        this.gameState.pauseGame();
        this.musicManager.pause();
        this.inputHandler.clearInputs();
      } else if (this.gameState.getState() === GameStateEnum.Paused) {
        this.resumeRun();
      }
    }
  }

  private handleStartRestartInput() {
    if (
      this.gameState.getState() === GameStateEnum.Start &&
      this.inputHandler.consumeStartRequested()
    ) {
      this.startRun();
    }

    if (
      this.gameState.getState() === GameStateEnum.GameOver &&
      this.inputHandler.consumeRestartRequested()
    ) {
      this.startRun();
    }
  }

  private updateRunning(deltaTime: number) {
    const inputDirection = this.inputHandler.pollInput();
    if (inputDirection !== null) {
      this.inputSystem.handleDirection(inputDirection);
    }

    this.player.update(deltaTime);
    this.playerVisual.update();
    this.difficultyManager.update(deltaTime);

    const currentSpeed = this.difficultyManager.getCurrentSpeed();
    const currentDensity = this.difficultyManager.getCurrentDensity();

    this.obstacleSystem.update(
      deltaTime,
      currentSpeed,
      currentDensity,
      this.difficultyManager.getRunDuration(),
    );
    this.gameState.updateScore(deltaTime, currentSpeed);

    if (
      this.collisionDetector.hasCollision(
        this.player,
        this.obstacleSystem.getActiveObstacles(),
      )
    ) {
      this.soundManager.collide.play();
      this.musicManager.pause();
      this.gameState.triggerGameOver();
      this.inputHandler.clearInputs();
    }
  }

  private resetRun() {
    this.player.reset();
    this.playerVisual.syncImmediate();
    this.difficultyManager.reset();
    this.obstacleSystem.reset();
    this.inputHandler.clearInputs();
  }

  private startRun() {
    if (this.gameState.getState() === GameStateEnum.Start) {
      this.resetRun();
      this.gameState.startGame();
      this.musicManager.play();
      return;
    }

    if (this.gameState.getState() === GameStateEnum.GameOver) {
      this.resetRun();
      this.gameState.restartGame();
      this.musicManager.resume();
    }
  }

  private resumeRun() {
    if (this.gameState.getState() === GameStateEnum.Paused) {
      this.gameState.resumeGame();
      this.musicManager.resume();
      this.inputHandler.clearInputs();
    }
  }

  pauseOnBlur() {
    if (this.gameState.getState() === GameStateEnum.Running) {
      this.gameState.pauseGame();
      this.musicManager.pause();
      this.inputHandler.clearInputs();
    }
  }

  dispose() {
    this.inputHandler.dispose();
    this.uiManager.dispose();
    this.playerVisual.dispose();
    this.obstaclePool.dispose();
    this.musicManager.dispose();
    this.soundManager.dispose();
  }
}
