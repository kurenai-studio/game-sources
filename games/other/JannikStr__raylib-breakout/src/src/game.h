#ifndef BREAKOUT_GAME_H
#define BREAKOUT_GAME_H

#include "player.h"
#define BALL_SIZE 5
#define BALL_SPEED 350

#define BRICK_WIDTH 100
#define BRICK_HEIGHT 20

#include <raylib.h>

typedef struct {
    Vector2 pos;
    Vector2 direction;
} ball_t;

typedef struct {
    Vector2 pos;
    Color color;
    Color border_color;
    bool destroyed;
} brick_t;

void init_bricks(brick_t *bricks, int rows, int columns, Color *colors);

void draw_game_ball(const ball_t *ball);
bool move_game_ball(ball_t *ball, float delta);

brick_t* detect_brick_collision(ball_t *ball, brick_t *bricks, int rows, int cols);
void detect_player_collision(ball_t *ball, const player_t *player);


void draw_game_border();
void draw_bricks(const brick_t *bricks, int n);

void create_brick_particles(brick_t *destroyed_brick, Vector2* particles);
void draw_particles(Vector2 *particles, Color color);
void move_particles(Vector2 *particles, float delta);

bool player_won(brick_t *bricks, int n);

#endif // BREAKOUT_GAME_H
