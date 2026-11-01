#include "BulletManager.h"

namespace SpaceShooter {

BulletManager::BulletManager()
    : nextAvailableIndex(0)
{
}

void BulletManager::Initialize()
{
    bulletPool.clear();
    bulletPool.reserve(MAX_BULLETS);

    // Create bullet pool
    for(int i = 0; i < MAX_BULLETS; i++) {
        bulletPool.push_back(std::make_unique<Bullet>());
    }

    nextAvailableIndex = 0;
}

void BulletManager::Update(float deltaTime)
{
    for(auto& bullet : bulletPool) {
        if(bullet->IsActive()) {
            bullet->Update(deltaTime);
        }
    }
}

void BulletManager::Draw()
{
    for(auto& bullet : bulletPool) {
        if(bullet->IsActive()) {
            bullet->Draw();
        }
    }
}

bool BulletManager::CreateBullet(Vec2 position, Vec2 direction, BulletType type)
{
    Bullet* bullet = GetAvailableBullet();
    if(bullet) {
        bullet->Initialize(position, direction, type);
        return true;
    }
    return false; // Pool is full
}

Bullet* BulletManager::GetAvailableBullet()
{
    for(int i = 0; i < MAX_BULLETS; i++) {
        int index = (nextAvailableIndex + i) % MAX_BULLETS;
        if(!bulletPool[index]->IsActive()) {
            nextAvailableIndex = (index + 1) % MAX_BULLETS;
            return bulletPool[index].get();
        }
    }
    return nullptr;
}

std::vector<Bullet*> BulletManager::GetPlayerBullets()
{
    std::vector<Bullet*> playerBullets;
    for(auto& bullet : bulletPool) {
        if(bullet->IsActive() && bullet->IsPlayerBullet()) {
            playerBullets.push_back(bullet.get());
        }
    }
    return playerBullets;
}

std::vector<Bullet*> BulletManager::GetEnemyBullets()
{
    std::vector<Bullet*> enemyBullets;
    for(auto& bullet : bulletPool) {
        if(bullet->IsActive() && !bullet->IsPlayerBullet()) {
            enemyBullets.push_back(bullet.get());
        }
    }
    return enemyBullets;
}

void BulletManager::Clear()
{
    for(auto& bullet : bulletPool) {
        bullet->Reset();
    }
    nextAvailableIndex = 0;
}
} // namespace SpaceShooter
