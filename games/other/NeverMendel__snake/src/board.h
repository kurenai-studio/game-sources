#ifndef BOARD_BOARD_H
#define BOARD_BOARD_H

#include <vector>

enum Direction { UP = 0, DOWN = 1, LEFT = 2, RIGHT = 3 };

struct CellDelta;

struct Cell {
  int r;
  int c;

  Cell();
  Cell(int r, int c);
  Cell(const Cell& cell);

  bool operator==(const Cell& rhs) const;

  void operator+=(const CellDelta& delta);
  void operator-=(const CellDelta& delta);
  Cell operator+(const CellDelta& delta) const;
  Cell operator-(const CellDelta& delta) const;

  void operator+=(const Direction& direction);
  void operator-=(const Direction& direction);
  Cell operator+(const Direction& direction) const;
  Cell operator-(const Direction& direction) const;
};

struct CellDelta {
  int r;
  int c;

  CellDelta();
  CellDelta(int r, int c);
  CellDelta(const CellDelta& delta);

  CellDelta operator-() const;
};

enum CellContent { EMPTY, SNAKE, APPLE };

Direction GetOppositeDirection(Direction direction);

#endif