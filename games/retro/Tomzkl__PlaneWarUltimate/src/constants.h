#pragma once

namespace pwu {

// ── Window ──────────────────────────────────
constexpr int SCREEN_W = 800;
constexpr int SCREEN_H = 600;
constexpr int TARGET_FPS = 60;

// ── Player ──────────────────────────────────
constexpr int PLAYER_SIZE = 80;
constexpr int PLAYER_SPEED = 6;
constexpr int PLAYER_MAX_HP = 5;
constexpr int INVINCIBILITY_FRAMES = 90;   // 1.5s at 60 fps

// ── Bullets ─────────────────────────────────
constexpr int MAX_BULLETS = 100;
constexpr float CHARGE_MAX  = 90.0f;   // frames to full charge
constexpr float LASER_DURATION = 18.0f; // frames laser stays active
constexpr int MAX_BOSS_BULLETS = 60;
constexpr int BULLET_W = 10;
constexpr int BULLET_H = 20;
constexpr int BULLET_SPEED = 10;
constexpr int SHOOT_COOLDOWN = 10;
constexpr float BULLET_GLOW_RADIUS = 6.0f;

// ── Enemies ─────────────────────────────────
constexpr int MAX_ENEMIES = 30;
constexpr int ENEMY_SMALL_SIZE = 40;
constexpr int ENEMY_MEDIUM_SIZE = 60;
constexpr int ENEMY_LARGE_SIZE = 80;
constexpr int ENEMY_SMALL_SCORE = 10;
constexpr int ENEMY_MEDIUM_SCORE = 20;
constexpr int ENEMY_LARGE_SCORE = 30;

// ── Boss ────────────────────────────────────
constexpr int BOSS_W = 240;
constexpr int BOSS_H = 140;
constexpr int BOSS_HP = 50;
constexpr int BOSS_SCORE = 500;
constexpr int BOSS_TRIGGER_SCORE = 150;
constexpr int BOSS_DEATH_FRAMES = 50;          // slow-mo duration
constexpr float BOSS_DEATH_SLOWMO = 0.15f;    // 15% normal speed during death
constexpr int BOSS_DEATH_PARTICLES = 80;       // particles on death

// ── Particles ───────────────────────────────
constexpr int MAX_PARTICLES = 300;
constexpr int PARTICLE_COUNT_PER_EXPLOSION = 30;

// ── PowerUps ────────────────────────────────
constexpr int MAX_POWERUPS = 10;
constexpr int POWERUP_SIZE = 30;
constexpr int POWERUP_FALL_SPEED = 2;
constexpr int TRIPLE_SHOT_DURATION = 600;
constexpr float POWERUP_DROP_CHANCE = 0.3f;

// ── Difficulty ──────────────────────────────
constexpr int DIFFICULTY_INTERVAL = 600;
constexpr int INITIAL_ENEMY_SPEED = 4;

// Speed caps per difficulty level
constexpr int ENEMY_SPEED_CAP_EASY    = 12;
constexpr int ENEMY_SPEED_CAP_NORMAL  = 16;
constexpr int ENEMY_SPEED_CAP_HARD    = 22;
constexpr int ENEMY_SPEED_CAP_LUNATIC = 30;

// Boss HP multiplier per difficulty
constexpr float BOSS_HP_MULT_EASY    = 0.6f;
constexpr float BOSS_HP_MULT_NORMAL  = 1.0f;
constexpr float BOSS_HP_MULT_HARD    = 1.5f;
constexpr float BOSS_HP_MULT_LUNATIC = 2.2f;

// Spawn rate (percent per frame)
constexpr int SPAWN_RATE_EASY    = 1;
constexpr int SPAWN_RATE_NORMAL  = 2;
constexpr int SPAWN_RATE_HARD    = 3;
constexpr int SPAWN_RATE_LUNATIC = 4;

// ── Background ──────────────────────────────
constexpr int BG_SCROLL_SPEED = 2;

// ── Combo ───────────────────────────────────
constexpr int COMBO_DECAY_FRAMES = 120;      // 2 seconds
constexpr int COMBO_DISPLAY_MIN = 3;         // show combo text from 3+

// ── Screen Shake ────────────────────────────
constexpr float SHAKE_EXPLOSION_DUR = 8.0f;
constexpr float SHAKE_DAMAGE_DUR = 15.0f;
constexpr float SHAKE_BOSS_DEATH_DUR = 40.0f;
constexpr float SHAKE_EXPLOSION_INT = 3.0f;
constexpr float SHAKE_DAMAGE_INT = 7.0f;
constexpr float SHAKE_BOSS_DEATH_INT = 14.0f;

// ── High Score ──────────────────────────────
constexpr const char* HIGH_SCORE_FILE = "highscore.dat";

// ── Settings ────────────────────────────────
constexpr float DEFAULT_VOLUME = 0.7f;
constexpr float DEFAULT_SFX_VOLUME = 0.8f;

// ── Starfield ───────────────────────────────
constexpr int MAX_STARS    = 80;
constexpr int STARFIELD_COUNT = 120;

// ── Extends ─────────────────────────────────
constexpr int FIRST_EXTEND_SCORE = 5000;
constexpr int EXTEND_INTERVAL    = 15000;

// ── Game Over ───────────────────────────────
constexpr int GAMEOVER_ANIM_LENGTH = 45;

} // namespace pwu
