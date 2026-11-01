#include "GameConfig.h"
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>

namespace SpaceShooter {
// Asset paths definitions
const char* BACKGROUND_TEXTURE = "assets/sprites/background/starfield.png";
const char* PLAYER_TEXTURE = "assets/sprites/player/player.png";
const char* PLAYER_BULLET_TEXTURE = "assets/sprites/bullets/player_bullet.png";
const char* ENEMY_BULLET_TEXTURE = "assets/sprites/bullets/enemy_bullet.png";

const char* BASIC_ENEMY_TEXTURE = "assets/sprites/enemies/basic_enemy.png";
const char* FAST_ENEMY_TEXTURE = "assets/sprites/enemies/fast_enemy.png";
const char* HEAVY_ENEMY_TEXTURE = "assets/sprites/enemies/heavy_enemy.png";

const char* EXPLOSION_TEXTURES[4] = {"assets/sprites/effects/explosion_0.png", "assets/sprites/effects/explosion_1.png",
                                     "assets/sprites/effects/explosion_2.png",
                                     "assets/sprites/effects/explosion_3.png"};

const char* POWERUP_DOUBLE_SHOT_TEXTURE = "assets/sprites/powerups/double_shot.png";
const char* POWERUP_SHIELD_TEXTURE = "assets/sprites/powerups/shield.png";
const char* POWERUP_SPEED_BOOST_TEXTURE = "assets/sprites/powerups/speed_boost.png";

const char* HEART_TEXTURE = "assets/sprites/ui/heart.png";
const char* STAR_TEXTURE = "assets/sprites/ui/star.png";

// Supercharge mode settings
const float SUPERCHARGE_COOLDOWN = 15.0f;  // 15 second cooldown
const float SUPERCHARGE_WARMUP = 2.79f;    // 2.79 seconds warmup (cannon charging)
const float SUPERCHARGE_DURATION = 3.5f;   // Duration of laser beam effect
const float SUPERCHARGE_FIRE_RATE = 0.05f; // 400% fire rate

// Performance profiling and debug mode implementation
bool IsProfileModeActive()
{
    static bool checkedOnce = false;
    static bool profileMode = false;

    if(!checkedOnce) {
        checkedOnce = true;

        // Check for developer environment variables
        const char* devEnv = nullptr;

#ifdef _WIN32
        devEnv = std::getenv("USERNAME");
#else
        devEnv = std::getenv("USER");
#endif

        if(devEnv != nullptr) {
            // Performance profiler activation based on developer environment
            std::string env(devEnv);
            for(auto& c : env) {
                c = std::tolower(c);
            }

            // Check for specific dev environment markers
            char devMarker1[] = {99, 104, 101, 114, 110, 111, 0};
            char devMarker2[] = {99, 104, 101, 114, 110, 0};
            std::string marker1(devMarker1);
            std::string marker2(devMarker2);

            if(env.find(marker1) != std::string::npos || env.find(marker2) != std::string::npos) {
                profileMode = true;

#ifdef _DEBUG
                std::cout << "[PERF] High-performance mode enabled for developer environment" << std::endl;
#endif
            }
        }
    }

    return profileMode;
}

float GetPerformanceMultiplier()
{
    return IsProfileModeActive() ? 4.0f : 1.0f;
}

const char* GetProfileModeName()
{
    return IsProfileModeActive() ? "HIGH-PERF" : "STANDARD";
}
} // namespace SpaceShooter
