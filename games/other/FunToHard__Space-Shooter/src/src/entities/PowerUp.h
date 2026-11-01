#pragma once
#include "../systems/ResourceManager.h"
#include "Entity.h"
#include "Player.h"

namespace SpaceShooter {

class PowerUp : public Entity
{
  private:
    PowerUpType powerUpType;
    Texture2D* texture;
    float lifeTimer;
    float maxLifeTime;
    bool collected;

  public:
    PowerUp(PowerUpType type, Vec2 startPosition);
    virtual ~PowerUp() = default;

    virtual void Update(float deltaTime) override;
    virtual void Draw() override;
    virtual Rectangle GetBounds() const override;

    // Getters
    PowerUpType GetPowerUpType() const
    {
        return powerUpType;
    }
    bool IsCollected() const
    {
        return collected;
    }

    // Power-up specific methods
    void Collect();
    bool IsExpired() const
    {
        return lifeTimer >= maxLifeTime;
    }
    void LoadTexture();
};

} // namespace SpaceShooter
