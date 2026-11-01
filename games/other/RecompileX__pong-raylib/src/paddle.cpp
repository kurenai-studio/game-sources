#include "paddle.h"

void Paddle::Draw()
{
    DrawRectangle(x, y, 25, 120, WHITE);
}

void Paddle::Update(int key1, int key2)
{
    if(IsKeyDown(key1) && y > 0){
        veloY = -5;
    } 
    else if(IsKeyDown(key2) && y < GetScreenHeight() - 120){
        veloY = 5;
    }
    else{
        veloY = 0;
    }
    y += veloY;
}
