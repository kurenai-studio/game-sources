#include "PowerUp.h"
#include "../utils/GameConfig.h"
#include <iostream>

namespace SpaceShooter {

PowerUp::PowerUp(PowerUpType type, Vec2 startPosition)
    : Entity(startPosition)
    , powerUpType(type)
    , texture(nullptr)
    , lifeTimer(0.0f)
    , maxLifeTime(15.0f) // Power-ups last 15 seconds before disappearing
    , collected(false)
{
    // Set velocity to float down slowly
    velocity = Vec2(0, 30.0f);
    LoadTexture();

    std::cout << "[DEBUG] Spawned power-up type " << (int)powerUpType << " at position (" << position.x << ", "
              << position.y << ")" << std::endl;
}

void PowerUp::LoadTexture()
{
    ResourceManager* resourceManager = ResourceManager::GetInstance();
    if(!resourceManager)
        return;

    switch(powerUpType) {
        case PowerUpType::DOUBLE_SHOT:
            texture = resourceManager->GetTexture("powerup_double_shot");
            break;
        case PowerUpType::SHIELD:
            texture = resourceManager->GetTexture("powerup_shield");
            break;
        case PowerUpType::SPEED_BOOST:
            texture = resourceManager->GetTexture("powerup_speed_boost");
            break;
        default:
            texture = nullptr;
            break;
    }
}

void PowerUp::Update(float deltaTime)
{
    if(!active || collected)
        return;

    // Update life timer
    lifeTimer += deltaTime;

    // Move the power-up
    Move(deltaTime);

    // Check if power-up has expired or moved off screen
    if(IsExpired() || position.y > SCREEN_HEIGHT + 50) {
        active = false;
        std::cout << "[DEBUG] Power-up expired or went off-screen" << std::endl;
    }
}

void PowerUp::Draw()
{
    if(!active || collected || !texture)
        return;

    // Calculate flashing for the last 5 seconds
    bool shouldDraw = true;
    if(maxLifeTime - lifeTimer <= 5.0f) {
        // Flash faster as expiration approaches
        float flashRate = 5.0f * (1.0f - (maxLifeTime - lifeTimer) / 5.0f);
        shouldDraw = (int)(lifeTimer * flashRate) % 2 == 0;
    }

    if(shouldDraw) {
        Color tintColor = WHITE;

        // Add a glowing effect
        float pulse = sin(lifeTimer * 3.0f) * 0.3f + 0.7f;
        tintColor =
            Color{(unsigned char)(255 * pulse), (unsigned char)(255 * pulse), (unsigned char)(255 * pulse), 255};

        DrawTexture(*texture, (int)(position.x - texture->width / 2), (int)(position.y - texture->height / 2),
                    tintColor);
    }
}

Rectangle PowerUp::GetBounds() const
{
    if(!texture) {
        return Rectangle{position.x - 10, position.y - 10, 20, 20};
    }

    return Rectangle{position.x - texture->width / 2.0f, position.y - texture->height / 2.0f, (float)texture->width,
                     (float)texture->height};
}

void PowerUp::Collect()
{
    if(collected)
        return;

    collected = true;
    active = false;

    std::cout << "[DEBUG] Power-up collected! Type: " << (int)powerUpType << std::endl;
}

} // namespace SpaceShooter
