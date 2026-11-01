#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <raylib.h>

#include "snake.h"

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

// Window
static const int gameWidth = 660;
static const int gameHeight = 660;

static int resolutions[][2] = { { 640, 480 }, { 800, 600 }, { 1024, 768 }, { 1280, 720 } };

static const int gridSize = 22;
static float gridScale;

static int scoreMargin = 60;

static RenderTexture2D target;
static float targetScale;
static RenderTexture2D menuRender;
static float menuScale;

// Snake
static Vector2 headPos;
static node_t * head;

// Snake movement
static int tickCount = 0;
static enum { up, right, down, left } direction = right;
static bool canPress = true;

// Apple
static Vector2 applePos;
static int appleCount = 0;
static int appleBest = 0;

// Game state
static bool shouldQuit = false;
static bool pause = false;
static enum { menu, game, gameover } screen = menu;
static const char * options[] = { "JOGAR", "800x600", "SAIR" };
static const char * gameoverOptions[] = { "TENTAR DE NOVO", "MENU PRINCIPAL" };
static int resolutionSelected = 1;
static int menuSelected = 0;
static int gameoverSelected = 0;

// Function declaration
static void InitGame(void);
static void UpdateGame(void);
static void DrawGame(void);
static void DrawNode(node_t * head);
static void SpawnApple(void);

int main()
{
   InitWindow(resolutions[resolutionSelected][0], resolutions[resolutionSelected][1], "Snake");

   gridScale = gameWidth / (float) gridSize;

   target = LoadRenderTexture(gameWidth, gameHeight + scoreMargin);
   menuRender = LoadRenderTexture(gameWidth, gameHeight);
   SetTextureFilter(target.texture, TEXTURE_FILTER_BILINEAR);
   SetTextureFilter(menuRender.texture, TEXTURE_FILTER_BILINEAR);

   SetExitKey(KEY_NULL);

   SetTargetFPS(60);

   while (!shouldQuit)
   {
      UpdateGame();
      DrawGame();
   }

   deleteSnake(head);
   UnloadRenderTexture(menuRender);
   UnloadRenderTexture(target);
   CloseWindow();

   return 0;
}

void InitGame()
{
   direction = right;
   headPos = (Vector2) { (float) gridSize / 2 * gridScale, (float) gridSize / 2 * gridScale + scoreMargin };

   head = NULL;

   for (int i = 0; i < 3; i++) {
      head = createHead(head, headPos);
      headPos.x = headPos.x + gridScale;
   }

   SpawnApple();
}

