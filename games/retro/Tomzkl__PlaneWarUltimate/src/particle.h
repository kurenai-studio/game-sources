#pragma once
#include "raylib.h"
#include "constants.h"
#include "pool.h"
#include "types.h"

namespace pwu {

struct Particle
{
    float x;
    float y;
    float speedX;
    float speedY;
    float life;
    bool active;
};

void CreateExplosion(Pool<Particle, MAX_PARTICLES>& pool, float x, float y);
void UpdateParticles(Pool<Particle, MAX_PARTICLES>& pool);
void DrawParticles(const Pool<Particle, MAX_PARTICLES>& pool);

} // namespace pwu
