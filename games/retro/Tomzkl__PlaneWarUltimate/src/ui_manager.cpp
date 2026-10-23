#include "ui_manager.h"
#include "types.h"
#include "constants.h"
#include "input.h"
#include <cmath>

using namespace pwu;

// ==================================================================
//  Lifecycle
// ==================================================================

void UIManager::Init()
{
    menuSelection     = 0;
    pauseSelection    = 0;
    settingsSelection = 0;
    lastSettingsSel   = 0;
    sliderRepeatTimer = 0;
    sliderRepeatDir   = 0;
    volumeSetting     = DEFAULT_VOLUME;
    sfxVolume         = DEFAULT_SFX_VOLUME;

    for (int i = 0; i < STARFIELD_COUNT; i++)
    {
        stars[i].x     = (float)GetRandomValue(0, SCREEN_W);
        stars[i].y     = (float)GetRandomValue(0, SCREEN_H);
        stars[i].speed = GetRandomValue(10, 60) / 10.0f;
        stars[i].alpha = GetRandomValue(30, 100) / 100.0f;
        stars[i].size  = (float)GetRandomValue(1, 3);
    }
}

void UIManager::UpdateStarfield()
{
    float dtFrames = GetFrameTime() * 60.0f;
    for (int i = 0; i < STARFIELD_COUNT; i++)
    {
        stars[i].y += stars[i].speed * dtFrames;
        if (stars[i].y > SCREEN_H + 5)
        {
            stars[i].y     = -5;
            stars[i].x     = (float)GetRandomValue(0, SCREEN_W);
            stars[i].alpha = GetRandomValue(30, 100) / 100.0f;
        }
    }
}

// ==================================================================
//  State updates
// ==================================================================

bool UIManager::UpdateMenu(GameState& state)
{
    UpdateStarfield();

    if (Input::MenuUp())
    {
        menuSelection--;
        if (menuSelection < 0) menuSelection = 3;
    }
    if (Input::MenuDown())
    {
        menuSelection++;
        if (menuSelection > 3) menuSelection = 0;
    }

    if (Input::Confirm())
    {
        switch (menuSelection)
        {
        case 0: // Start
            state = GameState::PLAYING;
            return true;
        case 1: // Settings
            state = GameState::SETTINGS;
            settingsSelection = 0;
            return true;
        case 2: // Leaderboard
            state = GameState::LEADERBOARD;
            return true;
        case 3: // Quit
            return false;   // signal: quit requested
        }
    }
    return true;
}

bool UIManager::UpdateSettings(GameState& state, Difficulty& difficulty)
{
    int maxSel = 4;  // Difficulty, Master Vol, SFX Vol, Fullscreen, Back
    if (Input::MenuUp())
    {
        settingsSelection--;
        if (settingsSelection < 0) settingsSelection = maxSel;
    }
    if (Input::MenuDown())
    {
        settingsSelection++;
        if (settingsSelection > maxSel) settingsSelection = 0;
    }

    // Reset slider repeat state when selection changes
    if (settingsSelection != lastSettingsSel)
    {
        sliderRepeatTimer = 0;
        sliderRepeatDir   = 0;
        lastSettingsSel   = settingsSelection;
    }

    // Helper: volume slider logic with key-repeat acceleration
    auto adjustSlider = [this](float& val, float step) {
        int d = 0;
        if (Input::SliderLeftPressed())        { d = -1; sliderRepeatTimer = 0; sliderRepeatDir = -1; }
        if (Input::SliderRightPressed())       { d =  1; sliderRepeatTimer = 0; sliderRepeatDir =  1; }
        if (Input::SliderLeft()  && sliderRepeatDir == -1) { sliderRepeatTimer++; if (sliderRepeatTimer > 20 && sliderRepeatTimer % 3 == 0) d = -1; }
        else if (Input::SliderRight() && sliderRepeatDir == 1) { sliderRepeatTimer++; if (sliderRepeatTimer > 20 && sliderRepeatTimer % 3 == 0) d = 1; }
        else if (!Input::SliderLeft() && !Input::SliderRight()) { sliderRepeatDir = 0; sliderRepeatTimer = 0; }
        if (d != 0) { val += d * step; if (val < 0) val = 0; if (val > 1.0f) val = 1.0f; }
    };

    // 0: Difficulty
    if (settingsSelection == 0)
    {
        if (Input::SliderLeftPressed() || Input::SliderRightPressed())
        {
            int d = (int)difficulty;
            if (Input::SliderRightPressed()) d++;
            if (Input::SliderLeftPressed())  d--;
            if      (d < 0) d = 3;
            else if (d > 3) d = 0;
            difficulty = (Difficulty)d;
        }
    }

    if (settingsSelection == 1) { adjustSlider(volumeSetting, 0.05f); SetMasterVolume(volumeSetting); }
    if (settingsSelection == 2) { adjustSlider(sfxVolume,     0.05f); }

    if (settingsSelection == 3) // Fullscreen
    {
        if (Input::Confirm())
            ToggleFullscreen();
    }

    if (settingsSelection == 4 && Input::Confirm()) // Back
        state = GameState::MENU;

    if (Input::Back())
        state = GameState::MENU;

    return true;
}

