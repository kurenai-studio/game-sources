#include "raylib.h"
#include <stdio.h>
#include <time.h>

#define N 4
#define ROWS 20
#define COLS 10
#define CELL_SIZE 30
#define NUM_OF_PIECES 7

typedef struct {
    Vector2 pos;
    int shape[N][N];
    Color color;
} Piece;

void CreateArea(Rectangle *r);
void DrawPlayArea(Rectangle r);
Piece GeneratePiece(Piece pieces[NUM_OF_PIECES]);
void DrawPiece(Piece *p, Rectangle r);
void SetPiecePos(Piece *p);
void MoveRight(Piece *p);
void MoveLeft(Piece *p);
void MoveDown(Piece *p);
void Rotate(Piece *p);
int CanMoveRight(Piece *p, int grid[ROWS][COLS]);
int CanMoveLeft(Piece *p, int grid[ROWS][COLS]);
int CanMoveDown(Piece *p, int grid[ROWS][COLS]);
int CanRotate(Piece *p, int grid[ROWS][COLS]);
void DrawFixedPieces(int grid[ROWS][COLS], Rectangle r);
Color GetPieceColor(int cell);

int IsRowFull(int row[COLS]);
void ShiftDown(int grid[ROWS][COLS], int row);
void ClearLines(int grid[ROWS][COLS]);
int IsGameOver(Piece *p, int grid[ROWS][COLS]);
void DrawNextPiece(Piece *p, Rectangle r, int windowWidth);

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
int main(void) {
    // Initialization
    //--------------------------------------------------------------------------------------
    const int screenWidth = 600;
    const int screenHeight = 800;

    InitWindow(screenWidth, screenHeight, "Tetris");

    SetTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    Rectangle playArea;
    CreateArea(&playArea);

    Piece L = {
        .shape = {{0, 1, 0, 0}, {0, 1, 0, 0}, {0, 1, 1, 0}, {0, 0, 0, 0}},
        .color = RED};
    Piece I = {
        .shape = {{0, 0, 2, 0}, {0, 0, 2, 0}, {0, 0, 2, 0}, {0, 0, 2, 0}},
        .color = GREEN};
    Piece J = {
        .shape = {{0, 0, 0, 0}, {0, 0, 3, 0}, {0, 0, 3, 0}, {0, 3, 3, 0}},
        .color = WHITE};
    Piece O = {
        .shape = {{0, 0, 0, 0}, {0, 4, 4, 0}, {0, 4, 4, 0}, {0, 0, 0, 0}},
        .color = ORANGE};
    Piece S = {
        .shape = {{0, 0, 0, 0}, {0, 0, 5, 5}, {0, 5, 5, 0}, {0, 0, 0, 0}},
        .color = YELLOW};
    Piece Z = {
        .shape = {{0, 0, 0, 0}, {0, 6, 6, 0}, {0, 0, 6, 6}, {0, 0, 0, 0}},
        .color = VIOLET};
    Piece T = {
        .shape = {{0, 0, 0, 0}, {0, 0, 7, 0}, {0, 7, 7, 7}, {0, 0, 0, 0}},
        .color = BLUE};

    Piece pieces[NUM_OF_PIECES] = {L, I, J, S, O, T, Z};

    SetRandomSeed(time(NULL));
    Piece currentPiece = GeneratePiece(pieces);
    SetPiecePos(&currentPiece);
    Piece nextPiece = GeneratePiece(pieces);

    int grid[ROWS][COLS] = {0};

    int timer = 0;
    int gameOver = 0;

    // Main game loop
    while (!WindowShouldClose()) // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        if (!gameOver) {

            if (!CanMoveDown(&currentPiece, grid)) {
                // Set occupied cell
                for (int i = 0; i < N; i++) {
                    for (int j = 0; j < N; j++) {
                        if (currentPiece.shape[i][j] != 0) {
                            int col = (int)currentPiece.pos.x + j;
                            int row = (int)currentPiece.pos.y + i;
                            if (row >= 0 && row < ROWS) {
                                grid[row][col] = currentPiece.shape[i][j];
                            }
                        }
                    }
                }

                ClearLines(grid);

                currentPiece = nextPiece;
                nextPiece = GeneratePiece(pieces);
                SetPiecePos(&currentPiece);

                if (IsGameOver(&currentPiece, grid)) {
                    gameOver = 1;
                }
            }

            if (IsKeyPressed(KEY_RIGHT) && CanMoveRight(&currentPiece, grid)) {
                MoveRight(&currentPiece);
            }
            if (IsKeyPressed(KEY_LEFT) && CanMoveLeft(&currentPiece, grid)) {
                MoveLeft(&currentPiece);
            }
            if (IsKeyPressed(KEY_DOWN) && CanMoveDown(&currentPiece, grid)) {
                MoveDown(&currentPiece);
            }
            if (IsKeyPressed(KEY_UP) && CanRotate(&currentPiece, grid)) {
                Rotate(&currentPiece);
            }

            timer += 5;
            if ((timer % 100 == 0) && CanMoveDown(&currentPiece, grid)) {
                currentPiece.pos.y += 1;
            }
            if (timer >= 10000) {
                timer = 0;
            }
        }
        // Draw
        //----------------------------------------------------------------------------------
        BeginDrawing();

        ClearBackground(BLACK);

        DrawPlayArea(playArea);
        DrawFixedPieces(grid, playArea);

        if (!gameOver) {
            DrawPiece(&currentPiece, playArea);
            DrawNextPiece(&nextPiece, playArea, screenWidth);
        } else {
            DrawText("Game Over!", playArea.width / 2, 50, CELL_SIZE, RED);
        }

        EndDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    CloseWindow(); // Close window and OpenGL context
    //--------------------------------------------------------------------------------------

    return 0;
}

