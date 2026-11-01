#include "raylib.h"
#include <math.h>
#include <vector>

bool fCollisionBallBrick(Vector2 &ballPosition, Vector2 &ballSpeed, int ballRadius, Rectangle &brick) {
    if (CheckCollisionCircleRec(ballPosition, ballRadius, brick)) {
        // Sides of rectangle
        int left = brick.x;
        int right = brick.x + brick.width;
        int top = brick.y; 
        int bottom = brick.y + brick.height;

        // Previus position ball
        int px = ballPosition.x - ballSpeed.x;
        int py = ballPosition.y - ballSpeed.y;

        if( px < left ) {
            if ( ballSpeed.x > 0 )
                ballSpeed.x *= -1.0f;
            ballPosition.x = left - ballRadius;
        }
        else if( px > right ) {
            if ( ballSpeed.x < 0 )
                ballSpeed.x *= -1.0f;
            ballPosition.x = right + ballRadius; 
        }
        else if ( py < top ) {
            if ( ballSpeed.y > 0 )
                ballSpeed.y *= -1.0f;
            ballPosition.y = top - ballRadius; 
        }
        else if ( py > bottom) {
            if ( ballSpeed.y < 0 )
                ballSpeed.y *= -1.0f;
            ballPosition.y = bottom + ballRadius; 
        }
        return true;
    }
    return false;
}

void fCollisionBallPlatform(Vector2 &ballPosition, Vector2 &ballSpeed, int ballRadius, Rectangle platform) {
    if (CheckCollisionCircleRec(ballPosition, ballRadius, platform)) {
        // Sides of rectangle
        int left = platform.x;
        int right = platform.x + platform.width;
        int top = platform.y; 

        // Previus position ball
        int px = ballPosition.x - ballSpeed.x;
        int py = ballPosition.y - ballSpeed.y;
        if( px < left ) {
            if ( ballSpeed.x > 0 )
                ballSpeed.x *= -1.0f;
            ballPosition.x = left - ballRadius;
        }
        else if( px > right ) {
            if ( ballSpeed.x < 0 )
                ballSpeed.x *= -1.0f;
            ballPosition.x = right + ballRadius; 
        }
        else if ( py < top ) {
            if ( ballSpeed.y > 0 )
                ballSpeed.y *= -1.0f;
            ballPosition.y = top - ballRadius; 
        }
    }
}

void initBricks(std::vector<Rectangle> &bricks, Vector2 initBrickPos, Vector2 brickSize) {
    Vector2 brickDistant = {50 + brickSize.x, 25 + brickSize.y};
    if (bricks.size() > 0) bricks.clear();
    for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 4; j++) {
            Vector2 brickPos = { initBrickPos.x + i * brickDistant.x, initBrickPos.y + j * brickDistant.y};
            Rectangle brick = {brickPos.x, brickPos.y, brickSize.x, brickSize.y};
            bricks.push_back(brick); 
        }
    } 
};

#define WIDTH 800
#define HEIGHT 450

int main () {
	// Enables 4x Multi-Sample Anti-Aliasing (MSAA), which smooths edges and reduces aliasing effects. (If supported)
	SetConfigFlags(FLAG_MSAA_4X_HINT);
	InitWindow(WIDTH, HEIGHT, "Breakout!");

	// Platform
	Vector2 platformPos = {350, 420};
	Vector2 platformSize = {100, 30};
	Rectangle platform = {platformPos.x, platformPos.y, platformSize.x, platformSize.y};
	int platformSpeed = 5;
	// Ball
    int ballRadius = 20;
    Vector2 ballPosition = { platform.x + platformSize.x/2, platform.y - ballRadius };
    Vector2 ballSpeed = { 5.0f, 4.0f };
    // Bricks
    std::vector<Rectangle> bricks;
    Vector2 initBrickPos = {30, 20};
    Vector2 brickSize = {62, 25};
    initBricks(bricks, initBrickPos, brickSize);

	// Game variable
    bool pause = 0;
    bool gameOver = 0;
    int framesCounter = 0;

    SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
    //----------------------------------------------------------

    // Main game loop
    while (!WindowShouldClose())    // Detect window close button or ESC key
    {
        // Update
        //-----------------------------------------------------
        if (IsKeyPressed(KEY_SPACE)) pause = !pause;

        if (!pause && !gameOver)
        {
            ballPosition.x += ballSpeed.x;
            ballPosition.y += ballSpeed.y;

            // Check walls collision for bouncing
            if ((ballPosition.x >= (GetScreenWidth() - ballRadius)) || (ballPosition.x <= ballRadius)) ballSpeed.x *= -1.0f;
            if ((ballPosition.y >= (GetScreenHeight() - ballRadius)) || (ballPosition.y <= ballRadius)) ballSpeed.y *= -1.0f;
            if (ballPosition.y >= (GetScreenHeight() - ballRadius)) gameOver = true;
			
			if (IsKeyDown(KEY_A) && platform.x >= 0)
			{
				platform.x -= platformSpeed;	
			}

			if (IsKeyDown(KEY_D) && platform.x <= 700)
			{
				platform.x += platformSpeed;
			}

            fCollisionBallPlatform(ballPosition, ballSpeed, ballRadius, platform);
            for (size_t i = 0; i < bricks.size(); i++) {
                if (fCollisionBallBrick(ballPosition, ballSpeed, ballRadius, bricks[i]))
                {
                    bricks.erase(bricks.begin() + i);
                    i = 0;
                }
            }
        }
        else framesCounter++;

        if (gameOver) {
            if (IsKeyPressed(KEY_R)) 
            {
                ballPosition = { platform.x + platformSize.x/2, platform.y - ballRadius };
                initBricks(bricks, initBrickPos, brickSize); 
                gameOver = !gameOver;
            }
        }
        //-----------------------------------------------------

        // Draw
        //-----------------------------------------------------
        BeginDrawing();

            ClearBackground(BLACK);

            DrawCircleV(ballPosition, (float)ballRadius, MAROON);
			DrawRectangleRec(platform, MAROON);

            for (auto brick : bricks) {
                DrawRectangleRec(brick, MAROON);
            }
            // On pause, we draw a blinking message
            if (pause && !gameOver && ((framesCounter/30)%2)) DrawText("PAUSED, Press Space to continue", 150, 200, 30, GRAY);
            // On game over, we also drawo a blinking message
            if (gameOver && ((framesCounter/30)%2)) DrawText("GameOver, Press R to restart", 200, 200, 30, GRAY);

            DrawFPS(10, 10);

        EndDrawing();
        //-----------------------------------------------------
    }

    // De-Initialization
    //---------------------------------------------------------
    CloseWindow();        // Close window and OpenGL context
    //----------------------------------------------------------

	return 0;
}
