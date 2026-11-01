#pragma once
#include "Entity.h"
#include <memory>

namespace SpaceShooter {

class Explosion : public Entity
{
  private:
    static const int EXPLOSION_FRAMES = 4;
    static constexpr float FRAME_DURATION = 0.1f;

    Texture2D* explosionTextures[EXPLOSION_FRAMES];
    int currentFrame;
    float frameTimer;
    bool animationComplete;

    void LoadTextures();

  public:
    Explosion();
    Explosion(Vec2 startPos);
    virtual ~Explosion() = default;

    virtual void Update(float deltaTime) override;
    virtual void Draw() override;
    virtual Rectangle GetBounds() const override;

    void StartExplosion(Vec2 position);
    bool IsAnimationComplete() const
    {
        return animationComplete;
    }

    static std::unique_ptr<Explosion> CreateExplosion(Vec2 position);
};
} // namespace SpaceShooter