void CreateArea(Rectangle *r) {
    Vector2 point = {100, 100};
    Vector2 size = {COLS * CELL_SIZE, ROWS * CELL_SIZE};
    r->x = point.x;
    r->y = point.y;
    r->width = size.x;
    r->height = size.y;
}

void DrawPlayArea(Rectangle r) {
    float thickness = 3;
    DrawRectangleLinesEx(r, thickness, WHITE);
}

Piece GeneratePiece(Piece pieces[NUM_OF_PIECES]) {
    int num = GetRandomValue(0, NUM_OF_PIECES - 1);
    return pieces[num];
}

void DrawPiece(Piece *p, Rectangle r) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            if (p->shape[i][j] != 0) {
                int screenX = r.x + (p->pos.x + j) * CELL_SIZE;
                int screenY = r.y + (p->pos.y + i) * CELL_SIZE;
                DrawRectangle(screenX, screenY, CELL_SIZE - 1, CELL_SIZE - 1,
                              p->color);
            }
        }
    }
}

void SetPiecePos(Piece *p) {
    p->pos.x = 3;
    p->pos.y = 0;
}

void MoveRight(Piece *p) { p->pos.x++; }
void MoveLeft(Piece *p) { p->pos.x--; }
void MoveDown(Piece *p) { p->pos.y++; }

void Rotate(Piece *p) {
    // transpose matrix
    for (int i = 0; i < N; i++) {
        for (int j = i + 1; j < N; j++) {
            int temp = p->shape[i][j];
            p->shape[i][j] = p->shape[j][i];
            p->shape[j][i] = temp;
        }
    }

    // reverse each row
    for (int i = 0; i < N; i++) {
        int start = 0, end = N - 1;
        while (start < end) {
            int temp = p->shape[i][start];
            p->shape[i][start] = p->shape[i][end];
            p->shape[i][end] = temp;

            start++;
            end--;
        }
    }
}

