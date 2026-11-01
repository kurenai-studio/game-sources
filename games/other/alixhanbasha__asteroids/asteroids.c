#include "asteroids.h"

#include "raymath.h"
#include <raylib.h>

#define GAME_WIDTH 800
#define GAME_HEIGHT 800

Asteroid NewAsteroid(Vector2 postition, Vector2 velocity, AsteroidSize size) {
  return (Asteroid){
      .isActive = true,
      .size = size,
      .rotation = GetRandomValue(0, 360), // rand() % 360,
      .rotationSpeed = GetRandomValue(ASTEROID_ROTATION_SPEED_MIN,
                                      ASTEROID_ROTATION_SPEED_MAX),
      .velocity = velocity,
      .position = postition,
  };
}

void UpdateAsteroid(Asteroid *asteroid, float frameTime) {
  // ignore inactive asteroids
  if (!asteroid->isActive)
    return;

  // change the position
  asteroid->position = Vector2Add(asteroid->position,
                                  Vector2Scale(asteroid->velocity, frameTime));

  // rotate the asteroid
  asteroid->rotation += asteroid->rotationSpeed * frameTime;

  // if (asteroid->position.x < 0) {
  //   asteroid->position.x = 0;
  //   asteroid->velocity.x *= -1;
  // } else if (asteroid->position.x > GAME_WIDTH) {
  //   asteroid->position.x = GAME_WIDTH;
  //   asteroid->velocity.x *= -1;
  // }
  //
  // if (asteroid->position.y < 0) {
  //   asteroid->position.y = 0;
  //   asteroid->velocity.y *= -1;
  // } else if (asteroid->position.y > GAME_HEIGHT) {
  //   asteroid->position.y = GAME_HEIGHT;
  //   asteroid->velocity.y *= -1;
  // }
}

void DrawAsteroid(Asteroid *asteroid) {
  DrawPolyLines(asteroid->position, 3, 16 * (int)(asteroid->size),
                asteroid->rotation, WHITE);
}
