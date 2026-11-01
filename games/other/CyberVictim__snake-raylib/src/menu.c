#include "menu.h"
#include "raylib.h"
#include "utils_snake.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "raygui.h" // GuiStatusBar

int UpdateDrawMenuSettings(SettingsMenu *menu, GameData *gameData)
{
    // result > -1 if apply button was pressed
    int result = -1;

    BeginDrawing();

    ClearBackground(SNAKE_BACKGROUND_COLOR);

    // lock gui if dropdown box is active
    menu->changeResEditMode ? GuiLock() : GuiUnlock();

    GuiSetStyle(0, TEXT_SIZE, menu->fontSize);
    GuiGroupBox(menu->group.rec, menu->group.name);

    // GuiSetStyle(0, TEXT_SIZE,menu->fontSize);
    GuiGroupBox(menu->groupControls.rec, menu->groupControls.name);

    if (GuiButton(menu->changeResolution.rec, menu->changeResolution.name))
    {
        if (!gameData->alertMsg)
        {
            char *msg;
            AllocString(&msg, TextFormat("Choose resolution from dropdown and "
                                         "press the button\"%s\"",
                                         menu->save.name));
            gameData->alertMsg = msg;
        }
    }

    menu->checkFPSBool = GuiCheckBox(menu->checkFPS.rec, menu->checkFPS.name,
                                     menu->checkFPSBool);

    menu->checkFullScreenBool =
        GuiCheckBox(menu->checkFullScreen.rec, menu->checkFullScreen.name,
                    menu->checkFullScreenBool);

    // controls change buttons will save the key being changed
    // and change game state to controls set menu
    if (GuiButton(menu->setSnakeDown.rec, menu->setSnakeDown.name))
    {
        gameData->GAME_STATE = GAME_SET_CONTROLS;
        gameData->CONTROLS.changedKey = &gameData->CONTROLS.snakeDown;
    }

    if (GuiButton(menu->setSnakeLeft.rec, menu->setSnakeLeft.name))
    {
        gameData->GAME_STATE = GAME_SET_CONTROLS;
        gameData->CONTROLS.changedKey = &gameData->CONTROLS.snakeLeft;
    }

    if (GuiButton(menu->setSnakeRight.rec, menu->setSnakeRight.name))
    {
        gameData->GAME_STATE = GAME_SET_CONTROLS;
        gameData->CONTROLS.changedKey = &gameData->CONTROLS.snakeRight;
    }

    if (GuiButton(menu->setSnakeUp.rec, menu->setSnakeUp.name))
    {
        gameData->GAME_STATE = GAME_SET_CONTROLS;
        gameData->CONTROLS.changedKey = &gameData->CONTROLS.snakeUp;
    }

    // apply the changes
    if (GuiButton(menu->save.rec, menu->save.name))
    {
        // toggle full screen
        if (menu->checkFullScreenBool)
        {
            if (!IsWindowFullscreen())
            {
                ToggleFullscreen();
            }
        }
        else
        {
            if (IsWindowFullscreen())
            {
                ToggleFullscreen();
            }
        }

        // toggle fps counter
        menu->checkFPSBool
            ? (gameData->gameSettingsFlags |= SET_SNAKE_SHOW_FPS)
            : (gameData->gameSettingsFlags &= ~SET_SNAKE_SHOW_FPS);

        result = menu->changeResBoxValue;
    }

    // has to be drawn after the elements
    // that are below it on the screen
    if (GuiDropdownBox(menu->changeResValues.rec, menu->changeResValues.name,
                       &menu->changeResBoxValue, menu->changeResEditMode))
    {
        menu->changeResEditMode = !menu->changeResEditMode;
    }

    EndDrawing();

    return result;
}

