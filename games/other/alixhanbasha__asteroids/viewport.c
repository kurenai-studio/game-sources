#include "viewport.h"
#include "raylib.h"
#include <math.h>

// Create a new scaling viewport
Viewport NewViewport(int screenW, int screenH, int gameW, int gameH) {
  Viewport vp = {0};

  vp.scale = fminf((float)screenW / gameW, (float)screenH / gameH);

  vp.rect = (Rectangle){(screenW - gameW * vp.scale) * 0.5f,
                        (screenH - gameH * vp.scale) * 0.5f, gameW * vp.scale,
                        gameH * vp.scale};

  return vp;
}

// Translate global screen corrdinates to
// game corrdinates (i.e display stuff into the viewport instead of the global
// screen space)
Vector2 ScreenCoordinatesToGameCoordinates(Vector2 screenCoordinates,
                                           Viewport *vp) {
  return (Vector2){(screenCoordinates.x - vp->rect.x) / vp->scale,
                   (screenCoordinates.y - vp->rect.y) / vp->scale};
}

bool Vector2IsInViewport(Vector2 coordinates, Viewport *vp) {
  return CheckCollisionPointRec(coordinates, vp->rect);
}
