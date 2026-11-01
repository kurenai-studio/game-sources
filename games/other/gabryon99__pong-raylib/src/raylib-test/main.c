//
//  main.c
//  raylib-test
//
//  Created by Gabriele Pappalardo on 04/04/2020.
//  Copyright © 2020 Gabriele Pappalardo. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <raylib.h>
#include <time.h>

#include "game.h"
#include "ball.h"
#include "paddle.h"

unsigned int playerOneScore_g = 0;
unsigned int playerTwoScore_g = 0;

int main(int argc, char** argv) {
    
    // initalize pseudo number generator
    srand((unsigned int) time(NULL));
    
    const int screenWidth = SCREEN_WIDTH;
    const int screenHeight = SCREEN_HEIGHT;
    GameState state = IDLE;
    
    InitWindow(screenWidth, screenHeight, "always stupid pong");

    paddle playerOne, playerTwo;
    ball ball;
    
    SET_PADDLE_POSITION(playerOne, 8, screenHeight / 2);
    SET_PADDLE_SIZE(playerOne, 15, 80);
    SET_PADDLE_INPUT(playerOne, KEY_W, KEY_S);
    
    SET_PADDLE_POSITION(playerTwo, screenWidth - 15 - 8, screenHeight / 2);
    SET_PADDLE_SIZE(playerTwo, 15, 80);
    
    SET_PADDLE_SIZE(ball, 15, 15);
    SET_PADDLE_POSITION(ball, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);
    
    playerOne.velocity.y = 12.0f; playerTwo.velocity.y = 12.0f;
    ball.velocity.x = 8.0f; ball.velocity.y = 0;
    
    // Set our game to run at 60 frames-per-second
    SetTargetFPS(FPS);

    float paddleAITimeout = 0;
    
    // Main game loop
    while (!WindowShouldClose()) {
        
        switch (state) {
            case IDLE:
                if (IsKeyReleased(KEY_SPACE)) state = PLAYING;
                break;
            case PLAYER_ONE_SERVE:
                if (IsKeyReleased(KEY_SPACE)) {
                    state = PLAYING;
                    ball.velocity.x = 8.0f;
                }
                MovePaddle(&playerOne);
                ball.rect.y = playerOne.rect.y + playerOne.rect.height / 2 - ball.rect.height / 2;
                PaddleAI(&playerTwo, ball);
                break;
            case PLAYER_TWO_SERVE:
                if (paddleAITimeout >= 1.2) {
                    state = PLAYING;
                    ball.velocity.x = -8.0f;
                    paddleAITimeout = 0;
                    break;
                }
                ball.rect.y = playerTwo.rect.y + playerTwo.rect.height / 2 - ball.rect.height / 2;
                paddleAITimeout += GetFrameTime();
                break;
            case PLAYING:
            default:
                // Update Players position
                MovePaddle(&playerOne);
                PaddleAI(&playerTwo, ball);
                MoveBall(&ball, playerOne.rect, playerTwo.rect, &state);
                break;
        }

        // Draw player
        BeginDrawing(); {
            
            ClearBackground(BLACK);
            DrawText(FormatText("%02i", playerOneScore_g), SCREEN_WIDTH / 2 - 100, 80, 32, WHITE);
            DrawText(FormatText("%02i", playerTwoScore_g), SCREEN_WIDTH / 2 + 100, 80, 32, WHITE);

            DRAW_PADDLE(playerOne);
            DRAW_PADDLE(playerTwo);
            DRAW_PADDLE(ball);
            
        } EndDrawing();
    }

    // Close window and OpenGL context
    CloseWindow();

    return 0;
}
