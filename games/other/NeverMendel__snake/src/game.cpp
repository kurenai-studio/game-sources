#include "game.h"

#include <stdlib.h>
#include <time.h>

Game::Game() : Game(25, 25) {}

Game::Game(int rows, int cols)
    : rows(rows),
      cols(cols),
      board(rows, std::vector<CellContent>(cols)),
      highest_score(0) {
  srand(time(NULL));
  Reset();
}

GameStatus Game::Move() {
  if (status == ENDED) return status;
  snake_direction = snake_next_direction;
  Cell snake_head = snake.front();
  snake_head += snake_direction;
  if (snake_head.r < 0 || snake_head.r >= rows || snake_head.c < 0 ||
      snake_head.c >= cols) {
    status = ENDED;
    return status;
  }
  if (board[snake_head.r][snake_head.c] == SNAKE) {
    status = ENDED;
    return status;
  }
  snake.push_front(snake_head);
  board[snake_head.r][snake_head.c] = SNAKE;

  if (snake_head == apple) {
    GenerateRandomApple();
    highest_score = std::max(highest_score, GetScore());
  } else {
    const Cell& tail = snake.back();
    board[tail.r][tail.c] = EMPTY;
    snake.pop_back();
  }

  return status;
}

bool Game::ChangeDirection(Direction direction) {
  if (status == ENDED) return false;
  if (direction == GetOppositeDirection(snake_direction)) return false;
  snake_next_direction = direction;
  return true;
}

void Game::Reset() {
  status = PLAYING;
  for (auto& vec : board) {
    std::fill(vec.begin(), vec.end(), EMPTY);
  }
  GenerateSnake();
  GenerateRandomApple();
}

GameStatus Game::GetStatus() const { return status; }

int Game::GetScore() const { return (snake.size() - 3) * 100; }

int Game::GetHighestScore() const { return highest_score; }

const Board& Game::GetBoard() const { return board; }

const std::list<Cell>& Game::GetSnake() const { return snake; }

const Cell& Game::GetApple() const { return apple; };

void Game::GenerateRandomApple() {
  if (snake.size() >= (size_t)rows * cols) return;
  int row, col;
  do {
    row = rand() % rows;
    col = rand() % cols;
  } while (board[row][col] == SNAKE);
  apple = {row, col};
  board[row][col] = APPLE;
}

void Game::GenerateSnake() {
  snake.clear();
  int row = rand() % 25;
  int col = rand() % 25;
  snake = {{row, col}};
  snake_direction = col > cols / 2 ? LEFT : RIGHT;
  snake_next_direction = snake_direction;
  for (int i = 0; i < 2; i++) {
    snake.push_back(snake.back() - snake_direction);
  }
  for (const auto& snake_piece : snake) {
    board[snake_piece.r][snake_piece.c] = SNAKE;
  }
}