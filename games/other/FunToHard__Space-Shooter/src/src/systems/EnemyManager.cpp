#include "EnemyManager.h"
#include "../utils/GameConfig.h"
#include <algorithm>
#include <iostream>
#include <raylib.h>

namespace SpaceShooter {

EnemyManager::EnemyManager()
    : gameTime(0.0f)
    , nextSpawnTime(1.0f)
    , baseSpawnInterval(1.5f)
    , difficultyMultiplier(1.0f)
    , currentWave(1)
    , enemiesSpawnedThisWave(0)
    , enemiesPerWave(8)
    , randomGenerator(randomDevice())
{
    enemies.reserve(50);
    spawnWaves.reserve(100);
}

void EnemyManager::Initialize()
{
    // Reset all game state
    gameTime = 0.0f;
    nextSpawnTime = 1.0f;
    difficultyMultiplier = 1.0f;
    currentWave = 1;
    enemiesSpawnedThisWave = 0;

    // Clear any existing enemies and waves
    enemies.clear();
    spawnWaves.clear();
    enemiesToRemove.clear();

    // Generate the first wave
    GenerateSpawnWave();
}

void EnemyManager::GenerateSpawnWave()
{
    // Clear existing spawn waves
    spawnWaves.clear();

    // For now, basic spawning - no pre-planned waves
    // The UpdateSpawning method will handle dynamic spawning
    std::cout << "[DEBUG] Generated spawn wave " << currentWave << std::endl;
}

void EnemyManager::SetEnemyDestroyedCallback(std::function<void(int)> callback)
{
    onEnemyDestroyed = callback;
}

void EnemyManager::SetEnemyExplodedCallback(std::function<void(Vec2)> callback)
{
    onEnemyExploded = callback;
}

void EnemyManager::Update(float deltaTime, Player* player, BulletManager* bulletManager)
{
    gameTime += deltaTime;

    // Update difficulty based on time
    UpdateDifficulty();

    // Handle spawning
    UpdateSpawning(deltaTime);

    // Update enemy AI and behavior
    if(player && player->IsActive()) {
        UpdateEnemyAI(deltaTime, player->GetPosition());
    }

    // Update enemy combat
    UpdateEnemyCombat(deltaTime, bulletManager);

    // Update individual enemies
    for(auto& enemy : enemies) {
        if(enemy && enemy->IsActive()) {
            enemy->Update(deltaTime);
        }
    }

    // Handle collisions
    if(player) {
        CheckPlayerCollisions(player);
    }
    CheckBulletCollisions(bulletManager);

    // Clean up inactive enemies
    RemoveInactiveEnemies();
}

void EnemyManager::UpdateSpawning(float deltaTime)
{
    if(gameTime >= nextSpawnTime && ShouldSpawnEnemy()) {
        EnemyType enemyType = SelectRandomEnemyType();
        Vec2 spawnPos = GenerateSpawnPosition(enemyType);

        SpawnEnemy(enemyType, spawnPos);

        // Calculate next spawn time
        float spawnInterval = GetSpawnIntervalForType(enemyType);
        nextSpawnTime = gameTime + (spawnInterval / difficultyMultiplier);

        enemiesSpawnedThisWave++;

        // Check if wave is complete
        if(enemiesSpawnedThisWave >= enemiesPerWave) {
            currentWave++;
            enemiesSpawnedThisWave = 0;
            enemiesPerWave += 2; // Increase enemies per wave

            std::cout << "[DEBUG] Wave " << currentWave << " started! Enemies per wave: " << enemiesPerWave
                      << std::endl;
        }
    }
}

void EnemyManager::SpawnEnemy(EnemyType type, Vec2 position)
{
    auto enemy = Enemy::CreateEnemy(type, position);
    if(enemy) {
        enemies.push_back(std::move(enemy));

        std::cout << "[DEBUG] Spawned enemy type " << (int)type << " at position (" << position.x << ", " << position.y
                  << ")" << std::endl;
    }
}

Vec2 EnemyManager::GenerateSpawnPosition(EnemyType type)
{
    std::uniform_real_distribution<float> xDist(50.0f, SCREEN_WIDTH - 50.0f);

    float spawnY = -30.0f; // Spawn above screen

    switch(type) {
        case EnemyType::BASIC:
            // Basic enemies can spawn anywhere across the top
            break;
        case EnemyType::FAST:
            // Fast enemies prefer edges for surprise attacks
            if(randomGenerator() % 2 == 0) {
                return Vec2(xDist(randomGenerator) < SCREEN_WIDTH / 2 ? 30.0f : SCREEN_WIDTH - 30.0f, spawnY);
            }
            break;
        case EnemyType::HEAVY:
            // Heavy enemies spawn in the center area
            std::uniform_real_distribution<float> centerDist(SCREEN_WIDTH * 0.3f, SCREEN_WIDTH * 0.7f);
            return Vec2(centerDist(randomGenerator), spawnY);
    }

    return Vec2(xDist(randomGenerator), spawnY);
}

EnemyType EnemyManager::SelectRandomEnemyType()
{
    std::uniform_int_distribution<int> dist(0, 99);
    int roll = dist(randomGenerator);

    // Spawn probabilities based on difficulty
    float heavyChance = std::min(10.0f + (currentWave * 2.0f), 25.0f);
    float fastChance = std::min(25.0f + (currentWave * 1.5f), 40.0f);

    if(roll < heavyChance) {
        return EnemyType::HEAVY;
    } else if(roll < heavyChance + fastChance) {
        return EnemyType::FAST;
    } else {
        return EnemyType::BASIC;
    }
}

float EnemyManager::GetSpawnIntervalForType(EnemyType type)
{
    switch(type) {
        case EnemyType::BASIC:
            return baseSpawnInterval * 0.8f;
        case EnemyType::FAST:
            return baseSpawnInterval * 0.6f;
        case EnemyType::HEAVY:
            return baseSpawnInterval * 1.2f;
    }
    return baseSpawnInterval;
}

int EnemyManager::GetScoreForEnemyType(EnemyType type)
{
    switch(type) {
        case EnemyType::BASIC:
            return 100; // Basic enemies are worth 100 points
        case EnemyType::FAST:
            return 150; // Fast enemies are worth 150 points
        case EnemyType::HEAVY:
            return 500; // Heavy enemies (bosses) are worth 500 points
    }
    return 100; // Default fallback
}

bool EnemyManager::ShouldSpawnEnemy()
{
    // Don't spawn too many enemies at once
    size_t activeEnemies = GetActiveEnemyCount();
    size_t maxEnemies = 8 + (currentWave / 3); // Increase max enemies with waves

    return activeEnemies < maxEnemies;
}

void EnemyManager::UpdateEnemyAI(float deltaTime, Vec2 playerPosition)
{
    for(auto& enemy : enemies) {
        if(enemy && enemy->IsActive()) {
            enemy->UpdateAI(deltaTime, playerPosition);
        }
    }
}

void EnemyManager::UpdateEnemyCombat(float deltaTime, BulletManager* bulletManager)
{
    if(!bulletManager)
        return;

    for(auto& enemy : enemies) {
        if(enemy && enemy->IsActive()) {
            enemy->UpdateCombat(deltaTime, bulletManager);
        }
    }
}

void EnemyManager::CheckPlayerCollisions(Player* player)
{
    if(!player || !player->IsActive())
        return;

    Rectangle playerBounds = player->GetBounds();

    for(auto& enemy : enemies) {
        if(!enemy || !enemy->IsActive())
            continue;

        Rectangle enemyBounds = enemy->GetBounds();

        if(CheckCollisionRecs(playerBounds, enemyBounds)) {
            // Player takes damage
            player->TakeDamage(1);

            // Enemy is destroyed on collision
            enemy->TakeDamage(enemy->GetMaxHealth());

            std::cout << "[DEBUG] Player-Enemy collision! Player health: " << player->GetHealth() << std::endl;
        }
    }
}

void EnemyManager::CheckBulletCollisions(BulletManager* bulletManager)
{
    if(!bulletManager)
        return;

    const auto& bullets = bulletManager->GetPlayerBullets();

    for(const auto& bullet : bullets) {
        if(!bullet || !bullet->IsActive())
            continue;

        Rectangle bulletBounds = bullet->GetBounds();

        for(auto& enemy : enemies) {
            if(!enemy || !enemy->IsActive())
                continue;

            Rectangle enemyBounds = enemy->GetBounds();

            if(CheckCollisionRecs(bulletBounds, enemyBounds)) {
                // Determine damage based on bullet type
                int damage = (bullet->GetType() == BulletType::PLAYER_LASER) ? 2 : 1;

                // Check if enemy will be destroyed by this damage
                bool willBeDestroyed = (enemy->GetCurrentHealth() <= damage);
                EnemyType destroyedType = enemy->GetEnemyType();

                enemy->TakeDamage(damage);
                bullet->SetActive(false); // Bullet is consumed

                // Award points if enemy was destroyed
                if(willBeDestroyed && onEnemyDestroyed) {
                    int points = GetScoreForEnemyType(destroyedType);
                    onEnemyDestroyed(points);
                }

                // Create explosion if enemy was destroyed
                if(willBeDestroyed && onEnemyExploded) {
                    Vec2 explosionPos = enemy->GetPosition();
                    onEnemyExploded(explosionPos);
                }

                std::cout << "[DEBUG] Bullet hit enemy! Damage: " << damage
                          << " Enemy health: " << enemy->GetCurrentHealth() << std::endl;
                break; // Bullet can only hit one enemy
            }
        }
    }
}

void EnemyManager::RemoveInactiveEnemies()
{
    enemies.erase(std::remove_if(enemies.begin(), enemies.end(),
                                 [](const std::unique_ptr<Enemy>& enemy) { return !enemy || !enemy->IsActive(); }),
                  enemies.end());
}

void EnemyManager::UpdateDifficulty()
{
    // Gradually increase difficulty over time
    float timeMultiplier = 1.0f + (gameTime / 60.0f) * 0.2f;    // 20% increase per minute
    float waveMultiplier = 1.0f + (currentWave / 10.0f) * 0.3f; // 30% increase per 10 waves

    difficultyMultiplier = std::min(timeMultiplier * waveMultiplier, 3.0f); // Cap at 3x difficulty
}

size_t EnemyManager::GetActiveEnemyCount() const
{
    return std::count_if(enemies.begin(), enemies.end(),
                         [](const std::unique_ptr<Enemy>& enemy) { return enemy && enemy->IsActive(); });
}

void EnemyManager::Draw()
{
    for(const auto& enemy : enemies) {
        if(enemy && enemy->IsActive()) {
            enemy->Draw();
        }
    }
}

void EnemyManager::Reset()
{
    enemies.clear();
    spawnWaves.clear();

    gameTime = 0.0f;
    nextSpawnTime = 2.0f;
    difficultyMultiplier = 1.0f;
    currentWave = 1;
    enemiesSpawnedThisWave = 0;
    enemiesPerWave = 5;

    std::cout << "[DEBUG] EnemyManager reset!" << std::endl;
}

} // namespace SpaceShooter
