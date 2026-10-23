#include "boss.h"
#include "constants.h"
#include <cmath>
#include <math.h>

using namespace pwu;

void Boss::Init(int type)
{
    x = SCREEN_W / 2.0f - BOSS_W / 2.0f;
    y = 50;
    bossType = type;
    hp = BOSS_HP;
    shootTimer = 0;
    moveTimer = 0;
    phase = 1;
    moveDir = 1;
    active = true;
}

void Boss::Update(Pool<Bullet, MAX_BOSS_BULLETS>& bullets, float playerX, float playerY)
{
    if (!active) return;

    float dtFrames = GetFrameTime() * 60.0f;

    phase = (hp > BOSS_HP / 2) ? 1 : 2;

    // Movement varies by type
    float baseSpeed;
    switch (bossType)
    {
    case 0: baseSpeed = (phase == 1) ? 2.0f : 4.0f; break;  // Carrier: slow->fast
    case 1: baseSpeed = (phase == 1) ? 5.0f : 7.0f; break;  // Destroyer: always fast
    case 2: baseSpeed = (phase == 1) ? 1.5f : 2.5f; break;  // BulletHell: slow, steady
    default: baseSpeed = 2.0f; break;
    }

    x += moveDir * baseSpeed * dtFrames;

    if (x <= 0)                { x = 0;               moveDir = 1; }
    if (x >= SCREEN_W - BOSS_W) { x = SCREEN_W - BOSS_W; moveDir = -1; }

    moveTimer += GetFrameTime();

    // Type 2 (BulletHell) always does sinusoidal movement
    if (bossType == 2 || phase == 2)
    {
        float amp = (bossType == 2) ? 60.0f : 40.0f;
        y = 50.0f + (float)sin(moveTimer * 3.0) * amp;
    }

    // Shooting
    shootTimer += dtFrames;

    float shootInterval;
    switch (bossType)
    {
    case 0: shootInterval = (phase == 1) ? 50.0f : 25.0f; break;
    case 1: shootInterval = (phase == 1) ? 35.0f : 18.0f; break;
    case 2: shootInterval = (phase == 1) ? 60.0f : 30.0f; break;
    default: shootInterval = 50.0f; break;
    }

    if (shootTimer >= shootInterval)
    {
        shootTimer -= shootInterval;

        switch (bossType)
        {
        // ── Type 0: Carrier ──
        // Phase 1: aimed shot   Phase 2: 5-way fan
        case 0:
            if (phase == 1)
            {
                Bullet* b = bullets.Acquire();
                if (b)
                {
                    b->x = x + BOSS_W / 2.0f;
                    b->y = y + BOSS_H;
                    float dx = playerX + PLAYER_SIZE / 2.0f - (x + BOSS_W / 2.0f);
                    float dy = playerY + PLAYER_SIZE / 2.0f - (y + BOSS_H);
                    float len = (float)sqrt(dx * dx + dy * dy);
                    if (len > 0) { dx /= len; dy /= len; }
                    b->speedX = dx * 4.0f;
                    b->speedY = dy * 4.0f;
                    b->trailTimer = 0;
                }
            }
            else
            {
                float angles[] = { -0.3f, -0.15f, 0.0f, 0.15f, 0.3f };
                for (int i = 0; i < 5; i++)
                {
                    Bullet* b = bullets.Acquire();
                    if (b)
                    {
                        b->x = x + BOSS_W / 2.0f;
                        b->y = y + BOSS_H;
                        b->speedX = (float)sin(angles[i]) * 5.0f;
                        b->speedY = (float)cos(angles[i]) * 5.0f;
                        b->trailTimer = 0;
                    }
                }
            }
            break;

        // ── Type 1: Destroyer ──
        // Phase 1: 3-way aimed burst   Phase 2: spiral barrage
        case 1:
            if (phase == 1)
            {
                for (int s = -1; s <= 1; s++)
                {
                    Bullet* b = bullets.Acquire();
                    if (b)
                    {
                        b->x = x + BOSS_W / 2.0f + s * 20.0f;
                        b->y = y + BOSS_H;
                        float dx = playerX + PLAYER_SIZE / 2.0f - (x + BOSS_W / 2.0f);
                        float dy = playerY + PLAYER_SIZE / 2.0f - (y + BOSS_H);
                        float len = (float)sqrt(dx * dx + dy * dy);
                        if (len > 0) { dx /= len; dy /= len; }
                        b->speedX = dx * 4.0f + s * 1.5f;
                        b->speedY = dy * 4.0f;
                        b->trailTimer = 0;
                    }
                }
            }
            else
            {
                // Spiral pattern
                for (int i = 0; i < 8; i++)
                {
                    Bullet* b = bullets.Acquire();
                    if (b)
                    {
                        float ang = moveTimer * 2.0f + i * 0.785f;
                        b->x = x + BOSS_W / 2.0f;
                        b->y = y + BOSS_H;
                        b->speedX = (float)sin(ang) * 3.5f;
                        b->speedY = (float)cos(ang) * 3.5f;
                        b->trailTimer = 0;
                    }
                }
            }
            break;

        // ── Type 2: BulletHell ──
        // Phase 1: slow wide spread   Phase 2: dense 7-way + aimed
        case 2:
            if (phase == 1)
            {
                float angles[] = { -0.4f, -0.2f, 0.0f, 0.2f, 0.4f };
                for (int i = 0; i < 5; i++)
                {
                    Bullet* b = bullets.Acquire();
                    if (b)
                    {
                        b->x = x + BOSS_W / 2.0f;
                        b->y = y + BOSS_H;
                        b->speedX = (float)sin(angles[i]) * 3.0f;
                        b->speedY = (float)cos(angles[i]) * 3.0f;
                        b->trailTimer = 0;
                    }
                }
            }
            else
            {
                // 7-way + aimed shot
                for (int i = -3; i <= 3; i++)
                {
                    Bullet* b = bullets.Acquire();
                    if (b)
                    {
                        b->x = x + BOSS_W / 2.0f;
                        b->y = y + BOSS_H;
                        b->speedX = (float)i * 1.2f;
                        b->speedY = 4.0f;
                        b->trailTimer = 0;
                    }
                }
            }
            break;
        }
    }
}

