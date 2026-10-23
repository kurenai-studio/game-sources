#pragma once
#include "raylib.h"
#include "constants.h"
#include "types.h"

// ==================================================================
//  UIManager - all menu / settings / pause / game-over / HUD logic
// ==================================================================
namespace pwu {

struct UIManager
{
    // -- Menu / settings / pause navigation -----
    int  menuSelection       = 0;
    int  pauseSelection      = 0;
    bool pauseWantsRestart   = false;
    int  settingsSelection   = 0;
    int  lastSettingsSel     = 0;
    int  sliderRepeatTimer   = 0;
    int  sliderRepeatDir     = 0;

    // -- Settings values ------------------------
    float volumeSetting = DEFAULT_VOLUME;
    float sfxVolume     = DEFAULT_SFX_VOLUME;

    // -- Starfield (menu background) ------------
    StarData stars[STARFIELD_COUNT];

    // ==============================================
    //  Lifecycle
    // ==============================================
    void Init();
    void UpdateStarfield();

    // ==============================================
    //  State updates  (return false to quit app)
    // ==============================================
    bool UpdateMenu(GameState& state);
    bool UpdateSettings(GameState& state, Difficulty& difficulty);
    bool UpdatePaused(GameState& state);
    bool UpdateGameOver(GameState& state);

    // ==============================================
    //  Drawing  (called from Game::Draw)
    // ==============================================
    void DrawMenuBackground() const;
    void DrawMenu(int highScore, int highLevel) const;
    void DrawSettings(Difficulty difficulty) const;
    void DrawPauseOverlay() const;
    void DrawGameOverOverlay(int score, int highScore, int highLevel,
                             int enemySpeed, int totalKills, int totalShots,
                             int totalHits, int maxCombo, int gameTimerSecs) const;
    void DrawHUD(int score, int playerHp, int tripleTimerSecs,
                 int totalKills, int level, int waveNum,
                 int bombCount, int chain, float multiplier,
                 int grazeCount, bool bossActive) const;
    void DrawBossHPBar(int bossHp, int bossMaxHp) const;
    void DrawComboPopup(int combo, float comboTimerSecs) const;
    void DrawScreenFlash(float alpha) const;
    void DrawBullet(float x, float y, Color color) const;

private:
    void DrawStatBar(int cx, int y, const char* label,
                     int val, int maxVal, Color color) const;
};

} // namespace pwu
