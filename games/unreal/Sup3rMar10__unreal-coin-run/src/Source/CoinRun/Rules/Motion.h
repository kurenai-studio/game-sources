#pragma once

#include "Rules/Vec2.h"

namespace coinrun {

// Keep a circle of the given radius fully inside the square arena [-half, half]^2.
Vec2 ClampToArena(Vec2 p, float half, float radius);

// Direction to move this frame. Input wins when present; with no input a dash keeps going the way the
// player last moved; otherwise the player stands still. The result is a unit vector or (0, 0).
Vec2 MoveDirection(Vec2 input, Vec2 last_direction, bool dashing);

// Move at `speed` along `direction` (normalised if longer than 1), then clamp into the arena.
Vec2 StepPlayer(Vec2 position, Vec2 direction, float speed, float dt, float half, float radius);

// Circles touch when the centre distance is at most the sum of the radii.
bool Overlaps(Vec2 a, float radius_a, Vec2 b, float radius_b);

// Rotate the unit vector `direction` toward `target_direction` by at most `max_turn` radians.
// A zero `direction` snaps to the target; a zero target leaves it unchanged.
Vec2 SteerToward(Vec2 direction, Vec2 target_direction, float max_turn);

}  // namespace coinrun
