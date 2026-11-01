#include "RaylibRenderer.hpp"
#include <string>

RaylibRenderer::RaylibRenderer() {}

RaylibRenderer::Layout
RaylibRenderer::calculateLayout(const MinesweeperGame &game, int screenWidth,
                                int screenHeight) {
  int gridW = game.getWidth();
  int gridH = game.getHeight();

  // Avoid division by zero
  if (gridW == 0 || gridH == 0)
    return {40, 0, 0};

  int cellSizeX = screenWidth / gridW;
  int cellSizeY = screenHeight / gridH;
  int cellSize = (cellSizeX < cellSizeY) ? cellSizeX : cellSizeY;

  // Clamp max cell size for aesthetics if window is huge
  // if (cellSize > 100) cellSize = 100;

  int totalGridWidth = cellSize * gridW;
  int totalGridHeight = cellSize * gridH;

  int offsetX = (screenWidth - totalGridWidth) / 2;
  int offsetY = (screenHeight - totalGridHeight) / 2;

  return {cellSize, offsetX, offsetY};
}

void RaylibRenderer::draw(const MinesweeperGame &game, int screenWidth,
                          int screenHeight) {
  Layout layout = calculateLayout(game, screenWidth, screenHeight);
  const auto &grid = game.getGrid();

  int width = game.getWidth();
  int height = game.getHeight();

  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      int index = y * width + x;
      drawCell(grid[index], x, y, layout.cellSize, layout.offsetX,
               layout.offsetY);
    }
  }

  if (game.getState() != GameState::Playing) {
    const char *text = (game.getState() == GameState::Won)
                           ? "You Won! 'R' to Restart"
                           : "Game Over! 'R' to Restart";
    int fontSize = 20;
    int textWidth = MeasureText(text, fontSize);
    DrawText(text, (screenWidth - textWidth) / 2, 20, fontSize, PINK);
  } else {
    std::string flagText =
        "Mines: " + std::to_string(game.getMinesCount() - game.getFlagsCount());
    DrawText(flagText.c_str(), 10, 10, 20, DARKGRAY);
  }
}

void RaylibRenderer::drawCell(const Cell &cell, int x, int y, int cellSize,
                              int offsetX, int offsetY) {
  int posX = offsetX + x * cellSize;
  int posY = offsetY + y * cellSize;
  int gap = 2;

  if (cell.is_revealed) {
    DrawRectangle(posX + gap, posY + gap, cellSize - gap, cellSize - gap,
                  DARKGRAY);
    DrawRectangleLines(posX + gap, posY + gap, cellSize - gap, cellSize - gap,
                       LIGHTGRAY);

    if (cell.is_mine) {
      DrawCircle(posX + cellSize / 2, posY + cellSize / 2, cellSize / 4, RED);
    } else if (cell.num_adjacent_mines > 0) {
      std::string numText = std::to_string(cell.num_adjacent_mines);
      int fontSize = cellSize / 2;
      int textW = MeasureText(numText.c_str(), fontSize);
      DrawText(numText.c_str(), posX + (cellSize - textW) / 2,
               posY + (cellSize - fontSize) / 2, fontSize, BLUE);
    }
  } else {
    DrawRectangle(posX + gap, posY + gap, cellSize - gap, cellSize - gap,
                  BLACK);
    DrawRectangleLines(posX + gap, posY + gap, cellSize - gap, cellSize - gap,
                       LIGHTGRAY);

    if (cell.is_flagged) {
      int fontSize = static_cast<int>(cellSize / 1.5f);
      int textW = MeasureText("F", fontSize);
      DrawText("F", posX + (cellSize - textW) / 2,
               posY + (cellSize - fontSize) / 2, fontSize, GREEN);
    }
  }
}
