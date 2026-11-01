#include "board.h"

#include <stdexcept>

Direction GetOppositeDirection(Direction direction) {
  switch (direction) {
    case UP:
      return DOWN;
    case DOWN:
      return UP;
    case LEFT:
      return RIGHT;
    case RIGHT:
      return LEFT;
  }
  throw std::invalid_argument("invalid direction");
}

CellDelta GetDeltaFromDirection(Direction direction) {
  switch (direction) {
    case UP:
      return {-1, 0};
    case DOWN:
      return {1, 0};
    case LEFT:
      return {0, -1};
    case RIGHT:
      return {0, 1};
  }
  throw std::invalid_argument("invalid direction");
}

Cell::Cell() {}

Cell::Cell(int r, int c) : r(r), c(c) {}

Cell::Cell(const Cell& cell) : r(cell.r), c(cell.c) {}

bool Cell::operator==(const Cell& rhs) const {
  return r == rhs.r && c == rhs.c;
}

void Cell::operator+=(const CellDelta& delta) {
  r += delta.r;
  c += delta.c;
}

void Cell::operator-=(const CellDelta& delta) { *this += (-delta); }

Cell Cell::operator+(const CellDelta& delta) const {
  Cell copy = *this;
  copy += delta;
  return copy;
}

Cell Cell::operator-(const CellDelta& delta) const { return *this + (-delta); }

void Cell::operator+=(const Direction& direction) {
  CellDelta delta = GetDeltaFromDirection(direction);
  *this += delta;
}

void Cell::operator-=(const Direction& direction) {
  CellDelta delta = -GetDeltaFromDirection(direction);
  *this += delta;
}

Cell Cell::operator+(const Direction& direction) const {
  Cell copy = *this;
  copy += direction;
  return copy;
}

Cell Cell::operator-(const Direction& direction) const {
  return *this + GetOppositeDirection(direction);
}

CellDelta::CellDelta(){};

CellDelta::CellDelta(int r, int c) : r(r), c(c){};

CellDelta::CellDelta(const CellDelta& delta) {
  r = delta.r;
  c = delta.c;
}

CellDelta CellDelta::operator-() const { return {-r, -c}; }
