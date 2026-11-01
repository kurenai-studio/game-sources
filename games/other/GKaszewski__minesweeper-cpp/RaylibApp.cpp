#include "RaylibApp.hpp"
#include <raylib.h>

#if defined(PLATFORM_WEB)
#include <emscripten/emscripten.h>
#endif

RaylibApp::RaylibApp(MinesweeperGame &game, int width, int height,
                     const char *title)
    : m_game(game), m_windowWidth(width), m_windowHeight(height) {
  SetConfigFlags(FLAG_WINDOW_RESIZABLE);
  InitWindow(m_windowWidth, m_windowHeight, title);
  SetTargetFPS(60);
}

RaylibApp::~RaylibApp() { CloseWindow(); }

void UpdateDrawFrame(void *arg) {
  static_cast<RaylibApp *>(arg)->runOneFrame();
}

void RaylibApp::run() {
#if defined(PLATFORM_WEB)
  emscripten_set_main_loop_arg(UpdateDrawFrame, this, 0, 1);
#else
  while (!WindowShouldClose()) {
    runOneFrame();
  }
#endif
}

void RaylibApp::runOneFrame() {
  if (IsWindowResized()) {
    m_windowWidth = GetScreenWidth();
    m_windowHeight = GetScreenHeight();
  }

  auto layout =
      m_renderer.calculateLayout(m_game, m_windowWidth, m_windowHeight);
  processInput(layout);

  BeginDrawing();
  ClearBackground(RAYWHITE);
  m_renderer.draw(m_game, m_windowWidth, m_windowHeight);
  EndDrawing();
}

void RaylibApp::processInput(const RaylibRenderer::Layout &layout) {
  if (m_game.getState() == GameState::Playing) {
    int mouseX = GetMouseX();
    int mouseY = GetMouseY();

    // Map mouse to grid coordinates
    // gridX * cellSize = mouseX - offsetX -> gridX = (mouseX - offsetX) /
    // cellSize We need to guard against division by zero if cellSize is somehow
    // 0, but layout calc handles that.

    if (layout.cellSize > 0) {
      int gridX = (mouseX - layout.offsetX) / layout.cellSize;
      int gridY = (mouseY - layout.offsetY) / layout.cellSize;

      if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
        m_game.revealCell(gridX, gridY);
      }
      if (IsMouseButtonPressed(MOUSE_RIGHT_BUTTON)) {
        m_game.toggleFlag(gridX, gridY);
      }
    }
  }

  // Restart Handler
  if (IsKeyPressed(KEY_R)) {
    m_game.reset();
  }
}
