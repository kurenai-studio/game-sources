#ifndef H_2048
#define H_2048
#include <stdbool.h>

#define HEX_DIGIT_TO_INT(c)                                                    \
  ((c >= '0' && c <= '9')                                                      \
       ? (c - '0')                                                             \
       : ((c >= 'a' && c <= 'f') ? (c - 'a' + 10) : (c - 'A' + 10)))

#define HEXSTR_TO_COLOR(hexStr)                                                \
  (Color) {                                                                    \
    (HEX_DIGIT_TO_INT(hexStr[1]) * 16 + HEX_DIGIT_TO_INT(hexStr[2])),          \
        (HEX_DIGIT_TO_INT(hexStr[3]) * 16 + HEX_DIGIT_TO_INT(hexStr[4])),      \
        (HEX_DIGIT_TO_INT(hexStr[5]) * 16 + HEX_DIGIT_TO_INT(hexStr[6])), 0xFF \
  }

#define POW_2(exponent) 1 << exponent

typedef int Grid[4][4];

bool isValidPosition(int x, int y);
bool isGridFull(const Grid grid);
bool isGridLocked(const Grid grid);
bool spawnTile(Grid grid);

int moveTilesUp(Grid grid);
int moveTilesDown(Grid grid);
int moveTilesLeft(Grid grid);
int moveTilesRight(Grid grid);

void draw(int screenWidth, int screenHeight, Grid grid, int score,
          int diffScore, float secondsSinceLastScoreUpdate, bool gridLocked);

#endif // !H_2048
