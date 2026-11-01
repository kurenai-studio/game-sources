#include <iostream>
#include <raylib.h>
#include <vector>
#include <random>
#include <algorithm>

using namespace std;

// Grid configuration
const int cellSize = 52;
const int gridCols = 10;
const int gridRows = 16;

const int screen_width = 882;
const int screen_height = cellSize * gridRows; // 832

int static score = 0;
bool gameOver = false;

vector<int> bag;
mt19937 rng(random_device{}()); // RNG = Random Number Generator

Color board[gridRows][gridCols] = {BLANK};

void DrawBoard()
{
    for (int r = 0; r < gridRows; r++)
    {
        for (int c = 0; c < gridCols; c++)
        {
            if (board[r][c].a != 0) // not BLANK
            {
                DrawRectangle(
                    c * cellSize,
                    r * cellSize,
                    cellSize,
                    cellSize,
                    board[r][c]);
            }
        }
    }
}

class Shape
{
public:
    int matrix[4][4]; // max size of the Tetromino shapes
    int size;         // 2, 3, or 4

    int posX, posY;
    float fallTimer = 0.0f;
    float fallDelay = 0.5f; // for storing the current fall delay
    float normalFallDelay = 0.5f;
    float softDropDelay = 0.05f;

    bool isLocked = false;
    Color color;

    Shape(int s, Color c) : size(s), color(c)
    {
        posX = gridCols / 2 - 1;
        posY = 0;

        // Clear matrix
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                matrix[i][j] = 0;
    }

    // ---------- DRAW ----------
    void Draw()
    {
        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (matrix[r][c] == 1)
                {
                    DrawRectangle(
                        (posX + c) * cellSize,
                        (posY + r) * cellSize,
                        cellSize,
                        cellSize,
                        color);
                }
            }
        }
    }

    // ======================================= Remove Row ===========================
    void RemoveRow(int row)
    {
        for (int r = row; r > 0; r--)
        {
            for (int c = 0; c < gridCols; c++)
            {
                board[r][c] = board[r - 1][c];
            }
        }

        // Clear the top row
        for (int c = 0; c < gridCols; c++)
        {
            board[0][c] = BLANK;
        }
    }

    // ======================================= isRowFull ?? ===========================
    bool IsRowFull(int row)
    {
        for (int c = 0; c < gridCols; c++)
        {
            if (board[row][c].a == 0)
                return false;
        }
        return true;
    }
    // ============================= scoring/lines cleared =================================
    int linesClearedThisTurn = 0;

    void ClearLines()
    {
        int linesClearedThisTurn = 0;

        for (int r = gridRows - 1; r >= 0; r--)
        {
            if (IsRowFull(r))
            {
                RemoveRow(r);
                linesClearedThisTurn++;
                r++; // recheck same row
            }
        }

        score += linesClearedThisTurn * linesClearedThisTurn * 100;
    }

    // ---------- UPDATE ----------
    void Update()
    {
        if (isLocked)
            return;

        // -------- Soft Drop --------
        if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S))
            fallDelay = softDropDelay;
        else
            fallDelay = normalFallDelay;

        // Gravity
        fallTimer += GetFrameTime();
        if (fallTimer >= fallDelay)
        {
            fallTimer += GetFrameTime();

            if (fallTimer >= fallDelay)
            {
                if (CanMoveDown())
                {
                    posY++;
                }
                else
                {
                    LockToBoard();
                    ClearLines();
                    isLocked = true;
                }
                fallTimer = 0.0f;
            }
        }

        // Horizontal movement
        if (IsKeyPressed(KEY_LEFT) || IsKeyPressed(KEY_A))
        {
            if (CanMoveLeft())
                posX--;
        }

        if (IsKeyPressed(KEY_RIGHT) || IsKeyPressed(KEY_D))
        {
            if (CanMoveRight())
                posX++;
        }

        // rotation
        if (IsKeyPressed(KEY_UP) || IsKeyPressed(KEY_W))
        {
            Rotate();
        }
    }

    //============================== Can Move Right?? ==============================
    bool CanMoveRight()
    {
        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (matrix[r][c] == 1)
                {
                    int nextCol = posX + c + 1;

                    // Hit right wall
                    if (nextCol >= gridCols)
                        return false;

                    // Hit another block
                    if (board[posY + r][nextCol].a != 0)
                        return false;
                }
            }
        }
        return true;
    }

    // ============================== Can Move Left ?? ===============================
    bool CanMoveLeft()
    {
        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (matrix[r][c] == 1)
                {
                    int nextCol = posX + c - 1;

                    // Hit left wall
                    if (nextCol < 0)
                        return false;

                    // Hit another block
                    if (board[posY + r][nextCol].a != 0)
                        return false;
                }
            }
        }
        return true;
    }

    //======================= rotate =============================
    void Rotate()
    {
        int temp[4][4] = {0};

        // Rotate clockwise
        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                temp[c][size - 1 - r] = matrix[r][c];
            }
        }

        // Check if rotation is valid
        if (CanRotate(temp))
        {
            // Apply rotation
            for (int r = 0; r < size; r++)
                for (int c = 0; c < size; c++)
                    matrix[r][c] = temp[r][c];
        }
    }

    // ========================= Can Rotate?? ======================
    bool CanRotate(int temp[4][4])
    {
        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (temp[r][c] == 1)
                {
                    int boardX = posX + c;
                    int boardY = posY + r;

                    // Out of bounds
                    if (boardX < 0 || boardX >= gridCols ||
                        boardY < 0 || boardY >= gridRows)
                        return false;

                    // Hit locked block
                    if (board[boardY][boardX].a != 0)
                        return false;
                }
            }
        }
        return true;
    }

    // Draw the shape to board when it touches the ground
    void LockToBoard()
    {
        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (matrix[r][c] == 1)
                {
                    board[posY + r][posX + c] = color;
                }
            }
        }
    }

    //======================== Can Move Down ??? =============================
    bool CanMoveDown()
    {
        for (int r = 0; r < size; r++)
        {
            for (int c = 0; c < size; c++)
            {
                if (matrix[r][c] == 1)
                {
                    int nextRow = posY + r + 1;

                    // Hit bottom of grid
                    if (nextRow >= gridRows)
                        return false;

                    // (Later) hit another block
                    if (board[nextRow][posX + c].a != 0)
                        return false;
                }
            }
        }
        return true;
    }
};

