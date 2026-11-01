#pragma once
#include <raylib.h>

class Ball
{
public:
    float x = 640, y = 400, veloX, veloY;
    int score1, score2, radius = 20;

    void Draw();
    void Update();
};