#ifndef MENU_H_SNAKE
#define MENU_H_SNAKE

#include "main.h"
#include "raylib.h"

void InitSettingsMenu(SettingsMenu *settingsMenu);
void UpdateSettingsMenuButtons(SettingsMenu *menu);
int UpdateDrawMenuSettings(SettingsMenu *menu, GameData *gameData);

void InitGameMenu(GameMenu *gameMenu);
void UpdateGameMenuButtons(GameMenu *menu);
void UpdateDrawMenu(GameMenu *gameMenu, GameData *gameData);

void FreeSettingsMenu(SettingsMenu *settingsMenu);
void FreeGameMenu(GameMenu *gameMenu);

void ReadUpdateControls(SnakeGameState *gameState, KeyboardKey *changedKey);

#endif // !MENU_H_SNAKE
