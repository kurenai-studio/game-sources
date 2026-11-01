#pragma once
#include "../entities/Player.h"
#include "../entities/PowerUp.h"
#include <memory>
#include <random>
#include <vector>

namespace SpaceShooter {

class PowerUpManager
{
  private:
    std::vector<std::unique_ptr<PowerUp>> powerUps;

    // Spawning control
    float gameTime;
    float nextSpawnTime;
    float baseSpawnInterval;

    // Random generation
    std::random_device randomDevice;
    std::mt19937 randomGenerator;

  public:
    PowerUpManager();
    ~PowerUpManager() = default;

    void Initialize();
    void Update(float deltaTime, Player* player);
    void Draw();
    void Reset();

    // Spawning methods
    void SpawnRandomPowerUp();
    void SpawnPowerUp(PowerUpType type, Vec2 position);
    Vec2 GenerateSpawnPosition();
    PowerUpType GetRandomPowerUpType();

    // Collision detection
    void CheckPlayerCollisions(Player* player);

    // Cleanup
    void RemoveInactivePowerUps();

    // Getters
    size_t GetActivePowerUpCount() const;
};

} // namespace SpaceShooter