bool UIManager::UpdatePaused(GameState& state)
{
    if (Input::Pause())
    {
        state = GameState::PLAYING;
        return true;
    }

    if (Input::MenuUp())
    {
        pauseSelection--;
        if (pauseSelection < 0) pauseSelection = 2;
    }
    if (Input::MenuDown())
    {
        pauseSelection++;
        if (pauseSelection > 2) pauseSelection = 0;
    }

    if (Input::Confirm())
    {
        switch (pauseSelection)
        {
        case 0: state = GameState::PLAYING; break;   // Continue
        case 1:                                        // Restart
            pauseWantsRestart = true;
            state = GameState::PLAYING;
            break;
        case 2: state = GameState::MENU;    break;   // Main Menu
        }
    }
    return true;
}

bool UIManager::UpdateGameOver(GameState& state)
{
    if (Input::Restart() || Input::Confirm())
    {
        state = GameState::PLAYING;
    }
    if (Input::Back())
    {
        state = GameState::MENU;
    }
    return true;
}

// ==================================================================
//  Menu drawing
// ==================================================================

void UIManager::DrawMenuBackground() const
{
    int bandH = 16;
    for (int i = 0; i < SCREEN_H; i += bandH)
    {
        float pct = (float)i / SCREEN_H;
        Color c = {
            (unsigned char)(10 + (int)(pct * 15)),
            (unsigned char)(8  + (int)(pct * 12)),
            (unsigned char)(30 + (int)(pct * 20)), 255
        };
        DrawRectangle(0, i, SCREEN_W, bandH, c);
    }
}

void UIManager::DrawMenu(int highScore, int highLevel) const
{
    float t = (float)GetTime();

    // Fighter silhouettes on sides
    DrawTriangle({ 120, 110 }, { 185, 80 }, { 185, 140 }, Fade(SKYBLUE, 0.12f));
    DrawTriangle({ 680, 110 }, { 615, 80 }, { 615, 140 }, Fade(SKYBLUE, 0.12f));

    float pulse = 1.0f + (float)sin(t * 2.5) * 0.04f;
    int ts = (int)(52 * pulse);
    DrawText("PLANE WAR", 202, 72, ts, Fade(SKYBLUE, 0.1f));
    DrawText("PLANE WAR", 200, 70, ts, WHITE);
    DrawText("ULTIMATE", 252, 122, ts, Fade(GOLD, 0.1f));
    DrawText("ULTIMATE", 250, 120, ts, GOLD);

    DrawLine(210, 185, 340, 185, Fade(GRAY, 0.3f));
    DrawLine(460, 185, 590, 185, Fade(GRAY, 0.3f));
    DrawText("C++  |  Raylib  |  Arcade", 330, 178, 14, GRAY);

    if (highScore > 0)
        DrawText(TextFormat("BEST: %d  (Lv.%d)", highScore, highLevel), 260, 220, 20, SKYBLUE);

    const char* items[] = { "START GAME", "SETTINGS", "LEADERBOARD", "QUIT" };
    for (int i = 0; i < 4; i++)
    {
        int iy = 290 + i * 55;
        bool sel = (i == menuSelection);
        if (sel)
        {
            DrawRectangle(280, iy - 4, 240, 36, Fade(SKYBLUE, 0.1f));
            DrawRectangleLines(280, iy - 4, 240, 36, Fade(SKYBLUE, 0.25f));
            float bob = (float)sin(t * 6.0 + i) * 3.0f;
            DrawText(">", 295, iy + (int)bob, 26, YELLOW);
        }
        DrawText(items[i], sel ? 318 : 320, iy, sel ? 28 : 26,
                 sel ? YELLOW : Color{ 150, 150, 170, 255 });
    }

    DrawText("v1.0", 760, 575, 14, Fade(GRAY, 0.4f));
    DrawText("W/S Nav  ENTER Select", 280, 520, 16, Fade(GRAY, 0.35f));
}