void UpdateSettingsMenuButtons(SettingsMenu *menu)
{
    const int SCREEN_W = GetScreenWidth();
    const int SCREEN_H = GetScreenHeight();

    menu->fontSize = (int)(SCREEN_H * 0.04f);

    // init group area where all buttons go
    menu->group.rec = (Rectangle){SCREEN_W * 0.02f, SCREEN_H * 0.03f,
                                  SCREEN_W * 0.95f, SCREEN_H * 0.95f};

    // button values
    float butWidth = menu->group.rec.width * 0.6f;
    float butWSmall = menu->group.rec.width * 0.2f;
    float butHeight = menu->group.rec.height * 0.125f;
    float checkBoxHeight = butHeight * 0.5f;
    float posX = menu->group.rec.x + menu->group.rec.width * 0.02f;
    float posY = menu->group.rec.y + (float)(menu->fontSize);
    // padding between buttons
    float pad = SCREEN_W * 0.05f;
    float paddingX = pad + butWSmall;
    float paddingY = pad + butHeight;

    // first row taking two columns
    // init change resolution label and dropbox with values
    menu->changeResolution.rec =
        (Rectangle){posX, posY, butWidth * 0.8f, butHeight};
    menu->changeResValues.rec =
        (Rectangle){posX + menu->changeResolution.rec.width + pad, posY,
                    butWSmall * 1.2f, butHeight};

    // second row, two columns
    menu->checkFPS.rec =
        (Rectangle){posX, posY + paddingY, checkBoxHeight, checkBoxHeight};
    menu->checkFullScreen.rec = (Rectangle){posX + paddingX, posY + paddingY,
                                            checkBoxHeight, checkBoxHeight};

    // third row taking four columns
    // inner group
    menu->groupControls.rec =
        (Rectangle){menu->group.rec.x + menu->group.rec.width * 0.005f,
                    posY + 2.0f * paddingY, menu->group.rec.width * 0.99f,
                    butHeight * 1.3f};

    float controlsPosX = posX + menu->groupControls.rec.x * 0.01f;
    float controlsPosY = menu->groupControls.rec.y + (float)menu->fontSize;

    menu->setSnakeUp.rec =
        (Rectangle){controlsPosX, controlsPosY, butWSmall, butHeight * 0.6f};

    menu->setSnakeDown.rec = (Rectangle){controlsPosX + paddingX, controlsPosY,
                                         butWSmall, butHeight * 0.6f};

    menu->setSnakeRight.rec =
        (Rectangle){controlsPosX + 2.0f * paddingX, controlsPosY, butWSmall,
                    butHeight * 0.6f};

    menu->setSnakeLeft.rec =
        (Rectangle){controlsPosX + 3.0f * paddingX, controlsPosY, butWSmall,
                    butHeight * 0.6f};

    // fourth row
    menu->save.rec =
        (Rectangle){posX + menu->group.rec.width * 0.3f, posY + paddingY * 3.0f,
                    butWSmall * 1.3f, butHeight};
}

void InitSettingsMenu(SettingsMenu *settingsMenu)
{
    settingsMenu->changeResEditMode = false;
    settingsMenu->changeResBoxValue = 0;
    settingsMenu->checkFPSBool = false;
    settingsMenu->checkFullScreenBool = false;

    char *group;
    char *changeRes;
    char *changeResValues;
    char *setSnakeUp;
    char *setSnakeDown;
    char *setSnakeRight;
    char *setSnakeLeft;
    char *checkFPS;
    char *checkFullScreen;
    char *save;
    char *groupControls;

    AllocString(&groupControls, "CHANGE CONTROLS");
    AllocString(&changeRes, "Change resolution");
    AllocString(&save, "Apply changes");
    AllocString(&changeResValues, "800x600;1280x720;1600x900;1920x1080");
    AllocString(&setSnakeUp, "Snake up");
    AllocString(&setSnakeDown, "Snake down");
    AllocString(&setSnakeRight, "Snake right");
    AllocString(&setSnakeLeft, "Snake left");
    AllocString(&checkFPS, "Show FPS");
    AllocString(&checkFullScreen, "Toggle Fullscreen");
    AllocString(&group, "SETTINGS");

    settingsMenu->changeResValues.name = changeResValues;
    settingsMenu->group.name = group;
    settingsMenu->changeResolution.name = changeRes;
    settingsMenu->setSnakeLeft.name = setSnakeLeft;
    settingsMenu->checkFullScreen.name = checkFullScreen;
    settingsMenu->setSnakeUp.name = setSnakeUp;
    settingsMenu->checkFPS.name = checkFPS;
    settingsMenu->setSnakeRight.name = setSnakeRight;
    settingsMenu->groupControls.name = groupControls;
    settingsMenu->save.name = save;
    settingsMenu->setSnakeDown.name = setSnakeDown;

    UpdateSettingsMenuButtons(settingsMenu);
}

