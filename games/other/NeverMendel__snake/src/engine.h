#ifndef ENGINE_ENGINE_H
#define ENGINE_ENGINE_H

#include "board.h"
#include "game.h"
#include "graphic.h"

class Engine {
 public:
  Engine();

  void Play();

 private:
  Game game;
  Graphic graphic;
};

#endif