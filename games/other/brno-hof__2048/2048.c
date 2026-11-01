#include "2048.h"
#include <raylib.h>
#include <stdio.h>
#include <sys/time.h>

const int screenWidth = 600;
const int screenHeight = 600;
const int halfScreenWidth = screenWidth / 2;
const int halfScreenHeight = screenHeight / 2;

const int gridWidth = 400;
const int halfGridWidth = gridWidth / 2;

const int tileWidth = gridWidth / 4;
const int halfTileWidth = tileWidth / 2;

const int gridPositionX = halfScreenWidth - halfGridWidth;
const int gridPositionY = halfScreenHeight - halfGridWidth;

const Color backgroundColor = HEXSTR_TO_COLOR("#2c2f33");
const Color gridBackgroundColor = HEXSTR_TO_COLOR("#3a3d42");
const Color textColor = WHITE;

const Color tileColors[] = {
    HEXSTR_TO_COLOR("#f4d35e"), HEXSTR_TO_COLOR("#f28c28"),
    HEXSTR_TO_COLOR("#e94e1b"), HEXSTR_TO_COLOR("#d72638"),
    HEXSTR_TO_COLOR("#a01a7d"), HEXSTR_TO_COLOR("#6a0572"),
    HEXSTR_TO_COLOR("#5c3d99"), HEXSTR_TO_COLOR("#197278"),
    HEXSTR_TO_COLOR("#0d8050"), HEXSTR_TO_COLOR("#556b2f"),
    HEXSTR_TO_COLOR("#B8860B"),
};
const int numTileColors = sizeof(tileColors) / sizeof(Color);

const float diffScoreFadeOutTimeSeconds = 1.0;

const int fontSize = 32;

int main(void) {
  InitWindow(screenWidth, screenHeight, "2048");
  SetTargetFPS(60);

  // -----------------------------------------------------------------------
  // Initialize game state
  // --------------------------------------------------------------------vvv
  Grid grid = {0};
  int score = 0;

  bool hasMoved = true;
  int lastDiffScore = 0;
  bool gridLocked = false;

  struct timeval lastScoreUpdate;
  gettimeofday(&lastScoreUpdate, NULL);
  // --------------------------------------------------------------------^^^

  while (!WindowShouldClose()) {
    if (hasMoved) {
      spawnTile(grid);
      gridLocked = isGridLocked(grid);
    }

    // ------------------------------------------------------------------------
    // Handle input
    // --------------------------------------------------------------------vvv
    int diffScore = -1;
    if (IsKeyPressed(KEY_W) || IsKeyPressed(KEY_UP)) {
      diffScore = moveTilesUp(grid);
    } else if (IsKeyPressed(KEY_S) || IsKeyPressed(KEY_DOWN)) {
      diffScore = moveTilesDown(grid);
    } else if (IsKeyPressed(KEY_A) || IsKeyPressed(KEY_LEFT)) {
      diffScore = moveTilesLeft(grid);
    } else if (IsKeyPressed(KEY_D) || IsKeyPressed(KEY_RIGHT)) {
      diffScore = moveTilesRight(grid);
    }
    // --------------------------------------------------------------------^^^

    // ------------------------------------------------------------------------
    // Calculate Score
    // --------------------------------------------------------------------vvv
    if (diffScore == -1) {
      hasMoved = false;
    } else {
      hasMoved = true;
      if (diffScore > 0) {
        score += diffScore;
        lastDiffScore = diffScore;
        gettimeofday(&lastScoreUpdate, NULL);
      }
    }
    // --------------------------------------------------------------------^^^

    // ------------------------------------------------------------------------
    // Calculate time for score difference fade out
    // --------------------------------------------------------------------vvv
    float timeSinceLastScoreUpdateSeconds;
    {
      struct timeval currentTime;
      gettimeofday(&currentTime, NULL);
      long seconds = currentTime.tv_sec - lastScoreUpdate.tv_sec;
      long microseconds = currentTime.tv_usec - lastScoreUpdate.tv_usec;
      timeSinceLastScoreUpdateSeconds = seconds + microseconds * 1e-6;
    }
    // --------------------------------------------------------------------^^^

    draw(screenWidth, screenHeight, grid, score, lastDiffScore,
         timeSinceLastScoreUpdateSeconds, gridLocked);
  }

  CloseWindow();
  return 0;
}

bool isValidPosition(int x, int y) {
  return x >= 0 && x < 4 && y >= 0 && y < 4;
}

bool isGridFull(const Grid grid) {
  for (int x = 0; x < 4; x++) {
    for (int y = 0; y < 4; y++) {
      if (grid[x][y] == 0) {
        return false;
      }
    }
  }
  return true;
}

bool isGridLocked(const Grid grid) {
  if (!isGridFull(grid)) {
    return false;
  }
  const int dxs[4] = {0, 0, -1, 1};
  const int dys[4] = {-1, 1, 0, 0};
  for (int x = 0; x < 4; x++) {
    for (int y = 0; y < 4; y++) {
      for (int i = 0; i < 4; i++) {
        int dx = dxs[i];
        int dy = dys[i];
        int otherX = x + dx;
        int otherY = y + dy;
        if (isValidPosition(otherX, otherY) &&
            grid[x][y] == grid[otherX][otherY]) {
          return false;
        }
      }
    }
  }
  return true;
}

bool spawnTile(Grid grid) {
  if (isGridFull(grid)) {
    return false;
  }

  while (1) {
    int x = GetRandomValue(0, 3);
    int y = GetRandomValue(0, 3);
    if (grid[x][y] == 0) {
      grid[x][y] = 1;
      break;
    }
  }
  return true;
}

