#pragma once
#include "../utils/Vector2D.h"
#include <raylib.h>

namespace SpaceShooter {

class Entity
{
  protected:
    Vec2 position;
    Vec2 velocity;
    float rotation;
    bool active;

  public:
    Entity();
    Entity(Vec2 pos);
    virtual ~Entity() = default;

    virtual void Update(float deltaTime) = 0;
    virtual void Draw() = 0;
    virtual Rectangle GetBounds() const = 0;

    // Getters
    Vec2 GetPosition() const
    {
        return position;
    }
    Vec2 GetVelocity() const
    {
        return velocity;
    }
    float GetRotation() const
    {
        return rotation;
    }
    bool IsActive() const
    {
        return active;
    }

    // Setters
    void SetPosition(Vec2 pos)
    {
        position = pos;
    }
    void SetVelocity(Vec2 vel)
    {
        velocity = vel;
    }
    void SetRotation(float rot)
    {
        rotation = rot;
    }
    void SetActive(bool isActive)
    {
        active = isActive;
    }

    // Utility
    bool CheckCollision(const Entity& other) const;
    void Move(float deltaTime);
};
} // namespace SpaceShooter
