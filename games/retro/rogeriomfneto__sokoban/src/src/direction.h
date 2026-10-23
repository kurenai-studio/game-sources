#pragma once

#include <raylib.h>

enum class Direction {
    Up,
    Down,
    Left,
    Right
};

Vector2 applyDirectionToPosition(Vector2 pos, Direction direction);
