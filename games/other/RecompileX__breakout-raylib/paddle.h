#pragma once
#include <raylib.h>

struct paddle
{
    float x, y, veloX;

    void update();
    void draw();

};