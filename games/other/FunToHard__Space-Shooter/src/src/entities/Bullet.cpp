#include "Bullet.h"
#include "../systems/ResourceManager.h"

namespace SpaceShooter {

Bullet::Bullet()
    : Entity()
{
    Reset();
}

void Bullet::Initialize(Vec2 startPos, Vec2 direction, BulletType bulletType)
{
    position = startPos;
    type = bulletType;
    active = true;

    // Set properties based on bullet type
    switch(type) {
        case BulletType::PLAYER_NORMAL:
            speed = PLAYER_BULLET_SPEED;
            damage = 1.0f;
            isPlayerBullet = true;
            texture = ResourceManager::GetInstance()->GetTexture("player_bullet");
            break;

        case BulletType::PLAYER_LASER:
            speed = PLAYER_BULLET_SPEED * 1.5f; // Faster laser
            damage = 3.0f;                      // More damage
            isPlayerBullet = true;
            texture = ResourceManager::GetInstance()->GetTexture("player_bullet"); // Same texture for now
            break;

        case BulletType::ENEMY_NORMAL:
            speed = ENEMY_BULLET_SPEED;
            damage = 1.0f;
            isPlayerBullet = false;
            texture = ResourceManager::GetInstance()->GetTexture("enemy_bullet");
            break;
    }

    velocity = direction.Normalize() * speed;
}

void Bullet::Update(float deltaTime)
{
    if(!active)
        return;

    Move(deltaTime);

    // Check if bullet is off-screen
    if(position.y < -50 || position.y > SCREEN_HEIGHT + 50 || position.x < -50 || position.x > SCREEN_WIDTH + 50) {
        active = false;
    }
}

void Bullet::Draw()
{
    if(!active || !texture)
        return;

    Color tint = WHITE;

    // Special effect for laser bullets
    if(type == BulletType::PLAYER_LASER) {
        // Add a blue tint and slight glow effect for laser
        tint = Color{100, 150, 255, 255};
    }

    DrawTextureEx(*texture, Vector2{position.x - texture->width / 2, position.y - texture->height / 2}, rotation, 1.0f,
                  tint);
}

Rectangle Bullet::GetBounds() const
{
    if(!texture)
        return {position.x, position.y, 8, 16};

    return Rectangle{position.x - texture->width / 2, position.y - texture->height / 2, (float)texture->width,
                     (float)texture->height};
}

void Bullet::Reset()
{
    active = false;
    position = Vec2(0, 0);
    velocity = Vec2(0, 0);
    rotation = 0;
    type = BulletType::PLAYER_NORMAL;
    damage = 1.0f;
    speed = 0;
    isPlayerBullet = true;
    texture = nullptr;
}
} // namespace SpaceShooter
