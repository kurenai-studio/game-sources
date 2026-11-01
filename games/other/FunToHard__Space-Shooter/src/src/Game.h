#pragma once
#include "entities/Player.h"
#include "systems/AudioManager.h"
#include "systems/BulletManager.h"
#include "systems/EnemyManager.h"
#include "systems/ExplosionManager.h"
#include "systems/PowerUpManager.h"
#include "systems/ResourceManager.h"
#include "utils/GameConfig.h"
#include <memory>
#include <raylib.h>

namespace SpaceShooter {

enum class GameState
{
    MENU,
    PLAYING,
    PAUSED,
    GAME_OVER
};

class Game
{
  private:
    GameState currentState;
    bool isRunning;

    // Game objects
    std::unique_ptr<Player> player;
    std::unique_ptr<BulletManager> bulletManager;
    std::unique_ptr<EnemyManager> enemyManager;
    std::unique_ptr<PowerUpManager> powerUpManager;
    std::unique_ptr<ExplosionManager> explosionManager;

    // Background
    Texture2D* backgroundTexture;
    float backgroundY1, backgroundY2;

    // Game stats
    int score;
    int wave;

  public:
    Game();
    ~Game();

    bool Initialize();
    void Run();
    void Shutdown();

  private:
    void Update(float deltaTime);
    void Draw();

    void UpdateMenu(float deltaTime);
    void UpdateGame(float deltaTime);
    void UpdatePause(float deltaTime);
    void UpdateGameOver(float deltaTime);

    void DrawMenu();
    void DrawGame();
    void DrawPause();
    void DrawGameOver();
    void DrawHUD();

    void StartNewGame();
    void ResetGame();

    // Score management
    void AddScore(int points);

    // Collision detection
    void CheckEnemyBulletPlayerCollisions();

    void UpdateBackground(float deltaTime);
    void DrawBackground();
};
} // namespace SpaceShooter