//======================================= Square ==========================================
class Square : public Shape
{
public:
    Square() : Shape(2, BLUE)
    {
        matrix[0][0] = 1;
        matrix[0][1] = 1;
        matrix[1][0] = 1;
        matrix[1][1] = 1;
    }
};

//======================================== T Shape =================================
class TShape : public Shape
{
public:
    TShape() : Shape(3, GREEN)
    {
        matrix[0][1] = 1;
        matrix[1][0] = 1;
        matrix[1][1] = 1;
        matrix[1][2] = 1;
    }
};

// ====================================== Z shape =============================

class ZShape : public Shape
{
public:
    ZShape() : Shape(3, YELLOW)
    {
        matrix[0][0] = 1;
        matrix[0][1] = 1;
        matrix[1][1] = 1;
        matrix[1][2] = 1;
    }
};

// =============================== L shape ===================================
class LShape : public Shape
{
public:
    LShape() : Shape(3, ORANGE)
    {
        matrix[0][0] = 1;
        matrix[1][0] = 1;
        matrix[2][0] = 1;
        matrix[2][1] = 1;
    }
};

// =========================== line ============================================
class line : public Shape
{
public:
    line() : Shape(4, RED)
    {
        matrix[1][0] = 1;
        matrix[1][1] = 1;
        matrix[1][2] = 1;
        matrix[1][3] = 1;
    }
};

//=========================== S Shape ====================================
class SShape : public Shape
{
public:
    SShape() : Shape(3, PINK)
    {
        matrix[0][1] = 1;
        matrix[0][2] = 1;
        matrix[1][0] = 1;
        matrix[1][1] = 1;
    }
};

//========================== J Shape ========================================
class JShape : public Shape
{
public:
    JShape() : Shape(3, GRAY)
    {
        matrix[0][1] = 1;
        matrix[1][1] = 1;
        matrix[2][0] = 1;
        matrix[2][1] = 1;
    }
};

