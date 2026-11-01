#ifndef SNAKE_H_SNAKE
#define SNAKE_H_SNAKE

#include "main.h"
#include "raylib.h"

void ResetGameData(GameData *gameData);
void RestartGame(GameData *gameData);
void FreeGameData(GameData *gameData);

void InitSnake(Snake *snake, const Rectangle *gameField,
               const float snakeBlockSize, SnakeBlock *snakeBlock);

void DrawSnake(Snake *snake, Color bodyColor, Color headColor,const Texture2D *headTex, const Texture2D *bodyTex);
void DrawGame(GameData *gameData);

void UpdateSnake(GameData *gameData);
int UpdateSnakePosition(Snake *snake, const float bounds[4],
                        const Rectangle *apple);
bool UpdateSnakeDirection(Snake *snake, const Controls *controls);

void UpdateResolution(GameData *gameData, GameMenu *gameMenu,
                      SettingsMenu *settingsMenu, const int resolutionId);

void EatApple(Rectangle *apple, Snake *snake, SnakeBlock *appleBlock);

bool SnakeHitItself(const Snake *snake);

#endif // !SNAKE_H_SNAKE
