#include "ExplosionManager.h"
#include <algorithm>
#include <iostream>

namespace SpaceShooter {

ExplosionManager::ExplosionManager()
{
    explosions.clear();
}

void ExplosionManager::Initialize()
{
    Clear();
    std::cout << "[DEBUG] ExplosionManager initialized!" << std::endl;
}

void ExplosionManager::Update(float deltaTime)
{
    // Update all explosions
    for(auto& explosion : explosions) {
        if(explosion && explosion->IsActive()) {
            explosion->Update(deltaTime);
        }
    }

    // Remove completed explosions
    RemoveCompletedExplosions();
}

void ExplosionManager::Draw()
{
    for(auto& explosion : explosions) {
        if(explosion && explosion->IsActive()) {
            explosion->Draw();
        }
    }
}

void ExplosionManager::Clear()
{
    explosions.clear();
}

void ExplosionManager::CreateExplosion(Vec2 position)
{
    auto explosion = Explosion::CreateExplosion(position);
    if(explosion) {
        explosions.push_back(std::move(explosion));

        std::cout << "[DEBUG] Created explosion at (" << position.x << ", " << position.y
                  << "), total explosions: " << explosions.size() << std::endl;
    }
}

void ExplosionManager::RemoveCompletedExplosions()
{
    // Remove explosions that are completed
    explosions.erase(std::remove_if(explosions.begin(), explosions.end(),
                                    [](const std::unique_ptr<Explosion>& explosion) {
                                        return !explosion || explosion->IsAnimationComplete();
                                    }),
                     explosions.end());
}

int ExplosionManager::GetActiveExplosionCount() const
{
    int count = 0;
    for(const auto& explosion : explosions) {
        if(explosion && explosion->IsActive()) {
            count++;
        }
    }
    return count;
}
} // namespace SpaceShooter