void UpdateGame()
{
   shouldQuit = WindowShouldClose();

   targetScale = MIN((float) GetScreenWidth() / gameWidth, (float) GetScreenHeight() / (gameHeight + scoreMargin));
   menuScale = MIN((float) GetScreenWidth() / gameWidth, (float) GetScreenHeight() / gameHeight);

   switch (screen)
   {
      case menu:
         if (IsKeyPressed(KEY_DOWN) && menuSelected < 2)
         {
            menuSelected++;
         }
         if (IsKeyPressed(KEY_UP) && menuSelected > 0)
         {
            menuSelected--;
         }
         if (IsKeyPressed(KEY_ENTER))
         {
            switch (menuSelected)
            {
               case 0:
                  screen = game;
                  InitGame();
                  break;
               case 1:
                  resolutionSelected = resolutionSelected < 3 ? resolutionSelected + 1 : 0;
                  SetWindowSize(resolutions[resolutionSelected][0], resolutions[resolutionSelected][1]);
                  break;
               case 2:
                  shouldQuit = true;
                  break;
            }
         }
         if (IsKeyPressed(KEY_LEFT) && menuSelected == 1 && resolutionSelected > 0)
         {
            resolutionSelected--;
            SetWindowSize(resolutions[resolutionSelected][0], resolutions[resolutionSelected][1]);
         }
         if (IsKeyPressed(KEY_RIGHT) && menuSelected == 1 && resolutionSelected < 3)
         {
            resolutionSelected++;
            SetWindowSize(resolutions[resolutionSelected][0], resolutions[resolutionSelected][1]);
         }
         break;

      case game:
         if (IsKeyPressed(KEY_ESCAPE))
         {
            pause = !pause;
         }

         if (!pause)
         {
            tickCount++;

            // Input handling
            if (IsKeyPressed(KEY_RIGHT) && canPress && direction != left)
            {
               direction = right;
               canPress = false;
            }
            if (IsKeyPressed(KEY_LEFT) && canPress && direction != right)
            {
               direction = left;
               canPress = false;
            }
            if (IsKeyPressed(KEY_UP) && canPress && direction != down)
            {
               direction = up;
               canPress = false;
            }
            if (IsKeyPressed(KEY_DOWN) && canPress && direction != up)
            {
               direction = down;
               canPress = false;
            }

            // Update snake position
            if (tickCount % 5 == 0)
            {
               tickCount = 0;

               switch (direction)
               {
                  case up:
                     headPos.y -= gridScale;
                     break;
                  case down:
                     headPos.y += gridScale;
                     break;
                  case left:
                     headPos.x -= gridScale;
                     break;
                  case right:
                     headPos.x += gridScale;
                     break;
               }

               // Check if snake has eaten apple
               if (head->position.x == applePos.x && head->position.y == applePos.y)
               {
                  appleCount++;
                  appleBest = appleCount > appleBest ? appleCount : appleBest;
                  do
                  {
                     SpawnApple();
                  }
                  while (isColliding(head, applePos));
               }
               // If the snake has not eaten a apple, delete the tail
               else
               {
                  deleteTail(head);
               }

               head = createHead(head, headPos);

               canPress = true;
            }

            // Collision check
            if (isColliding(head->next, head->position)
                  || headPos.x < gridScale
                  || headPos.y < gridScale + scoreMargin
                  || headPos.x >= gameWidth - gridScale
                  || headPos.y >= gameHeight + scoreMargin - gridScale)
            {
               deleteSnake(head);
               head = NULL;
               appleCount = 0;
               screen = gameover;
               gameoverSelected = 0;
            }
         }
         break;

      case gameover:
         if (IsKeyPressed(KEY_DOWN) && gameoverSelected < 1)
         {
            gameoverSelected++;
         }
         if (IsKeyPressed(KEY_UP) && gameoverSelected > 0)
         {
            gameoverSelected--;
         }
         if (IsKeyPressed(KEY_ENTER))
         {
            switch (gameoverSelected)
            {
               case 0:
                  screen = game;
                  InitGame();
                  break;

               case 1:
                  screen = menu;
                  menuSelected = 0;
                  break;
            }
         }
         break;
   }

}

