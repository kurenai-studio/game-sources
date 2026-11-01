#include "raylib.h"
#include "time.h"
#include "math.h"

long long int frameCount = 0;

const int screenWidth = 800;
const int screenHeight = 600;

const int paddleWidth = 100;
const int paddleHeight = 20;
const Vector2 paddleRect = {
    paddleWidth,
    paddleHeight
};
struct {
    Vector2 position;
    float speed;
} paddle;

struct {
    Vector2 position;
    Vector2 direction;
    float speed;
    float radius;
} ball;

typedef struct {
    Vector2 position;
    bool active;
} Brick;
const int brickSpacing = 2;
const int brickWidth = (screenWidth - 20) / 20 - brickSpacing; 
const int brickHeight = 15;
struct BrickRow {
    Brick bricks[20];
};
struct BrickRow brickRows[10];

const float resetDelay = 1.0f;
float resetTimer = 0.0f;
enum GameState {
    GAME_MENU,
    GAME_PLAYING,
    GAME_RESETTING,
    GAME_OVER
};

struct {
    enum GameState state;
    int score;
    int best;
    int lives;
} game = {
    GAME_MENU,
    0,
    0,
    3
};


void InitBricks(void) {
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 20; j++) {
            brickRows[i].bricks[j].position = (Vector2) {
                j * (brickWidth + brickSpacing) + 10,
                i * (brickHeight + brickSpacing) + 70
            };

            brickRows[i].bricks[j].active = true;
        }
    }
}

void DrawBricks(void) {
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 20; j++) {
            if (!brickRows[i].bricks[j].active) {
                continue;
            }

            DrawRectangleV(brickRows[i].bricks[j].position, (Vector2) {
                brickWidth,
                brickHeight
            }, MAROON);
        }
    }
}

void StartGame(void) {
    game.state = GAME_PLAYING;
    float direction = GetRandomValue(0, 50) / 50.0f;
    ball.direction = (Vector2) {
        direction,
        -1.0f
    };

    ball.speed = 500.0f;
}

void DoInput(float deltaTime) {
    if (game.state == GAME_MENU) {
        if (IsKeyPressed(KEY_SPACE)) {
            StartGame();
        }

        return;
    } else if (game.state == GAME_OVER) {
        return;
    }

    if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A)) {
        paddle.position.x -= paddle.speed * deltaTime;

        if (paddle.position.x < 0) {
            paddle.position.x = 0;
        }
    }

    if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D)) {
        paddle.position.x += paddle.speed * deltaTime;

        if (paddle.position.x > screenWidth - paddleWidth) {
            paddle.position.x = screenWidth - paddleWidth;
        }
    }
}

void WallBounce(float deltaTime) {
    (void) deltaTime;
    if (ball.position.x >= screenWidth - ball.radius) {
        ball.direction.x *= -1;
    }

    if (ball.position.x <= ball.radius) {
        ball.direction.x *= -1;
    }

    if (ball.position.y <= ball.radius) {
        ball.direction.y *= -1;
    }
}

void PaddleBounce(float deltaTime) {
    Rectangle paddleTopRect = {
        paddle.position.x,
        paddle.position.y,
        paddleWidth,
        1 
    };

    float deltaX = ball.direction.x * ball.speed * deltaTime;
    float deltaY = ball.direction.y * ball.speed * deltaTime;
    Rectangle ballRect = {
        ball.position.x - ball.radius + deltaX,
        ball.position.y - ball.radius + deltaY,
        ball.radius * 2,
        ball.radius * 2
    };

    bool collision = CheckCollisionRecs(paddleTopRect, ballRect);
    if (!collision) {
        return;
    }

    float paddleCenter = paddle.position.x + paddleWidth / 2;
    float ballDistance = ball.position.x - paddleCenter;
    float ballDistancePercent = ballDistance / (paddleWidth / 2);
    float bounceAngle = ballDistancePercent * 5.0f;

    ball.direction.x = sinf(bounceAngle);
    ball.direction.y *= -1;
}

