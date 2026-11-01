#include "MinesweeperGame.hpp"
#include <algorithm>
#include <numeric>
#include <random>

MinesweeperGame::MinesweeperGame(int width, int height, int num_mines)
    : m_width(width), m_height(height), m_num_mines(num_mines),
      m_flags_placed(0), m_state(GameState::Playing) {
  if (m_num_mines > m_width * m_height) {
    m_num_mines = m_width * m_height - 1;
  }
  reset();
}

void MinesweeperGame::reset() {
  m_grid.clear();
  m_grid.resize(m_width * m_height);
  m_safe_cells_revealed = 0;
  m_state = GameState::Playing;

  // Initialize cells
  for (int i = 0; i < m_width * m_height; ++i) {
    m_grid[i].is_mine = false;
    m_grid[i].is_revealed = false;
    m_grid[i].is_flagged = false;
    m_grid[i].num_adjacent_mines = 0;
  }

  m_is_first_move = true;
}

int MinesweeperGame::getIndex(int x, int y) const { return y * m_width + x; }

void MinesweeperGame::placeMines(int safeX, int safeY) {
  std::vector<int> indices;
  indices.reserve(m_width * m_height);

  int safeIndex = getIndex(safeX, safeY);

  for (int i = 0; i < m_width * m_height; ++i) {
    if (i != safeIndex) {
      indices.push_back(i);
    }
  }

  static std::random_device rd;
  static std::mt19937 g(rd());
  std::shuffle(indices.begin(), indices.end(), g);

  for (int i = 0; i < m_num_mines && i < static_cast<int>(indices.size());
       ++i) {
    m_grid[indices[i]].is_mine = true;
  }
}

void MinesweeperGame::calculateAdjacentMines() {
  for (int y = 0; y < m_height; ++y) {
    for (int x = 0; x < m_width; ++x) {
      if (!m_grid[getIndex(x, y)].is_mine) {
        m_grid[getIndex(x, y)].num_adjacent_mines = countAdjacentMines(x, y);
      }
    }
  }
}

int MinesweeperGame::countAdjacentMines(int x, int y) const {
  int count = 0;
  for (int dy = -1; dy <= 1; ++dy) {
    for (int dx = -1; dx <= 1; ++dx) {
      if (dx == 0 && dy == 0)
        continue;

      int nx = x + dx;
      int ny = y + dy;

      if (nx >= 0 && nx < m_width && ny >= 0 && ny < m_height) {
        if (m_grid[getIndex(nx, ny)].is_mine) {
          count++;
        }
      }
    }
  }
  return count;
}

void MinesweeperGame::revealCell(int x, int y) {
  if (m_state != GameState::Playing)
    return;
  if (x < 0 || x >= m_width || y < 0 || y >= m_height)
    return;

  if (m_is_first_move) {
    placeMines(x, y);
    calculateAdjacentMines();
    m_is_first_move = false;
  }

  Cell &cell = m_grid[getIndex(x, y)];

  if (cell.is_revealed || cell.is_flagged)
    return;

  cell.is_revealed = true;
  if (!cell.is_mine) {
    m_safe_cells_revealed++;
  }

  if (cell.is_mine) {
    m_state = GameState::Lost;
    revealAllMines();
  } else {
    if (cell.num_adjacent_mines == 0) {
      revealAdjacentEmptyCells(x, y);
    }
    checkWinCondition();
  }
}

void MinesweeperGame::revealAdjacentEmptyCells(int startX, int startY) {
  std::vector<std::pair<int, int>> stack;
  stack.push_back({startX, startY});

  while (!stack.empty()) {
    auto [x, y] = stack.back();
    stack.pop_back();

    for (int dy = -1; dy <= 1; ++dy) {
      for (int dx = -1; dx <= 1; ++dx) {
        int nx = x + dx;
        int ny = y + dy;

        if (nx >= 0 && nx < m_width && ny >= 0 && ny < m_height) {
          Cell &neighbor = m_grid[getIndex(nx, ny)];
          if (!neighbor.is_revealed && !neighbor.is_mine &&
              !neighbor.is_flagged) {
            neighbor.is_revealed = true;
            m_safe_cells_revealed++;
            if (neighbor.num_adjacent_mines == 0) {
              stack.push_back({nx, ny});
            }
          }
        }
      }
    }
  }
}

void MinesweeperGame::toggleFlag(int x, int y) {
  if (m_state != GameState::Playing)
    return;
  if (x < 0 || x >= m_width || y < 0 || y >= m_height)
    return;

  Cell &cell = m_grid[getIndex(x, y)];
  if (cell.is_revealed)
    return;

  if (cell.is_flagged) {
    cell.is_flagged = false;
    m_flags_placed--;
  } else {
    if (m_flags_placed < m_num_mines) {
      cell.is_flagged = true;
      m_flags_placed++;
    }
  }
}

void MinesweeperGame::checkWinCondition() {
  int total_safe_cells = (m_width * m_height) - m_num_mines;
  if (m_safe_cells_revealed == total_safe_cells) {
    m_state = GameState::Won;
  }
}

void MinesweeperGame::revealAllMines() {
  for (auto &cell : m_grid) {
    if (cell.is_mine) {
      cell.is_revealed = true;
    }
  }
}

const std::vector<Cell> &MinesweeperGame::getGrid() const { return m_grid; }

int MinesweeperGame::getWidth() const { return m_width; }
int MinesweeperGame::getHeight() const { return m_height; }
GameState MinesweeperGame::getState() const { return m_state; }
int MinesweeperGame::getMinesCount() const { return m_num_mines; }
int MinesweeperGame::getFlagsCount() const { return m_flags_placed; }
