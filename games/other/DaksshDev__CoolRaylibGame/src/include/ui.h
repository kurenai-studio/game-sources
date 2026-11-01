#ifndef UI_H
#define UI_H

#include "game.h"

void HandleTitleBar(GameState* state, int screenWidth);
void HandleResize(GameState* state, int screenWidth, int screenHeight);
void DrawTitleBar(GameState* state, int screenWidth);
void DrawButton(Button* button, Vector2 mousePos);
void DrawMainMenu(GameState* state, int screenWidth, int screenHeight);
void DrawResizeHandles(GameState* state, int screenWidth, int screenHeight);

#endif