void Boss::Draw() const
{
    if (!active) return;

    int bx = (int)x, by = (int)y;
    int bw = BOSS_W, bh = BOSS_H;
    float t = (float)GetTime();
    float flicker = (phase == 2) ? (float)fabs(sin(t * 14.0)) * 0.5f : 0;
    float enginePulse = (float)fabs(sin(t * 8.0)) * 0.3f + 0.7f;

    // Color schemes per boss type
    Color metalDark, metalMid, metalLight, coreColor, flameColor, accentColor;
    switch (bossType)
    {
    case 0: // Carrier: blue-gray
        metalDark  = {  35,  35,  50, 255 };
        metalMid   = {  60,  55,  80, 255 };
        metalLight = { 100,  90, 130, 255 };
        coreColor  = (phase == 1) ? Color{  80, 180, 255, 255 } : Color{ 255,  60,  40, 255 };
        flameColor = (phase == 1) ? Color{ 255, 160,  30, 255 } : Color{ 255,  40,  20, 255 };
        accentColor = SKYBLUE;
        break;
    case 1: // Destroyer: red-black
        metalDark  = {  45,  20,  20, 255 };
        metalMid   = {  75,  35,  35, 255 };
        metalLight = { 120,  55,  55, 255 };
        coreColor  = (phase == 1) ? Color{ 255, 100,  30, 255 } : Color{ 255, 200,  50, 255 };
        flameColor = (phase == 1) ? Color{ 255,  80,  10, 255 } : Color{ 255, 220,  60, 255 };
        accentColor = ORANGE;
        break;
    case 2: // BulletHell: purple-green
    default:
        metalDark  = {  30,  15,  40, 255 };
        metalMid   = {  55,  30,  70, 255 };
        metalLight = {  90,  55, 110, 255 };
        coreColor  = (phase == 1) ? Color{ 120, 200,  60, 255 } : Color{ 255,  60, 200, 255 };
        flameColor = (phase == 1) ? Color{ 100, 220,  40, 255 } : Color{ 255,  40, 180, 255 };
        accentColor = GREEN;
        break;
    }

    // Shadow
    DrawRectangle(bx + 6, by + 6, bw, bh, Fade(BLACK, 0.35f));

    // Engine exhaust (number varies by type)
    int engineCount = (bossType == 1) ? 3 : 2;
    for (int e = 0; e < engineCount; e++)
    {
        int ex = bx + bw / 2 + (e - (engineCount - 1) / 2.0f) * (bw / (engineCount + 1));
        int ey = by + bh - 5;
        int flameH = (int)(14 + enginePulse * 10);
        DrawTriangle({ (float)ex, (float)ey }, { (float)(ex - 12), (float)(ey + flameH) },
                     { (float)(ex + 12), (float)(ey + flameH) }, flameColor);
        DrawTriangle({ (float)ex, (float)ey + 4 }, { (float)(ex - 7), (float)(ey + flameH - 4) },
                     { (float)(ex + 7), (float)(ey + flameH - 4) }, Fade(YELLOW, enginePulse * 0.6f));
    }

    // Wing pods
    for (int s = 0; s < 2; s++)
    {
        int wx = (s == 0) ? bx - 32 : bx + bw - 12;
        int wy = by + 20;
        int ww = 44, wh = 60;
        DrawRectangle(wx, wy, ww, wh, metalDark);
        Rectangle podRect = { (float)wx, (float)wy, (float)ww, (float)wh };
        DrawRectangleLinesEx(podRect, 2, metalLight);
        DrawLine(wx + ww / 2, wy + 4, wx + ww / 2, wy + wh - 4, metalLight);
        int gx = wx + ww / 2 - 3;
        DrawRectangle(gx, wy + wh - 8, 6, 12, DARKGRAY);
        DrawRectangle(gx, wy + wh - 4, 6, 6, Fade(coreColor, 0.7f));
        if (phase == 2)
        {
            Rectangle glowRect = { (float)wx - 1, (float)wy - 1, (float)ww + 2, (float)wh + 2 };
            DrawRectangleLinesEx(glowRect, 2, Fade(RED, 0.5f + flicker));
        }
    }

    // Main hull
    DrawRectangle(bx + 20, by + 8, bw - 40, bh - 6, metalMid);
    Rectangle hullRect = { (float)(bx + 20), (float)(by + 8), (float)(bw - 40), (float)(bh - 6) };
    DrawRectangleLinesEx(hullRect, 2, metalLight);
    for (int i = 0; i < 3; i++)
        DrawLine(bx + 30 + i * 55, by + 12, bx + 30 + i * 55, by + bh - 14, Fade(metalDark, 0.5f));
    DrawLine(bx + 22, by + bh / 2 + 5, bx + bw - 22, by + bh / 2 + 5, Fade(metalDark, 0.5f));

    // Cockpit dome
    DrawCircle(bx + bw / 2, by + 18, 16, Fade(accentColor, 0.2f));
    DrawCircleLines(bx + bw / 2, by + 18, 16, Fade(accentColor, 0.45f));

    // Core
    int coreX = bx + bw / 2, coreY = by + bh / 2 + 5;
    DrawCircle(coreX, coreY, 18, Fade(coreColor, 0.25f + flicker * 0.3f));
    DrawCircle(coreX, coreY, 12, Fade(coreColor, 0.5f + flicker * 0.3f));
    DrawCircle(coreX, coreY, 6, Fade(WHITE, 0.6f + flicker * 0.3f));

    if (phase == 2)
    {
        Rectangle phase2Rect = { (float)(bx + 18), (float)(by + 6), (float)(bw - 36), (float)(bh - 4) };
        DrawRectangleLinesEx(phase2Rect, 3, Fade(RED, 0.45f + flicker));
        DrawCircle(coreX, coreY, 22, Fade(RED, 0.15f + flicker * 0.2f));
    }

    // Damage cracks
    float hpRatio = (float)hp / BOSS_HP;
    if (hpRatio <= 0.4f)
    {
        DrawLine(bx + 30, by + 10, bx + 70, by + bh / 2, Fade(WHITE, (0.4f - hpRatio) * 2.5f));
        DrawLine(bx + bw - 35, by + 15, bx + bw - 75, by + bh / 2 + 10, Fade(WHITE, (0.4f - hpRatio) * 2.5f));
    }

    // Boss type label
    const char* typeName = (bossType == 0) ? "CARRIER" : (bossType == 1) ? "DESTROYER" : "HELLBRINGER";
    DrawText(TextFormat("%s  [ %d / %d ]", typeName, hp, BOSS_HP),
             bx + bw / 2 - 80, by - 26, 16, WHITE);
}

void Boss::TakeDamage()
{
    hp--;
    if (hp <= 0) active = false;
}

Rectangle Boss::GetBounds() const
{
    return { x, y, (float)BOSS_W, (float)BOSS_H };
}
