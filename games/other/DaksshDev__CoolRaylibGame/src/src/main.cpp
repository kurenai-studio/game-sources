#include "raylib.h"
#include "game.h"

int main()
{
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_WINDOW_UNDECORATED);
    InitWindow(800, 600, "IndexOutOfBoundsException()");
    SetTargetFPS(60);

    Image icon = LoadImage("game.ico");
    if (icon.data == NULL) icon = LoadImage("../game.ico");
    if (icon.data != NULL) {
        SetWindowIcon(icon);
        UnloadImage(icon);
    }

    GameState gameState = InitGame();

    while (!WindowShouldClose() && !gameState.shouldClose)
    {
        UpdateGame(&gameState);
        RenderGame(&gameState);
    }

    if ((gameState.phase == LEVEL_1 || gameState.phase == LEVEL_2 || gameState.phase == LEVEL_3 || gameState.phase == MAIN_MENU)
        && !(gameState.phase == LEVEL_3 && gameState.levelComplete))
        SaveGame(&gameState);

    CloseWindow();
    return 0;
}