#include "bricks.h"

Color colours[5] = { RED, ORANGE, YELLOW, GREEN, BLUE };

bricksGrid::bricksGrid(){

    for(int x = 0; x < 8; x++){

        for(int y = 0; y < 5; y++){

            bricks[x][y][0] = 30 + x * 155;
            bricks[x][y][1] = 30 + y * 60;

            visible[x][y] = true;
        }
    }
    width = 135;
    height = 40;
}

void bricksGrid::draw(){

    for(int x = 0; x < 8; x++){

        for(int y = 0; y < 5; y++){

            if(visible[x][y]){

                DrawRectangle(bricks[x][y][0], bricks[x][y][1], width, height, colours[y]);

            } 
        }
    }
}

void bricksGrid::update(float xa, float ya, int radius){

    for(int x = 0; x < 8; x++){

        for(int y = 0; y < 5; y++){

                if(CheckCollisionCircleRec(Vector2{xa, ya}, radius, Rectangle{bricks[x][y][0], bricks[x][y][1], width, height}) && visible[x][y] == true){

                    visible[x][y] = false;

                }
            } 
        }
    }