#pragma once

#include <random>
#include <vector>

enum class GameState { Playing, Won, Lost };

struct Cell {
  bool is_mine = false;
  bool is_revealed = false;
  bool is_flagged = false;
  int num_adjacent_mines = 0;
};

class MinesweeperGame {
public:
  MinesweeperGame(int width, int height, int num_mines);

  void reset();
  void revealCell(int x, int y);
  void toggleFlag(int x, int y);

  // Getters
  const std::vector<Cell> &getGrid() const;
  int getWidth() const;
  int getHeight() const;
  GameState getState() const;
  int getMinesCount() const;
  int getFlagsCount() const;

private:
  int m_width;
  int m_height;
  int m_num_mines;
  int m_flags_placed;
  int m_safe_cells_revealed;
  GameState m_state;
  std::vector<Cell> m_grid;

  // Helpers
  int getIndex(int x, int y) const;
  void placeMines(int safeX, int safeY);
  void calculateAdjacentMines();
  int countAdjacentMines(int x, int y) const;
  void revealAdjacentEmptyCells(int x, int y);
  void checkWinCondition();
  void revealAllMines();

  bool m_is_first_move;
};
