#include "asteroids.h"
#include "viewport.h"
#include <raylib.h>

#define WIDTH 1280
#define HEIGHT 720
#define GAME_WIDTH 800
#define GAME_HEIGHT 800
#define NEAR_BLACK CLITERAL(Color){15, 15, 15, 255}
#define MAX_ASTEROIDS 64

static AsteroidSize sizes[] = {SMALL_ASTEROID, MEDIUM_ASTEROID, LARGE_ASTEROID};
static Asteroid asteroids[MAX_ASTEROIDS] = {0};
RenderTexture2D gameTarget;

void AddNewAsteroid(Vector2 position, Vector2 velocity, AsteroidSize size) {
  bool wasCreated = false;

  for (int i = 0; i < MAX_ASTEROIDS; i++) {
    if (asteroids[i].isActive)
      continue;

    asteroids[i] = NewAsteroid(position, velocity, size);
    wasCreated = true;
    break;
  }

  if (!wasCreated) {
    TraceLog(LOG_ERROR, "Could not create an asteroid");
  }
}

void GameUpdate(Viewport *viewport) {
  float frameTime = GetFrameTime();

  for (int i = 0; i < MAX_ASTEROIDS; i++) {
    UpdateAsteroid(&asteroids[i], frameTime);
  }

  if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
    Vector2 mouse = GetMousePosition();

    if (Vector2IsInViewport(mouse, viewport)) {
      AsteroidSize size = sizes[GetRandomValue(0, 2)];
      Vector2 viewport_position =
          ScreenCoordinatesToGameCoordinates(mouse, viewport);

      AddNewAsteroid(viewport_position, (Vector2){200, 0}, size);
    }
  }

  // if (IsKeyPressed(KEY_SPACE)) {
  //   AddNewAsteroid((Vector2){GAME_WIDTH / 2, GAME_HEIGHT / 2},
  //                  (Vector2){200, 0}, sizes[GetRandomValue(0, 2)]);
  // }

  BeginTextureMode(gameTarget);
  ClearBackground(NEAR_BLACK);
  for (int i = 0; i < MAX_ASTEROIDS; i++) {
    DrawAsteroid(&asteroids[i]);
  }
  EndTextureMode();
}

int main(void) {
  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(WIDTH, HEIGHT, "Ateroids Clone in C");
  SetTargetFPS(60);

  gameTarget = LoadRenderTexture(GAME_WIDTH, GAME_HEIGHT);
  SetTextureFilter(gameTarget.texture, TEXTURE_FILTER_BILINEAR);

  while (!WindowShouldClose()) {
    int screenW = GetScreenWidth();
    int screenH = GetScreenHeight();

    Viewport viewport = NewViewport(screenW, screenH, GAME_WIDTH, GAME_HEIGHT);

    GameUpdate(&viewport);

    BeginDrawing();
    DrawFPS(10, 10);
    ClearBackground(BLACK);

    Rectangle src = {0, 0, GAME_WIDTH, -GAME_HEIGHT};

    DrawTexturePro(gameTarget.texture, src, viewport.rect, (Vector2){0, 0},
                   0.0f, WHITE);

    DrawRectangleLinesEx(viewport.rect, 2, WHITE);
    EndDrawing();
  }
  UnloadRenderTexture(gameTarget);
  CloseWindow();
}