int moveTilesUp(Grid grid) {
  bool moved = false;
  int score = 0;
  for (int x = 0; x < 4; x++) {
    for (int y = 0; y < 4; y++) {
      for (int d = y + 1; d < 4; d++) {
        if (grid[x][d] == 0) {
          continue;
        }
        if (grid[x][d] == grid[x][y]) {
          grid[x][y] += 1;
          grid[x][d] = 0;
          score += POW_2(grid[x][y]);
          moved = true;
          break;
        } else if (grid[x][y] == 0) {
          grid[x][y] = grid[x][d];
          grid[x][d] = 0;
          moved = true;
        } else {
          break;
        }
      }
    }
  }
  if (!moved) {
    return -1;
  }
  return score;
}

int moveTilesDown(Grid grid) {
  bool moved = false;
  int score = 0;
  for (int x = 0; x < 4; x++) {
    for (int y = 3; y >= 0; y--) {
      for (int d = y - 1; d >= 0; d--) {
        if (grid[x][d] == 0) {
          continue;
        }
        if (grid[x][d] == grid[x][y]) {
          grid[x][y] += 1;
          grid[x][d] = 0;
          score += POW_2(grid[x][y]);
          moved = true;
          break;
        } else if (grid[x][y] == 0) {
          grid[x][y] = grid[x][d];
          grid[x][d] = 0;
          moved = true;
        } else {
          break;
        }
      }
    }
  }
  if (!moved) {
    return -1;
  }
  return score;
}

int moveTilesLeft(Grid grid) {
  bool moved = false;
  int score = 0;
  for (int x = 0; x < 4; x++) {
    for (int y = 0; y < 4; y++) {
      for (int d = x + 1; d < 4; d++) {
        if (grid[d][y] == 0) {
          continue;
        }
        if (grid[d][y] == grid[x][y]) {
          grid[x][y] += 1;
          grid[d][y] = 0;
          score += POW_2(grid[x][y]);
          moved = true;
          break;
        } else if (grid[x][y] == 0) {
          grid[x][y] = grid[d][y];
          grid[d][y] = 0;
          moved = true;
        } else {
          break;
        }
      }
    }
  }
  if (!moved) {
    return -1;
  }
  return score;
}

int moveTilesRight(Grid grid) {
  bool moved = false;
  int score = 0;
  for (int x = 3; x >= 0; x--) {
    for (int y = 0; y < 4; y++) {
      for (int d = x - 1; d >= 0; d--) {
        if (grid[d][y] == 0) {
          continue;
        }
        if (grid[d][y] == grid[x][y]) {
          grid[x][y] += 1;
          grid[d][y] = 0;
          score += POW_2(grid[x][y]);
          moved = true;
          break;
        } else if (grid[x][y] == 0) {
          grid[x][y] = grid[d][y];
          grid[d][y] = 0;
          moved = true;
        } else {
          break;
        }
      }
    }
  }
  if (!moved) {
    return -1;
  }
  return score;
}

void draw(int screenWidth, int screenHeight, Grid grid, int score,
          int diffScore, float timeSinceLastScoreUpdateSeconds,
          bool gridLocked) {

  BeginDrawing();

  ClearBackground(backgroundColor);

  DrawRectangle(gridPositionX - 1, gridPositionY - 1, gridWidth + 2,
                gridWidth + 2, gridBackgroundColor);

  // ------------------------------------------------------------------------
  // Draw Score
  // --------------------------------------------------------------------vvv
  char scoreString[32];
  sprintf(scoreString, "%d", score);

  int scoreStringWidth = MeasureText(scoreString, fontSize);
  int scorePositionX = gridPositionX + halfGridWidth - scoreStringWidth / 2;
  int scorePositionY = gridPositionY / 2 - fontSize / 2;

  DrawText(scoreString, scorePositionX, scorePositionY, fontSize, textColor);
  // --------------------------------------------------------------------^^^

  // ------------------------------------------------------------------------
  // Draw score difference and fade out
  // --------------------------------------------------------------------vvv
  if (diffScore > 0) {
    char diffScoreString[32];
    sprintf(diffScoreString, " +%d", diffScore);
    float diffScoreAlpha =
        (diffScoreFadeOutTimeSeconds - timeSinceLastScoreUpdateSeconds) /
        diffScoreFadeOutTimeSeconds;
    DrawText(diffScoreString, scorePositionX + scoreStringWidth, scorePositionY,
             fontSize, ColorAlpha(textColor, diffScoreAlpha));
  }
  // --------------------------------------------------------------------^^^

  // ------------------------------------------------------------------------
  // Draw Grid
  // --------------------------------------------------------------------vvv
  for (int x = 0; x < 4; x++) {
    int tilePositionX = gridPositionX + x * tileWidth;
    for (int y = 0; y < 4; y++) {
      int tilePositionY = gridPositionY + y * tileWidth;
      int gridValue = grid[x][y];

      Color color = gridBackgroundColor;
      if (gridValue > 0) {
        color = tileColors[(gridValue - 1) % numTileColors];
      }

      DrawRectangle(tilePositionX, tilePositionY, tileWidth, tileWidth, color);

      if (gridValue == 0) {
        continue;
      }

      char text[32];
      sprintf(text, "%d", POW_2(gridValue));

      int textWidth = MeasureText(text, fontSize);

      int textPositionX = tilePositionX + halfTileWidth - textWidth / 2;
      int textPositionY = tilePositionY + halfTileWidth - fontSize / 2;

      DrawText(text, textPositionX, textPositionY, fontSize, textColor);
    }
  }
  // --------------------------------------------------------------------^^^

  if (gridLocked) {
    DrawRectangle(gridPositionX - 1, gridPositionY - 1, gridWidth + 2,
                  gridWidth + 2, ColorAlpha(gridBackgroundColor, 0.5));
  }
  EndDrawing();
}
