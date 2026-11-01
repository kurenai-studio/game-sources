#include <iostream>
#include <raylib.h>
#include "ball.h"
#include "paddle.h"

Ball ball;
Paddle pad1;
Paddle pad2;

int main(){

    std::cout << "Starting the game." << std::endl;
    const int screenWidth = 1280;
    const int screenHeight = 800;
    ball.score1 = 0;
    ball.score2 = 0;
    ball.veloX = 6.5;
    ball.veloY = 6.5;
    pad1.y = 340;
    pad1.x = 10;
    pad2.y = 340;
    pad2.x = 1245;
    
    InitWindow(screenWidth, screenHeight, "Pong++");
    SetTargetFPS(60);

    while(WindowShouldClose() == false){

        BeginDrawing();

        if(CheckCollisionCircleRec(Vector2{ball.x, ball.y}, ball.radius, Rectangle{pad1.x, pad1.y, 25, 120})){
            ball.veloX *= -1;
        }

        if(CheckCollisionCircleRec(Vector2{ball.x, ball.y}, ball.radius, Rectangle{pad2.x, pad2.y, 25, 120})){
            ball.veloX *= -1;
        }

        ClearBackground(BLACK);
        DrawText(TextFormat("%i", ball.score1), 200, 20, 80, WHITE);
        DrawText(TextFormat("%i", ball.score2), 1080, 20, 80, WHITE);
        DrawLine(640, 0, 640, 800, WHITE);
        DrawLine(640, 0, 640, 800, WHITE);
        ball.Update();        
        ball.Draw();
        pad1.Update(KEY_W, KEY_S);
        pad1.Draw();
        pad2.Update(KEY_UP, KEY_DOWN);
        pad2.Draw();


        EndDrawing();

    }

    CloseWindow();
    return 0;
}