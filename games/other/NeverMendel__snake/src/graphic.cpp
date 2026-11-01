#include "graphic.h"

#include <stdexcept>
#include <string>
#include <unordered_map>

#include "raylib.h"

#define SNAKE_PAIR 1
#define APPLE_PAIR 2
#define WALL_PAIR 3

Graphic::Graphic() : Graphic(25, 25) {}

Graphic::Graphic(int rows, int cols) : rows(rows), cols(cols) {
  InitWindow(kScreenWidth, kScreenHeight, "snake");
  SetTargetFPS(120);
  BeginDrawing();
  ClearBackground(BLACK);
  EndDrawing();
}

Graphic::~Graphic() { CloseWindow(); }

void Graphic::DisplayGame(const Game& game) {
  if (WindowShouldClose()) exit(0);

  BeginDrawing();
  ClearBackground(BLACK);
  // Draw grid
  for (int i = 0; i < rows; i++) {
    DrawLine(0, i * kScreenHeight / rows, kScreenWidth,
             i * kScreenHeight / rows, GRAY);
  }
  for (int i = 0; i < cols; i++) {
    DrawLine(i * kScreenWidth / cols, 0, i * kScreenWidth / cols, kScreenHeight,
             GRAY);
  }
  // Draw snake
  for (const auto& segment : game.GetSnake()) {
    DrawRectangle(segment.c * kScreenWidth / cols,
                  segment.r * kScreenHeight / rows, kScreenWidth / cols,
                  kScreenHeight / rows, GREEN);
  }
  // Draw apple
  const Cell& apple = game.GetApple();
  DrawRectangle(apple.c * kScreenWidth / cols, apple.r * kScreenHeight / rows,
                kScreenWidth / cols, kScreenHeight / rows, RED);
  // Draw score
  DrawText(std::to_string(game.GetScore()).c_str(), 10, 10, 20, WHITE);
  EndDrawing();
}

const std::unordered_map<int, Direction> kMappings = {
    // wasd
    {KEY_A, LEFT},
    {KEY_S, DOWN},
    {KEY_D, RIGHT},
    {KEY_W, UP},
    // arrows
    {KEY_LEFT, LEFT},
    {KEY_DOWN, DOWN},
    {KEY_RIGHT, RIGHT},
    {KEY_UP, UP},
};

Direction Graphic::GetDirection() const {
  for (auto const& [key, value] : kMappings) {
    if (IsKeyPressed(key)) {
      return value;
    }
  }
  throw std::runtime_error("No direction found");
}

bool Graphic::HasDirection() const {
  for (auto const& [key, value] : kMappings) {
    if (IsKeyPressed(key)) {
      return true;
    }
  }
  return false;
}