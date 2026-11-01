#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "apple.h"
#include "main.h"
#include "menu.h"
#include "raylib.h"
#include "snake.h"
#include "utils_snake.h"

#define RAYGUI_IMPLEMENTATION
#include "raygui.h"

#ifdef DEBUG
int logIsAppleInSnake = 0;
double timeToGetApple = 0;
#endif // DEBUG

int main(void)
{
    // Init window
    SetConfigFlags(FLAG_MSAA_4X_HINT | FLAG_VSYNC_HINT);
    const short SCREEN_W = 800;
    const short SCREEN_H = 600;
    InitWindow(SCREEN_W, SCREEN_H, TITLE);

    InitAudioDevice();
    SetTargetFPS(MAX_FPS);
    SetExitKey(0); // Remove exit key (esc by default)

    // Set window icon
    Image icon = LoadImage("resources/icon.png");
    printf("----- %d\n", icon.format);
    SetWindowIcon(icon);

    // Init menu struct
    GameMenu gameMenu;
    InitGameMenu(&gameMenu);

    // init settings menu
    SettingsMenu settingsMenu;
    InitSettingsMenu(&settingsMenu);

    // GameData
    GameData gameData;
    InitGameData(&gameData);

#ifdef DEBUG
    printf("game state number %d\n", gameData.GAME_STATE);
    LogCheckGameRatios(gameData.blockSize, (int)gameData.gameField.width);
#endif // DEBUG

    // Game loop
    while (!WindowShouldClose() && gameData.GAME_STATE != GAME_EXIT)
    {
#ifdef DEBUG
        DrawText(TextFormat("%dx%d", GetScreenWidth(), GetScreenHeight()), 15,
                 30, 10, BANANA);
#endif // DEBUG
        CheckExitInput(&gameData.GAME_STATE, gameData.CONTROLS.exitKeyFirst,
                       gameData.CONTROLS.exitKeyLast);
        CheckMenuInput(&gameData.GAME_STATE);

        if (gameData.gameSettingsFlags & SET_SNAKE_SHOW_FPS)
        {
            DrawFPS(15, 15);
        }

        switch (gameData.GAME_STATE)
        {
        case GAME_MENU:
            UpdateDrawMenu(&gameMenu, &gameData);
            break;

        case GAME_MENU_SETTINGS: {
            int resolutionId = UpdateDrawMenuSettings(&settingsMenu, &gameData);
            if (resolutionId > -1)
            {
                UpdateResolution(&gameData, &gameMenu, &settingsMenu,
                                 resolutionId);
            }
        }
        break;

        case GAME_SET_CONTROLS:
            ReadUpdateControls(&gameData.GAME_STATE,
                               gameData.CONTROLS.changedKey);
            break;

        case GAME_OVER:
            if (gameData.gameOverMsg == NULL)
            {
                AllocString(&gameData.gameOverMsg, "GAME OVER!");
            }
            DrawGame(&gameData);
            break;

        case GAME_SCREEN_FILLED:
            if (gameData.gameOverMsg == NULL)
            {
                AllocString(&gameData.gameOverMsg, "GAME SCREEN FILLED!");
            }
            DrawGame(&gameData);
            break;

        case GAME_ON:
            UpdateSnake(&gameData);
            UpdateApple(&gameData);
            DrawGame(&gameData);
            break;
#ifndef DEBUG
        default:
            break;
#endif // !DEBUG
        }
        // draw alert if have any
        AlertWithTimer(&gameData.alertMsg, GetFrameTime(), 3.0f);
    }

    // Free resources
    FreeSettingsMenu(&settingsMenu);
    FreeGameMenu(&gameMenu);
    FreeGameData(&gameData);

    CloseWindow();
    return 0;
}
