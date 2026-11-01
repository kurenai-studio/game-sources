#include <iostream>
#include <ctime>
#include <raylib.h>
#include "paddle.h"
#include "bricks.h"
#include "ball.h"

paddle pad;
bricksGrid bricks;
Ball ball;

int main(){

    std::cout << "Starting the game." << std::endl;
    const int screenWidth = 1280;
    const int screenHeight = 800;
    int gameStarted = 0;
    pad.x = 544;
    pad.y = 720;
    Color backgroundColour = { 25, 20, 60, 255 };
    
    InitWindow(screenWidth, screenHeight, "Breakout++");
    SetTargetFPS(60);

    while(WindowShouldClose() == false){

        BeginDrawing();
        ClearBackground(backgroundColour);

        if(gameStarted == 0 && ball.lives > 0){

            DrawText("Press Enter to Launch", 164, 400, 80, WHITE);

            if(IsKeyPressed(KEY_ENTER)){

                gameStarted = 1;

            }
        }
        if(ball.lostLife()){
            gameStarted = 0;
                pad.x = 544;
        }

        if(CheckCollisionCircleRec(Vector2{ball.x, ball.y}, ball.radius, Rectangle{pad.x, pad.y, 192, 30})){
            ball.veloY *= -1;
            ball.paddleBug(time(0));
        }

        if(ball.lives > 0 && gameStarted == 1){
            ball.update();
        
        for(int x = 0; x < 8; x++){

            for(int y = 0; y < 5; y++){
                
                if(CheckCollisionCircleRec(Vector2{ball.x, ball.y}, ball.radius, Rectangle{bricks.bricks[x][y][0], bricks.bricks[x][y][1], bricks.width, bricks.height}) && bricks.visible[x][y] == true){
                    ball.veloY *= -1;
                }
            }
        }

            bricks.update(ball.x, ball.y, ball.radius);
            pad.update();
        }

        DrawText(TextFormat("%d", ball.lives), 1180, 700, 80, WHITE);
        ball.draw();
        bricks.draw();
        pad.draw();

        EndDrawing();

    }

    CloseWindow();
    return 0;
}