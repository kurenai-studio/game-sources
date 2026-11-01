#include "player.h"
#include "math.h"
#include "raylib.h"

void draw_player(const player_t *player)
{
    DrawRectangle(player->pos.x, player->pos.y, PLAYER_WIDTH, PLAYER_HEIGHT, DARKGRAY);
    DrawRectangleLines(player->pos.x, player->pos.y, PLAYER_WIDTH, PLAYER_HEIGHT, WHITE);
}

void move_player(player_t *player, float delta, int direction)
{
    direction = direction == 0 ? 0 : (direction < 0 ? -1 : 1);
    player->pos.x += direction * delta * PLAYER_SPEED;
    if(player->pos.x <= 15)
    {
        player->pos.x = 15;
    }
    else if(player->pos.x + PLAYER_WIDTH >= GetScreenWidth() - 15)
    {
        player->pos.x = GetScreenWidth() - 15 - PLAYER_WIDTH;
    }
}

