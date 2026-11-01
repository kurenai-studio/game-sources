#pragma once
#include "../entities/Bullet.h"
#include "../utils/GameConfig.h"
#include <memory>
#include <vector>

namespace SpaceShooter {

class BulletManager
{
  private:
    std::vector<std::unique_ptr<Bullet>> bulletPool;
    int nextAvailableIndex;

    Bullet* GetAvailableBullet();

  public:
    BulletManager();
    ~BulletManager() = default;

    void Initialize();
    void Update(float deltaTime);
    void Draw();

    // Bullet creation
    bool CreateBullet(Vec2 position, Vec2 direction, BulletType type);

    // Collision detection helpers
    std::vector<Bullet*> GetPlayerBullets();
    std::vector<Bullet*> GetEnemyBullets();

    void Clear();
};
} // namespace SpaceShooter
