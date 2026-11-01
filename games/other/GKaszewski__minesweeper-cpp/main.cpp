#include "MinesweeperGame.hpp"
#include "RaylibApp.hpp"
#include <string>

int main(int argc, char **argv) {
  int gridWidth = 9;
  int gridHeight = 9;
  int numMines = 10;

  if (argc == 4) {
    try {
      gridWidth = std::stoi(argv[1]);
      gridHeight = std::stoi(argv[2]);
      numMines = std::stoi(argv[3]);
    } catch (...) {
      // Ignore errors, use defaults
    }
  }

  MinesweeperGame game(gridWidth, gridHeight, numMines);

  RaylibApp app(game, 800, 600, "Minesweeper");

  app.run();

  return 0;
}