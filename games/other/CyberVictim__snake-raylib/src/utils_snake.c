#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "main.h"
#include "menu.h"
#include "raylib.h"
#include "snake.h"
#include "utils_snake.h"

#include "raygui.h" // GuiStatusBar

// Relative to the screen
void UpdateGameField(Rectangle *gameField, const float snakeSize)
{
    int screenW = GetScreenWidth();
    int screenH = GetScreenHeight();

    gameField->width = gameField->height = FIELD_SIZE * snakeSize;
    gameField->x = (screenW - gameField->width) * 0.5f;
    gameField->y = (screenH - gameField->height) * 0.5f;
}

// Fill the array with bounds of the rectangle, starting from left side going
// clockwise
int GetBounds(Rectangle rec, float buf[4])
{
    buf[0] = rec.x;
    buf[1] = rec.y;
    buf[2] = rec.x + rec.width;
    buf[3] = rec.y + rec.height;
    return 0;
}

void CheckExitInput(SnakeGameState *state, const KeyboardKey firstExitkey,
                    const KeyboardKey lastExitKey)
{
    // Set exit combination
    if (IsKeyDown(firstExitkey) && IsKeyDown(lastExitKey))
    {
        *state = GAME_EXIT;
    }
}

void LogCheckGameRatios(int snakeSize, int gameFieldWidth)
{
    if (gameFieldWidth % snakeSize != 0)
    {
        TraceLog(LOG_WARNING,
                 "Snake size to gamefield ratio is wrong: snake size %d | "
                 "field size %d\nAsjust "
                 "SNAKE_SIZE or FIELD_SIZE",
                 snakeSize, gameFieldWidth);
        exit(EXIT_FAILURE);
    }
    TraceLog(LOG_INFO, "Snake size seems good");
}

void AllocString(char **ptr, const char *msg)
{
    *ptr = malloc(sizeof(char) * (1 + strlen(msg)));
    strcpy(*ptr, msg);
}

void CheckMenuInput(SnakeGameState *state)
{
    if (IsKeyPressed(KEY_ESCAPE))
    {
        switch (*state)
        {
        case GAME_ON:
            *state = GAME_MENU;
            break;

        case GAME_OVER:
        case GAME_SCREEN_FILLED:
            break;

        case GAME_SET_CONTROLS:
            *state = GAME_MENU_SETTINGS;
            break;

        default:
            *state = GAME_MENU;
            break;
        }
    }
}

void ChangeSnakeWindowSize(const int resId)
{
    const int screenW = GetScreenWidth();

    int newWidth;
    int newHeight;
    switch (resId)
    {
    case 0:
        newWidth = 800;
        newHeight = 600;
        break;

    case 1:
        newWidth = 1280;
        newHeight = 720;
        break;

    case 2:
        newWidth = 1600;
        newHeight = 900;
        break;

    case 3:
        newWidth = 1920;
        newHeight = 1080;
        break;

    default:
        newWidth = screenW;
        break;
    }

    if (screenW != newWidth)
    {
        // workaround, SetWindowSize gets unexpected results when in fullscreen
        if (IsWindowFullscreen())
        {
            ToggleFullscreen();
            SetWindowSize(newWidth, newHeight);
            ToggleFullscreen();
        }
        else
        {
            SetWindowSize(newWidth, newHeight);
        }
    }
}

void AlertWithTimer(char **msg, const float frameTime, const float alertTime)
{
    static float timer = 0;
    timer += frameTime;
    if (timer < alertTime && *msg)
    {
        float height = 30;
        GuiStatusBar(
            (Rectangle){0, GetScreenHeight() - height, GetScreenWidth(), height}, *msg);
    }
    else
    {
        free(*msg);
        *msg = NULL;
        timer = 0;
    }
}

// top level statements should be only called once,
// inside functions can be called again to reset some values
void InitGameData(GameData *gameData)
{
    gameData->gameOverMsg = NULL;
    gameData->alertMsg = NULL;

    // load textures
    gameData->snakeHeadTex = LoadTexture("resources/snake_head.png");
    gameData->snakeBodyTex = LoadTexture("resources/snake_body.png");
    gameData->appleTex = LoadTexture("resources/apple.png");
    // load sound effects
    gameData->fxMove = LoadSound("resources/fx/move_fx.wav");
    gameData->dxApple = LoadSound("resources/fx/apple_fx.wav");
    gameData->fxLoss = LoadSound("resources/fx/loss_fx.mp3");

    gameData->blockSize = (float)GetScreenHeight() / SNAKE_SIZE;

    // Init game field in the center of the screen
    UpdateGameField(&gameData->gameField, gameData->blockSize);

    // number of maximum snake blocks in the field
    // field width = height = blocksize * FIELD_SIZE
    const size_t rows = FIELD_SIZE;
    const size_t cols = rows;
    gameData->maxBlocks = rows * cols;

    // matrix of allowed apple positions
    // bool matrix[rows][cols]
    bool **matrix = malloc(sizeof(*matrix) * rows);
    for (size_t i = 0; i < rows; ++i)
    {
        matrix[i] = malloc(sizeof(**matrix) * cols);
    }
    gameData->appleMatrix = matrix;

    // Init array of all snake blocks
    // destroyed when window closes
    gameData->snakeBlocks = MemAlloc(sizeof(SnakeBlock) * gameData->maxBlocks);

    ResetGameData(gameData);

    gameData->apple =
        (Rectangle){0.0f, 0.0f, gameData->blockSize, gameData->blockSize};

    // init game default settings
    unsigned int defaultGameSettings = 0;
    gameData->gameSettingsFlags = defaultGameSettings;

    // Init default controls
    gameData->CONTROLS = (Controls){KEY_UP,
                                    KEY_DOWN,
                                    KEY_LEFT,
                                    KEY_RIGHT,
                                    .exitKeyFirst = KEY_LEFT_ALT,
                                    .exitKeyLast = KEY_Q};
}
