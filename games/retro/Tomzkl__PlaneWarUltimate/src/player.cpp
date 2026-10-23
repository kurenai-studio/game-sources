#include "player.h"
#include "input.h"
#include <math.h>

using namespace pwu;

void Player::Init()
{
    x = SCREEN_W / 2.0f - PLAYER_SIZE / 2.0f;
    y = SCREEN_H - 120.0f;
    hp = PLAYER_MAX_HP;
    bombCount = 3;
    shootTimer = 0;
    tripleTimer = 0;
    invincibleTimer = 0;
    chargeTimer = 0;
    isCharging  = false;
    chargeReady = false;
    laserActive = false;
    laserTimer  = 0;
}

void Player::Update(Pool<Bullet, MAX_BULLETS>& bullets, Sound& shootSound, int& totalShots,
                    float& laserOutX, bool& laserOutActive, float& laserOutTimer)
{
    float dx = Input::AxisX();
    float dy = Input::AxisY();

    float dtFrames = GetFrameTime() * 60.0f;

    // Normalize diagonal movement
    if (dx != 0 && dy != 0)
    {
        const float inv = 0.70710678f;
        dx *= inv; dy *= inv;
    }

    // -- Laser active countdown --
    if (laserActive)
    {
        laserTimer -= dtFrames;
        if (laserTimer <= 0) laserActive = false;
    }

    // Output laser state for Game
    laserOutX      = laserX;
    laserOutActive = laserActive;
    laserOutTimer  = laserTimer;

    x += dx * PLAYER_SPEED * dtFrames;
    y += dy * PLAYER_SPEED * dtFrames;

    // Clamp
    if (x < 0) x = 0;
    if (x > SCREEN_W - PLAYER_SIZE) x = SCREEN_W - PLAYER_SIZE;
    if (y < 0) y = 0;
    if (y > SCREEN_H - PLAYER_SIZE) y = SCREEN_H - PLAYER_SIZE;

    // Timers
    if (invincibleTimer > 0) invincibleTimer -= dtFrames;
    if (tripleTimer > 0) tripleTimer -= dtFrames;

    // -- Shooting + Charge --
    // Tap space      -> one bullet
    // Hold space     -> one bullet, then charge builds
    // Release full   -> laser beam
    // Release partial-> nothing (charge wasted)
    if (!laserActive && Input::Shoot())
    {
        // Fire on first frame of press
        if (Input::ShootPressed())
        {
            chargeTimer = 0;
            chargeReady = false;
            isCharging  = false;

            float cx = x + PLAYER_SIZE / 2.0f - BULLET_W / 2.0f;
            bool fired = false;
            if (tripleTimer > 0)
            {
                float speeds[] = { -3.0f, 0.0f, 3.0f };
                for (int i = 0; i < 3; i++) {
                    Bullet* b = bullets.Acquire();
                    if (b) { b->x = cx; b->y = y; b->speedX = speeds[i];
                             b->speedY = -(float)BULLET_SPEED; b->trailTimer = 0; fired = true; }
                }
            }
            else {
                Bullet* b = bullets.Acquire();
                if (b) { b->x = cx; b->y = y; b->speedX = 0;
                         b->speedY = -(float)BULLET_SPEED; b->trailTimer = 0; fired = true; }
            }
            if (fired) { totalShots++; PlaySound(shootSound); }
        }
        else
        {
            // Holding: build charge
            chargeTimer += dtFrames;
            if (chargeTimer >= CHARGE_MAX) { chargeTimer = CHARGE_MAX; chargeReady = true; }
            if (chargeTimer > 3.0f) { isCharging = true; dx *= 0.5f; dy *= 0.5f; }
        }
    }
    else if (!laserActive && !Input::Shoot())
    {
        // Released
        if (chargeReady)
        {
            // Full charge -> laser
            laserActive = true;
            laserTimer  = LASER_DURATION;
            laserX      = x + PLAYER_SIZE / 2.0f;
            totalShots++;
            PlaySound(shootSound);
        }
        else if (chargeTimer > 5.0f)
        {
            // Partial charge -> consolation bullet (so release always feels responsive)
            float cx = x + PLAYER_SIZE / 2.0f - BULLET_W / 2.0f;
            bool fired = false;
            if (tripleTimer > 0)
            {
                float speeds[] = { -3.0f, 0.0f, 3.0f };
                for (int i = 0; i < 3; i++) {
                    Bullet* b = bullets.Acquire();
                    if (b) { b->x = cx; b->y = y; b->speedX = speeds[i];
                             b->speedY = -(float)BULLET_SPEED; b->trailTimer = 0; fired = true; }
                }
            }
            else {
                Bullet* b = bullets.Acquire();
                if (b) { b->x = cx; b->y = y; b->speedX = 0;
                         b->speedY = -(float)BULLET_SPEED; b->trailTimer = 0; fired = true; }
            }
            if (fired) { totalShots++; PlaySound(shootSound); }
        }
        chargeTimer = 0;
        chargeReady = false;
        isCharging  = false;
    }
}

