#include "particle.h"

namespace pwu {

void CreateExplosion(Pool<Particle, MAX_PARTICLES>& pool, float x, float y)
{
    for (int i = 0; i < PARTICLE_COUNT_PER_EXPLOSION; i++)
    {
        Particle* p = pool.Acquire();
        if (p)
        {
            p->x = x;
            p->y = y;
            p->speedX = GetRandomValue(-50, 50) / 10.0f;
            p->speedY = GetRandomValue(-50, 50) / 10.0f;
            p->life = 1.0f;
        }
    }
}

void UpdateParticles(Pool<Particle, MAX_PARTICLES>& pool)
{
    float dtFrames = GetFrameTime() * 60.0f;
    for (int i = 0; i < MAX_PARTICLES; i++)
    {
        if (pool.items[i].active)
        {
            pool.items[i].x += pool.items[i].speedX * dtFrames;
            pool.items[i].y += pool.items[i].speedY * dtFrames;
            pool.items[i].life -= 0.02f * dtFrames;

            if (pool.items[i].life <= 0)
            {
                pool.items[i].active = false;
            }
        }
    }
}

void DrawParticles(const Pool<Particle, MAX_PARTICLES>& pool)
{
    for (int i = 0; i < MAX_PARTICLES; i++)
    {
        if (pool.items[i].active)
        {
            DrawCircle(
                (int)pool.items[i].x,
                (int)pool.items[i].y,
                3,
                Fade(ORANGE, pool.items[i].life)
            );
        }
    }
}

} // namespace pwu
