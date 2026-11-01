#include <stdio.h>
#include <raylib.h>
#include <stdbool.h>
#include <math.h>

typedef enum {
    LEFT_BOUND,
    RIGHT_BOUND,
    UPPER_BOUND,
    LOWER_BOUND,
    NONE,
} Boundary;

Boundary DetectCollision(Vector2* position, Vector4* bounds) {
    if (position->x < bounds->x) {
        return LEFT_BOUND;
    }    
    if (position->x > bounds->y) {
        return RIGHT_BOUND;
    }
    if (position->y < bounds->z) {
        return UPPER_BOUND;
    }
    if (position->y > bounds->w) {
        return LOWER_BOUND;
    }
    return NONE;
}

bool MissedPaddle(Vector2* position, Vector2* paddlePosition, Vector2* paddleSize) {
    return fabs((paddlePosition->y + (paddleSize->y / 2)) - position->y) > (paddleSize->y / 2);
}

void ResetState(Vector2* position, Vector2* defaultPosition, Vector2* velocity, Vector2* defaultVelocity) {
    *position = *defaultPosition;
    *velocity = *defaultVelocity;
}

int main() {
    const int screenWidth = 1280;
    const int screenHeight = 720;

    InitWindow(screenWidth, screenHeight, "Pong");

    const bool singlePlayer = true;

    // sizing
    const float ballRadius = (float) screenHeight / 40;
    const float paddleWidth = (float) screenWidth / 80;
    const float paddleHeight = (float) screenHeight / 6;
    Vector2 paddleSize = { paddleWidth, paddleHeight };

    // positioning
    const float paddleSpacing = (float) screenWidth / 14;
    Vector2 ballPosition = { (float) screenWidth / 2, (float) screenHeight / 2 };
    Vector2 paddlePosition1 = { paddleSpacing, (float) screenHeight / 2 - (paddleHeight / 2) };
    Vector2 paddlePosition2 = { screenWidth - (paddleSpacing + paddleWidth), (float) screenHeight / 2 - (paddleHeight / 2) };

    // velocities
    Vector2 ballVelocity = { (float) screenWidth / 2, (float) screenWidth / 6 };
    const float paddleSpeed = (float) screenHeight;

    // defaults, shouldn't be important in the future
    Vector2 defaultPosition = ballPosition;
    Vector2 defaultVelocity = ballVelocity; 

    // screen bounds
    const float upperBound = ballRadius;
    const float lowerBound = screenHeight - ballRadius;
    const float leftBound = paddlePosition1.x + paddleWidth + ballRadius;
    const float rightBound = paddlePosition2.x - ballRadius;
    Vector4 bounds = { leftBound, rightBound, upperBound, lowerBound };

    // colors
    Color ballColor = RAYWHITE;
    Color paddleColor1 = RAYWHITE;
    Color paddleColor2 = RAYWHITE;

    SetTargetFPS(1000);

    while (!WindowShouldClose()) {
        float deltaTime = GetFrameTime();

        ballPosition.x += ballVelocity.x * deltaTime;
        ballPosition.y += ballVelocity.y * deltaTime;

        if (IsKeyDown(KEY_UP) && paddlePosition1.y > 0) {
            paddlePosition1.y -= paddleSpeed * deltaTime;
        }

        if (IsKeyDown(KEY_DOWN) && paddlePosition1.y < screenHeight - paddleSize.y) {
            paddlePosition1.y += paddleSpeed * deltaTime;
        }

        // ai
        if (singlePlayer) {
            if (paddlePosition2.y + (paddleHeight / 2) > ballPosition.y && paddlePosition2.y > 0) {
                paddlePosition2.y -= paddleSpeed * deltaTime;
            }
            if (paddlePosition2.y + (paddleHeight / 2) < ballPosition.y && paddlePosition2.y < screenHeight - paddleSize.y) {
                paddlePosition2.y += paddleSpeed * deltaTime;
            }
        }

        // collision detection and handling
        Boundary collision = DetectCollision(&ballPosition, &bounds);
        switch (collision) {
            case NONE: break;
            case LEFT_BOUND: {
                ballVelocity.x = fabs(ballVelocity.x);
                if (MissedPaddle(&ballPosition, &paddlePosition1, &paddleSize)) {
                    ResetState(&ballPosition, &defaultPosition, &ballVelocity, &defaultVelocity);
                }
                break;
            }
            case RIGHT_BOUND: {
                ballVelocity.x = -fabs(ballVelocity.x);
                if (MissedPaddle(&ballPosition, &paddlePosition2, &paddleSize)) {
                    ResetState(&ballPosition, &defaultPosition, &ballVelocity, &defaultVelocity);
                }
                break;
            }
            case UPPER_BOUND: {
                ballVelocity.y = fabs(ballVelocity.y);
                break;
            }
            case LOWER_BOUND: {
                ballVelocity.y = -fabs(ballVelocity.y);
                break;
            }
        }

        // drawing
        BeginDrawing();
            ClearBackground(BLACK);
            DrawCircleV(ballPosition, ballRadius, ballColor);
            DrawRectangleV(paddlePosition1, paddleSize, paddleColor1);
            DrawRectangleV(paddlePosition2, paddleSize, paddleColor2);
        EndDrawing();
    }

    CloseWindow();
}
