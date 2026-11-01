#include "snake.h"

int main () {
     int factor = 100;
     Vector2 w = {
          .x = factor*16,
          .y = factor*9,
     };
     SetRandomSeed (clock());
     SetConfigFlags(FLAG_WINDOW_RESIZABLE);
     SetTraceLogLevel(LOG_ERROR);
     InitWindow (w.x, w.y, "Snake");
     Game *game = new Game (Menu, w, {0}, 0);
     SetTargetFPS(60);
     Vector2 canvas = {
          .x = w.x,
          .y = w.y/2,
     };
     Element title = {
          .box = {
               .x = canvas.x,
               .y = canvas.y,
               .width = 100,
               .height = 100,
          },
          .font_size = canvas.x/15,
          .bg = WHITE,
          .fg = BLACK,
          .texture = {0},
     };
     strcpy (title.label, "Snake");
     game->e.push_back (title);
     canvas.y = w.y;
     Element button1 = {
          .box = {
               .x = canvas.x,
               .y = canvas.y,
               .width = 100,
               .height = 100,
          },
          .font_size = canvas.x/20,
          .bg = WHITE,
          .fg = BLACK,
          .texture = {0},
     };
     strcpy (button1.label, "Play");
     game->e.push_back (button1);
     canvas.y = w.y + w.y/2;
     Element button2 = {
          .box = {
               .x = canvas.x,
               .y = canvas.y,
               .width = 100,
               .height = 100,
          },
          .font_size = canvas.x/20,
          .bg = WHITE,
          .fg = BLACK,
          .texture = {0},
     };
     strcpy (button2.label, "Quit");
     game->e.push_back (button2);
     Element score = {
          .box = {
               .x = w.x/60,
               .y = w.y/60,
               .width = w.x/60,
               .height = w.x/60,
          },
          .font_size = canvas.x/20,
          .bg = {
               .r = 255, .g = 255, .b = 255, .a = 0,
          },
          .fg = BLACK,
          .texture = {0},
     };
     game->e.push_back (score);

     Snake *snake = new Snake (NULL, 0.5f, DARKGREEN);
     Fruit *fruit = new Fruit (NULL, RED);
     while (!WindowShouldClose()) {
          w.x = GetScreenWidth();
          w.y = GetScreenHeight();
          game->set_canvas (w);
          BeginDrawing();
               ClearBackground (RAYWHITE);
               game->state_machine(snake, fruit);
          EndDrawing();
     }
     CloseWindow();
     return 0;
}