void DrawGame()
{

      switch (screen)
      {
         case menu:
            BeginTextureMode(menuRender);
               ClearBackground(BLACK);

               Color textColor;
               int posY;

               for (int i = 0; i < 3; i++)
               {
                  textColor = menuSelected == i ? WHITE : GRAY;
                  switch (i)
                  {
                     case 0:
                        posY = gameHeight / 2 - 100;
                        break;
                     case 1:
                        posY = gameHeight / 2 - 50;
                        DrawText(TextFormat("%dx%d", resolutions[resolutionSelected][0], resolutions[resolutionSelected][1]), gameWidth / 2 - MeasureText(options[i], 50) / 2, posY, 50, textColor);
                        break;
                     case 2:
                        posY = gameHeight / 2;
                        break;
                  }
                  if (i != 1)
                  {
                     DrawText(options[i], gameWidth / 2 - MeasureText(options[i], 50) / 2, posY, 50, textColor);
                  }
               }
            EndTextureMode();

            BeginDrawing();
               ClearBackground(BLACK);

               DrawTexturePro(menuRender.texture,
                     (Rectangle) { 0.0f, 0.0f, (float) menuRender.texture.width, (float) - menuRender.texture.height },
                     (Rectangle) { (GetScreenWidth() - (float) gameWidth * menuScale) * 0.5f, (GetScreenHeight() - (float) gameHeight * menuScale) * 0.5f, gameWidth * menuScale, gameHeight * menuScale },
                     (Vector2) { 0.0f, 0.0f }, 0.0f, WHITE);
            EndDrawing();
            break;

         case game:
            BeginTextureMode(target);
               ClearBackground(BLACK);

               // Drawl walls
               for (int i = 0; i <= gameWidth - gridScale; i += gridScale)
               {
                  // Top row
                  DrawRectangle(i, scoreMargin, gridScale, gridScale, WHITE);
                  DrawRectangleLines(i, scoreMargin, gridScale, gridScale, BLACK);

                  // Bottom row
                  DrawRectangle(i, gameHeight + scoreMargin - gridScale, gridScale, gridScale, WHITE);
                  DrawRectangleLines(i, gameHeight + scoreMargin - gridScale, gridScale, gridScale, BLACK);
               }
               for (int i = gridScale + scoreMargin; i <= gameHeight + scoreMargin - gridScale * 2; i += gridScale)
               {
                  // Left row
                  DrawRectangle(0, i, gridScale, gridScale, WHITE);
                  DrawRectangleLines(0, i, gridScale, gridScale, BLACK);

                  // Right row
                  DrawRectangle(gameWidth - gridScale, i, gridScale, gridScale, WHITE);
                  DrawRectangleLines(gameWidth - gridScale, i, gridScale, gridScale, BLACK);
               }

               // Draw the apple
               DrawRectangle(applePos.x, applePos.y, gridScale, gridScale, RED);
               DrawRectangleLines(applePos.x, applePos.y, gridScale, gridScale, BLACK);

               // Draw the snake
               forEach(head, &DrawNode);

               // Draw score
               DrawText(TextFormat("Score: %d", appleCount), gridScale, scoreMargin / 4, 35, WHITE);
               DrawText(TextFormat("Best: %d", appleBest), gameWidth - gridScale - MeasureText(TextFormat("Best: %d", appleBest), 35), scoreMargin / 4, 35, WHITE);

               if (pause)
               {
                  DrawText("PAUSED", gameWidth / 2 - MeasureText("PAUSED", 30) / 2, gameHeight / 2 - 30 + scoreMargin, 40, WHITE);
               }
            EndTextureMode();

            BeginDrawing();
               ClearBackground(BLACK);
               // texture, source, dest, origin, rotation, color tint
               DrawTexturePro(target.texture,
                     (Rectangle) { 0.0f, 0.0f, (float) target.texture.width, (float) - target.texture.height },
                     (Rectangle) { (GetScreenWidth() - (float) gameWidth * targetScale) * 0.5f, (GetScreenHeight() - (float) (gameHeight + scoreMargin) * targetScale) * 0.5f, gameWidth * targetScale, (gameHeight + scoreMargin) * targetScale },
                     (Vector2) { 0.0f, 0.0f }, 0.0f, WHITE);
            EndDrawing();
            break;

         case gameover:
            BeginTextureMode(menuRender);
               ClearBackground(BLACK);

               DrawText("GAME OVER", gameWidth / 2 - MeasureText("GAME OVER", 40) / 2, gameHeight / 2 - 80, 40, WHITE);

               textColor = GRAY;
               for (int i = 0; i < 2; i++)
               {
                  textColor = gameoverSelected == i ? WHITE : GRAY;
                  DrawText(gameoverOptions[i], gameWidth / 2 - MeasureText(gameoverOptions[i], 30) / 2, gameHeight / 2 + i * 40, 30, textColor);
               }
            EndTextureMode();

            BeginDrawing();
               ClearBackground(BLACK);

               DrawTexturePro(menuRender.texture,
                     (Rectangle) { 0.0f, 0.0f, (float) menuRender.texture.width, (float) - menuRender.texture.height },
                     (Rectangle) { (GetScreenWidth() - (float) gameWidth * menuScale) * 0.5f, (GetScreenHeight() - (float) gameHeight * menuScale) * 0.5f, gameWidth * menuScale, gameHeight * menuScale },
                     (Vector2) { 0.0f, 0.0f }, 0.0f, WHITE);
            EndDrawing();
            break;
      }
}

static void DrawNode(node_t * node)
{
   DrawRectangle(node->position.x, node->position.y, gridScale, gridScale, GREEN);
   DrawRectangleLines(node->position.x, node->position.y, gridScale, gridScale, BLACK);
}

void SpawnApple()
{
   // Prevents apple from spawning outside screen or inside the bottom and right walls
   int max = gridSize - 2;

   applePos.x = GetRandomValue(1, max) * gridScale;
   applePos.y = GetRandomValue(1, max) * gridScale + scoreMargin;
}
