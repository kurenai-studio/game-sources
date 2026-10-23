#include "powerup.h"
#include <math.h>

namespace pwu {

void PowerUp::Init(PowerUpKind k, float startX, float startY)
{
    kind = k;
    x = startX;
    y = startY;
}

void PowerUp::Update()
{
    y += POWERUP_FALL_SPEED * GetFrameTime() * 60.0f;
    if (y > SCREEN_H + 50) active = false;
}

void PowerUp::Draw() const
{
    float r = POWERUP_SIZE / 2.0f;
    float pulse = 1.0f + (float)sin(GetTime() * 5.0 + x * 0.01) * 0.1f;
    float outerR = r * pulse + 4;

    Color baseColor, glowColor;
    const char* label;

    switch (kind)
    {
    case PowerUpKind::HEAL:
        baseColor = GREEN;
        glowColor = { 0, 255, 100, 60 };
        label = "+";
        break;
    case PowerUpKind::TRIPLE:
        baseColor = BLUE;
        glowColor = { 60, 120, 255, 60 };
        label = "T";
        break;
    case PowerUpKind::BOMB:
        baseColor = RED;
        glowColor = { 255, 80, 80, 60 };
        label = "B";
        break;
    default:
        baseColor = GRAY;
        glowColor = { 128, 128, 128, 60 };
        label = "?";
        break;
    }

    // Outer glow ring
    DrawCircle((int)x, (int)y, outerR, Fade(glowColor, 0.3f));
    DrawCircle((int)x, (int)y, outerR * 0.7f, Fade(glowColor, 0.5f));

    // Main body
    DrawCircle((int)x, (int)y, r * pulse, baseColor);

    // Inner highlight
    DrawCircle((int)(x - r * 0.2f), (int)(y - r * 0.25f), r * 0.45f, Fade(WHITE, 0.25f));

    // Border
    DrawCircleLines((int)x, (int)y, r * pulse, Fade(WHITE, 0.4f));

    // Label
    int fontSize = (kind == PowerUpKind::HEAL) ? 24 : 18;
    int textW = MeasureText(label, fontSize);
    DrawText(label, (int)x - textW / 2, (int)y - fontSize / 2, fontSize, WHITE);

    // Icon-specific extras
    switch (kind)
    {
    case PowerUpKind::TRIPLE:
        // Three small dots above
        for (int i = -1; i <= 1; i++)
        {
            DrawCircle((int)x + i * 8, (int)y - (int)r - 6, 3, Fade(BLUE, 0.8f));
        }
        break;
    case PowerUpKind::BOMB:
        // Sparkle effect
        DrawCircle((int)x + 8, (int)y - 8, 3, Fade(WHITE, 0.7f));
        DrawCircle((int)x - 6, (int)y + 10, 2, Fade(WHITE, 0.5f));
        break;
    case PowerUpKind::HEAL:
        // Cross glow
        DrawRectangle((int)(x - r * 0.25f), (int)(y - r * 0.6f), (int)(r * 0.5f), (int)(r * 1.2f),
                      Fade(WHITE, 0.15f));
        DrawRectangle((int)(x - r * 0.6f), (int)(y - r * 0.25f), (int)(r * 1.2f), (int)(r * 0.5f),
                      Fade(WHITE, 0.15f));
        break;
    }
}

Rectangle PowerUp::GetBounds() const
{
    float r = POWERUP_SIZE / 2.0f;
    return { x - r, y - r, (float)POWERUP_SIZE, (float)POWERUP_SIZE };
}

void TrySpawnPowerUp(Pool<PowerUp, MAX_POWERUPS>& pool, float x, float y)
{
    if (GetRandomValue(0, 100) < (int)(POWERUP_DROP_CHANCE * 100))
    {
        PowerUp* p = pool.Acquire();
        if (p)
        {
            int r = GetRandomValue(0, 100);
            PowerUpKind kind;
            if (r < 35)
                kind = PowerUpKind::HEAL;
            else
                kind = PowerUpKind::TRIPLE;
            // BOMB is now a stock ability (B key), not a drop

            p->Init(kind, x, y);
        }
    }
}

} // namespace pwu
