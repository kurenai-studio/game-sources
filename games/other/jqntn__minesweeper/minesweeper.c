#include "raylib.h"

/* TODO:
 * - resolution scale factor
 */

/**/

#define NULL ((void*)0)

#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

/**/

#define EASY_COL_COUNT 9
#define EASY_ROW_COUNT 9

#define MEDIUM_COL_COUNT 16
#define MEDIUM_ROW_COUNT 16

#define HARD_COL_COUNT 30
#define HARD_ROW_COUNT 16

/**/

#define DEFAULT_TILE_W 16
#define DEFAULT_TILE_H 16

/**/

#define REF_SCREEN_H 1080

/**/

#define WINDOW_SCALE 2

#define WINDOW_TITLE "Minesweeper"

int
main(void)
{
  int defaultWindowW = DEFAULT_TILE_W * MEDIUM_COL_COUNT * WINDOW_SCALE;
  int defaultWindowH = DEFAULT_TILE_H * MEDIUM_ROW_COUNT * WINDOW_SCALE;

  const char* p_WindowTitle = WINDOW_TITLE;

  if (NULL == p_WindowTitle) {
    return EXIT_FAILURE;
  }

  InitWindow(defaultWindowW, defaultWindowH, p_WindowTitle);
  SetWindowState(FLAG_VSYNC_HINT);

  while (!WindowShouldClose()) {
    BeginDrawing();

    ClearBackground(RAYWHITE);

    EndDrawing();
  }

  CloseWindow();

  return EXIT_SUCCESS;
}