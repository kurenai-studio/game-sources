#include "PowerUpManager.h"
#include "../utils/GameConfig.h"
#include <algorithm>
#include <iostream>
#include <raylib.h>

namespace SpaceShooter {

PowerUpManager::PowerUpManager()
    : gameTime(0.0f)
    , nextSpawnTime(20.0f)     // First power-up spawns after 20 seconds
    , baseSpawnInterval(25.0f) // Power-ups spawn every 25 seconds
    , randomGenerator(randomDevice())
{
    powerUps.reserve(10);
}

void PowerUpManager::Initialize()
{
    // Reset all state
    gameTime = 0.0f;
    nextSpawnTime = 20.0f;

    // Clear existing power-ups
    powerUps.clear();

    std::cout << "[DEBUG] PowerUpManager initialized!" << std::endl;
}

void PowerUpManager::Update(float deltaTime, Player* player)
{
    gameTime += deltaTime;

    // Handle spawning
    if(gameTime >= nextSpawnTime) {
        SpawnRandomPowerUp();

        // Calculate next spawn time with some randomness
        std::uniform_real_distribution<float> dist(0.8f, 1.2f);
        float randomMultiplier = dist(randomGenerator);
        nextSpawnTime = gameTime + (baseSpawnInterval * randomMultiplier);
    }

    // Update all power-ups
    for(auto& powerUp : powerUps) {
        if(powerUp && powerUp->IsActive()) {
            powerUp->Update(deltaTime);
        }
    }

    // Check collisions with player
    if(player && player->IsActive()) {
        CheckPlayerCollisions(player);
    }

    // Remove inactive power-ups
    RemoveInactivePowerUps();
}

void PowerUpManager::Draw()
{
    for(auto& powerUp : powerUps) {
        if(powerUp && powerUp->IsActive()) {
            powerUp->Draw();
        }
    }
}

void PowerUpManager::SpawnRandomPowerUp()
{
    PowerUpType type = GetRandomPowerUpType();
    Vec2 position = GenerateSpawnPosition();
    SpawnPowerUp(type, position);
}

void PowerUpManager::SpawnPowerUp(PowerUpType type, Vec2 position)
{
    auto powerUp = std::make_unique<PowerUp>(type, position);
    powerUps.push_back(std::move(powerUp));

    std::cout << "[DEBUG] Spawned power-up type " << (int)type << " at position (" << position.x << ", " << position.y
              << ")" << std::endl;
}

Vec2 PowerUpManager::GenerateSpawnPosition()
{
    // Generate random X position within screen bounds with some margin
    std::uniform_real_distribution<float> xDist(50.0f, SCREEN_WIDTH - 50.0f);
    float x = xDist(randomGenerator);

    // Spawn above the screen
    float y = -30.0f;

    return Vec2(x, y);
}

PowerUpType PowerUpManager::GetRandomPowerUpType()
{
    // Equal probability for each power-up type
    std::uniform_int_distribution<int> dist(1, 3); // 1-3 (excluding NONE)
    int type = dist(randomGenerator);

    switch(type) {
        case 1:
            return PowerUpType::DOUBLE_SHOT;
        case 2:
            return PowerUpType::SHIELD;
        case 3:
            return PowerUpType::SPEED_BOOST;
        default:
            return PowerUpType::DOUBLE_SHOT;
    }
}

void PowerUpManager::CheckPlayerCollisions(Player* player)
{
    if(!player)
        return;

    Rectangle playerBounds = player->GetBounds();

    for(auto& powerUp : powerUps) {
        if(!powerUp || !powerUp->IsActive() || powerUp->IsCollected()) {
            continue;
        }

        Rectangle powerUpBounds = powerUp->GetBounds();

        if(CheckCollisionRecs(playerBounds, powerUpBounds)) {
            // Apply power-up to player
            player->ApplyPowerUp(powerUp->GetPowerUpType());

            // Mark power-up as collected
            powerUp->Collect();

            std::cout << "[DEBUG] Player collected power-up type " << (int)powerUp->GetPowerUpType() << std::endl;
        }
    }
}

void PowerUpManager::RemoveInactivePowerUps()
{
    powerUps.erase(
        std::remove_if(powerUps.begin(), powerUps.end(),
                       [](const std::unique_ptr<PowerUp>& powerUp) { return !powerUp || !powerUp->IsActive(); }),
        powerUps.end());
}

void PowerUpManager::Reset()
{
    powerUps.clear();
    gameTime = 0.0f;
    nextSpawnTime = 20.0f;

    std::cout << "[DEBUG] PowerUpManager reset!" << std::endl;
}

size_t PowerUpManager::GetActivePowerUpCount() const
{
    size_t count = 0;
    for(const auto& powerUp : powerUps) {
        if(powerUp && powerUp->IsActive()) {
            count++;
        }
    }
    return count;
}

} // namespace SpaceShooter
