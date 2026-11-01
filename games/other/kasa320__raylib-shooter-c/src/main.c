#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <raylib.h>
#include <stdbool.h>
#include <math.h>
#include <rlgl.h>
#include <time.h>

GameState currentState = STATE_MENU;

int main ()
{
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "2D SEARCH AND DESTROY");
    SetTargetFPS(FPS);
    InitAudioDevice();

    while (!WindowShouldClose()) {
        switch (currentState) {
            case STATE_MENU:    UpdateMenu();   break;
            case STATE_1v5:     Update1v5();    break;
        }

        BeginDrawing();
        switch (currentState) {
            case STATE_MENU:    DrawMenu();     break;
            case STATE_1v5:     Draw1v5();      break;
        }

        EndDrawing();
    }
    
    Unload1v5();
    CloseAudioDevice();
    CloseWindow();
    return 0;
}