// draw immediate gui of main menu
void UpdateDrawMenu(GameMenu *gameMenu, GameData *gameData)
{
    BeginDrawing();

    ClearBackground(GetColor(CYAN_COLOR_S_HEX));
    GuiSetStyle(0, TEXT_SIZE, gameMenu->fontSize);

    GuiGroupBox(gameMenu->buttonGroup.rec, gameMenu->buttonGroup.name);

    if (GuiButton(gameMenu->bPlay.rec, gameMenu->bPlay.name))
    {
        gameData->GAME_STATE = GAME_ON;
    }

    if (GuiButton(gameMenu->bSettings.rec, gameMenu->bSettings.name))
    {
        gameData->GAME_STATE = GAME_MENU_SETTINGS;
    }

    if (GuiButton(gameMenu->bExit.rec, gameMenu->bExit.name))
    {
        gameData->GAME_STATE = GAME_EXIT;
    }

    EndDrawing();
}

void UpdateGameMenuButtons(GameMenu *menu)
{
    const int screenW = GetScreenWidth();
    const int screenH = GetScreenHeight();

    menu->fontSize = (int)(screenH * 0.05f);

    // init group where all buttons go
    menu->buttonGroup.rec = (Rectangle){screenW * 0.05f, screenH * 0.05f,
                                        screenW * 0.4f, screenH * 0.9f};

    //  button values
    float bWidth = menu->buttonGroup.rec.width * 0.8f;
    float bHeight = menu->buttonGroup.rec.height * 0.2f;
    float posX =
        menu->buttonGroup.rec.x + (menu->buttonGroup.rec.width - bWidth) * 0.5f;
    float posY = menu->buttonGroup.rec.y + menu->fontSize;

    // padding between buttons
    float pad = 5.0f + bHeight;

    // first row, play button
    menu->bPlay.rec = (Rectangle){posX, posY, bWidth, bHeight};

    // second row, settings button
    menu->bSettings.rec = (Rectangle){posX, posY + pad, bWidth, bHeight};

    // third row, exit button
    menu->bExit.rec = (Rectangle){posX, posY + pad * 2.0f, bWidth, bHeight};
}

// create rectangles needed to draw menu gui(raygui)
// allocates memory using raylib MemAlloc
void InitGameMenu(GameMenu *gameMenu)
{
    // char menuS[] = "MENU";
    // char playS[] = "Play";
    // char exitS[] = "Exit";
    // char settingsS[] = "Settings";

    char *menu;
    // = MemAlloc(sizeof(menuS));
    char *play;
    // = MemAlloc(sizeof(playS));
    char *exit;
    // = MemAlloc(sizeof(exitS));
    char *settings;
    // = MemAlloc(sizeof(settingsS));
    // strcpy(menu, menuS);
    // strcpy(play, playS);
    // strcpy(exit, exitS);
    // strcpy(settings, settingsS);

    AllocString(&menu, "MENU");
    AllocString(&play, "Play");
    AllocString(&exit, "Exit");
    AllocString(&settings, "Settings");

    gameMenu->buttonGroup.name = menu;
    gameMenu->bPlay.name = play;
    gameMenu->bSettings.name = settings;
    gameMenu->bExit.name = exit;

    UpdateGameMenuButtons(gameMenu);
}
void FreeGameMenu(GameMenu *gameMenu)
{
    MemFree(gameMenu->buttonGroup.name);
    MemFree(gameMenu->bPlay.name);
    MemFree(gameMenu->bExit.name);
    MemFree(gameMenu->bSettings.name);
}

void FreeSettingsMenu(SettingsMenu *settingsMenu)
{
    free(settingsMenu->changeResolution.name);
    free(settingsMenu->changeResValues.name);
    free(settingsMenu->groupControls.name);
    free(settingsMenu->group.name);
    free(settingsMenu->checkFPS.name);
    free(settingsMenu->checkFullScreen.name);
    free(settingsMenu->setSnakeDown.name);
    free(settingsMenu->setSnakeLeft.name);
    free(settingsMenu->setSnakeRight.name);
    free(settingsMenu->setSnakeUp.name);
    free(settingsMenu->save.name);
}

void ReadUpdateControls(SnakeGameState *gameState, KeyboardKey *changedKey)
{
    BeginDrawing();

    ClearBackground(BANANA);

    DrawText("Press keyboard button to save\n escape to cancel", 5, 5,
             GetScreenHeight() * 0.06f, SOFT_RED);
    KeyboardKey currentKey = GetKeyPressed();
    if (currentKey)
    {
        if (currentKey != KEY_ESCAPE)
        {
            *changedKey = currentKey;
        }
        *gameState = GAME_MENU_SETTINGS;
    }

    EndDrawing();
}
