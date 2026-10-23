#pragma once
#include "raylib.h"
#include "constants.h"
#include "pool.h"
#include "types.h"
#ifdef _MSC_VER
#pragma warning(disable: 4244)  // int to float conversion in drawing
#endif

namespace pwu {

struct Player
{
    float x;
    float y;
    int hp;
    float shootTimer;        // seconds accumulated
    float tripleTimer;       // seconds remaining
    float invincibleTimer;   // seconds remaining

    int bombCount = 3;     // starts with 3, refill on death

    // Charge shot
    float chargeTimer = 0;      // accumulates while holding
    bool  isCharging = false;
    bool  chargeReady = false;
    bool  laserActive = false;
    float laserTimer  = 0;      // frames remaining for laser beam
    float laserX      = 0;      // where the laser was fired

    void Init();
    void Update(Pool<Bullet, MAX_BULLETS>& bullets, Sound& shootSound, int& totalShots,
                float& laserOutX, bool& laserOutActive, float& laserOutTimer);
    void Draw(const Texture2D& tex) const;
    void TakeDamage();
    bool IsInvincible() const;
    Rectangle GetBounds() const;
    float ChargePercent() const { return chargeTimer / CHARGE_MAX; }
    bool  IsCharging()    const { return isCharging; }
};

} // namespace pwu
