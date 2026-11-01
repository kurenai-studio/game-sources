#include "Enemy.h"
#include "../systems/ResourceManager.h"
#include "../utils/GameConfig.h"
#include <iostream>
#include <random>
#include <raylib.h>

namespace SpaceShooter {

Enemy::Enemy(EnemyType type, Vec2 startPosition)
    : Entity(startPosition)
    , enemyType(type)
    , behaviorState(EnemyBehaviorState::NORMAL)
    , texture(nullptr)
    , fireTimer(0.0f)
    , canShoot(true)
    , targetPosition(startPosition)
    , aiUpdateTimer(0.0f)
    , aiUpdateInterval(0.1f)     // Update AI 10 times per second
    , shootDirection(Vec2(0, 1)) // Default shoot downward
{
    InitializeEnemyStats();
    LoadTextures();

    // Random initial fire delay to prevent synchronized shooting
    static std::random_device rd;
    static std::mt19937 gen(rd());
    std::uniform_real_distribution<float> dist(0.0f, fireRate);
    fireTimer = dist(gen);
}

void Enemy::InitializeEnemyStats()
{
    switch(enemyType) {
        case EnemyType::BASIC:
            maxHealth = 2;
            baseSpeed = 80.0f;
            fireRate = 1.2f;                     // Faster shooting - reduced from 2.0f to 1.2f
            kamikazeTriggerHealthPercent = 0.5f; // 50% health
            kamikazeSpeedMultiplier = 2.0f;
            break;

        case EnemyType::FAST:
            maxHealth = 2; // Increased from 1 to 2 so they can enter kamikaze mode
            baseSpeed = 150.0f;
            fireRate = 0.8f;                     // Faster shooting - reduced from 1.5f to 0.8f
            kamikazeTriggerHealthPercent = 0.5f; // 50% health (now triggers at 1 HP)
            kamikazeSpeedMultiplier = 2.5f;
            break;

        case EnemyType::HEAVY:
            maxHealth = 8;
            baseSpeed = 40.0f;
            fireRate = 0.1f;                     // Rapid fire - shoot every 0.1 seconds for continuous laser effect
            kamikazeTriggerHealthPercent = 0.0f; // Never goes kamikaze
            kamikazeSpeedMultiplier = 1.0f;
            break;
    }

    // Apply performance scaling multiplier
    float speedMultiplier = GetPerformanceMultiplier();
    baseSpeed *= speedMultiplier;

    currentHealth = maxHealth;
    currentSpeed = baseSpeed;
}

void Enemy::LoadTextures()
{
    ResourceManager* resourceManager = ResourceManager::GetInstance();

    switch(enemyType) {
        case EnemyType::BASIC:
            texture = resourceManager->GetTexture("basic_enemy");
            break;
        case EnemyType::FAST:
            texture = resourceManager->GetTexture("fast_enemy");
            break;
        case EnemyType::HEAVY:
            texture = resourceManager->GetTexture("heavy_enemy");
            break;
    }
}

void Enemy::Update(float deltaTime)
{
    if(!active || behaviorState == EnemyBehaviorState::DESTROYED) {
        return;
    }

    // Update timers
    aiUpdateTimer += deltaTime;
    fireTimer += deltaTime;

    // Check if enemy has moved off screen (bottom)
    if(position.y > SCREEN_HEIGHT + 50) {
        active = false;
        return;
    }
}

void Enemy::UpdateAI(float deltaTime, Vec2 playerPosition)
{
    if(!active || behaviorState == EnemyBehaviorState::DESTROYED) {
        return;
    }

    // Only update AI at intervals to reduce CPU usage
    if(aiUpdateTimer >= aiUpdateInterval) {
        aiUpdateTimer = 0.0f;

        switch(behaviorState) {
            case EnemyBehaviorState::NORMAL:
                UpdateNormalBehavior(deltaTime, playerPosition);
                break;
            case EnemyBehaviorState::KAMIKAZE:
                UpdateKamikazeBehavior(deltaTime, playerPosition);
                break;
            default:
                break;
        }
    }

    UpdateMovement(deltaTime);
}

void Enemy::UpdateNormalBehavior(float deltaTime, Vec2 playerPosition)
{
    switch(enemyType) {
        case EnemyType::BASIC:
            // Basic enemy: Move downward with slight side-to-side movement
            targetPosition.x = position.x + sinf(GetTime() * 2.0f + position.y * 0.01f) * 30.0f;
            targetPosition.y = position.y + baseSpeed * deltaTime;
            shootDirection = Vec2(0, 1); // Shoot downward
            break;

        case EnemyType::FAST:
            // Fast enemy: More erratic movement, occasionally dart toward player
            if((int)(GetTime() * 3.0f) % 3 == 0) {
                // Occasionally move toward player
                targetPosition =
                    Vec2(playerPosition.x + (float)(rand() % 100 - 50), position.y + baseSpeed * deltaTime);
            } else {
                // Normal zigzag movement
                targetPosition.x = position.x + cosf(GetTime() * 4.0f + position.x * 0.02f) * 50.0f;
                targetPosition.y = position.y + baseSpeed * deltaTime;
            }
            shootDirection = Vec2((playerPosition.x - position.x) * 0.1f, 1.0f).Normalize();
            break;

        case EnemyType::HEAVY:
            // Heavy enemy: Slow, deliberate movement, tracks player horizontally
            targetPosition.x = playerPosition.x + sinf(GetTime() * 0.5f) * 60.0f;
            targetPosition.y = position.y + baseSpeed * deltaTime;
            shootDirection = Vec2((playerPosition.x - position.x) * 0.3f, 1.0f).Normalize();
            break;
    }
}

void Enemy::UpdateKamikazeBehavior(float deltaTime, Vec2 playerPosition)
{
    // In kamikaze mode, enemies move directly toward the player at increased speed
    targetPosition = playerPosition;
    currentSpeed = baseSpeed * kamikazeSpeedMultiplier;

    // Stop shooting in kamikaze mode - focus on ramming
    canShoot = false;
}

void Enemy::UpdateMovement(float deltaTime)
{
    Vec2 movementVector = CalculateMovementVector(targetPosition);
    velocity = movementVector * currentSpeed;
    position = position + velocity * deltaTime;

    // Keep enemy within screen bounds horizontally
    if(position.x < 0)
        position.x = 0;
    if(position.x > SCREEN_WIDTH)
        position.x = (float)SCREEN_WIDTH;
}

void Enemy::UpdateCombat(float deltaTime, BulletManager* bulletManager)
{
    if(!canShoot || !bulletManager || behaviorState == EnemyBehaviorState::KAMIKAZE) {
        return;
    }

    if(fireTimer >= fireRate) {
        Shoot(bulletManager);
        fireTimer = 0.0f;
    }
}

Vec2 Enemy::CalculateMovementVector(Vec2 target)
{
    Vec2 direction = target - position;
    return direction.Normalize();
}

void Enemy::Shoot(BulletManager* bulletManager)
{
    if(!bulletManager)
        return;

    // Calculate bullet spawn position (bottom center of enemy)
    Vec2 bulletPos = Vec2(position.x, position.y + (texture->height / 2.0f));

    Vec2 bulletVelocity = shootDirection * 200.0f;

    bulletManager->CreateBullet(bulletPos, bulletVelocity, BulletType::ENEMY_NORMAL);
}

void Enemy::TakeDamage(int damage)
{
    if(behaviorState == EnemyBehaviorState::DESTROYED) {
        return;
    }

    currentHealth -= damage;

    if(currentHealth <= 0) {
        currentHealth = 0;
        behaviorState = EnemyBehaviorState::DESTROYED;
        active = false;

        std::cout << "[DEBUG] Enemy destroyed! Type: " << (int)enemyType << std::endl;
    } else {
        CheckKamikazeTrigger();
    }
}

void Enemy::CheckKamikazeTrigger()
{
    if(behaviorState != EnemyBehaviorState::NORMAL) {
        return;
    }

    if(enemyType == EnemyType::HEAVY) {
        return; // Heavy enemies never go kamikaze
    }

    float healthPercent = GetHealthPercent();
    if(healthPercent <= kamikazeTriggerHealthPercent) {
        behaviorState = EnemyBehaviorState::KAMIKAZE;
        std::cout << "[DEBUG] Enemy entering KAMIKAZE mode! Type: " << (int)enemyType
                  << " Health: " << healthPercent * 100.0f << "%" << std::endl;
    }
}

void Enemy::Draw()
{
    if(!active || !texture || texture->id == 0) {
        return;
    }

    // Choose tint color based on behavior state
    Color tintColor = WHITE;
    if(behaviorState == EnemyBehaviorState::KAMIKAZE) {
        // Flash red for kamikaze enemies
        float flashIntensity = (sinf(GetTime() * 10.0f) + 1.0f) * 0.5f;
        tintColor = Color{255, (unsigned char)(100 * (1.0f - flashIntensity)),
                          (unsigned char)(100 * (1.0f - flashIntensity)), 255};
    }

    DrawTexture(*texture, (int)(position.x - texture->width / 2), (int)(position.y - texture->height / 2), tintColor);
}

Rectangle Enemy::GetBounds() const
{
    return Rectangle{position.x - texture->width / 2.0f, position.y - texture->height / 2.0f, (float)texture->width,
                     (float)texture->height};
}

std::unique_ptr<Enemy> Enemy::CreateEnemy(EnemyType type, Vec2 position)
{
    return std::make_unique<Enemy>(type, position);
}

} // namespace SpaceShooter