void BrickBounce(float deltaTime) {
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 20; j++) {
            if (!brickRows[i].bricks[j].active) {
                continue;
            }

            Rectangle brickRect = {
                brickRows[i].bricks[j].position.x,
                brickRows[i].bricks[j].position.y,
                brickWidth,
                brickHeight
            };

            // A collision rectangle representing the ball's position next frame
            float deltaX = ball.direction.x * ball.speed * deltaTime;
            float deltaY = ball.direction.y * ball.speed * deltaTime;
            Rectangle ballRect = {
                ball.position.x - ball.radius + deltaX,
                ball.position.y - ball.radius + deltaY,
                ball.radius * 2,
                ball.radius * 2
            };

            bool collision = CheckCollisionRecs(brickRect, ballRect);

            if (!collision) {
                continue;
            }

            brickRows[i].bricks[j].active = false;
            game.score += 100;

            if (game.score > game.best) {
                game.best = game.score;
            }

            bool leftCollision = ballRect.x <= brickRect.x;
            bool rightCollision = ballRect.x + ballRect.width
                                >= brickRect.x + brickRect.width;
            bool topCollision = ballRect.y <= brickRect.y;
            bool bottomCollision = ballRect.y + ballRect.height
                                 >= brickRect.y + brickRect.height;

            if (leftCollision || rightCollision) {
                ball.direction.x *= -1;
            }

            if (topCollision || bottomCollision) {
                ball.direction.y *= -1;
            }
        }
    }
}

void DeathZone(float deltaTime) {
    (void) deltaTime;
    if (ball.position.y >= screenHeight - ball.radius) {
        game.lives--;

        if (game.lives <= 0) {
            game.state = GAME_OVER;
        } else {
            game.state = GAME_RESETTING;
        }
    }
}

void DoPhysics(float deltaTime) {
    if (game.state != GAME_PLAYING) {
        return;
    }

    ball.position.x += ball.direction.x * ball.speed * deltaTime;
    ball.position.y += ball.direction.y * ball.speed * deltaTime;

    WallBounce(deltaTime);
    PaddleBounce(deltaTime);
    DeathZone(deltaTime);
    BrickBounce(deltaTime);
}

int main(void) {
    
    SetRandomSeed(time(NULL));

    InitWindow(screenWidth, screenHeight, "Hello, Sailor!");
    SetTargetFPS(60);

    paddle.position = (Vector2) {
        screenWidth / 2,
        screenHeight - 50
    };
    paddle.speed = 800.0f;

    ball.position = (Vector2) {
        paddle.position.x + paddleWidth / 2, 
        paddle.position.y - paddleHeight / 2 
    };
    ball.direction = (Vector2) {
        1.0f,
        -1.0f
    };
    ball.speed = 0.0f;
    ball.radius = 10.0f;

    InitBricks();

    while (!WindowShouldClose()) {

        float deltaTime = GetFrameTime();
        float deltaTimeMs = deltaTime * 1000.0f;
        const char *title = TextFormat("Breakout - %.2f ms", deltaTimeMs);
        SetWindowTitle(title);

        DoInput(deltaTime);

        BeginDrawing();
            ClearBackground(RAYWHITE);

            DrawBricks();
            
            DrawRectangleV(paddle.position, paddleRect, MAROON);
            DrawCircleV(ball.position, ball.radius, DARKBLUE);

            const char *scoreText = TextFormat("Score: %i", game.score);
            DrawText(scoreText, 10, 10, 20, DARKGRAY);

            const char *bestText = TextFormat("Best: %i", game.best);
            //int bestTextWidth = MeasureText(bestText, 20);
            DrawText(
                bestText,
                10, 30 + 10,
                20,
                DARKGRAY
            );

            const char *livesText = TextFormat("Lives: %i", game.lives);
            int livesTextWidth = MeasureText(livesText, 20);
            DrawText(
                livesText,
                screenWidth - livesTextWidth - 10,
                10, 20,
                DARKGRAY
            );

            if (game.state == GAME_MENU) {
                const char *message = "Press [Space] to start!";
                DrawText(
                    message,
                    screenWidth / 2 - MeasureText(message, 20) / 2,
                    screenHeight / 2 - 50,
                    20,
                    GRAY
                ); 
            } else if (game.state == GAME_OVER) {
                const char *message = "Game Over!";
                DrawText(
                    message,
                    screenWidth / 2 - MeasureText(message, 20) / 2,
                    screenHeight / 2 - 50,
                    20,
                    GRAY
                );
            }
        EndDrawing();

        if (game.state == GAME_OVER || game.state == GAME_RESETTING) {
            resetTimer += deltaTime;

            if (resetTimer >= resetDelay) {

                if (game.state == GAME_OVER) {
                    game.score = 0;
                    game.lives = 3;
                }

                game.state = GAME_MENU;
                resetTimer = 0.0f;

                ball.position = (Vector2) {
                    paddle.position.x + paddleWidth / 2, 
                    paddle.position.y - paddleHeight / 2 
                };
            }
        }

        DoPhysics(deltaTime);

        frameCount++;
    }

    CloseWindow();

    return 0;
}
