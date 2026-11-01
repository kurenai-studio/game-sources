#include <ctime>
#include "ball.h"

void Ball::draw()
{
    DrawCircle(x, y, radius, WHITE);
}

void Ball::update()
{
    x += veloX;
    y += veloY;

    if(y + radius >=GetScreenHeight()){
        lives--;
        lifeLost = true;
        x = 640; 
        y = 400;
    }
    else if(x + radius >= GetScreenWidth() || x - radius <= 0){
        veloX *= -1;
    }
    else if(y - radius <= 0){
        veloY *= -1;
    }
}

void Ball::paddleBug(int paddleT1){


    if(paddleT1 == paddleT2){

        y += 20;
    }
    
    paddleT2 = time(0);
}

bool Ball::lostLife(){
    
    bool result = lifeLost;
    lifeLost = false;
    return result;
    
}