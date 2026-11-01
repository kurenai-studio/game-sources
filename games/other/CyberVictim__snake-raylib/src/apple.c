#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "apple.h"
#include "main.h"
#include "raylib.h"
#include "snake.h"

static bool GetApple(Rectangle *apple, const Rectangle *gameField,
                     const bool **matrix)
{
    bool foundApple = true;

    // rows == cols
    int rows = FIELD_SIZE;
    Vector2 appleArray[rows * rows];
    int appleIndex = 0;
    // fill array with all possible apple coordinates
    for (int y = 0; y < rows; ++y)
    {
        for (int x = 0; x < rows; ++x)
        {
            if (matrix[y][x])
            {
                appleArray[appleIndex].y = y;
                appleArray[appleIndex].x = x;
                appleIndex++;
            }
        }
    }
    --appleIndex; // remove unused index;

    // no place for apple
    // only happens if bool matrix is all false,
    if (appleIndex < 0)
    {
        foundApple = false;
    }
    else
    {
        SetRandomSeed(time(NULL));
        int rndIndex = GetRandomValue(0, appleIndex);
        int y = appleArray[rndIndex].y;
        int x = appleArray[rndIndex].x;

        // Calculate actual screen coordinate
        float appleSize = apple->height;
        apple->x = x * appleSize + gameField->x;
        apple->y = y * appleSize + gameField->y;
    }

    return foundApple;
}

void UpdateApple(GameData *gameData)
{
    gameData->dtApple += GetFrameTime();

    // if enough time has passed
    if ((gameData->dtApple >= APPLE_SPEED &&
         gameData->GAME_STATE != GAME_SCREEN_FILLED))
    {

        #ifdef DEBUG
        double oldTime = GetTime();
        #endif // DEBUG

        // update matrix with the position of snake
        UpdateAppleMatrix(gameData->appleMatrix, &gameData->snakePlayer,
                          &gameData->gameField);

        // get random position and check with the matrix
        if (GetApple(&gameData->apple, &gameData->gameField,
                    gameData->appleMatrix))
        {
            gameData->dtApple = 0.0f;
            gameData->appleActive = true;
            #ifdef DEBUG
            printf("apple found");
            #endif // DEBUG
        }
        else
        {
            gameData->dtApple = APPLE_SPEED - 0.1f;
            gameData->appleActive = false;
        }
        #ifdef DEBUG
        timeToGetApple = GetTime() - oldTime;
        printf("%f\n", timeToGetApple);
        #endif // DEBUG
    }
}

// mark snake coordinates with false
// in the bool matrix
void UpdateAppleMatrix(bool **appleMatrix, const Snake *snake,
                       const Rectangle *field)
{
    // reset apple matrix
    const size_t rows = FIELD_SIZE;
    const size_t cols = rows;
    for (size_t i = 0; i < rows; ++i)
    {
        for (size_t j = 0; j < cols; ++j)
        {
            appleMatrix[i][j] = true;
        }
    }

    SnakeBlock *block = snake->tail;
    const float blockSize = block->body.height;
    while (block)
    {
        int row = (block->body.y - field->y) / blockSize;
        int col = (block->body.x - field->x) / blockSize;
        appleMatrix[row][col] = false;
        block = block->next;
    }
}
