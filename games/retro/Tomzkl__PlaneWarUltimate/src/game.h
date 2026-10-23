#pragma once
#include "raylib.h"
#include <cmath>
#include <cstdio>
#ifdef _MSC_VER
#pragma warning(disable: 4244)  // float to int
#pragma warning(disable: 26495) // uninitialized member (raylib types)
#endif
#include "constants.h"
#include "pool.h"
#include "types.h"
#include "player.h"
#include "enemy.h"
#include "boss.h"
#include "particle.h"
#include "powerup.h"
#include "ui_manager.h"
#include "wave_manager.h"

namespace pwu {

class Game
{
public:
    void Init();
    void Update();
    void Draw();
    void Close();
    bool ShouldQuit() const { return quitRequested; }

private:
    // -- State -----------------------------
    GameState   state      = GameState::MENU;
    Difficulty  difficulty = Difficulty::NORMAL;
    bool quitRequested = false;
    bool bossDefeated = false;

    // -- Subsystems -------------------------
    UIManager    ui;
    WaveManager  waveManager;

    // -- Game data -------------------------
    int   score = 0;
    int   nextExtendScore = FIRST_EXTEND_SCORE;
    float gameTimer = 0;             // seconds
    float difficultyAccum = 0;       // seconds accumulator for difficulty ticks
    int   enemySpeed = INITIAL_ENEMY_SPEED;
    float bgY = 0;

    // -- Combo -----------------------------
    int   combo = 0;
    float comboTimer = 0;            // "effective frames" remaining
    int   maxCombo = 0;

    // -- Collection chain -------------------
    int   chain = 0;            // consecutive item pickups
    float chainTimer = 0;       // decays like combo
    float scoreMultiplier = 1.0f;

    // -- Graze ------------------------------
    int   grazeCount = 0;
    float grazeTimer = 0;       // brief glow after graze
    int   totalGrazes = 0;      // lifetime stat

    // -- Stats -----------------------------
    int totalShots = 0;
    int totalHits  = 0;
    int totalKills = 0;

    // -- Screen shake ----------------------
    float shakeTimer    = 0;
    float shakeIntensity = 0;

    // -- Laser (charge shot) -----------------
    float laserX      = 0;
    bool  laserActive = false;
    float laserTimer  = 0;

    // -- Bomb shockwave ---------------------
    static constexpr int MAX_SHOCKWAVES = 4;
    struct Shockwave { float x, y, radius, maxRadius, alpha; bool active; };
    Shockwave shockwaves[MAX_SHOCKWAVES];

    // -- Boss death FX ---------------------
    float bossDeathTimer = 0;        // "effective frames" remaining
    bool  bossDeathMidShakeDone = false;
    float screenFlashAlpha = 0;

    // -- High score (quick display) ---------
    int highScore = 0;
    int highLevel = 0;

    // -- Leaderboard -----------------------
    static constexpr int LEADERBOARD_SIZE = 10;
    struct Entry { int score, difficulty, wave, kills, accuracy; char date[20]; };
    Entry leaderboard[LEADERBOARD_SIZE];
    int   leaderboardCount = 0;
    void  LoadLeaderboard();
    void  SaveLeaderboard();
    void  AddToLeaderboard(int score, int difficulty, int wave, int kills, int accuracy);
    void  DrawLeaderboard() const;

    // -- Objects ---------------------------
    Player player;
    Pool<Bullet, MAX_BULLETS>      playerBullets;
    Pool<Bullet, MAX_BOSS_BULLETS> bossBullets;
    Pool<Enemy, MAX_ENEMIES>       enemies;
    Pool<Particle, MAX_PARTICLES>  particles;
    Pool<PowerUp, MAX_POWERUPS>    powerups;
    Pool<StarItem, MAX_STARS>      stars;
    Boss boss;
    bool midBossActive = false;   // smaller boss for waves 3/7

    // -- Resources -------------------------
    Texture2D playerTex;
    Texture2D enemyTex;
    Texture2D bgTex;
    Sound shootSound;
    Sound explodeSound;
    Sound hurtSound;
    Sound powerupSound;
    Sound alarmSound;
    Music bgm;
    bool  bgmOk = false;

    // ==========================================
    //  Internal helpers
    // ==========================================

    // Init / resources
    void LoadResources();
    Wave  GenWave(float freq, float duration, float decay, int type);
    Sound LoadProceduralSound(float freq, float duration, float decay, int type);

    // Difficulty helpers
    int   GetEnemySpeedCap() const;
    float GetBossHpMultiplier() const;
    int   GetSpawnRate() const;

    // Gameplay
    void RestartGame();
    void UpdatePlaying();
    void UpdateBackground();
    void UpdateDifficulty();
    void SpawnEnemies();
    void UpdatePlayerBullets();
    void UpdateBossBullets();
    void CheckCollisions();
    void UpdateCombo(bool enemyKilled);
    void TriggerShake(float intensity, float duration);
    void UpdateShake();

    // Persistence
    void LoadHighScore();
    void SaveHighScore();
    void PlayGameSfx(Sound& snd);

    // Drawing (game layer only - UI handled by ui_)
    void DrawGameLayer();
    void DrawStarfield() const;
};

} // namespace pwu
