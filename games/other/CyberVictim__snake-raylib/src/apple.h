#ifndef APPLE_H_SNAKE
#define APPLE_H_SNAKE

#include "main.h"
#include "raylib.h"

void UpdateApple(GameData *gameData);
void UpdateAppleMatrix(bool **appleMatrix, const Snake *snake,
                       const Rectangle *field);

#endif // !APPLE_H_SNAKE
