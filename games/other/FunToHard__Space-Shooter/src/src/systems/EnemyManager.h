#pragma once
#include "../entities/Enemy.h"
#include "../entities/Player.h"
#include "../systems/BulletManager.h"
#include <functional>
#include <memory>
#include <random>
#include <vector>

namespace SpaceShooter {

struct SpawnWave
{
    float spawnTime;
    EnemyType enemyType;
    Vec2 spawnPosition;
    bool spawned;

    SpawnWave(float time, EnemyType type, Vec2 pos)
        : spawnTime(time)
        , enemyType(type)
        , spawnPosition(pos)
        , spawned(false)
    {
    }
};

class EnemyManager
{
  private:
    std::vector<std::unique_ptr<Enemy>> enemies;
    std::vector<SpawnWave> spawnWaves;

    // Spawning control
    float gameTime;
    float nextSpawnTime;
    float baseSpawnInterval;
    float difficultyMultiplier;

    // Wave management
    int currentWave;
    int enemiesSpawnedThisWave;
    int enemiesPerWave;

    // Random generation
    std::random_device randomDevice;
    std::mt19937 randomGenerator;

    // Collision system
    std::vector<Enemy*> enemiesToRemove;

    // Score callback
    std::function<void(int)> onEnemyDestroyed;

    // Explosion callback
    std::function<void(Vec2)> onEnemyExploded;

  public:
    EnemyManager();
    ~EnemyManager() = default;

    // Initialize the system
    void Initialize();

    // Set callback for when enemies are destroyed (for scoring)
    void SetEnemyDestroyedCallback(std::function<void(int)> callback);

    // Set callback for when enemies explode (for visual effects)
    void SetEnemyExplodedCallback(std::function<void(Vec2)> callback);

    // Core system methods
    void Update(float deltaTime, Player* player, BulletManager* bulletManager);
    void Draw();
    void Reset();

    // Spawning methods
    void SpawnEnemy(EnemyType type, Vec2 position);
    void GenerateSpawnWave();
    void UpdateSpawning(float deltaTime);

    // AI and behavior
    void UpdateEnemyAI(float deltaTime, Vec2 playerPosition);
    void UpdateEnemyCombat(float deltaTime, BulletManager* bulletManager);

    // Collision detection
    void CheckPlayerCollisions(Player* player);
    void CheckBulletCollisions(BulletManager* bulletManager);

    // Cleanup
    void RemoveInactiveEnemies();

    // Getters
    size_t GetActiveEnemyCount() const;
    int GetCurrentWave() const
    {
        return currentWave;
    }
    const std::vector<std::unique_ptr<Enemy>>& GetEnemies() const
    {
        return enemies;
    }

    // Difficulty scaling
    void UpdateDifficulty();

  private:
    Vec2 GenerateSpawnPosition(EnemyType type);
    EnemyType SelectRandomEnemyType();
    float GetSpawnIntervalForType(EnemyType type);
    int GetScoreForEnemyType(EnemyType type);
    bool ShouldSpawnEnemy();
};

} // namespace SpaceShooter
