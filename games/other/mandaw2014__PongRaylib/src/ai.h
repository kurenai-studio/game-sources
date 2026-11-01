#pragma once

#include "ball.h"

class AI {
    public:
        int width;
        int height;
        int x;
        int y;
        int difficulty;

        int screenHeight;
        int screenWidth;

        AI(int width = 15, int height = 100, int x = 0, int y = 0);

        void draw();
        void update(Ball ball, float dt);
        bool collide(Ball ball);
};