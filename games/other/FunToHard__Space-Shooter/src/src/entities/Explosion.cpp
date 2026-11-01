#include "Explosion.h"
#include "../systems/ResourceManager.h"
#include <iostream>

namespace SpaceShooter {

Explosion::Explosion()
    : Explosion(Vec2(0, 0))
{
}

Explosion::Explosion(Vec2 startPos)
    : Entity(startPos)
{
    currentFrame = 0;
    frameTimer = 0.0f;
    animationComplete = false;

    for(int i = 0; i < EXPLOSION_FRAMES; i++) {
        explosionTextures[i] = nullptr;
    }

    LoadTextures();
    active = false;
}

void Explosion::LoadTextures()
{
    ResourceManager* rm = ResourceManager::GetInstance();
    if(!rm) {
        std::cout << "Warning: ResourceManager not available for Explosion textures!" << std::endl;
        return;
    }

    explosionTextures[0] = rm->GetTexture("explosion_0");
    explosionTextures[1] = rm->GetTexture("explosion_1");
    explosionTextures[2] = rm->GetTexture("explosion_2");
    explosionTextures[3] = rm->GetTexture("explosion_3");

    for(int i = 0; i < EXPLOSION_FRAMES; i++) {
        if(!explosionTextures[i]) {
            std::cout << "Warning: Failed to load explosion texture " << i << std::endl;
        }
    }
}

void Explosion::Update(float deltaTime)
{
    if(!active || animationComplete)
        return;

    frameTimer += deltaTime;

    if(frameTimer >= FRAME_DURATION) {
        frameTimer = 0.0f;
        currentFrame++;

        if(currentFrame >= EXPLOSION_FRAMES) {
            animationComplete = true;
            active = false;

            std::cout << "[DEBUG] Explosion animation complete" << std::endl;
        }
    }
}

void Explosion::Draw()
{
    if(!active || animationComplete)
        return;

    Texture2D* currentTexture = explosionTextures[currentFrame];
    if(!currentTexture)
        return;

    float x = position.x - currentTexture->width / 2.0f;
    float y = position.y - currentTexture->height / 2.0f;

    DrawTexture(*currentTexture, (int)x, (int)y, WHITE);
}

Rectangle Explosion::GetBounds() const
{
    if(!active || currentFrame >= EXPLOSION_FRAMES) {
        return Rectangle{0, 0, 0, 0};
    }

    Texture2D* currentTexture = explosionTextures[currentFrame];
    if(!currentTexture) {
        return Rectangle{0, 0, 0, 0};
    }

    return Rectangle{position.x - currentTexture->width / 2.0f, position.y - currentTexture->height / 2.0f,
                     (float)currentTexture->width, (float)currentTexture->height};
}

void Explosion::StartExplosion(Vec2 explosionPosition)
{
    position = explosionPosition;
    currentFrame = 0;
    frameTimer = 0.0f;
    animationComplete = false;
    active = true;

    std::cout << "[DEBUG] Started explosion at (" << position.x << ", " << position.y << ")" << std::endl;
}

std::unique_ptr<Explosion> Explosion::CreateExplosion(Vec2 explosionPosition)
{
    auto explosion = std::make_unique<Explosion>(explosionPosition);
    explosion->StartExplosion(explosionPosition);
    return explosion;
}
} // namespace SpaceShooter
