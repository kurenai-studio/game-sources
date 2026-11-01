#include "ball.h"
#include <iostream>

void Ball::Draw()
{
    DrawCircle(x, y, radius, WHITE);
}

void Ball::Update()
{
    x += veloX;
    y += veloY;

    if(y + radius >=GetScreenHeight() || y - radius <= 0){
        veloY *= -1;
    }
    if(x + radius >= GetScreenWidth()){
        score1++;
        x = 640;
        y = 400;
    }
    else if(x - radius <= 0){
        score2++;
        x = 640; 
        y = 400;
    }
}