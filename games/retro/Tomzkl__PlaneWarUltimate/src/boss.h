#pragma once
#include "raylib.h"
#include "constants.h"
#include "pool.h"
#include "types.h"

namespace pwu {

struct Boss
{
    float x;
    float y;
    int hp;
    float shootTimer;        // seconds accumulated
    float moveTimer;         // seconds accumulated
    int  phase;
    int  bossType;   // 0=Carrier, 1=Destroyer, 2=BulletHell
    float moveDir;
    bool active;

    void Init(int type = 0);
    void Update(Pool<Bullet, MAX_BOSS_BULLETS>& bullets, float playerX, float playerY);
    void Draw() const;
    void TakeDamage();
    Rectangle GetBounds() const;
};

} // namespace pwu
