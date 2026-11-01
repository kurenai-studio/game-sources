#ifndef GAME_GAME_H
#define GAME_GAME_H

#include <list>
#include <vector>

#include "board.h"

typedef std::vector<std::vector<CellContent>> Board;

enum GameStatus { PLAYING, ENDED };

class Game {
 public:
  Game();
  Game(int rows, int cols);

  GameStatus Move();
  bool ChangeDirection(Direction direction);

  void Reset();

  GameStatus GetStatus() const;
  int GetScore() const;
  int GetHighestScore() const;
  const Board& GetBoard() const;
  const std::list<Cell>& GetSnake() const;
  const Cell& GetApple() const;

 private:
  int rows;
  int cols;
  Board board;
  std::list<Cell> snake;
  Cell apple;
  int highest_score;
  GameStatus status;
  Direction snake_direction;
  Direction snake_next_direction;

  void GenerateRandomApple();
  void GenerateSnake();
};

#endif