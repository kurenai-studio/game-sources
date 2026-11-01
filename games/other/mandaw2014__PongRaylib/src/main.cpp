#include "raylib/src/raylib.h"

#include "paddle.h" 
#include "ball.h"
#include "ai.h"

int main()
{
    const int screenWidth = 800;
    const int screenHeight = 600;

    InitWindow(screenWidth, screenHeight, "Pong");

    SetTargetFPS(60);

    Paddle player(15, 100, 0, 0);
    player.y = screenHeight / 2 - player.height / 2;
    player.screenHeight = screenHeight;

    AI ai(15, 100, 0, 0);
    ai.y = screenHeight / 2 - ai.height / 2;
    ai.x = screenWidth - 15;

    Ball ball(screenWidth, screenHeight, 20, 20, 0, 0);
    ball.reset();

    int playerScore = 0;
    int aiScore = 0;

    while(!WindowShouldClose())
    {
        float deltaTime = GetFrameTime();

        player.update(deltaTime);
        ball.update(deltaTime);
        ai.update(ball, deltaTime);
        
        if(player.collide(ball)) 
            ball.ballSpeedX = ball.random(-1, 1);

        if(ai.collide(ball))
            ball.ballSpeedX = ball.random(-1, 1);

        if(ball.playerPoint == true)
            playerScore += 1;
        if(ball.aiPoint == true)
            aiScore += 1;

        BeginDrawing();

            ClearBackground(BLACK);

            ball.draw();
            player.draw();
            ai.draw();

            DrawText(TextFormat("%d", playerScore), screenWidth / 2 - 200, 25, 30, LIGHTGRAY);
            DrawText(TextFormat("%d", aiScore), screenWidth / 2 + 200, 25, 30, LIGHTGRAY);

        EndDrawing();
    }

    CloseWindow();

    return 0;
}