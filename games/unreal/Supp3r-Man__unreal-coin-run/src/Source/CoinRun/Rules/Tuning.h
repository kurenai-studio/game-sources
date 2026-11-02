#pragma once

#include <algorithm>

namespace coinrun {
namespace tuning {

// World units are Unreal centimetres. The arena is a square centred on the origin.
constexpr float kArenaHalfExtent = 1500.0f;

constexpr float kPlayerRadius = 40.0f;
constexpr float kCoinRadius = 30.0f;

constexpr float kPlayerSpeed = 650.0f;
constexpr float kDashSpeed = 1600.0f;
constexpr float kDashDuration = 0.18f;
constexpr float kDashCooldown = 1.2f;

constexpr int kStartHealth = 3;
constexpr float kInvulnerableSeconds = 1.5f;

constexpr float kStartTime = 45.0f;
constexpr float kMaxTime = 60.0f;
constexpr float kCoinTimeBonus = 1.5f;

constexpr int kCoinPoints = 10;
constexpr int kCoinsPerWave = 8;
constexpr int kWaveBonusPerWave = 25;
constexpr float kComboWindow = 3.0f;
constexpr int kMaxMultiplier = 4;

constexpr int kMaxCoins = 3;
constexpr float kMinCoinDistance = 600.0f;
constexpr float kCoinMargin = 80.0f;
constexpr float kMinDrifterSpawnDistance = 900.0f;
constexpr float kDrifterMinRadius = 40.0f;
constexpr float kDrifterMaxRadius = 55.0f;

// Drifters never get faster than the player, so a player who keeps moving can always get away.
inline float DrifterSpeed(int wave) { return std::min(520.0f, 220.0f + 45.0f * static_cast<float>(wave - 1)); }
// Radians per second a drifter can turn toward the player.
inline float DrifterTurnRate(int wave) { return std::min(2.6f, 0.9f + 0.2f * static_cast<float>(wave - 1)); }
inline int MaxDrifters(int wave) { return std::min(12, 2 + wave); }
inline float DrifterSpawnInterval(int wave) { return std::max(0.9f, 3.5f - 0.3f * static_cast<float>(wave - 1)); }

}  // namespace tuning
}  // namespace coinrun
