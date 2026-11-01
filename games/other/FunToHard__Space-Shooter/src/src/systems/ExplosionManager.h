#pragma once
#include "../entities/Explosion.h"
#include "../utils/GameConfig.h"
#include <memory>
#include <vector>

namespace SpaceShooter {

class ExplosionManager
{
  private:
    std::vector<std::unique_ptr<Explosion>> explosions;

    void RemoveCompletedExplosions();

  public:
    ExplosionManager();
    ~ExplosionManager() = default;

    void Initialize();
    void Update(float deltaTime);
    void Draw();
    void Clear();

    // Create explosion at position
    void CreateExplosion(Vec2 position);

    // Get count for debugging
    int GetActiveExplosionCount() const;
};
} // namespace SpaceShooter
