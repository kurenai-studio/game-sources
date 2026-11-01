#ifndef DRAWFUNCTIONS_H
#define DRAWFUNCTIONS_H

#include "../raylib/src/raylib.h"

void DrawWall(const int i, const int mapwidth, const Color color);
void DrawBox(const int i, const int mapwidth, const Color color);
void DrawTileOutline(const int i, const int mapwidth, const Color color);
void DrawPlayer(const int i, const int mapwidth, const Color color);

#endif /* DRAWFUNCTIONS_H */