// ============================ spawn shape =======================================
Shape *CreateShape(int type)
{
    switch (type)
    {
    case 0:
        return new Square();
    case 1:
        return new TShape();
    case 2:
        return new SShape();
    case 3:
        return new ZShape();
    case 4:
        return new LShape();
    case 5:
        return new JShape();
    case 6:
        return new line();
    }
    return new Square();
}
void RefillBag()
{
    bag = {0, 1, 2, 3, 4, 5, 6};
    shuffle(bag.begin(), bag.end(), rng);
}

Shape *SpawnShape()
{
    if (bag.empty())
        RefillBag();

    int type = bag.back();
    bag.pop_back();

    return CreateShape(type);
}

// ============================== Draw Next Shape ==================================
void DrawNextShape(Shape *shape, int startX, int startY)
{
    for (int r = 0; r < shape->size; r++)
    {
        for (int c = 0; c < shape->size; c++)
        {
            if (shape->matrix[r][c] == 1)
            {
                DrawRectangle(
                    startX + c * cellSize,
                    startY + r * cellSize,
                    cellSize,
                    cellSize,
                    shape->color);
            }
        }
    }
}

//============================ CanSpawn ===============================
bool CanSpawn(Shape *shape)
{
    for (int r = 0; r < shape->size; r++)
    {
        for (int c = 0; c < shape->size; c++)
        {
            if (shape->matrix[r][c] == 1)
            {
                int boardX = shape->posX + c;
                int boardY = shape->posY + r;

                // Outside board (should not happen, but safe)
                if (boardY < 0 || boardY >= gridRows ||
                    boardX < 0 || boardX >= gridCols)
                    return false;

                // Collision with existing block
                if (board[boardY][boardX].a != 0)
                    return false;
            }
        }
    }
    return true;
}

int main()
{
    InitWindow(screen_width, screen_height, "Tetris made by marvelboyop & Dwip");
    SetTargetFPS(60);

    Shape *currentShape = SpawnShape();
    Shape *nextShape = SpawnShape();

    while (!WindowShouldClose())
    {
        // Update
        if (!gameOver)
        {
            currentShape->Update();

            if (currentShape->isLocked)
            {
                delete currentShape;
                currentShape = nextShape;
                nextShape = SpawnShape();

                if (!CanSpawn(currentShape))
                    gameOver = true;
            }
        }

        BeginDrawing();
        ClearBackground(BLACK);

        DrawBoard();
        currentShape->Draw();

        // Grid by drawing lines
        for (int row = 0; row < gridRows; row++)
        {
            for (int col = 0; col < gridCols; col++)
            {
                DrawRectangleLines(
                    col * cellSize,
                    row * cellSize,
                    cellSize,
                    cellSize,
                    WHITE);
            }
        }

        int PrintInfoX = gridCols * cellSize + 120;
        DrawText("SCORE", PrintInfoX, 60, 40, WHITE);
        DrawText(TextFormat("%d", score), PrintInfoX, 120, 40, YELLOW);

        DrawText("NEXT", PrintInfoX, 320, 40, WHITE);
        DrawNextShape(nextShape, PrintInfoX - 20, 400);
        // Draw grid lines ONLY around preview area
        for (int r = 0; r <= nextShape->size; r++)
        {
            DrawLine(
                PrintInfoX - 20,
                400 + r * cellSize,
                PrintInfoX - 20 + nextShape->size * cellSize,
                400 + r * cellSize,
                WHITE);
        }

        for (int c = 0; c <= nextShape->size; c++)
        {
            DrawLine(
                PrintInfoX - 20 + c * cellSize,
                400,
                PrintInfoX - 20 + c * cellSize,
                400 + nextShape->size * cellSize,
                WHITE);
        }
        if (gameOver)
        {
            DrawText(
                "GAME OVER",
                gridCols * cellSize / 2 - 140 - 45,
                screen_height / 2 - 20,
                60,
                GOLD);
        }
        DrawText("marvelboyop", 620, 709, 28, GOLD);
        DrawText("&", 695, 744, 28, GOLD);
        DrawText("Dwip", 675, 777, 28, GOLD);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}