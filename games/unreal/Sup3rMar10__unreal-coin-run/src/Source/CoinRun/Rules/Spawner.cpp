#include "Rules/Spawner.h"

#include <algorithm>

#include "Rules/Tuning.h"

namespace coinrun {

Spawner::Spawner(int seed) : rng_(seed), drifter_timer_(2.0f), coin_timer_(0.0f) {}

bool Spawner::ShouldSpawnCoin(float dt, int active_coins) {
    if (active_coins <= 0) {
        coin_timer_ = rng_.RangeF(1.5f, 3.0f);
        return true;
    }
    if (active_coins >= tuning::kMaxCoins) return false;
    coin_timer_ -= dt;
    if (coin_timer_ > 0.0f) return false;
    coin_timer_ = rng_.RangeF(1.5f, 3.0f);
    return true;
}

bool Spawner::ShouldSpawnDrifter(float dt, int wave, int active_drifters) {
    drifter_timer_ -= dt;
    if (drifter_timer_ > 0.0f) return false;
    if (active_drifters >= tuning::MaxDrifters(wave)) {
        drifter_timer_ = 0.0f;  // spawn as soon as a slot frees up
        return false;
    }
    drifter_timer_ = tuning::DrifterSpawnInterval(wave) * rng_.RangeF(0.8f, 1.2f);
    return true;
}

Vec2 Spawner::NextCoinPosition(Vec2 player, float half, float min_distance) {
    const float limit = std::max(0.0f, half - tuning::kCoinMargin);
    for (int i = 0; i < 30; ++i) {
        const Vec2 p(rng_.RangeF(-limit, limit), rng_.RangeF(-limit, limit));
        if (Distance(p, player) >= min_distance) return p;
    }
    // Arena too small for the requested distance: take the corner furthest from the player.
    return Vec2(player.x >= 0.0f ? -limit : limit, player.y >= 0.0f ? -limit : limit);
}

DrifterSpawn Spawner::NextDrifter(Vec2 player, float half, int wave) {
    (void)wave;  // reserved: later waves could spawn bigger or faster drifters
    DrifterSpawn spawn;
    spawn.radius = rng_.RangeF(tuning::kDrifterMinRadius, tuning::kDrifterMaxRadius);
    const float limit = std::max(0.0f, half - spawn.radius - 10.0f);

    Vec2 pos;
    bool placed = false;
    for (int i = 0; i < 20 && !placed; ++i) {
        const float t = rng_.RangeF(-limit, limit);
        switch (rng_.RangeI(0, 4)) {
            case 0: pos = Vec2(t, limit); break;    // +Y edge
            case 1: pos = Vec2(t, -limit); break;   // -Y edge
            case 2: pos = Vec2(-limit, t); break;   // -X edge
            default: pos = Vec2(limit, t); break;   // +X edge
        }
        placed = Distance(pos, player) >= tuning::kMinDrifterSpawnDistance;
    }
    if (!placed) {
        // Nowhere far enough (player in the middle of a tiny arena): use the corner furthest from the player.
        pos = Vec2(player.x >= 0.0f ? -limit : limit, player.y >= 0.0f ? -limit : limit);
    }

    spawn.position = pos;
    spawn.direction = (player - pos).Normalized();
    return spawn;
}

}  // namespace coinrun