void Player::Draw(const Texture2D& tex) const
{
    Color tint = WHITE;
    if (invincibleTimer > 0 && ((int)(invincibleTimer / 6.0f) % 2) == 0)
        tint = Fade(WHITE, 0.35f);

    if (tex.id != 0)
    {
        DrawTexture(tex, (int)x, (int)y, tint);
        // Draw charge indicator on top of texture
        float sz2 = (float)PLAYER_SIZE;
        float cx2 = x + sz2 / 2.0f, cy2 = y + sz2 / 2.0f;
        float chargePct2 = chargeTimer / CHARGE_MAX;
        if (isCharging && chargePct2 > 0.1f)
            DrawRing({ cx2, cy2 + sz2 * 0.45f }, 8, 12, -90, -90 + (int)(chargePct2 * 360), 32,
                     chargeReady ? Fade(GOLD, 0.9f) : Fade(SKYBLUE, 0.7f));
        if (invincibleTimer > 0)
            DrawCircleLines((int)cx2, (int)cy2, (int)(sz2 / 2 + 6), Fade(SKYBLUE, 0.6f));
        return;
    }

    // ── Procedural X-wing fighter ────────────────────────────
    float sz  = (float)PLAYER_SIZE;
    float cx  = x + sz / 2.0f;
    float cy  = y + sz / 2.0f;
    float t   = (float)GetTime();

    float flicker  = 0.7f + (float)fabs(sin(t * 18.0)) * 0.3f;
    float flicker2 = 0.6f + (float)fabs(sin(t * 22.0 + 1.5f)) * 0.4f;

    // Charge glow
    float chargePct = chargeTimer / CHARGE_MAX;
    Color bodyDark   = { (unsigned char)(20 + (int)(chargePct * 40)),  22,  48, 255 };
    Color bodyMid    = { (unsigned char)(35 + (int)(chargePct * 40)),  38,  70, 255 };
    Color bodyLight  = { (unsigned char)(55 + (int)(chargePct * 30)),  60, 100, 255 };
    Color accent     = {  50, 140, 240, 255 };
    Color accentDark = {  30,  80, 160, 255 };
    Color cockpit    = { 100, 210, 255, 255 };
    Color engineGlow = { 255, 160,  40, 255 };
    Color flameCore  = { 255, 240, 200, 255 };
    Color gunMetal   = {  80,  82,  90, 255 };
    Color wingEdge   = {  70,  75, 110, 255 };

    if (chargeReady) {
        float pulse = 0.7f + (float)fabs(sin(t * 30.0)) * 0.3f;
        bodyDark  = { (unsigned char)(60 + (int)(pulse * 80)),  (unsigned char)(22 + (int)(pulse * 30)),  (unsigned char)(48 + (int)(pulse * 50)), 255 };
        bodyMid   = { (unsigned char)(75 + (int)(pulse * 60)),  (unsigned char)(38 + (int)(pulse * 20)),  (unsigned char)(70 + (int)(pulse * 30)), 255 };
        accent    = { 255, 200, 20, 255 };
        engineGlow= { 255, 240, 180, 255 };
    }

    if (tint.a < 255) {
        float a = (float)tint.a / 255.0f;
        bodyDark=Fade(bodyDark,a); bodyMid=Fade(bodyMid,a); bodyLight=Fade(bodyLight,a);
        accent=Fade(accent,a); accentDark=Fade(accentDark,a); cockpit=Fade(cockpit,a);
        engineGlow=Fade(engineGlow,a); flameCore=Fade(flameCore,a);
        gunMetal=Fade(gunMetal,a); wingEdge=Fade(wingEdge,a);
    }

    // Engine afterburner
    for (int e = 0; e < 2; e++) {
        float ex = cx - 14.0f + e * 28.0f, ey = cy + sz * 0.35f;
        float flameH = (12.0f + flicker * 10.0f) * 0.7f;
        DrawTriangle({ ex - 5, ey }, { ex - 8, ey + flameH }, { ex + 5, ey + flameH }, Fade(ORANGE, 0.6f * flicker));
        DrawTriangle({ ex - 5, ey }, { ex + 8, ey + flameH }, { ex + 5, ey + flameH }, Fade(ORANGE, 0.6f * flicker));
        flameH *= 0.6f;
        DrawTriangle({ ex - 2, ey }, { ex - 4, ey + flameH }, { ex + 2, ey + flameH }, Fade(YELLOW, 0.8f * flicker2));
        DrawTriangle({ ex - 2, ey }, { ex + 4, ey + flameH }, { ex + 2, ey + flameH }, Fade(YELLOW, 0.8f * flicker2));
        DrawCircle((int)ex, (int)(ey + 2), 2, Fade(WHITE, 0.9f * flicker));
    }

    // S-foils
    for (int s = -1; s <= 1; s += 2) {
        float wx = cx + s * sz * 0.38f, wy = cy - sz * 0.05f;
        DrawTriangle({ wx, wy }, { wx - s * 8, wy + sz * 0.45f }, { wx + s * 16, wy + sz * 0.3f }, bodyDark);
        DrawLineEx({ wx, wy }, { wx + s * 18, wy + sz * 0.32f }, 2, wingEdge);
        DrawTriangle({ wx - s * 3, wy + sz * 0.38f }, { wx - s * 10, wy + sz * 0.6f }, { wx + s * 12, wy + sz * 0.5f }, bodyDark);
        float epx = wx + s * 8, epy = wy + sz * 0.35f;
        DrawRectangle((int)(epx - 4), (int)(epy - 3), 8, 14, gunMetal);
        DrawRectangleLines((int)(epx - 4), (int)(epy - 3), 8, 14, bodyLight);
        DrawCircle((int)epx, (int)(epy - 5), 3, Fade(accent, 0.5f));
        DrawCircle((int)epx, (int)(epy + 12), 3, Fade(engineGlow, 0.7f * flicker));
        DrawRectangle((int)(epx - 1.5f), (int)(epy - 8), 3, 6, gunMetal);
    }

    // Fuselage
    DrawTriangle({ cx, cy - sz * 0.45f }, { cx - sz * 0.2f, cy - sz * 0.1f }, { cx + sz * 0.2f, cy - sz * 0.1f }, bodyMid);
    DrawRectangle((int)(cx - sz * 0.17f), (int)(cy - sz * 0.1f), (int)(sz * 0.34f), (int)(sz * 0.45f), bodyMid);
    DrawRectangle((int)(cx - 2), (int)(cy - sz * 0.12f), 4, (int)(sz * 0.5f), accentDark);
    for (int i = 0; i < 3; i++) {
        float ly = cy - sz * 0.05f + i * sz * 0.14f;
        DrawLineEx({ cx - sz * 0.16f, ly }, { cx + sz * 0.16f, ly }, 1.5f, bodyLight);
    }

    // Cockpit
    float cpy = cy - sz * 0.18f;
    DrawEllipse((int)cx, (int)cpy, sz * 0.1f, sz * 0.12f, cockpit);
    DrawEllipseLines((int)cx, (int)cpy, (int)(sz * 0.1f), (int)(sz * 0.12f), accent);
    DrawCircle((int)(cx - sz * 0.03f), (int)(cpy - sz * 0.04f), (int)(sz * 0.03f), Fade(WHITE, 0.4f));

    // Nose
    DrawLineEx({ cx, cy - sz * 0.45f }, { cx, cy - sz * 0.15f }, 2, accent);
    DrawLineEx({ cx - sz * 0.2f, cy - sz * 0.1f }, { cx - sz * 0.17f, cy + sz * 0.35f }, 1.5f, wingEdge);
    DrawLineEx({ cx + sz * 0.2f, cy - sz * 0.1f }, { cx + sz * 0.17f, cy + sz * 0.35f }, 1.5f, wingEdge);

    // Wing markings
    for (int s = -1; s <= 1; s += 2) {
        DrawTriangle({ cx + s * sz * 0.16f, cy + sz * 0.05f },
                     { cx + s * sz * 0.16f - s * 3, cy + sz * 0.2f },
                     { cx + s * sz * 0.16f + s * 3, cy + sz * 0.2f }, accentDark);
    }

    // Engine vents
    for (int e = 0; e < 2; e++) {
        float ex = cx - 12.0f + e * 24.0f, ey = cy + sz * 0.33f;
        DrawRectangle((int)(ex - 3), (int)ey, 6, 5, gunMetal);
        DrawCircle((int)ex, (int)(ey + 5), 2, Fade(engineGlow, 0.8f * flicker));
    }

    // Charge indicator ring
    if (isCharging && chargePct > 0.1f) {
        DrawRing({ cx, cy + sz * 0.45f }, 8, 12, -90, -90 + (int)(chargePct * 360), 32,
                 chargeReady ? Fade(GOLD, 0.9f) : Fade(SKYBLUE, 0.7f));
    }

    if (invincibleTimer > 0) {
        DrawCircleLines((int)cx, (int)cy, (int)(sz / 2 + 6), Fade(SKYBLUE, 0.6f));
        DrawCircleLines((int)cx, (int)cy, (int)(sz / 2 + 4), Fade(WHITE, 0.3f));
    }
}

void Player::TakeDamage()
{
    if (invincibleTimer > 0) return;
    hp--;
    if (hp < 0) hp = 0;
    invincibleTimer = (float)INVINCIBILITY_FRAMES;
}

bool Player::IsInvincible() const { return invincibleTimer > 0; }

Rectangle Player::GetBounds() const { return { x, y, (float)PLAYER_SIZE, (float)PLAYER_SIZE }; }
