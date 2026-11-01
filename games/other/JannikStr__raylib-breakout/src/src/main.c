#include "game.h"
#include "player.h"
#include <stdio.h>
#include <raylib.h>
#include <raymath.h>

#define ROWS 4
#define COLS 12
#define DEFAULT_PARTICLES_TTL 0.5

static void init_game(brick_t *bricks, player_t *player, ball_t *ball, Color *colors);
static void draw(brick_t *bricks, player_t *player, ball_t *ball);

int main(void)
{
  bool is_running = true;

  InitWindow(1280, 720, "BreakOut");
  SetTargetFPS(60);
  SetExitKey(KEY_NULL);

  player_t player;
  ball_t ball;
  brick_t bricks[ROWS*COLS];

  Color colors[ROWS] = {
    GREEN,
    BLUE,
    YELLOW,
    RED
  };

  init_game(bricks, &player, &ball, colors);

  brick_t *destroyed_brick = 0;
  brick_t *current_brick = 0;
  Vector2 particles[10];
  float particles_ttl = DEFAULT_PARTICLES_TTL;

  const int you_win_width = MeasureText("You Win", 60);
  const int game_over_width = MeasureText("Game Over", 60);
  const int restart_width = MeasureText("Press Space to Restart", 40);

  while (!WindowShouldClose()) {
    if(is_running) {
      if(IsKeyDown(KEY_LEFT)) {
        move_player(&player, GetFrameTime(), -1);
      } else if(IsKeyDown(KEY_RIGHT)) {
        move_player(&player, GetFrameTime(), 1);
      }

      is_running = move_game_ball(&ball, GetFrameTime());
      detect_player_collision(&ball, &player);

      if(destroyed_brick) {
        move_particles(particles, GetFrameTime());
        particles_ttl -= GetFrameTime();
      }

      current_brick = detect_brick_collision(&ball, bricks, ROWS, COLS);
      if(current_brick) {
        particles_ttl = DEFAULT_PARTICLES_TTL;
        destroyed_brick = current_brick;
        create_brick_particles(destroyed_brick, particles);
      }

      if(particles_ttl < 0 && destroyed_brick) {
        destroyed_brick = 0;
      } else if(particles_ttl > 0 && destroyed_brick) {
        draw_particles(particles, destroyed_brick->color);
      }

      if (IsKeyPressed(KEY_F)) {
        ToggleFullscreen();
      }
    } else {
      if(IsKeyPressed(KEY_SPACE)) {
        is_running = true;
        init_game(bricks, &player, &ball, colors);
      }
    }
    BeginDrawing();
    ClearBackground(BLACK);

    draw(bricks, &player, &ball);

    if (!is_running) {
      if(player_won(bricks, ROWS*COLS)) {
        DrawText("You Win", (GetScreenWidth() - you_win_width)/2, GetScreenHeight()/2 - 30, 60, DARKGREEN);
      } else {
        DrawText("Game Over", (GetScreenWidth() - game_over_width)/2, GetScreenHeight()/2 - 30, 60, DARKBLUE);
      }
      DrawText("Press Space to Restart", (GetScreenWidth() - restart_width)/2, (GetScreenHeight()/2) + 60, 40, BLUE);
    }
    DrawFPS(20, 20);
    EndDrawing();

    if (is_running && player_won(bricks, ROWS*COLS)) {
      is_running = false;
    }
  }
  CloseWindow();
}

static void init_game(brick_t *bricks, player_t *player, ball_t *ball, Color *colors)
{

  init_bricks(bricks, ROWS, COLS, colors);

  Vector2 direction_vec = {.x = 1, .y = 2};
  ball->pos.x = GetScreenWidth()/2.;
  ball->pos.y = 250;
  ball->direction = Vector2Normalize(direction_vec);

  player->pos.x = (GetScreenWidth()-PLAYER_WIDTH)/2.;
  player->pos.y = GetScreenHeight() - 50;

}

static void draw(brick_t *bricks, player_t *player, ball_t *ball)
{
    draw_player(player);
    draw_game_ball(ball);
    draw_game_border();
    draw_bricks(bricks, ROWS*COLS);
}
