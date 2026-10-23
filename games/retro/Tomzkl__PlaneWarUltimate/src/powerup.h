#pragma once
#include "raylib.h"
#include "constants.h"
#include "pool.h"
#include "types.h"

namespace pwu {

struct PowerUp
{
    float x;
    float y;
    PowerUpKind kind;
    bool active;

    void Init(PowerUpKind k, float startX, float startY);
    void Update();
    void Draw() const;
    Rectangle GetBounds() const;
};

void TrySpawnPowerUp(Pool<PowerUp, MAX_POWERUPS>& pool, float x, float y);

} // namespace pwu
