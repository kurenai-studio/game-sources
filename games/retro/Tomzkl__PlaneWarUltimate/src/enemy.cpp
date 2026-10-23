#include "enemy.h"
#include <math.h>

namespace pwu {

void Enemy::Init(EnemyKind k, float startX, float startY)
{
    kind = k;
    x = startX;
    y = startY;

    switch (k)
    {
    case EnemyKind::SMALL:  hp = 1; break;
    case EnemyKind::MEDIUM: hp = 1; break;
    case EnemyKind::LARGE:  hp = 2; break;
    }
}

void Enemy::Update(int enemySpeed)
{
    int speed = enemySpeed;
    switch (kind)
    {
    case EnemyKind::SMALL:  speed = enemySpeed + 2; break;
    case EnemyKind::MEDIUM: speed = enemySpeed;     break;
    case EnemyKind::LARGE:  speed = enemySpeed - 2; break;
    }
    if (speed < 1) speed = 1;

    y += (float)speed * GetFrameTime() * 60.0f;

    if (y > SCREEN_H + 80) active = false;
}

// ==================================================================
//  Enemy Drawing - procedurally designed alien warships
// ==================================================================

void Enemy::Draw(const Texture2D& tex) const
{
    int size = GetSize();
    float sz  = (float)size;
    float cx  = x + sz / 2.0f;
    float cy  = y + sz / 2.0f;
    float t   = (float)GetTime();

    // Use texture if available
    if (tex.id != 0)
    {
        Rectangle src = { 0, 0, (float)tex.width, (float)tex.height };
        Rectangle dst = { x, y, sz, sz };
        DrawTexturePro(tex, src, dst, { 0, 0 }, 0, WHITE);
        return;
    }

    // -- Procedural alien warships -------------------------

    switch (kind)
    {
    // ============================================================
    //  SMALL - "Stinger" interceptor (40 px)
    // ============================================================
    case EnemyKind::SMALL:
    {
        Color fg = { 220, 60, 40, 255 };   // red hull
        Color fgDark  = { 140, 25, 15, 255 };
        Color accent  = { 255, 140, 20, 255 };  // orange
        Color cockpit = { 255, 220, 60, 255 };  // yellow

        // Main body (sharp diamond)
        DrawTriangle({ cx,           cy - sz * 0.45f },   // nose
                     { cx - sz * 0.3f, cy + sz * 0.15f },
                     { cx + sz * 0.3f, cy + sz * 0.15f },
                     fgDark);
        DrawTriangle({ cx - sz * 0.05f, cy - sz * 0.1f },
                     { cx - sz * 0.3f,  cy + sz * 0.15f },
                     { cx + sz * 0.3f,  cy + sz * 0.15f },
                     fg);

        // Side fins
        for (int s = -1; s <= 1; s += 2)
        {
            DrawTriangle({ cx + s * sz * 0.15f, cy + sz * 0.05f },
                         { cx + s * sz * 0.35f, cy + sz * 0.3f },
                         { cx + s * sz * 0.05f, cy + sz * 0.35f },
                         accent);
        }

        // Cockpit
        DrawCircle((int)cx, (int)(cy - sz * 0.05f), (int)(sz * 0.08f), cockpit);

        // Engine glow
        float flicker = 0.6f + (float)fabs(sin(t * 14 + x * 0.1f)) * 0.4f;
        DrawCircle((int)cx, (int)(cy + sz * 0.3f), (int)(sz * 0.1f), Fade(ORANGE, flicker));
        DrawCircle((int)cx, (int)(cy + sz * 0.3f), (int)(sz * 0.05f), Fade(YELLOW, flicker));

        // Hull highlights
        DrawLineEx({ cx, cy - sz * 0.42f }, { cx, cy + sz * 0.05f }, 1, Fade(WHITE, 0.25f));
        break;
    }

    // ============================================================
    //  MEDIUM - "Ravager" attack fighter (60 px)
    // ============================================================
    case EnemyKind::MEDIUM:
    {
        Color hull    = {  80,  30,  90, 255 };  // purple
        Color hull2   = { 110,  40, 120, 255 };
        Color accent  = { 220,  60, 200, 255 };  // magenta
        Color cockpit = { 180, 240, 100, 255 };  // green
        Color metal   = { 100,  90, 110, 255 };

        // Forward-swept wings
        for (int s = -1; s <= 1; s += 2)
        {
            DrawTriangle({ cx + s * sz * 0.05f, cy - sz * 0.15f },
                         { cx + s * sz * 0.38f, cy - sz * 0.3f },
                         { cx + s * sz * 0.25f, cy + sz * 0.2f },
                         hull);
            // Wing edge glow
            DrawLineEx({ cx + s * sz * 0.05f, cy - sz * 0.15f },
                       { cx + s * sz * 0.38f, cy - sz * 0.28f }, 1.5f, Fade(accent, 0.6f));
        }

        // Central fuselage
        DrawRectangle((int)(cx - sz * 0.1f), (int)(cy - sz * 0.25f),
                      (int)(sz * 0.2f), (int)(sz * 0.5f), hull2);

        // Nose prow
        DrawTriangle({ cx,           cy - sz * 0.45f },
                     { cx - sz * 0.1f, cy - sz * 0.2f },
                     { cx + sz * 0.1f, cy - sz * 0.2f },
                     metal);

        // Cockpit
        DrawEllipse((int)cx, (int)(cy - sz * 0.05f),
                    (int)(sz * 0.07f), (int)(sz * 0.1f), cockpit);
        DrawEllipseLines((int)cx, (int)(cy - sz * 0.05f),
                         (int)(sz * 0.07f), (int)(sz * 0.1f), Fade(WHITE, 0.3f));

        // Twin engine pods
        for (int e = -1; e <= 1; e += 2)
        {
            float ex = cx + e * sz * 0.12f;
            float ey = cy + sz * 0.25f;
            DrawRectangle((int)(ex - sz * 0.05f), (int)ey,
                          (int)(sz * 0.1f), (int)(sz * 0.15f), metal);
            float flicker = 0.5f + (float)fabs(sin(t * 16 + e + x * 0.1f)) * 0.5f;
            DrawCircle((int)ex, (int)(ey + sz * 0.15f),
                       (int)(sz * 0.05f), Fade(accent, flicker));
        }

        // Hull panel lines
        DrawLineEx({ cx - sz * 0.08f, cy - sz * 0.05f },
                   { cx + sz * 0.08f, cy - sz * 0.05f }, 1, Fade(WHITE, 0.15f));
        DrawLineEx({ cx - sz * 0.08f, cy + sz * 0.1f },
                   { cx + sz * 0.08f, cy + sz * 0.1f }, 1, Fade(WHITE, 0.15f));
        break;
    }

    // ============================================================
    //  LARGE - "Juggernaut" heavy gunship (80 px)
    // ============================================================
    case EnemyKind::LARGE:
    {
        Color armor    = {  40,  45,  40, 255 };  // olive-drab
        Color armorLt  = {  65,  70,  60, 255 };
        Color accent   = { 200, 180,  40, 255 };  // gold/brass
        Color cockpit  = { 255,  80,  30, 255 };  // red-orange
        Color engine   = { 200, 200, 180, 255 };

        // Heavy armor plates (hexagonal body)
        DrawPoly({ cx, cy }, 6, sz * 0.35f, 30, armor);
        DrawPolyLines({ cx, cy }, 6, (int)(sz * 0.35f), 30, armorLt);

        // Inner armor ring
        DrawPoly({ cx, cy }, 6, sz * 0.28f, 30, armorLt);
        DrawPolyLines({ cx, cy }, 6, (int)(sz * 0.28f), 30, accent);

        // Forward armor prow
        DrawTriangle({ cx,              cy - sz * 0.45f },
                     { cx - sz * 0.22f, cy - sz * 0.05f },
                     { cx + sz * 0.22f, cy - sz * 0.05f },
                     armorLt);
        DrawLineEx({ cx, cy - sz * 0.45f }, { cx, cy - sz * 0.05f }, 2, accent);

        // Side gun turrets
        for (int s = -1; s <= 1; s += 2)
        {
            float tx = cx + s * sz * 0.32f;
            float ty = cy - sz * 0.05f;
            // Turret base
            DrawCircle((int)tx, (int)ty, (int)(sz * 0.06f), armorLt);
            DrawCircleLines((int)tx, (int)ty, (int)(sz * 0.06f), accent);
            // Barrel
            DrawRectangle((int)(tx - 1.5f), (int)(ty - sz * 0.2f),
                          3, (int)(sz * 0.2f), accent);
            // Muzzle flash
            float flicker = (float)fabs(sin(t * 12 + s));
            DrawCircle((int)tx, (int)(ty - (int)(sz * 0.22f)),
                       2, Fade(YELLOW, flicker * 0.7f));
        }

        // Cockpit (narrow slit)
        DrawRectangle((int)(cx - sz * 0.12f), (int)(cy - sz * 0.1f),
                      (int)(sz * 0.24f), (int)(sz * 0.08f), cockpit);
        DrawRectangleLines((int)(cx - sz * 0.12f), (int)(cy - sz * 0.1f),
                           (int)(sz * 0.24f), (int)(sz * 0.08f), Fade(WHITE, 0.3f));

        // Triple engine exhaust
        for (int e = -1; e <= 1; e++)
        {
            float ex = cx + e * sz * 0.15f;
            float ey = cy + sz * 0.25f;
            float flicker = 0.6f + (float)fabs(sin(t * 10 + e * 1.8f)) * 0.4f;
            DrawCircle((int)ex, (int)ey, (int)(sz * 0.06f), Fade(engine, flicker));
            DrawCircle((int)ex, (int)ey, (int)(sz * 0.03f), Fade(WHITE, flicker * 0.7f));
            // Exhaust trail
            DrawCircle((int)ex, (int)(ey + sz * 0.08f),
                       (int)(sz * 0.04f), Fade(ORANGE, flicker * 0.4f));
        }

        // Armor rivets / detail dots
        for (int a = 0; a < 6; a++)
        {
            float ang = a * 60.0f * DEG2RAD + 30.0f * DEG2RAD;
            float rx = cx + (float)cos(ang) * sz * 0.3f;
            float ry = cy + (float)sin(ang) * sz * 0.3f;
            DrawCircle((int)rx, (int)ry, 2, accent);
        }
        break;
    }
    }
}

Rectangle Enemy::GetBounds() const
{
    int s = GetSize();
    return { x, y, (float)s, (float)s };
}

int Enemy::GetScore() const
{
    switch (kind)
    {
    case EnemyKind::SMALL:  return ENEMY_SMALL_SCORE;
    case EnemyKind::MEDIUM: return ENEMY_MEDIUM_SCORE;
    case EnemyKind::LARGE:  return ENEMY_LARGE_SCORE;
    default:                return 0;
    }
}

int Enemy::GetSize() const
{
    switch (kind)
    {
    case EnemyKind::SMALL:  return ENEMY_SMALL_SIZE;
    case EnemyKind::MEDIUM: return ENEMY_MEDIUM_SIZE;
    case EnemyKind::LARGE:  return ENEMY_LARGE_SIZE;
    default:                return ENEMY_MEDIUM_SIZE;
    }
}

Enemy* SpawnEnemy(Pool<Enemy, MAX_ENEMIES>& pool, int difficulty)
{
    Enemy* e = pool.Acquire();
    if (!e) return nullptr;

    int r = GetRandomValue(0, 100);
    EnemyKind kind;
    if (difficulty < 4)
        kind = (r < 80) ? EnemyKind::SMALL : EnemyKind::MEDIUM;
    else if (difficulty < 8)
        kind = (r < 50) ? EnemyKind::SMALL : (r < 85 ? EnemyKind::MEDIUM : EnemyKind::LARGE);
    else
        kind = (r < 30) ? EnemyKind::SMALL : (r < 70 ? EnemyKind::MEDIUM : EnemyKind::LARGE);

    int size = 0;
    switch (kind)
    {
    case EnemyKind::SMALL:  size = ENEMY_SMALL_SIZE;  break;
    case EnemyKind::MEDIUM: size = ENEMY_MEDIUM_SIZE; break;
    case EnemyKind::LARGE:  size = ENEMY_LARGE_SIZE;  break;
    }

    e->Init(kind, (float)GetRandomValue(50, SCREEN_W - 50 - size), -80.0f);
    return e;
}

} // namespace pwu
