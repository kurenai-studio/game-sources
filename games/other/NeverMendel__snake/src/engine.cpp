#include "engine.h"

#include <chrono>
#include <thread>

Engine::Engine() {}

void Engine::Play() {
  graphic.DisplayGame(game);
  std::this_thread::sleep_for(std::chrono::microseconds(100000));
  while (true) {
    for (int i = 0; i < 80; i++) {
      if (graphic.HasDirection()) {
        Direction dir = graphic.GetDirection();
        game.ChangeDirection(dir);
      }
      std::this_thread::sleep_for(std::chrono::microseconds(1000));
    }
    game.Move();
    graphic.DisplayGame(game);
    if (game.GetStatus() == ENDED) {
      std::this_thread::sleep_for(std::chrono::seconds(1));
      game.Reset();
      graphic.DisplayGame(game);
    }
  }
}