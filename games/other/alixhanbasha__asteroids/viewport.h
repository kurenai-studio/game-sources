#ifndef VIEWPORT_H_
#define VIEWPORT_H_

#include "raylib.h"

typedef struct {
  float scale;
  Rectangle rect;
} Viewport;

Viewport NewViewport(int screenW, int screenH, int gameW, int gameH);
Vector2 ScreenCoordinatesToGameCoordinates(Vector2 screenCoordinates,
                                           Viewport *vp);
bool Vector2IsInViewport(Vector2 coordinates, Viewport *vp);

#endif // !VIEWPORT_H_