void UIManager::DrawSettings(Difficulty difficulty) const
{
    DrawText("SETTINGS", 300, 60, 42, WHITE);

    // Difficulty
    {
        Color c = (settingsSelection == 0) ? YELLOW : WHITE;
        DrawText("Difficulty", 160, 115, 26, c);
        const char* diffNames[] = { "EASY", "NORMAL", "HARD", "LUNATIC" };
        Color diffColor = (settingsSelection == 0) ? YELLOW : SKYBLUE;
        DrawText(diffNames[(int)difficulty], 460, 115, 26, diffColor);
    }

    // Master Volume
    {
        Color c = (settingsSelection == 0) ? YELLOW : WHITE;
        DrawText("Master Volume", 160, 155, 26, c);
        DrawRectangle(360, 162, 200, 18, DARKGRAY);
        DrawRectangle(360, 162, (int)(200 * volumeSetting), 18,
                      settingsSelection == 0 ? YELLOW : SKYBLUE);
        DrawText(TextFormat("%d%%", (int)(volumeSetting * 100)), 575, 155, 24, WHITE);
    }

    // SFX Volume
    {
        Color c = (settingsSelection == 1) ? YELLOW : WHITE;
        DrawText("SFX Volume", 160, 215, 26, c);
        DrawRectangle(360, 222, 200, 18, DARKGRAY);
        DrawRectangle(360, 222, (int)(200 * sfxVolume), 18,
                      settingsSelection == 1 ? YELLOW : SKYBLUE);
        DrawText(TextFormat("%d%%", (int)(sfxVolume * 100)), 575, 215, 24, WHITE);
    }

    // Fullscreen
    {
        Color c = (settingsSelection == 2) ? YELLOW : WHITE;
        DrawText("Fullscreen", 160, 275, 26, c);
        DrawText(IsWindowFullscreen() ? "ON" : "OFF", 460, 275, 26, SKYBLUE);
    }

    // Back
    {
        Color c = (settingsSelection == 3) ? YELLOW : GRAY;
        DrawText("BACK", 370, 355, 28, c);
    }

    DrawText("<- / -> Adjust    ENTER Toggle    ESC Back", 150, 500, 16, Fade(GRAY, 0.4f));
    DrawText("ESC to return", 320, 525, 18, DARKGRAY);
}

// ==================================================================
//  Pause / Game Over overlays
// ==================================================================

void UIManager::DrawPauseOverlay() const
{
    DrawRectangle(0, 0, SCREEN_W, SCREEN_H, Fade(BLACK, 0.65f));
    DrawText("PAUSED", 260, 100, 60, YELLOW);

    const char* items[] = { "CONTINUE", "RESTART", "MAIN MENU" };
    for (int i = 0; i < 3; i++)
    {
        Color c = (i == pauseSelection) ? YELLOW : GRAY;
        if (i == pauseSelection)
            DrawText(">", 290, 230 + i * 45, 30, YELLOW);
        DrawText(items[i], 325, 230 + i * 45, 30, c);
    }

    DrawText("Navigate: W/S    Select: ENTER    Resume: ESC / P",
             110, 500, 18, DARKGRAY);
}

