#include <string.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include "raylib.h"
#include "raymath.h"

#define GRID_BLOCK_WIDTH 16
#define GRID_BLOCK_HEIGHT 16
#define SCREEN_WIDTH 1280
#define SCREEN_HEIGHT 720
#define BLOCKS_PER_ROW (int)(SCREEN_WIDTH / GRID_BLOCK_WIDTH)
#define BLOCKS_PER_COL (int)(SCREEN_HEIGHT / GRID_BLOCK_HEIGHT)
#define BLOCK_COUNT BLOCKS_PER_ROW * BLOCKS_PER_COL
#define PLAYER_STARTING_X ceil(BLOCKS_PER_ROW / 2)
#define PLAYER_STARTING_Y ceil(BLOCKS_PER_COL / 2)
#define TICK_TIMEOUT 0.2


typedef struct PlayerNode {
  Vector2 position;
  Vector2 direction;
} PlayerNode;

typedef struct Player {
  PlayerNode head;
  PlayerNode* tail;
  int size;
  int preallocated_tail;
} PLAYER;

Vector2 RandomPosition(){
  int x = rand() % BLOCKS_PER_ROW;
  int y = rand() % BLOCKS_PER_COL;
  return (Vector2){x, y};
}

bool ThereIsFoodInPosition(Vector2 position, Vector2* food, int food_count){
  for(int i = 0; i < food_count; i++){
    if (position.x == food[i].x && position.y == food[i].y){
      return true;
    }
  }
  return false;
}

Vector2 NewFoodLocation(Vector2* food, int food_count){
  Vector2 position = RandomPosition();
  if (!ThereIsFoodInPosition(position, food, food_count))
    return position;
  return NewFoodLocation(food, food_count);
}

void GrowPlayer(PLAYER* player){
  if (player->size + 1 > player->preallocated_tail) {
    PlayerNode* old_tail = malloc(sizeof(PlayerNode)*player->preallocated_tail);
    memcpy(old_tail, player->tail, sizeof(PlayerNode) * player->preallocated_tail);
    int new_prellocated_tail = player->preallocated_tail + 16;
    player->tail = malloc(sizeof(PlayerNode)*new_prellocated_tail);
    memcpy(player->tail, old_tail, sizeof(PlayerNode) * new_prellocated_tail);
    player->preallocated_tail = new_prellocated_tail;
  }
  if (player->size == 0) {
    player->tail[0].position = player->head.position;
  } else {
    player->tail[player->size].position = player->tail[player->size - 1].position;
  }
  player->size += 1;
}

void PropagateDirection(PLAYER* player) {
  Vector2 propagating_direction = player->head.direction;
  Vector2 swap_buffer;
  for(int i = 0; i < player->size; i++){
    swap_buffer = player->tail[i].direction;
    player->tail[i].direction = propagating_direction;
    propagating_direction = swap_buffer;
  }
}

void CalculatePlayerMovement(PLAYER* player){
  player->head.position = Vector2Add(player->head.position, player->head.direction);
  for(int i = 0; i < player->size; i++){
    player->tail[i].position = Vector2Add(
      player->tail[i].position,
      player->tail[i].direction
    );
  }
  PropagateDirection(player);
}

void Update(PLAYER* player, Vector2* food, int food_count){
  CalculatePlayerMovement(player);
  for(int i = 0; i < food_count; i++) {
    if (player->head.position.x == food[i].x && player->head.position.y == food[i].y){
      food[i] = NewFoodLocation(food, food_count);
      GrowPlayer(player);
      printf("Player Size: %d\n", player->size);
    }
  }
}


void DrawPlayer(PLAYER* player){
  DrawRectangle(
      GRID_BLOCK_WIDTH * player->head.position.x,
      GRID_BLOCK_HEIGHT * player->head.position.y,
      GRID_BLOCK_WIDTH,
      GRID_BLOCK_HEIGHT,
      GREEN
  );
  for(int i = 0; i < player->size; i++){
    DrawRectangle(
        GRID_BLOCK_WIDTH * player->tail[i].position.x,
        GRID_BLOCK_HEIGHT * player->tail[i].position.y,
        GRID_BLOCK_WIDTH,
        GRID_BLOCK_HEIGHT,
        GREEN
    );
  }
}

void DrawFood(Vector2* food, int amount){
  for(int i = 0; i < amount; i++)
    DrawRectangle(
        GRID_BLOCK_WIDTH * food[i].x,
        GRID_BLOCK_HEIGHT * food[i].y,
        GRID_BLOCK_WIDTH,
        GRID_BLOCK_HEIGHT,
        RED
    );
}

void DrawGameGrid(){
  for(int i = 0; i <= BLOCK_COUNT; i++){
    DrawRectangleLines(
        GRID_BLOCK_WIDTH * (i % BLOCKS_PER_ROW),
        GRID_BLOCK_HEIGHT * ((int)(i / BLOCKS_PER_ROW)),
        GRID_BLOCK_WIDTH,
        GRID_BLOCK_HEIGHT,
        (Color){0xC3,0xC3,0xC3,0xFF}
    );
  };
}

int main(int argc, char *argv[]){
  srand(time(NULL));
  PLAYER* player = malloc(sizeof(PLAYER));
  player->head = (PlayerNode){
    (Vector2){PLAYER_STARTING_X, PLAYER_STARTING_Y},
    (Vector2){1,0}
  };
  player->preallocated_tail = 16;
  player->size = 0;
  player->tail = malloc(sizeof(PlayerNode)*player->preallocated_tail);
  Vector2* food = malloc(8 * sizeof(Vector2));
  for(int i = 0; i < 8; i++)
    food[i] = NewFoodLocation(food, 8);
  float until_tick = TICK_TIMEOUT;

  InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "SNAKE");

  while (!WindowShouldClose()) {
    if (until_tick < 0) {
      Update(player, food, 8);
      until_tick = TICK_TIMEOUT;
    }

    until_tick -= GetFrameTime();

    // Handle Player Direction changes
    if (IsKeyDown(KEY_A) && player->head.direction.x == 0){
      player->head.direction = (Vector2){-1,0};
    } else if (IsKeyDown(KEY_D) && player->head.direction.x == 0){
      player->head.direction = (Vector2){1,0};
    }

    if (IsKeyDown(KEY_W) && player->head.direction.y == 0){
      player->head.direction = (Vector2){0,-1};
    } else if (IsKeyDown(KEY_S) && player->head.direction.y == 0) {
      player->head.direction = (Vector2){0,1};
    }

    BeginDrawing();
      ClearBackground(BLACK);
      DrawPlayer(player);
      DrawFood(food, 8);
      DrawGameGrid();
    EndDrawing();
  }

  CloseWindow();

  return 0;
}
