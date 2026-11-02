#include "Rules/Rng.h"

namespace coinrun {

Rng::Rng(int32_t seed) {
    // Mix the seed so that 0 and small seeds do not start in a weak state.
    state_ = static_cast<uint32_t>(seed) * 2654435761u + 0x9E3779B9u;
    if (state_ == 0u) state_ = 2463534242u;
    for (int i = 0; i < 4; ++i) NextUInt();
}

uint32_t Rng::NextUInt() {
    state_ ^= state_ << 13;
    state_ ^= state_ >> 17;
    state_ ^= state_ << 5;
    return state_;
}

float Rng::NextFloat() {
    return static_cast<float>(NextUInt() & 0xFFFFFFu) / 16777216.0f;
}

float Rng::RangeF(float min_value, float max_value) {
    return min_value + (max_value - min_value) * NextFloat();
}

int Rng::RangeI(int min_value, int max_exclusive) {
    if (max_exclusive <= min_value) return min_value;
    return min_value + static_cast<int>(NextUInt() % static_cast<uint32_t>(max_exclusive - min_value));
}

}  // namespace coinrun