void UIManager::DrawGameOverOverlay(int score, int highScore, int highLevel,
                                    int enemySpeed, int totalKills, int totalShots,
                                    int totalHits, int maxCombo, int gameTimerSecs) const
{
    DrawRectangle(0, 0, SCREEN_W, SCREEN_H, Fade(BLACK, 0.78f));
    int cx = SCREEN_W / 2;
    int lvl = enemySpeed - INITIAL_ENEMY_SPEED;
    float t = (float)GetTime();

    DrawText("MISSION OVER", cx - 160, 45, 44, RED);
    DrawText(TextFormat("%d", score),
             cx - MeasureText(TextFormat("%d", score), 60) / 2, 95, 60, WHITE);
    DrawText("FINAL SCORE", cx - 55, 155, 16, GRAY);
    DrawLine(cx - 150, 175, cx + 150, 175, Fade(GRAY, 0.3f));

    int acc = totalShots > 0 ? (int)((float)totalHits / totalShots * 100) : 0;

    int yp = 195;
    DrawStatBar(cx, yp,  "LEVEL",     lvl,        12,            SKYBLUE); yp += 25;
    DrawStatBar(cx, yp,  "KILLS",     totalKills,  totalKills + 5, GREEN);  yp += 25;
    DrawStatBar(cx, yp,  "ACCURACY",  acc,         100,            YELLOW); yp += 25;
    DrawStatBar(cx, yp,  "MAX COMBO", maxCombo,    maxCombo + 5,   ORANGE); yp += 25;

    int secs = gameTimerSecs;
    DrawText(TextFormat("TIME  %d:%02d", secs / 60, secs % 60),
             cx - 55, yp + 6, 18, GRAY);
    yp += 40;

    if (score >= highScore && score > 0)
    {
        float glow = (float)fabs(sin(t * 5.0));
        DrawText("NEW BEST!", cx - 90, yp, 34, Fade(GOLD, 0.7f + glow * 0.3f));
    }
    else
        DrawText(TextFormat("BEST: %d  (Lv.%d)", highScore, highLevel),
                 cx - 100, yp, 24, SKYBLUE);

    yp += 42;
    int stars = (score >= 300) + (score >= 600) + (maxCombo >= 10) + (acc >= 60);
    DrawText("RATING", cx - 30, yp, 14, GRAY);
    yp += 16;
    for (int s = 0; s < 4; s++)
        DrawText(s < stars ? "*" : "-", cx - 28 + s * 18, yp, 20,
                 s < stars ? GOLD : DARKGRAY);

    float blink = (float)fabs(sin(t * 3.0));
    DrawText("R / ENTER  Restart    ESC  Menu", cx - 170, SCREEN_H - 45,
             20, Fade(YELLOW, 0.5f + blink * 0.5f));
}

// ==================================================================
//  HUD
// ==================================================================

void UIManager::DrawHUD(int score, int playerHp, int tripleTimerSecs,
                        int totalKills, int level, int waveNum,
                        int bombCount, int chain, float multiplier,
                        int grazeCount, bool bossActive) const
{
    // Score + Wave + Multiplier
    DrawText(TextFormat("SCORE: %d", score), 20, 20, 28, WHITE);
    if (multiplier > 1.05f)
        DrawText(TextFormat("x%.2f", multiplier), 20, 46, 18, GOLD);
    DrawText(TextFormat("WAVE: %d", waveNum), SCREEN_W - 180, 48, 20, SKYBLUE);

    // Chain counter
    if (chain > 3)
        DrawText(TextFormat("%d CHAIN", chain), SCREEN_W - 180, 75, 16, GOLD);

    // Graze counter
    if (grazeCount > 0)
        DrawText(TextFormat("GRAZE: %d", grazeCount), SCREEN_W - 180, 95, 14, Fade(SKYBLUE, 0.7f));

    // Bomb stock
    DrawText("BOMB:", 20, 145, 20, GRAY);
    for (int i = 0; i < bombCount; i++)
        DrawCircle(88 + i * 20, 156, 7, ORANGE);

    // HP bar
    int displayHp = playerHp;
    if (displayHp < 0) displayHp = 0;
    DrawRectangle(20, 55, 200, 22, DARKGRAY);
    for (int i = 0; i < displayHp; i++)
    {
        float t = (float)i / PLAYER_MAX_HP;
        Color hpColor = { (unsigned char)(255 * (1 - t)), (unsigned char)(255 * t), 0, 255 };
        DrawRectangle(22 + i * 38, 57, 36, 18, hpColor);
    }
    DrawRectangleLines(20, 55, 200, 22, GRAY);
    DrawText("HP", 230, 55, 22, WHITE);

    // Level
    DrawText(TextFormat("LEVEL: %d", level), 20, 90, 24, SKYBLUE);

    // Triple shot timer
    if (tripleTimerSecs > 0)
    {
        DrawText(TextFormat("TRIPLE: %ds", tripleTimerSecs), 20, 120, 22, BLUE);
    }

    // Kill count
    DrawText(TextFormat("KILLS: %d", totalKills), SCREEN_W - 180, 20, 22, GRAY);

    // Boss warning
    if (bossActive)
    {
        float flicker = (float)fabs(sin(GetTime() * 10.0));
        DrawText("!! BOSS !!", SCREEN_W / 2 - 90, 18, 32,
                 Fade(RED, 0.6f + flicker * 0.4f));
    }
}

