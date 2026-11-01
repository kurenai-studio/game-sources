#ifndef ASTEROID_H_
#define ASTEROID_H_

#include "raylib.h"
#include <stdlib.h>

#define ASTEROID_ROTATION_SPEED_MIN 5
#define ASTEROID_ROTATION_SPEED_MAX 240

/*
 * Struct representing the asteroids
 * */

typedef enum {
  SMALL_ASTEROID = 1,
  MEDIUM_ASTEROID = 3,
  LARGE_ASTEROID = 5,
} AsteroidSize;

typedef struct {
  bool isActive;
  AsteroidSize size;
  float rotation;
  float rotationSpeed;
  Vector2 velocity;
  Vector2 position;
} Asteroid;

Asteroid NewAsteroid(Vector2 postition, Vector2 velocity, AsteroidSize size);
void UpdateAsteroid(Asteroid *asteroid, float frameTime);
void DrawAsteroid(Asteroid *asteroid);
#endif
