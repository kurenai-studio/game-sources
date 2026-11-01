#pragma once
#include "../systems/BulletManager.h"
#include "../utils/GameConfig.h"
#include "Entity.h"
#include <functional>

namespace SpaceShooter {

enum class EnemyType
{
    BASIC,
    FAST,
    HEAVY
};

enum class EnemyBehaviorState
{
    NORMAL,   // Regular movement and shooting
    KAMIKAZE, // Aggressive targeting towards player
    DESTROYED // Enemy is dead
};

class Enemy : public Entity
{
  private:
    EnemyType enemyType;
    EnemyBehaviorState behaviorState;
    Texture2D* texture;

    // Combat properties
    int maxHealth;
    int currentHealth;
    float fireTimer;
    float fireRate;
    bool canShoot;

    // Movement properties
    float baseSpeed;
    float currentSpeed;
    Vec2 targetPosition; // For AI targeting

    // Kamikaze properties
    float kamikazeTriggerHealthPercent;
    float kamikazeSpeedMultiplier;

    // AI timing
    float aiUpdateTimer;
    float aiUpdateInterval;

    // Shooting direction
    Vec2 shootDirection;

  public:
    Enemy(EnemyType type, Vec2 startPosition);
    virtual ~Enemy() = default;

    // Core entity methods
    void Update(float deltaTime) override;
    void Draw() override;
    void LoadTextures();

    // Enemy specific methods
    void TakeDamage(int damage);
    void UpdateAI(float deltaTime, Vec2 playerPosition);
    void UpdateMovement(float deltaTime);
    void UpdateCombat(float deltaTime, BulletManager* bulletManager);
    void CheckKamikazeTrigger();

    // Getters
    EnemyType GetEnemyType() const
    {
        return enemyType;
    }
    EnemyBehaviorState GetBehaviorState() const
    {
        return behaviorState;
    }
    int GetCurrentHealth() const
    {
        return currentHealth;
    }
    int GetMaxHealth() const
    {
        return maxHealth;
    }
    float GetHealthPercent() const
    {
        return (float)currentHealth / maxHealth;
    }
    bool IsKamikaze() const
    {
        return behaviorState == EnemyBehaviorState::KAMIKAZE;
    }

    Rectangle GetBounds() const override;

    static std::unique_ptr<Enemy> CreateEnemy(EnemyType type, Vec2 position);

  private:
    void InitializeEnemyStats();
    void UpdateNormalBehavior(float deltaTime, Vec2 playerPosition);
    void UpdateKamikazeBehavior(float deltaTime, Vec2 playerPosition);
    Vec2 CalculateMovementVector(Vec2 target);
    void Shoot(BulletManager* bulletManager);
};

} // namespace SpaceShooter
