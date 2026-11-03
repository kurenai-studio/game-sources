#pragma once

#include "Rules/Rng.h"
#include "Rules/Vec2.h"

namespace coinrun {

struct DrifterSpawn {
    Vec2 position;
    Vec2 direction;  // unit vector, initially pointing at the player
    float radius = 0.0f;
};

// Decides when and where coins and drifters appear. Deterministic for a given seed.
class Spawner {
public:
    explicit Spawner(int seed);

    // True when a new coin should appear: always when none is on the field, otherwise on a timer up to kMaxCoins.
    bool ShouldSpawnCoin(float dt, int active_coins);

    bool ShouldSpawnDrifter(float dt, int wave, int active_drifters);

    // A point inside the arena (with a margin) that is at least min_distance from the player.
    Vec2 NextCoinPosition(Vec2 player, float half, float min_distance);

    // A drifter that starts just inside a random arena edge, far from the player, heading at the player.
    DrifterSpawn NextDrifter(Vec2 player, float half, int wave);

private:
    Rng rng_;
    float drifter_timer_;
    float coin_timer_;
};

}  // namespace coinrun
