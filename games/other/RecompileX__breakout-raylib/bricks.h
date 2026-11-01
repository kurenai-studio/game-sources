#pragma once
#include <raylib.h>

class bricksGrid
{
public:

    float width, height;
    float bricks[8][5][2]{0};
    bool visible[8][5];
    
    bricksGrid();
    
    void draw();
    void update(float xa, float ya, int radius);

};
