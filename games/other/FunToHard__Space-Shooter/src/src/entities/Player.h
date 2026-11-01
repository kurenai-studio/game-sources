#pragma once
#include "../utils/GameConfig.h"
#include "Entity.h"

namespace SpaceShooter {

class BulletManager; // Forward declaration

enum class PowerUpType
{
    NONE,
    DOUBLE_SHOT,
    SHIELD,
    SPEED_BOOST
};

class Player : public Entity
{
  private:
    int health;
    int maxHealth;
    float fireTimer;
    bool canShoot;

    // Supercharge mode
    float superchargeCooldownTimer;
    float superchargeActiveTimer;
    float superchargeWarmupTimer;
    bool isSuperchargeReady;
    bool isSuperchargeActive;
    bool isSuperchargeWarming;

    // Power-ups
    PowerUpType activePowerUp;
    float powerUpTimer;
    bool hasDoubleShot;
    bool hasShield;
    float speedMultiplier;

    Texture2D* texture;

  public:
    Player();
    Player(Vec2 startPos);

    void Update(float deltaTime) override;
    void Update(float deltaTime, BulletManager* bulletManager);
    void Draw() override;
    Rectangle GetBounds() const override;

    // Input handling
    void HandleInput(float deltaTime);
    void HandleInput(float deltaTime, BulletManager* bulletManager);

    // Combat
    bool CanShoot() const
    {
        return canShoot;
    }
    void Shoot(BulletManager* bulletManager);
    void TakeDamage(int damage = 1);

    // Supercharge mode
    void ActivateSupercharge();
    bool IsSuperchargeReady() const
    {
        return isSuperchargeReady;
    }
    bool IsSuperchargeActive() const
    {
        return isSuperchargeActive;
    }
    bool IsSuperchargeWarming() const
    {
        return isSuperchargeWarming;
    }
    float GetSuperchargeCooldown() const
    {
        return superchargeCooldownTimer;
    }
    float GetSuperchargeWarmupTimer() const
    {
        return superchargeWarmupTimer;
    }
    void UpdateSupercharge(float deltaTime);

    // Power-ups
    void ApplyPowerUp(PowerUpType type);
    void UpdatePowerUps(float deltaTime);

    // Getters
    int GetHealth() const
    {
        return health;
    }
    int GetMaxHealth() const
    {
        return maxHealth;
    }
    bool HasShield() const
    {
        return hasShield;
    }
    bool HasDoubleShot() const
    {
        return hasDoubleShot;
    }
    float GetSpeedMultiplier() const
    {
        return speedMultiplier;
    }

    // Initialization
    void LoadTextures(); // Call after ResourceManager loads assets

    void Reset();
};
} // namespace SpaceShooter
