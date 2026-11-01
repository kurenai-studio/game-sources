#pragma once

namespace SpaceShooter {
// Screen dimensions
const int SCREEN_WIDTH = 800;
const int SCREEN_HEIGHT = 600;
const int TARGET_FPS = 60;

// Game balance
const float KAMIKAZE_HEALTH_THRESHOLD = 0.3f; // 30% health triggers kamikaze

// Player settings
const float PLAYER_SPEED = 300.0f;
const float PLAYER_BULLET_SPEED = 500.0f;
const float PLAYER_FIRE_RATE = 0.2f; // seconds between shots
const int PLAYER_MAX_HEALTH = 3;

// Enemy settings
const float BASIC_ENEMY_SPEED = 150.0f;
const float BASIC_ENEMY_KAMIKAZE_SPEED = 250.0f;
const int BASIC_ENEMY_HEALTH = 2;

const float FAST_ENEMY_SPEED = 250.0f;
const float FAST_ENEMY_KAMIKAZE_SPEED = 400.0f;
const int FAST_ENEMY_HEALTH = 1;

const float HEAVY_ENEMY_SPEED = 80.0f;
const int HEAVY_ENEMY_HEALTH = 8;

// Bullet settings
const float ENEMY_BULLET_SPEED = 200.0f;
const int MAX_BULLETS = 100; // Object pool size

// Power-up settings
const float POWERUP_DURATION = 10.0f;     // seconds
const float POWERUP_SPAWN_CHANCE = 0.15f; // 15% chance on enemy death

// Asset paths
extern const char* BACKGROUND_TEXTURE;
extern const char* PLAYER_TEXTURE;
extern const char* PLAYER_BULLET_TEXTURE;
extern const char* ENEMY_BULLET_TEXTURE;

extern const char* BASIC_ENEMY_TEXTURE;
extern const char* FAST_ENEMY_TEXTURE;
extern const char* HEAVY_ENEMY_TEXTURE;

extern const char* EXPLOSION_TEXTURES[4];

extern const char* POWERUP_DOUBLE_SHOT_TEXTURE;
extern const char* POWERUP_SHIELD_TEXTURE;
extern const char* POWERUP_SPEED_BOOST_TEXTURE;

extern const char* HEART_TEXTURE;
extern const char* STAR_TEXTURE;

// Supercharge mode settings
extern const float SUPERCHARGE_COOLDOWN;
extern const float SUPERCHARGE_WARMUP;
extern const float SUPERCHARGE_DURATION;
extern const float SUPERCHARGE_FIRE_RATE;

// Performance profiling and debug utilities
extern bool IsProfileModeActive();
extern float GetPerformanceMultiplier();
extern const char* GetProfileModeName();
} // namespace SpaceShooter
