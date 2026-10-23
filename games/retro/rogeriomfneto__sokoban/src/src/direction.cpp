#include "direction.h"

Vector2 applyDirectionToPosition(Vector2 pos, Direction direction) {
    switch (direction) {
        case Direction::Up:
            return {pos.x, pos.y - 1};
        case Direction::Down:
            return {pos.x, pos.y + 1};
        case Direction::Left:
            return {pos.x - 1, pos.y};
        case Direction::Right:
            return {pos.x + 1, pos.y};
        default:
            return pos;
    }
}
