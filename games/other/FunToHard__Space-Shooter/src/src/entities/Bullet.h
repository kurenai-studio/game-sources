#pragma once
#include "../utils/GameConfig.h"
#include "Entity.h"

namespace SpaceShooter {

enum class BulletType
{
    PLAYER_NORMAL,
    PLAYER_LASER, // For supercharge mode
    ENEMY_NORMAL
};

class Bullet : public Entity
{
  private:
    BulletType type;
    float damage;
    float speed;
    bool isPlayerBullet;
    Texture2D* texture;

  public:
    Bullet();

    void Initialize(Vec2 startPos, Vec2 direction, BulletType bulletType);
    void Update(float deltaTime) override;
    void Draw() override;
    Rectangle GetBounds() const override;

    // Getters
    BulletType GetType() const
    {
        return type;
    }
    float GetDamage() const
    {
        return damage;
    }
    bool IsPlayerBullet() const
    {
        return isPlayerBullet;
    }

    // Reset for object pooling
    void Reset();
};
} // namespace SpaceShooter
