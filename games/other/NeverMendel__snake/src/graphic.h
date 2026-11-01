#ifndef GRAPHIC_GRAPHIC_H
#define GRAPHIC_GRAPHIC_H

#include "game.h"

class Graphic {
 public:
  Graphic();
  Graphic(int rows, int cols);

  ~Graphic();

  void DisplayGame(const Game& game);
  Direction GetDirection() const;
  bool HasDirection() const;

 private:
  int rows;
  int cols;

  const int kScreenWidth = 900;
  const int kScreenHeight = 900;
};

#endif