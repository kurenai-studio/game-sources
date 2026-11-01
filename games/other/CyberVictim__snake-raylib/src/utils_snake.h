#ifndef UTILS_H_SNAKE
#define UTILS_H_SNAKE

#include "main.h"
#include "raylib.h"

void InitGameData(GameData *gameData);
void UpdateGameField(Rectangle *gameField, const float snakeSize);

int GetBounds(Rectangle rec, float buf[4]);
void AllocString(char **ptr, const char *msg);

void LogCheckGameRatios(int snakeSize, int gameFieldWidth);
void AlertWithTimer(char **msg, const float frameTime, const float alertTime);

void CheckExitInput(SnakeGameState *state, const KeyboardKey firstExitkey,
                    const KeyboardKey lastExitKey);
void CheckMenuInput(SnakeGameState *state);

void ChangeSnakeWindowSize(const int resId);

#endif // !UTILS_H_SNAKE
