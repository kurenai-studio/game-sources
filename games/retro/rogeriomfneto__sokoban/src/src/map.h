#pragma once

#include <raylib.h>
#include "box.h"
#include "direction.h"

namespace tson {
class Map;
}

class Map {
    public:
        int layout[50][50];

        int width = 0;
        int height = 0;

        Texture2D texture;

        Box boxes[50];
        int boxCount = 0;

        bool loadFromFile(const char* path);
        void loadMap(tson::Map& tileson);

        bool isWall(int x, int y);
        bool isEmpty(int x, int y);
        bool isButton(int x, int y);

        void loadBoxes(Box newBoxes[], int n);
        void moveBox(Box* box, Direction direction);
        bool canMoveBox(Box box, Direction direction);
        Box* getBox(int x, int y);
};
