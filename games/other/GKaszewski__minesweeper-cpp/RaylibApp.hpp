#pragma once

#include "MinesweeperGame.hpp"
#include "RaylibRenderer.hpp"

class RaylibApp {
public:
  RaylibApp(MinesweeperGame &game, int width, int height, const char *title);
  ~RaylibApp();

  void run();
  void runOneFrame();

private:
  MinesweeperGame &m_game;
  RaylibRenderer m_renderer;
  // Window state
  int m_windowWidth;
  int m_windowHeight;

  void processInput(const RaylibRenderer::Layout &layout);
};