void UIManager::DrawBossHPBar(int bossHp, int bossMaxHp) const
{
    int barW = 400;
    int barH = 18;
    int barX = SCREEN_W / 2 - barW / 2;
    int barY = 55;

    DrawRectangle(barX - 2, barY - 2, barW + 4, barH + 4, DARKGRAY);
    DrawRectangle(barX, barY, barW, barH, BLACK);

    float ratio = (float)bossHp / bossMaxHp;
    Color barColor;
    if (ratio > 0.5f)       barColor = RED;
    else if (ratio > 0.25f) barColor = ORANGE;
    else                    barColor = MAROON;

    DrawRectangle(barX, barY, (int)(barW * ratio), barH, barColor);
    DrawRectangleLines(barX, barY, barW, barH, GRAY);
    DrawText(TextFormat("BOSS  %d / %d", bossHp, bossMaxHp),
             SCREEN_W / 2 - 100, barY + barH + 5, 20, WHITE);
}

void UIManager::DrawComboPopup(int combo, float comboTimerSecs) const
{
    const float displayMinFrames = (float)COMBO_DISPLAY_MIN;
    if (combo < COMBO_DISPLAY_MIN) return;

    float alpha = 1.0f;
    float decayFrames = (float)COMBO_DECAY_FRAMES;
    if (comboTimerSecs < 30.0f)
        alpha = comboTimerSecs / 30.0f;

    int size = 36 + combo * 2;
    if (size > 70) size = 70;

    Color c;
    if (combo >= 20)      c = Fade(GOLD,   alpha);
    else if (combo >= 10) c = Fade(ORANGE, alpha);
    else if (combo >= 5)  c = Fade(YELLOW, alpha);
    else                  c = Fade(WHITE,  alpha);

    DrawText(TextFormat("%d COMBO!", combo),
             SCREEN_W / 2 - MeasureText(TextFormat("%d COMBO!", combo), size) / 2,
             130, size, c);

    float mult = 1.0f + (combo - COMBO_DISPLAY_MIN + 1) * 0.1f;
    DrawText(TextFormat("x%.1f SCORE", mult),
             SCREEN_W / 2 - 40, 130 + size + 5, 16, Fade(SKYBLUE, alpha));
}

void UIManager::DrawScreenFlash(float alpha) const
{
    if (alpha > 0.005f)
    {
        DrawRectangle(0, 0, SCREEN_W, SCREEN_H, Fade(WHITE, alpha));
    }
}

void UIManager::DrawBullet(float x, float y, Color color) const
{
    int ix = (int)x, iy = (int)y;
    DrawCircle(ix, iy, (int)(BULLET_GLOW_RADIUS + 2),     Fade(color, 0.08f));
    DrawCircle(ix, iy, (int)(BULLET_GLOW_RADIUS * 0.6f),  Fade(color, 0.25f));
    DrawCircle(ix, iy, 2, WHITE);
}

// ==================================================================
//  Private helpers
// ==================================================================

void UIManager::DrawStatBar(int cx, int y, const char* label,
                            int val, int maxVal, Color color) const
{
    DrawText(label, cx - 155, y, 15, GRAY);
    DrawText(TextFormat("%d", val), cx + 120, y, 15, WHITE);
    DrawRectangle(cx - 45, y + 5, 150, 6, Fade(DARKGRAY, 0.6f));
    float ratio = maxVal > 0 ? (float)val / maxVal : 0;
    if (ratio > 1.0f) ratio = 1.0f;
    DrawRectangle(cx - 45, y + 5, (int)(150 * ratio), 6, color);
}
