#include "game.h"
#include "raylib.h"
#include "stdlib.h"
#include <stdio.h>
#include "time.h"

#define min(x,y) (x < y) ? x : y

void init_bricks(brick_t *bricks, int rows, int columns, Color *colors)
{
    srand(time(NULL));
    const int FIELD_WIDTH = GetScreenWidth() - 30;
    const int HSPACING = min(FIELD_WIDTH/(columns+1) - BRICK_WIDTH, 10);
    const int VSPACING = 5;
    const int START_X = 15 + (FIELD_WIDTH - columns*(BRICK_WIDTH + HSPACING))/2;

    for(int y = 0; y < rows; ++y)
    {
        Color color = (colors == 0) ? GREEN : colors[y];
        for(int x = 0; x < columns; ++x)
        {
            const int idx = y*columns + x;
            bricks[idx].pos.x = START_X + x*(BRICK_WIDTH+HSPACING);
            bricks[idx].pos.y = 10 + VSPACING + y*(BRICK_HEIGHT + VSPACING);
            bricks[idx].color = color;
            bricks[idx].border_color = DARKGRAY;
            bricks[idx].destroyed = false;
        }
    }
}

void draw_bricks(const brick_t *bricks, int n){
    for(int i = 0; i < n; ++i)
    {
        const brick_t *b = &bricks[i];
        if(!b->destroyed) {
            DrawRectangle(b->pos.x, b->pos.y, BRICK_WIDTH, BRICK_HEIGHT, b->color);
            DrawRectangleLines(b->pos.x, b->pos.y, BRICK_WIDTH, BRICK_HEIGHT, b->border_color);
        }
    }
}

void draw_game_ball(const ball_t *ball)
{
    DrawCircleV(ball->pos, BALL_SIZE, WHITE);
}

bool move_game_ball(ball_t *ball, float delta)
{
    ball->pos.x += ball->direction.x * delta * BALL_SPEED;
    ball->pos.y += ball->direction.y * delta * BALL_SPEED;

    if (ball->pos.y >= GetScreenHeight())
    {
        ball->direction.y *= -1;
        return false;
    }
    else if(ball->pos.y <= 15)
    {
        ball->direction.y *= -1;
    }

    if ((ball->pos.x - 5 <= 15 && ball->direction.x < 0) || (ball->pos.x >= GetScreenWidth() - 20 && ball->direction.x > 0)) {
        ball->direction.x *= -1;
    }
    return true;
}

brick_t* detect_brick_collision(ball_t *ball, brick_t *bricks, int rows, int cols)
{
    for(int x = 0; x < cols; ++x)
    {
        if (ball->pos.x + BALL_SIZE < bricks[x].pos.x || ball->pos.x - BALL_SIZE > bricks[x].pos.x + BRICK_WIDTH) {
            continue;
        }
        for(int y = rows - 1; y >= 0; --y)
        {
            const int idx = y*cols + x;
            if (bricks[idx].destroyed) {
                continue;
            }
            if(ball->pos.y + BALL_SIZE >= bricks[idx].pos.y && ball->pos.y - BALL_SIZE <= bricks[idx].pos.y + BRICK_HEIGHT) {
                ball->direction.y *= -1;
                bricks[idx].destroyed = true;
                return &bricks[idx];
            }
        }
    }
    return 0;
}

void detect_player_collision(ball_t *ball, const player_t *player)
{
    if (
        ball->pos.x + BALL_SIZE >= player->pos.x
        && ball->pos.x - BALL_SIZE <= player->pos.x + PLAYER_WIDTH
        && ball->pos.y + BALL_SIZE >= player->pos.y
        && ball->pos.y - BALL_SIZE <= player->pos.y + BRICK_HEIGHT/2.
        && ball->direction.y > 0
    ) {
        if (rand() % 10 < 2) {
            ball->direction.x *= -1;
        }
        ball->direction.y *= -1;
    }


}

void draw_game_border()
{
    static float hue = 0;
    hue += GetFrameTime();
    if(hue > 1.) {
        hue = 0;
    }
    Color color = ColorFromHSV(hue, .08, .92);
    DrawRectangle(0, 0, 15, GetScreenHeight(), color);
    DrawRectangle(15, 0, GetScreenWidth()-30, 10, color);
    DrawRectangle(GetScreenWidth()-15, 0, 15, GetScreenHeight(), color);
}

void create_brick_particles(brick_t *destroyed_brick, Vector2* particles)
{
    for(int i = 0; i < 10; i++)
    {
        particles[i].x = destroyed_brick->pos.x + (rand() % BRICK_WIDTH);
        particles[i].y = destroyed_brick->pos.y + (rand() % BRICK_HEIGHT);
    }
}


void draw_particles(Vector2 *particles, Color color)
{
    const Vector2 size = {4, 4};
    for(int i = 0; i < 10; ++i)
    {
        DrawRectangleV(particles[i], size, color);
    }
}

void move_particles(Vector2 *particles, float delta)
{
    for(int i = 0; i < 10; ++i)
    {
        particles[i].y += 50*delta;
        particles[i].x += (rand()%5 - 2)*100 * delta;
    }
}


bool player_won(brick_t *bricks, int n)
{
    for (int i = 0; i < n; ++i) {
        if (!bricks[i].destroyed) {
            return false;
        }
    }
    return true;
}
