#include <stdio.h>
#include <stdlib.h>
#include <time.h> // Rastgele sayıların tohumlanması için
#include "raylib.h"

#define COLS 20
#define ROWS 20

const int screenWidth = 400;
const int screenHeight = 400;

const int cellWidth = screenWidth / COLS;
const int cellHeight = screenHeight / ROWS;

typedef struct Cell
{
    int x;
    int y;
    bool haveFood;
} Cell;

typedef struct Position
{
    int x;
    int y;
} Position;

typedef struct Snake
{
    Position* body;   // Dinamik dizi
    Position direction;
    int length;
    int capacity;
} Snake;

Cell grid[COLS][ROWS];

Snake snake = {
    .body = NULL,
    .direction = {1, 0},
    .length = 1,
    .capacity = 5
};

void CellDraw(Cell);
void moveSnake(void);
bool checkFood(void);

int main(void)
{
    srand(time(NULL));

    snake.body = malloc(snake.capacity * sizeof(Position));
    if (!snake.body) {
        printf("Memory allocation failed\n");
        return 1;
    }
    snake.body[0] = (Position) {2, 2};
    InitWindow(screenWidth, screenHeight, "Classic snake game with raylib");
    SetTargetFPS(15);

    for (int x = 0; x < COLS; x++) {
        for (int y = 0; y < ROWS; y++) {
            grid[x][y] = (Cell) {.x = x, .y = y};
        }
    }

    while (!WindowShouldClose())
    {
        BeginDrawing();
        ClearBackground(RAYWHITE);

        for (int x = 0; x < COLS; x++) {
            for (int y = 0; y < ROWS; y++) {
                CellDraw(grid[x][y]);
            }
        }

        switch (GetKeyPressed()) {
            case KEY_UP:
                if (snake.direction.y != 1) {
                    snake.direction.y = -1;
                    snake.direction.x = 0;
                }
                break;
            case KEY_DOWN:
                if (snake.direction.y != -1) {
                    snake.direction.y = 1;
                    snake.direction.x = 0;
                }
                break;
            case KEY_RIGHT:
                if (snake.direction.x != -1) {
                    snake.direction.y = 0;
                    snake.direction.x = 1;
                }
                break;
            case KEY_LEFT:
                if (snake.direction.x != 1) {
                    snake.direction.y = 0;
                    snake.direction.x = -1;
                }
                break;
            default:
                break;
        }

        moveSnake();

        EndDrawing();
    }

    CloseWindow();
    free(snake.body);
    return 0;
}

void CellDraw(Cell cell)
{
    if (grid[cell.x][cell.y].haveFood)
        DrawRectangle(cell.x * cellWidth, cell.y * cellHeight, cellWidth, cellHeight, BLUE);

    if (grid[cell.x][cell.y].haveFood && (snake.body[0].x == cell.x && snake.body[0].y == cell.y)) {
        grid[cell.x][cell.y].haveFood = false;
        snake.length++;
    }

    if (!checkFood()) {
        int randX, randY;
        do {
            randX = rand() % ROWS;
            randY = rand() % COLS;
        } while (grid[randX][randY].haveFood);

        grid[randX][randY].haveFood = true;
    }

    for (int i = 0; i < snake.length; i++) {
        if (cell.x == snake.body[i].x && cell.y == snake.body[i].y) {
            DrawRectangle(snake.body[i].x * cellWidth, snake.body[i].y * cellHeight, cellWidth, cellHeight, ORANGE);
        }
    }

    DrawRectangleLines(cell.x * cellWidth, cell.y * cellHeight, cellWidth, cellHeight, BLACK);
}

void moveSnake(void)
{
    for (int i = snake.length - 1; i > 0; i--) {
        snake.body[i] = snake.body[i - 1];
    }

    snake.body[0].x += snake.direction.x;
    snake.body[0].y += snake.direction.y;

    if (snake.body[0].x < 0) snake.body[0].x = COLS - 1;
    if (snake.body[0].x >= COLS) snake.body[0].x = 0;
    if (snake.body[0].y < 0) snake.body[0].y = ROWS - 1;
    if (snake.body[0].y >= ROWS) snake.body[0].y = 0;
}

bool checkFood(void)
{
    for (int x = 0; x < ROWS; x++)
    {
        for (int y = 0; y < COLS; y++)
        {
            if (grid[x][y].haveFood)
                return true;
        }
    }

    return false;
}

