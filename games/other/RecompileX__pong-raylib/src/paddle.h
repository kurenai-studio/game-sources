#pragma once
#include <raylib.h>

class Paddle
{
public:
    float y, x;
    int veloY;

    void Draw();
    void Update(int key1, int key2);
};