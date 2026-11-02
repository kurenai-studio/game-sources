#include "Rules/Motion.h"

#include <algorithm>
#include <cmath>

namespace coinrun {

Vec2 ClampToArena(Vec2 p, float half, float radius) {
    const float limit = std::max(0.0f, half - radius);
    return Vec2(std::max(-limit, std::min(limit, p.x)), std::max(-limit, std::min(limit, p.y)));
}

Vec2 MoveDirection(Vec2 input, Vec2 last_direction, bool dashing) {
    if (input.SqrLength() > 1e-8f) return input.Normalized();
    if (dashing) return last_direction.Normalized();
    return Vec2(0.0f, 0.0f);
}

Vec2 StepPlayer(Vec2 position, Vec2 direction, float speed, float dt, float half, float radius) {
    Vec2 dir = direction;
    if (dir.SqrLength() > 1.0f) dir = dir.Normalized();
    return ClampToArena(position + dir * (speed * dt), half, radius);
}

bool Overlaps(Vec2 a, float radius_a, Vec2 b, float radius_b) {
    const float r = radius_a + radius_b;
    return (a - b).SqrLength() <= r * r;
}

Vec2 SteerToward(Vec2 direction, Vec2 target_direction, float max_turn) {
    const Vec2 target = target_direction.Normalized();
    if (target.SqrLength() < 0.5f) return direction;  // zero target: keep heading
    const Vec2 current = direction.Normalized();
    if (current.SqrLength() < 0.5f) return target;    // no heading yet: face the target

    // Signed angle from current to target, limited to +/- max_turn.
    const float cross = current.x * target.y - current.y * target.x;
    const float dot = Dot(current, target);
    const float angle = std::atan2(cross, dot);
    const float turn = std::max(-max_turn, std::min(max_turn, angle));

    const float c = std::cos(turn);
    const float s = std::sin(turn);
    return Vec2(current.x * c - current.y * s, current.x * s + current.y * c).Normalized();
}

}  // namespace coinrun
