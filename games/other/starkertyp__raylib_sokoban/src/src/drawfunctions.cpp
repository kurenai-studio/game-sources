#include "drawfunctions.hpp"
#include "constants.hpp"
#include "map.hpp"

void DrawWall(const int i, const int mapwidth, const Color color) {
  int x = RENDEROFFSETX + (GetGridXPosition(i, mapwidth) * TILESIZE);
  int y = RENDEROFFSETY + (GetGridYPosition(i, mapwidth) * TILESIZE);
  DrawRectangle(x, y, TILESIZE, TILESIZE, color);
}

void DrawBox(const int i, const int mapwidth, const Color color) {
  int size = TILESIZE - 8;
  int x = RENDEROFFSETX + (GetGridXPosition(i, mapwidth) * TILESIZE) + 4;
  int y = RENDEROFFSETY + (GetGridYPosition(i, mapwidth) * TILESIZE) + 4;
  DrawRectangle(x, y, size, size, color);
}

void DrawTileOutline(const int i, const int mapwidth, const Color color) {
  int x = RENDEROFFSETX + (GetGridXPosition(i, mapwidth) * TILESIZE);
  int y = RENDEROFFSETY + (GetGridYPosition(i, mapwidth) * TILESIZE);
  DrawRectangleLines(x, y, TILESIZE, TILESIZE, color);
}
void DrawPlayer(const int i, const int mapwidth, const Color color) {
  int indent = 4;
  int size = (TILESIZE / 2) - indent;
  int x = RENDEROFFSETX + (GetGridXPosition(i, mapwidth) * TILESIZE) + size + indent;
  int y = RENDEROFFSETY + (GetGridYPosition(i, mapwidth) * TILESIZE) + size + indent;
  DrawCircle(x, y, size, color);
}
