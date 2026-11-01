#pragma once

#include "MinesweeperGame.hpp"
#include <raylib.h>

class RaylibRenderer {
public:
  RaylibRenderer();

  void draw(const MinesweeperGame &game, int screenWidth, int screenHeight);

  // Helper to calculate grid layout based on screen size
  struct Layout {
    int cellSize;
    int offsetX;
    int offsetY;
  };

  Layout calculateLayout(const MinesweeperGame &game, int screenWidth,
                         int screenHeight);

private:
  void drawCell(const Cell &cell, int x, int y, int cellSize, int offsetX,
                int offsetY);
};