int CanMoveRight(Piece *p, int grid[ROWS][COLS]) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            if (p->shape[i][j] != 0) {
                int col = (int)p->pos.x + j;
                int row = (int)p->pos.y + i;
                if (col + 1 >= COLS || grid[row][col + 1] != 0) {
                    return 0;
                }
            }
        }
    }
    return 1;
}
int CanMoveLeft(Piece *p, int grid[ROWS][COLS]) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            if (p->shape[i][j] != 0) {
                int col = (int)p->pos.x + j;
                int row = (int)p->pos.y + i;
                if (col - 1 < 0 || grid[row][col - 1] != 0) {
                    return 0;
                }
            }
        }
    }
    return 1;
}

int CanMoveDown(Piece *p, int grid[ROWS][COLS]) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            if (p->shape[i][j] != 0) {
                int col = (int)p->pos.x + j;
                int row = (int)p->pos.y + i;
                if (row + 1 >= ROWS || grid[row + 1][col] != 0) {
                    return 0;
                }
            }
        }
    }
    return 1;
}

int CanRotate(Piece *p, int grid[ROWS][COLS]) {
    // copy of piece
    Piece copy = *p;
    Rotate(&copy);

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            if (copy.shape[i][j] != 0) {
                int col = copy.pos.x + j;
                int row = copy.pos.y + i;

                if (col < 0 || col >= COLS || row < 0 || row >= ROWS) {
                    return 0;
                }
                if (grid[row][col] != 0) {
                    return 0;
                }
            }
        }
    }
    return 1;
}

void DrawFixedPieces(int grid[ROWS][COLS], Rectangle r) {
    for (int i = 0; i < ROWS; i++) {
        for (int j = 0; j < COLS; j++) {
            if (grid[i][j] != 0) {
                int screenX = r.x + j * CELL_SIZE;
                int screenY = r.y + i * CELL_SIZE;
                DrawRectangle(screenX, screenY, CELL_SIZE - 1, CELL_SIZE - 1,
                              GetPieceColor(grid[i][j]));
            }
        }
    }
}

Color GetPieceColor(int cell) {
    switch (cell) {
    case 1:
        return RED;
    case 2:
        return GREEN;
    case 3:
        return WHITE;
    case 4:
        return ORANGE;
    case 5:
        return YELLOW;
    case 6:
        return VIOLET;
    case 7:
        return BLUE;
    default:
        return BLANK;
    }
}

int IsRowFull(int row[COLS]) {
    for (int i = 0; i < COLS; i++) {
        if (!row[i]) {
            return 0;
        }
    }
    return 1;
}

void ShiftDown(int grid[ROWS][COLS], int row) {
    for (int col = 0; col < COLS; col++) {
        grid[row][col] = 0;
    }
    for (int r = row; r > 0; r--) {
        for (int c = 0; c < COLS; c++) {
            grid[r][c] = grid[r - 1][c];
        }
    }
}

void ClearLines(int grid[ROWS][COLS]) {
    for (int r = 0; r < ROWS; r++) {
        if (IsRowFull(grid[r])) {
            ShiftDown(grid, r);
        }
    }
}

int IsGameOver(Piece *p, int grid[ROWS][COLS]) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            int col = p->pos.x + j;
            int row = p->pos.y + i;
            if (p->shape[i][j] != 0 && grid[row][col] != 0) {
                return 1;
            }
        }
    }
    return 0;
}

void DrawNextPiece(Piece *p, Rectangle r, int windowWidth) {
    int distanceX = windowWidth - r.x + r.width;
    distanceX = distanceX / 2;
    int distanceY = r.height / 2 - N * CELL_SIZE;
    DrawText("Next Piece:", distanceX + CELL_SIZE, distanceY, CELL_SIZE, WHITE);

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            if (p->shape[i][j] != 0) {
                int screenX = distanceX + (p->pos.x + j) * CELL_SIZE;
                int screenY =
                    distanceY + CELL_SIZE + (p->pos.y + i) * CELL_SIZE;
                DrawRectangle(screenX, screenY, CELL_SIZE - 1, CELL_SIZE - 1,
                              p->color);
            }
        }
    }
}
