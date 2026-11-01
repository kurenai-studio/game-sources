#pragma once
#include <raylib.h>

struct Ball
{
    float x = 640, y = 400, veloX = 8, veloY = 8;
    int radius = 20, lives = 3, paddleT2;
    bool lifeLost;

    bool lostLife();
    void draw();
    void update();
    void paddleBug(int paddleT1);
};