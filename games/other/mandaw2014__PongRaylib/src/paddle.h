#pragma once

#include "ball.h"

class Paddle {
    public:
        int width;
        int height;
        int x;
        int y;
        int speed;

        int screenHeight;

        Paddle(int width = 15, int height = 100, int x = 0, int y = 0);

        void draw();
        void update(float dt);
        bool collide(Ball ball);
};