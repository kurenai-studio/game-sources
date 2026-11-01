#ifndef BREAKOUT_PLAYER_C
#define BREAKOUT_PLAYER_C
#include <raylib.h>

#define PLAYER_WIDTH 100
#define PLAYER_HEIGHT 20
#define PLAYER_SPEED 300

typedef struct {
  Vector2 pos;
} player_t;

void draw_player(const player_t *player);
void move_player(player_t *player, float delta, int direction);

#endif // BREAKOUT_PLAYER_C
