#include "player.h"

void Player::tryMove(Map& map, Direction direction) {
    Vector2 newPos = applyDirectionToPosition(pos, direction);
    int x = newPos.x;
    int y = newPos.y;

    if (map.isWall(x, y))
        return;

    Box* box = map.getBox(x, y);

    if (box == nullptr) {
        pos.x = x;
        pos.y = y;
        return;
    }

    if (map.canMoveBox(*box, direction)) {
        map.moveBox(box, direction);
        pos.x = x;
        pos.y = y;
    }
}
