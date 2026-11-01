#include "paddle.h"

void paddle::update(){

    if(IsKeyDown(KEY_LEFT) && x > 0){

        veloX = -7;

    }
    else if(IsKeyDown(KEY_RIGHT) && x < (GetScreenWidth() - 192)){

        veloX = 7;

    }
    else{
        veloX = 0;
    }
        
    x += veloX;

}

void paddle::draw(){

    DrawRectangle(x, y, 192, 30, BLUE);

}