#include "Entity.h"

namespace SpaceShooter {

Entity::Entity()
    : position(0, 0)
    , velocity(0, 0)
    , rotation(0)
    , active(true)
{
}

Entity::Entity(Vec2 pos)
    : position(pos)
    , velocity(0, 0)
    , rotation(0)
    , active(true)
{
}

bool Entity::CheckCollision(const Entity& other) const
{
    if(!active || !other.IsActive())
        return false;

    Rectangle thisRect = GetBounds();
    Rectangle otherRect = other.GetBounds();

    return ::CheckCollisionRecs(thisRect, otherRect);
}

void Entity::Move(float deltaTime)
{
    position += velocity * deltaTime;
}
} // namespace SpaceShooter
