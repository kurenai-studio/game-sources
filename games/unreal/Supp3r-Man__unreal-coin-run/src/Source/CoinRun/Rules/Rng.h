#pragma once

#include <cstdint>

namespace coinrun {

// Small xorshift generator. std::rand and the standard distributions are not guaranteed to give the
// same sequence on every platform; this one does, so spawn tests are stable everywhere.
class Rng {
public:
    explicit Rng(int32_t seed);

    uint32_t NextUInt();

    // Uniform float in [0, 1).
    float NextFloat();

    // Uniform float in [min_value, max_value).
    float RangeF(float min_value, float max_value);

    // Uniform int in [min_value, max_exclusive). Returns min_value for an empty or inverted range.
    int RangeI(int min_value, int max_exclusive);

private:
    uint32_t state_;
};

}  // namespace coinrun
